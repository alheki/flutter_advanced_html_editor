import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'html_editor_controller.dart';
import 'html_editor_theme.dart';
import 'html_editor_toolbar.dart';

/// Main HTML editor widget
///
/// A comprehensive rich text editor that combines a WebView-based editing area
/// with a customizable toolbar for formatting and content management.
class FlutterAdvancedHtmlEditor extends StatefulWidget {
  final HtmlEditorController controller;
  final String initialContent;
  final double height;
  final int? minLines;
  final HtmlEditorTheme theme;
  final String? hintText;
  final Function(String)? onContentChanged;
  final Function(Map<String, dynamic>)? onSelectionChanged;
  final bool showToolbar;
  final List<HtmlEditorToolbarItem>? customToolbarItems;
  final BoxDecoration? boxDecoration;
  final BoxDecoration? errorBoxDecoration;
  final double? borderRadius;
  final Widget? loadingWidget;
  final int? maxLength;
  final int? minLength;
  final Function(String)? onLimitExceeded;
  final bool enabled;

  const FlutterAdvancedHtmlEditor({
    super.key,
    required this.controller,
    this.initialContent = '',
    this.height = 400,
    required this.theme,
    this.onContentChanged,
    this.onSelectionChanged,
    this.showToolbar = true,
    this.customToolbarItems,
    this.boxDecoration,
    this.errorBoxDecoration,
    this.borderRadius,
    this.loadingWidget,
    this.maxLength,
    this.minLength,
    this.hintText,
    this.onLimitExceeded,
    this.enabled=true,
    this.minLines,
  });

  @override
  State<FlutterAdvancedHtmlEditor> createState() => FlutterAdvancedHtmlEditorState();
}

class FlutterAdvancedHtmlEditorState extends State<FlutterAdvancedHtmlEditor> {
  late WebViewController _webViewController;
  bool _isLoaded = false;
  String _currentContent = '';
  String _pendingInitialContent = '';
  bool _contentWasTruncated = false; // Track if content was truncated
  final Completer<void> _editorReadyCompleter = Completer<void>();

  @override
  void initState() {
    super.initState();

    // Process initial content with smart truncation
    _processInitialContent();

    _initializeWebView();
    widget.controller.setWidget(this);

    // Fallback timer
    Timer(const Duration(seconds: 10), () {
      if (mounted && !_isLoaded) {
        setState(() {
          _isLoaded = true;
        });
        if (!_editorReadyCompleter.isCompleted) {
          _editorReadyCompleter.complete();
        }
      }
    });
  }

  /// Process and truncate initial content if needed
  void _processInitialContent() {
    _pendingInitialContent = widget.initialContent.substring(0, widget.maxLength);
    _contentWasTruncated = false;

    if (widget.initialContent.isNotEmpty && widget.maxLength != null) {
      if (widget.initialContent.length > widget.maxLength!) {
        // Use smart truncation that preserves words and HTML structure
        _pendingInitialContent = _truncateHtmlContent(widget.initialContent, widget.maxLength!);
        _contentWasTruncated = true;

        // Log truncation for debugging
        debugPrint('Initial content truncated: ${widget.initialContent.length} → ${_pendingInitialContent.length} characters');

        // Optionally notify about truncation via callback
        if (widget.onLimitExceeded != null) {
          Future.microtask(() => widget.onLimitExceeded!(
              'Initial content was truncated from ${widget.initialContent.length} to ${widget.maxLength} characters'
          ),);
        }
      }
    }
  }

  /// Smart HTML content truncation that preserves structure
  String _truncateHtmlContent(String content, int maxLength) {
    if (content.length <= maxLength) {
      return content;
    }

    // First, try to truncate plain text and preserve basic structure
    String truncated = content.substring(0, maxLength);

    // If content appears to be HTML, try to maintain tag integrity
    if (content.contains('<') && content.contains('>')) {
      // Find the last complete tag before the cut-off point
      final int lastCompleteTag = _findLastCompleteTag(truncated);
      if (lastCompleteTag > maxLength * 0.7) { // If we found a good break point
        truncated = truncated.substring(0, lastCompleteTag);
      }

      // Ensure we don't leave unclosed tags
      truncated = _closeOpenTags(truncated);
    } else {
      // For plain text, try to break at word boundary
      final int lastSpaceIndex = truncated.lastIndexOf(' ');
      if (lastSpaceIndex > maxLength * 0.8) {
        truncated = truncated.substring(0, lastSpaceIndex);
      }
    }

    return truncated;
  }

  /// Find the last complete HTML tag in the truncated content
  int _findLastCompleteTag(String truncated) {
    final int lastClosingBracket = truncated.lastIndexOf('>');
    if (lastClosingBracket == -1) return truncated.length;

    // Look backwards for the corresponding opening bracket
    final String beforeClosing = truncated.substring(0, lastClosingBracket);
    final int lastOpeningBracket = beforeClosing.lastIndexOf('<');

    if (lastOpeningBracket != -1) {
      return lastClosingBracket + 1;
    }

    return truncated.length;
  }

  /// Close any open HTML tags to maintain valid structure
  String _closeOpenTags(String html) {
    // Simple approach: find unclosed tags and close them
    final RegExp openTagRegex = RegExp(r'<(\w+)[^>]*>(?![^<]*</\1>)');
    final List<String> openTags = [];

    final Iterable<RegExpMatch> matches = openTagRegex.allMatches(html);
    for (RegExpMatch match in matches) {
      final String tagName = match.group(1)!.toLowerCase();
      // Skip self-closing tags
      if (!['img', 'br', 'hr', 'input', 'meta', 'link'].contains(tagName)) {
        openTags.add(tagName);
      }
    }

    // Close open tags in reverse order
    String result = html;
    for (String tag in openTags.reversed) {
      result += '</$tag>';
    }

    return result;
  }

  /// Enhanced _loadEditor method using processed content
  void _loadEditor() async {
    try {
      await _waitForEditorReady();

      // Set limits after editor is ready
      await _setLimits();

      // Use processed initial content
      if (_pendingInitialContent.isNotEmpty) {
        await setContent(_pendingInitialContent);

        // Update current content to reflect what was actually set
        _currentContent = _pendingInitialContent;

        // Trigger content changed callback if content was truncated
        if (_contentWasTruncated && widget.onContentChanged != null) {
          widget.onContentChanged!(_pendingInitialContent);
        }
      }

      if (mounted) {
        setState(() {
          _isLoaded = true;
        });
      }

      if (!_editorReadyCompleter.isCompleted) {
        _editorReadyCompleter.complete();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoaded = true;
        });
      }
      if (!_editorReadyCompleter.isCompleted) {
        _editorReadyCompleter.complete();
      }
    }
  }



  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            // debugPrint('Page started loading: $url');
          },
          onPageFinished: (String url) {
            // debugPrint('Page finished loading: $url');
            _loadEditor();
          },
          onWebResourceError: (WebResourceError error) {
            // debugPrint('WebView error: ${error.description}');
            if (!_isLoaded) {
              Future.delayed(const Duration(milliseconds: 500), () {
                if (!_isLoaded) {
                  setState(() {
                    _isLoaded = true;
                  });
                }
              });
            }
          },
        ),
      )
      ..addJavaScriptChannel(
        'HtmlEditor',
        onMessageReceived: (JavaScriptMessage message) {
          _handleJavaScriptMessage(message.message);
        },
      );

    _loadInitialContent();
  }

  void _loadInitialContent() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        final htmlContent = _generateHtmlContent();
        _webViewController.loadHtmlString(htmlContent);
      }
    });
  }


  Future<void> _setLimits() async {
    try {
      final limitsScript = '''
        if (flutterEditor) {
          flutterEditor.setLimits({
            maxLength: ${widget.maxLength ?? 'null'},
            minLength: 'null',
            maxLines:  'null',
            minLines: 'null'
          });
        }
      ''';
      await _webViewController.runJavaScript(limitsScript);
    } catch (e) {
      // debugPrint('Error setting limits: $e');
    }
  }

  Future<void> _waitForEditorReady() async {
    int attempts = 0;
    const maxAttempts = 30;
    const delay = Duration(milliseconds: 200);

    while (attempts < maxAttempts) {
      try {
        final result = await _webViewController.runJavaScriptReturningResult(
            'typeof flutterEditor !== "undefined" && flutterEditor !== null'
        );

        if (result.toString() == 'true') {
          return;
        }
      } catch (e) {
        // debugPrint('Attempt ${attempts + 1}: Editor not ready yet - $e');
      }

      attempts++;
      await Future.delayed(delay);
    }

    throw Exception('Editor initialization timeout');
  }

  String _generateHtmlContent() {
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
    <title>HTML Editor</title>
    <style>
        ${_generateCSS()}
    </style>
</head>
<body>
    <div class="editor-container">
        <div class="editor" id="editor" contenteditable="true" spellcheck="true" role="textbox" aria-label="Text editor">
        </div>
        <div class="editor-status" id="editorStatus" style="display: none;"></div>
    </div>
    <script>
        ${_generateJavaScript()}
    </script>
</body>
</html>
    ''';
  }

  String _generateCSS() {
    return '''
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background-color: ${widget.theme.backgroundColor};
            color: ${widget.theme.textColor};
            line-height: 1.6;
            overflow: hidden;
        }
        
        .editor-container {
            width: 100%;
            height: 100vh;
            display: flex;
            flex-direction: column;
        }
        
        .editor {
            flex: 1;
            padding: 16px;
            outline: none;
            font-size: 16px;
            line-height: 1.6;
            color: ${widget.theme.textColor};
            background: ${widget.theme.backgroundColor};
            overflow-y: auto;
            overflow-x: hidden;
            word-wrap: break-word;
            -webkit-overflow-scrolling: touch;
            min-height: 100%;
        }
        
        .editor:focus {
            outline: none;
            background: ${widget.theme.backgroundColor};
        }
        
        .editor p {
            margin-bottom: 12px;
        }
        
        .editor:empty:before {
            content: attr(data-placeholder);
            color: ${widget.theme.secondaryTextColor};
            opacity: 0.6;
            pointer-events: none;
        }
        
        .editor-status {
            padding: 8px 16px;
            font-size: 12px;
            background: ${widget.theme.surfaceColor};
            border-top: 1px solid ${widget.theme.borderColor};
            color: ${widget.theme.secondaryTextColor};
            text-align: right;
        }
        
        .editor-status.warning {
            color: #ff6b6b;
            background: rgba(255, 107, 107, 0.1);
        }
        
        .editor-status.error {
            color: #ff3333;
            background: rgba(255, 51, 51, 0.1);
        }
        
      
        
        .editor h1, .editor h2, .editor h3, .editor h4, .editor h5, .editor h6 {
            margin-bottom: 16px;
            font-weight: 600;
        }
        
        .editor h1 { font-size: 2em; }
        .editor h2 { font-size: 1.5em; }
        .editor h3 { font-size: 1.3em; }
        .editor h4 { font-size: 1.1em; }
        .editor h5 { font-size: 1em; }
        .editor h6 { font-size: 0.9em; }
        
        .editor ul, .editor ol {
            margin: 16px 0;
            padding-left: 32px;
        }
        
        .editor li {
            margin-bottom: 8px;
        }
        
        .editor table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
            border: 1px solid ${widget.theme.borderColor};
            table-layout: fixed;
        }
        
        .editor th, .editor td {
            border: 1px solid ${widget.theme.borderColor};
            padding: 8px 12px;
            text-align: left;
            word-wrap: break-word;
        }
        
        .editor th {
            background: ${widget.theme.surfaceColor};
            font-weight: 600;
        }
        
        .editor blockquote {
            border-left: 4px solid ${widget.theme.primaryColor};
            padding-left: 16px;
            margin: 16px 0;
            color: ${widget.theme.secondaryTextColor};
            font-style: italic;
        }
        
        .editor code {
            background: ${widget.theme.surfaceColor};
            border: 1px solid ${widget.theme.borderColor};
            border-radius: 4px;
            padding: 2px 6px;
            font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
            font-size: 0.9em;
        }
        
        .editor pre {
            background: ${widget.theme.surfaceColor};
            border: 1px solid ${widget.theme.borderColor};
            border-radius: 6px;
            padding: 16px;
            margin: 16px 0;
            overflow-x: auto;
            white-space: pre;
            font-family: 'Monaco', 'Menlo', 'Ubuntu Mono', monospace;
            font-size: 0.9em;
        }
        
        .editor pre code {
            background: none;
            border: none;
            padding: 0;
        }
        
        .editor img {
            max-width: 100%;
            height: auto;
            border-radius: 6px;
            margin: 10px 0;
            display: block;
        }
        
        .editor a {
            color: ${widget.theme.primaryColor};
            text-decoration: underline;
        }
        
        .editor ::selection {
            background: ${widget.theme.selectionColor};
        }
        
        .editor::-webkit-scrollbar {
            width: 8px;
        }
        
        .editor::-webkit-scrollbar-track {
            background: transparent;
        }
        
        .editor::-webkit-scrollbar-thumb {
            background: ${widget.theme.borderColor};
            border-radius: 4px;
        }
        
        .editor::-webkit-scrollbar-thumb:hover {
            background: ${widget.theme.secondaryTextColor};
        }
    ''';
  }

  String _generateJavaScript() {
    return '''
        class FlutterHtmlEditor {
            constructor() {
                this.editor = document.getElementById('editor');
                this.statusElement = document.getElementById('editorStatus');
                this.history = [];
                this.historyStep = -1;
                this.maxHistory = 50;
                this.debounceTimer = null;
                this.selectionTimer = null;
                this.limits = {
                    maxLength: null,
                    minLength: null,
                    maxLines: null,
                    minLines: null
                };
                
                this.init();
            }
            
            init() {
                if (!this.editor) {
                    console.error('Editor element not found');
                    return;
                }
                
                this.setupEditor();
                this.setupEventListeners();
                this.saveState();
            }
            
            setupEditor() {
                this.editor.setAttribute('spellcheck', 'true');
                this.editor.setAttribute('data-placeholder', '${widget.hintText??'Start typing...'}');
                
                try {
                    document.execCommand('defaultParagraphSeparator', false, 'p');
                } catch (e) {
                    console.warn('Could not set default paragraph separator:', e);
                }
            }
            
            setLimits(limits) {
                this.limits = { ...this.limits, ...limits };
                this.updateStatus();
            }
            
            setupEventListeners() {
                this.editor.addEventListener('input', (e) => {
                    if (!this.checkLimits(e)) {
                        e.preventDefault();
                        return false;
                    }
                    this.debounceContentChange();
                });
                
                this.editor.addEventListener('keydown', (e) => {
                    this.handleKeyDown(e);
                });
                
                this.editor.addEventListener('beforeinput', (e) => {
                    if (e.inputType === 'insertText' || e.inputType === 'insertCompositionText') {
                        if (!this.checkTextInput(e.data || '')) {
                            e.preventDefault();
                            return false;
                        }
                    }
                });
                
                document.addEventListener('selectionchange', () => {
                    if (document.activeElement === this.editor) {
                        this.debounceSelectionChange();
                    }
                });
                
                this.editor.addEventListener('paste', (e) => {
                    this.handlePaste(e);
                });
                
                this.editor.addEventListener('focus', () => {
                    this.notifySelectionChanged();
                });
            }
            
            checkLimits(e) {
                const currentText = this.getText();
                const currentLines = this.getLineCount();
                
                // Check max length
                if (this.limits.maxLength && currentText.length > this.limits.maxLength) {
                    this.showLimitError('maxLength', currentText.length, this.limits.maxLength);
                    return false;
                }
                
                // Check max lines
                if (this.limits.maxLines && currentLines > this.limits.maxLines) {
                    this.showLimitError('maxLines', currentLines, this.limits.maxLines);
                    return false;
                }
                
                this.updateStatus();
                return true;
            }
            
            checkTextInput(text) {
                const currentText = this.getText();
                const newLength = currentText.length + text.length;
                
                if (this.limits.maxLength && newLength > this.limits.maxLength) {
                    this.showLimitError('maxLength', newLength, this.limits.maxLength);
                    return false;
                }
                
                // Check if adding text would exceed line limit
                const newLineCount = (text.match(/\\n/g) || []).length;
                const currentLines = this.getLineCount();
                
                if (this.limits.maxLines && (currentLines + newLineCount) > this.limits.maxLines) {
                    this.showLimitError('maxLines', currentLines + newLineCount, this.limits.maxLines);
                    return false;
                }
                
                return true;
            }
            
            getLineCount() {
                const text = this.getText();
                if (!text.trim()) return 1;
                return text.split('\\n').length;
            }
            
            updateStatus() {
                if (!this.statusElement) return;
                
                const text = this.getText();
                const lines = this.getLineCount();
                
                let statusText = '';
                let statusClass = '';
                let showStatus = false;
                
                // Character count status
                // if (this.limits.maxLength) {
                //     const remaining = this.limits.maxLength - text.length;
                //     statusText += \`Characters: \${text.length}/\${this.limits.maxLength}\`;
                //    
                //     if (remaining < 20) {
                //         statusClass = remaining <= 0 ? 'error' : 'warning';
                //         showStatus = true;
                //     }
                // }
                //
                // // Line count status
                // if (this.limits.maxLines) {
                //     if (statusText) statusText += ' | ';
                //     const remaining = this.limits.maxLines - lines;
                //     statusText += \`Lines: \${lines}/\${this.limits.maxLines}\`;
                //    
                //     if (remaining < 3) {
                //         statusClass = remaining <= 0 ? 'error' : 'warning';
                //         showStatus = true;
                //     }
                // }
                
                if (showStatus || this.limits.maxLength || this.limits.maxLines) {
                    this.statusElement.textContent = statusText;
                    this.statusElement.className = 'editor-status ' + statusClass;
                    // this.statusElement.style.display = 'block';
                    
                    // Update editor styling
                    this.editor.className = 'editor ' + (statusClass ? 'limit-' + statusClass : '');
                } else {
                    this.statusElement.style.display = 'none';
                    this.editor.className = 'editor';
                }
            }
            
            showLimitError(type, current, limit) {
                const message = type === 'maxLength' 
                    ? \`Character limit exceeded: \${current}/\${limit}\`
                    : \`Line limit exceeded: \${current}/\${limit}\`;
                    
                if (window.HtmlEditor && window.HtmlEditor.postMessage) {
                    window.HtmlEditor.postMessage(JSON.stringify({
                        type: 'limitExceeded',
                        limitType: type,
                        current: current,
                        limit: limit,
                        message: message
                    }));
                }
            }
            
            validateMinimums() {
                const text = this.getText();
                const lines = this.getLineCount();
                
                const errors = [];
                
                if (this.limits.minLength && text.length < this.limits.minLength) {
                    errors.push(\`Minimum \${this.limits.minLength} characters required (current: \${text.length})\`);
                }
                
                if (this.limits.minLines && lines < this.limits.minLines) {
                    errors.push(\`Minimum \${this.limits.minLines} lines required (current: \${lines})\`);
                }
                
                return {
                    valid: errors.length === 0,
                    errors: errors
                };
            }
            
            handleKeyDown(e) {
                // Handle Ctrl+Z (Undo) and Ctrl+Y (Redo)
                if (e.ctrlKey || e.metaKey) {
                    if (e.key === 'z' && !e.shiftKey) {
                        e.preventDefault();
                        this.undo();
                        return;
                    } else if (e.key === 'y' || (e.key === 'z' && e.shiftKey)) {
                        e.preventDefault();
                        this.redo();
                        return;
                    }
                }
                
                // Handle Enter key
                if (e.key === 'Enter') {
                    const currentLines = this.getLineCount();
                    if (this.limits.maxLines && currentLines >= this.limits.maxLines) {
                        e.preventDefault();
                        this.showLimitError('maxLines', currentLines + 1, this.limits.maxLines);
                        return false;
                    }
                    this.handleEnterKey(e);
                }
            }
            
            handleEnterKey(e) {
                const selection = window.getSelection();
                if (!selection.rangeCount) return;
                
                const range = selection.getRangeAt(0);
                const container = range.commonAncestorContainer;
                
                const listItem = container.nodeType === Node.TEXT_NODE 
                    ? container.parentElement?.closest('li')
                    : container.closest?.('li');
                
                if (listItem) {
                    return;
                }
                
                if (!range.collapsed) {
                    range.deleteContents();
                }
                
                const p = document.createElement('p');
                const br = document.createElement('br');
                p.appendChild(br);
                
                range.insertNode(p);
                range.setStart(p, 0);
                range.collapse(true);
                selection.removeAllRanges();
                selection.addRange(range);
                
                e.preventDefault();
            }
            
            handlePaste(e) {
                e.preventDefault();
                
                const clipboardData = e.clipboardData || window.clipboardData;
                if (!clipboardData) return;
                
                let content = clipboardData.getData('text/html');
                if (!content) {
                    content = clipboardData.getData('text/plain');
                    if (content) {
                        content = this.sanitizePlainText(content);
                    }
                } else {
                    content = this.sanitizeHTML(content);
                }
                
                if (content) {
                    // Check if pasted content would exceed limits
                    const currentText = this.getText();
                    const pastedText = this.extractTextFromHTML(content);
                    const newLength = currentText.length + pastedText.length;
                    
                    if (this.limits.maxLength && newLength > this.limits.maxLength) {
                        // Truncate content to fit
                        const remaining = this.limits.maxLength - currentText.length;
                        const truncatedText = pastedText.substring(0, remaining);
                        content = truncatedText.replace(/\\n/g, '<br>');
                    }
                    
                    this.insertHTML(content);
                }
            }
            
            extractTextFromHTML(html) {
                const div = document.createElement('div');
                div.innerHTML = html;
                return div.textContent || div.innerText || '';
            }
            
            sanitizePlainText(text) {
                return text.replace(/\\n/g, '<br>').replace(/\\r/g, '');
            }
            
            sanitizeHTML(html) {
                const div = document.createElement('div');
                div.innerHTML = html;
                
                const scripts = div.querySelectorAll('script');
                scripts.forEach(script => script.remove());
                
                const allElements = div.querySelectorAll('*');
                allElements.forEach(el => {
                    Array.from(el.attributes).forEach(attr => {
                        if (attr.name.startsWith('on') || (attr.name === 'href' && attr.value.startsWith('javascript:'))) {
                            el.removeAttribute(attr.name);
                        }
                    });
                });
                
                return div.innerHTML;
            }
            
            debounceContentChange() {
                clearTimeout(this.debounceTimer);
                this.debounceTimer = setTimeout(() => {
                    this.saveState();
                    this.updateStatus();
                    this.notifyContentChanged();
                }, 300);
            }
            
            debounceSelectionChange() {
                clearTimeout(this.selectionTimer);
                this.selectionTimer = setTimeout(() => {
                    this.notifySelectionChanged();
                }, 100);
            }
            
            executeCommand(command, value = null) {
                try {
                    const success = document.execCommand(command, false, value);
                    if (success) {
                        this.editor.focus();
                        this.saveState();
                        this.updateStatus();
                        this.notifyContentChanged();
                    }
                    return success;
                } catch (e) {
                    console.error('Command execution failed:', command, e);
                    return false;
                }
            }
            
            getContent() {
                return this.editor.innerHTML;
            }
            
            getText() {
                return this.editor.textContent || this.editor.innerText || '';
            }
            
            setContent(content) {
                this.editor.innerHTML = content || '';
                this.saveState();
                this.updateStatus();
                this.notifyContentChanged();
            }
            
            insertHTML(html) {
                const selection = window.getSelection();
                if (!selection.rangeCount) {
                    this.editor.focus();
                    const range = document.createRange();
                    range.selectNodeContents(this.editor);
                    range.collapse(false);
                    selection.removeAllRanges();
                    selection.addRange(range);
                }
                
                try {
                    const success = document.execCommand('insertHTML', false, html);
                    if (success) {
                        this.saveState();
                        this.updateStatus();
                        this.notifyContentChanged();
                    }
                } catch (e) {
                    console.error('Insert HTML failed:', e);
                }
            }
            
            saveState() {
                const state = this.editor.innerHTML;
                
                if (this.history[this.historyStep] === state) {
                    return;
                }
                
                this.history = this.history.slice(0, this.historyStep + 1);
                this.history.push(state);
                
                if (this.history.length > this.maxHistory) {
                    this.history = this.history.slice(-this.maxHistory);
                    this.historyStep = this.maxHistory - 1;
                } else {
                    this.historyStep = this.history.length - 1;
                }
            }
            
            undo() {
                if (this.historyStep > 0) {
                    this.historyStep--;
                    this.editor.innerHTML = this.history[this.historyStep];
                    this.editor.focus();
                    this.updateStatus();
                    this.notifyContentChanged();
                    return true;
                }
                return false;
            }
            
            redo() {
                if (this.historyStep < this.history.length - 1) {
                    this.historyStep++;
                    this.editor.innerHTML = this.history[this.historyStep];
                    this.editor.focus();
                    this.updateStatus();
                    this.notifyContentChanged();
                    return true;
                }
                return false;
            }
            
            notifyContentChanged() {
                try {
                    const content = this.getContent();
                    const text = this.getText();
                    const words = text.trim() ? text.trim().split(/\\s+/).length : 0;
                    const lines = this.getLineCount();
                    const validation = this.validateMinimums();
                    
                    if (window.HtmlEditor && window.HtmlEditor.postMessage) {
                        window.HtmlEditor.postMessage(JSON.stringify({
                            type: 'contentChanged',
                            content: content,
                            text: text,
                            wordCount: words,
                            charCount: text.length,
                            lineCount: lines,
                            validation: validation
                        }));
                    }
                } catch (e) {
                    console.error('Failed to notify content changed:', e);
                }
            }
            
            notifySelectionChanged() {
                try {
                    const selection = window.getSelection();
                    
                    if (window.HtmlEditor && window.HtmlEditor.postMessage) {
                        window.HtmlEditor.postMessage(JSON.stringify({
                            type: 'selectionChanged',
                            hasSelection: selection.toString().length > 0,
                            selectedText: selection.toString(),
                            isBold: document.queryCommandState('bold'),
                            isItalic: document.queryCommandState('italic'),
                            isUnderline: document.queryCommandState('underline')
                        }));
                    }
                } catch (e) {
                    console.error('Failed to notify selection changed:', e);
                }
            }
            
            insertTable(rows, cols) {
                let tableHTML = '<table>';
                
                for (let i = 0; i < rows; i++) {
                    tableHTML += '<tr>';
                    for (let j = 0; j < cols; j++) {
                        const cellType = i === 0 ? 'th' : 'td';
                        const cellContent = i === 0 ? \`Header \${j + 1}\` : '';
                        tableHTML += \`<\${cellType}>\${cellContent}</\${cellType}>\`;
                    }
                    tableHTML += '</tr>';
                }
                
                tableHTML += '</table>';
                this.insertHTML(tableHTML);
            }
            
            insertLink(url, text) {
                if (!url) return;
                
                if (text) {
                    this.insertHTML(\`<a href="\${url}" target="_blank">\${text}</a>\`);
                } else {
                    this.executeCommand('createLink', url);
                }
            }
            
            insertImage(url, alt = '') {
                if (!url) return;
                this.insertHTML(\`<img src="\${url}" alt="\${alt}">\`);
            }
            
            focus() {
                this.editor.focus();
            }
        }
        
        // Initialize the editor when DOM is ready
        let flutterEditor;
        
        function initializeEditor() {
            try {
                const editorElement = document.getElementById('editor');
                if (editorElement) {
                    flutterEditor = new FlutterHtmlEditor();
                    console.log('Flutter HTML Editor initialized successfully');
                    
                    // Notify Flutter that editor is ready
                    if (window.HtmlEditor && window.HtmlEditor.postMessage) {
                        window.HtmlEditor.postMessage(JSON.stringify({
                            type: 'editorReady',
                            ready: true
                        }));
                    }
                } else {
                    console.error('Editor element not found during initialization');
                    setTimeout(initializeEditor, 100); // Retry after 100ms
                }
            } catch (error) {
                console.error('Error initializing editor:', error);
                setTimeout(initializeEditor, 100); // Retry on error
            }
        }
        
        // Multiple initialization strategies
        if (document.readyState === 'loading') {
            document.addEventListener('DOMContentLoaded', initializeEditor);
        } else {
            // DOM is already ready
            initializeEditor();
        }
        
        // Backup initialization after a delay
        setTimeout(initializeEditor, 500);
        
        // Global functions for Flutter to call
        function executeCommand(command, value) {
            return flutterEditor ? flutterEditor.executeCommand(command, value) : false;
        }
        
        function getContent() {
            return flutterEditor ? flutterEditor.getContent() : '';
        }
        
        function setContent(content) {
            if (flutterEditor) {
                flutterEditor.setContent(content);
                return true;
            }
            return false;
        }
        
        function insertHTML(html) {
            if (flutterEditor) {
                flutterEditor.insertHTML(html);
                return true;
            }
            return false;
        }
        
        function undo() {
            return flutterEditor ? flutterEditor.undo() : false;
        }
        
        function redo() {
            return flutterEditor ? flutterEditor.redo() : false;
        }
        
        function insertTable(rows, cols) {
            if (flutterEditor) {
                flutterEditor.insertTable(rows, cols);
                return true;
            }
            return false;
        }
        
        function insertLink(url, text) {
            if (flutterEditor) {
                flutterEditor.insertLink(url, text);
                return true;
            }
            return false;
        }
        
        function insertImage(url, alt) {
            if (flutterEditor) {
                flutterEditor.insertImage(url, alt);
                return true;
            }
            return false;
        }
        
        function focusEditor() {
            if (flutterEditor) {
                flutterEditor.focus();
                return true;
            }
            return false;
        }
        
        function validateContent() {
            return flutterEditor ? flutterEditor.validateMinimums() : { valid: false, errors: [] };
        }
    ''';
  }

  void _handleJavaScriptMessage(String message) {
    try {
      final data = json.decode(message);
      final type = data['type'] as String;

      switch (type) {
        case 'editorReady':
          if (mounted && !_isLoaded) {
            setState(() {
              _isLoaded = true;
            });
          }
          if (!_editorReadyCompleter.isCompleted) {
            _editorReadyCompleter.complete();
          }
          break;
        case 'contentChanged':
          setState(() {
            _currentContent = data['content'] as String? ?? '';
          });
          if (widget.onContentChanged != null) {
            widget.onContentChanged!(_currentContent);
          }
          break;
        case 'selectionChanged':
          if (widget.onSelectionChanged != null) {
            widget.onSelectionChanged!(Map<String, dynamic>.from(data));
          }
          break;
        case 'limitExceeded':
          if (widget.onLimitExceeded != null) {
            widget.onLimitExceeded!(data['message'] as String);
          }
          break;
        default:
        // debugPrint('Unhandled message type: $type');
      }
    } catch (e) {
      // debugPrint('Error handling JavaScript message: $e');
    }
  }

  Future<void> executeCommand(String command, [String? value]) async {
    try {
      await _editorReadyCompleter.future.timeout(const Duration(seconds: 5));

      final script = value != null
          ? 'executeCommand("$command", "${_escapeForJavaScript(value)}")'
          : 'executeCommand("$command")';

      await _webViewController.runJavaScript(script);
    } catch (e) {
      // debugPrint('Error executing command $command: $e');
    }
  }

  Future<String> getContent() async {
    try {
      await _editorReadyCompleter.future.timeout(const Duration(seconds: 5));

      final result = await _webViewController.runJavaScriptReturningResult('getContent()');
      return _unescapeFromJavaScript(result.toString());
    } catch (e) {
      // debugPrint('Error getting content: $e');
      return _currentContent;
    }
  }

  Future<void> setContent(String content) async {
    try {
      await _editorReadyCompleter.future.timeout(const Duration(seconds: 5));

      final escapedContent = _escapeForJavaScript(content);
      await _webViewController.runJavaScript('setContent("$escapedContent")');
    } catch (e) {
      // debugPrint('Error setting content: $e');
    }
  }

  Future<void> insertHTML(String html) async {
    try {
      await _editorReadyCompleter.future.timeout(const Duration(seconds: 5));

      final escapedHtml = _escapeForJavaScript(html);
      await _webViewController.runJavaScript('insertHTML("$escapedHtml")');
    } catch (e) {
      // debugPrint('Error inserting HTML: $e');
    }
  }

  Future<void> undo() async {
    try {
      await _editorReadyCompleter.future.timeout(const Duration(seconds: 5));
      await _webViewController.runJavaScript('undo()');
    } catch (e) {
      // debugPrint('Error executing undo: $e');
    }
  }

  Future<void> redo() async {
    try {
      await _editorReadyCompleter.future.timeout(const Duration(seconds: 5));
      await _webViewController.runJavaScript('redo()');
    } catch (e) {
      // debugPrint('Error executing redo: $e');
    }
  }

  Future<void> insertTable(int rows, int cols) async {
    try {
      await _editorReadyCompleter.future.timeout(const Duration(seconds: 5));
      await _webViewController.runJavaScript('insertTable($rows, $cols)');
    } catch (e) {
      // debugPrint('Error inserting table: $e');
    }
  }

  Future<void> insertLink(String url, String text) async {
    try {
      await _editorReadyCompleter.future.timeout(const Duration(seconds: 5));
      final escapedUrl = _escapeForJavaScript(url);
      final escapedText = _escapeForJavaScript(text);
      await _webViewController.runJavaScript('insertLink("$escapedUrl", "$escapedText")');
    } catch (e) {
      // debugPrint('Error inserting link: $e');
    }
  }

  Future<void> insertImage(String url, [String alt = '']) async {
    try {
      await _editorReadyCompleter.future.timeout(const Duration(seconds: 5));
      final escapedUrl = _escapeForJavaScript(url);
      final escapedAlt = _escapeForJavaScript(alt);
      await _webViewController.runJavaScript('insertImage("$escapedUrl", "$escapedAlt")');
    } catch (e) {
      // debugPrint('Error inserting image: $e');
    }
  }

  Future<void> focus() async {
    try {
      await _editorReadyCompleter.future.timeout(const Duration(seconds: 5));
      await _webViewController.runJavaScript('focusEditor()');
    } catch (e) {
      // debugPrint('Error focusing editor: $e');
    }
  }

  /// Validates content against minimum requirements
  Future<Map<String, dynamic>> validateContent() async {
    try {
      await _editorReadyCompleter.future.timeout(const Duration(seconds: 5));
      final result = await _webViewController.runJavaScriptReturningResult('validateContent()');
      return json.decode(result.toString());
    } catch (e) {
      // debugPrint('Error validating content: $e');
      return {'valid': false, 'errors': []};
    }
  }

  String _escapeForJavaScript(String text) {
    return text
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll('\t', '\\t');
  }

  String _unescapeFromJavaScript(String text) {
    String result = text;
    if (result.startsWith('"') && result.endsWith('"')) {
      result = result.substring(1, result.length - 1);
    }

    return result
        .replaceAll('\\"', '"')
        .replaceAll('\\n', '\n')
        .replaceAll('\\r', '\r')
        .replaceAll('\\t', '\t')
        .replaceAll('\\\\', '\\');
  }

  String replaceHtmlTagsWith(String html, String replacement) {
    return html.replaceAll(RegExp(r'<[^>]*>'), replacement);
  }
  int getLineCount() {
    final textSpan = TextSpan(
      text: replaceHtmlTagsWith(_currentContent, ''),
    );

    final tp = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      maxLines: null,
    );

    tp.layout(maxWidth: MediaQuery.of(context).size.width*0.8);

    print(replaceHtmlTagsWith(_currentContent, '').length);
    return tp.computeLineMetrics().length;
  }


  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DecoratedBox(
          decoration:widget.errorBoxDecoration?? widget.boxDecoration ??  BoxDecoration(
            border: Border.all(
              color: widget.theme.borderColorValue,
            ),
            borderRadius: BorderRadius.circular(widget.borderRadius ?? 8),
          ),
          child: ClipRRect(
            borderRadius:widget.errorBoxDecoration?.borderRadius?? BorderRadius.circular(widget.borderRadius ?? 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.showToolbar)
                  HtmlEditorToolbar(
                    controller: widget.controller,
                    theme: widget.theme,
                    customItems: widget.customToolbarItems,
                    showLabels: false,
                    enabled: widget.enabled,
                  ),
                Container(
                  height:widget.minLines==null?widget.height: getLineCount()*26+((widget.minLines??0)*26),
                  padding: const EdgeInsets.symmetric(vertical: 8),

                  child: ClipRRect(
                    borderRadius: widget.errorBoxDecoration?.borderRadius??BorderRadius.circular(widget.borderRadius ?? 8),
                    child: _isLoaded
                        ? Stack(
                          children: [
                            WebViewWidget(controller: _webViewController),
                            if(!widget.enabled)
                              Container(
                                color: widget.theme.backgroundColorValue.withOpacity(0.5),
                              ),
                          ],

                        )
                        : ColoredBox(
                      color: widget.theme.backgroundColorValue,
                      child: widget.loadingWidget ?? const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  ),
                ),



              ],
            ),
          ),
        ),

      ],
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}