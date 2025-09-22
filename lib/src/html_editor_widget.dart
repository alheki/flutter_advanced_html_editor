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
  final HtmlEditorTheme theme;
  final Function(String)? onContentChanged;
  final Function(Map<String, dynamic>)? onSelectionChanged;
  final bool showToolbar;
  final List<HtmlEditorToolbarItem>? customToolbarItems;
  final BoxDecoration? boxDecoration;
  final double? borderRadius;
  final Widget? loadingWidget;

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
    this.borderRadius,
    this.loadingWidget,
  });

  @override
  State<FlutterAdvancedHtmlEditor> createState() => FlutterAdvancedHtmlEditorState();
}

class FlutterAdvancedHtmlEditorState extends State<FlutterAdvancedHtmlEditor> {
  late WebViewController _webViewController;
  bool _isLoaded = false;
  String _currentContent = '';
  final Completer<void> _editorReadyCompleter = Completer<void>();

  @override
  void initState() {
    super.initState();
    _initializeWebView();
    widget.controller.setWidget(this);

    // Fallback timer with longer duration
    Timer(const Duration(seconds: 10), () {
      if (mounted && !_isLoaded) {
        // debugPrint('Editor initialization fallback timeout');
        setState(() {
          _isLoaded = true;
        });
        if (!_editorReadyCompleter.isCompleted) {
          _editorReadyCompleter.complete();
        }
      }
    });
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
            // Don't fail completely on resource errors
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

    // Force load the initial content
    _loadInitialContent();
  }

  void _loadInitialContent() {
    // Small delay to ensure WebView is ready
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        final htmlContent = _generateHtmlContent();
        _webViewController.loadHtmlString(htmlContent);
      }
    });
  }

  void _loadEditor() async {
    try {
      // Wait for DOM to be ready and then check if editor is initialized
      await _waitForEditorReady();

      // Set initial content if provided
      if (widget.initialContent.isNotEmpty) {
        await setContent(widget.initialContent);
      }

      if (mounted) {
        setState(() {
          _isLoaded = true;
        });
      }

      if (!_editorReadyCompleter.isCompleted) {
        _editorReadyCompleter.complete();
      }

      // debugPrint('HTML Editor loaded successfully');
    } catch (e) {
      // debugPrint('Error loading editor: $e');
      if (mounted) {
        setState(() {
          _isLoaded = true; // Show editor even if there was an error
        });
      }
      if (!_editorReadyCompleter.isCompleted) {
        _editorReadyCompleter.complete();
      }
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
          // debugPrint('Editor is ready after ${attempts + 1} attempts');
          return;
        }
      } catch (e) {
        // debugPrint('Attempt ${attempts + 1}: Editor not ready yet - $e');
      }

      attempts++;
      await Future.delayed(delay);
    }

    // debugPrint('Editor initialization timeout after $maxAttempts attempts');
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
                this.history = [];
                this.historyStep = -1;
                this.maxHistory = 50;
                this.debounceTimer = null;
                this.selectionTimer = null;
                
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
                this.editor.setAttribute('data-placeholder', 'Start typing...');
                
                // Set default paragraph separator
                try {
                    document.execCommand('defaultParagraphSeparator', false, 'p');
                } catch (e) {
                    console.warn('Could not set default paragraph separator:', e);
                }
            }
            
            setupEventListeners() {
                // Content change events
                this.editor.addEventListener('input', () => {
                    this.debounceContentChange();
                });
                
                this.editor.addEventListener('keydown', (e) => {
                    this.handleKeyDown(e);
                });
                
                // Selection change events
                document.addEventListener('selectionchange', () => {
                    if (document.activeElement === this.editor) {
                        this.debounceSelectionChange();
                    }
                });
                
                // Paste handling
                this.editor.addEventListener('paste', (e) => {
                    this.handlePaste(e);
                });
                
                // Focus events
                this.editor.addEventListener('focus', () => {
                    this.notifySelectionChanged();
                });
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
                
                // Handle Enter key to ensure proper paragraph creation
                if (e.key === 'Enter') {
                    this.handleEnterKey(e);
                }
            }
            
            handleEnterKey(e) {
                const selection = window.getSelection();
                if (!selection.rangeCount) return;
                
                const range = selection.getRangeAt(0);
                const container = range.commonAncestorContainer;
                
                // If we're in a list, let the browser handle it naturally
                const listItem = container.nodeType === Node.TEXT_NODE 
                    ? container.parentElement?.closest('li')
                    : container.closest?.('li');
                
                if (listItem) {
                    return; // Let browser handle list item creation
                }
                
                // For other cases, ensure we create paragraphs
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
                
                // Try to get HTML first, then fall back to plain text
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
                    this.insertHTML(content);
                }
            }
            
            sanitizePlainText(text) {
                return text.replace(/\\n/g, '<br>').replace(/\\r/g, '');
            }
            
            sanitizeHTML(html) {
                // Basic HTML sanitization - remove dangerous elements and attributes
                const div = document.createElement('div');
                div.innerHTML = html;
                
                // Remove script tags and event handlers
                const scripts = div.querySelectorAll('script');
                scripts.forEach(script => script.remove());
                
                // Remove dangerous attributes
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
                        this.notifyContentChanged();
                    }
                } catch (e) {
                    console.error('Insert HTML failed:', e);
                }
            }
            
            saveState() {
                const state = this.editor.innerHTML;
                
                // Don't save if content hasn't changed
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
                    
                    if (window.HtmlEditor && window.HtmlEditor.postMessage) {
                        window.HtmlEditor.postMessage(JSON.stringify({
                            type: 'contentChanged',
                            content: content,
                            text: text,
                            wordCount: words,
                            charCount: text.length
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
    ''';
  }

  void _handleJavaScriptMessage(String message) {
    try {
      final data = json.decode(message);
      final type = data['type'] as String;

      switch (type) {
        case 'editorReady':
          // debugPrint('Editor ready message received');
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
          _currentContent = data['content'] as String? ?? '';
          if (widget.onContentChanged != null) {
            widget.onContentChanged!(_currentContent);
          }
          break;
        case 'selectionChanged':
          if (widget.onSelectionChanged != null) {
            widget.onSelectionChanged!(Map<String, dynamic>.from(data));
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

  String _escapeForJavaScript(String text) {
    return text
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll('\t', '\\t');
  }

  String _unescapeFromJavaScript(String text) {
    // Remove surrounding quotes if present
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration:widget.boxDecoration?? BoxDecoration(
        border: Border.all(
          color: widget.theme.borderColorValue,
        ),
        borderRadius: BorderRadius.circular(widget.borderRadius??8),
      ),
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius??8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showToolbar)
              HtmlEditorToolbar(
                controller: widget.controller,
                theme: widget.theme,
                customItems: widget.customToolbarItems,
                showLabels: false,
              ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(widget.borderRadius??8),
                child: _isLoaded
                    ? WebViewWidget(controller: _webViewController)
                    : ColoredBox(
                        color: widget.theme.backgroundColorValue,
                        child: widget.loadingWidget?? const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}