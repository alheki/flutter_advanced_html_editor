import 'package:flutter/foundation.dart';
import 'html_editor_widget.dart';

/// Controller class for managing HTML editor operations
/// 
/// Provides methods to interact with the HTML editor, including formatting,
/// content management, and editor state control.
class HtmlEditorController {
  FlutterAdvancedHtmlEditorState? _widget;

  /// Sets the widget instance for this controller
  void setWidget(FlutterAdvancedHtmlEditorState widget) {
    _widget = widget;
  }

  /// Execute a formatting command
  Future<void> executeCommand(String command, [String? value]) async {
    await _widget?.executeCommand(command, value);
  }

  /// Get the current HTML content
  Future<String> getHtml() async {
    return await _widget?.getContent() ?? '';
  }

  /// Set the HTML content
  Future<void> setHtml(String html) async {
    await _widget?.setContent(html);
  }

  /// Insert HTML at the current cursor position
  Future<void> insertHtml(String html) async {
    await _widget?.insertHTML(html);
  }

  /// Undo the last action
  Future<void> undo() async {
    await _widget?.undo();
  }

  /// Redo the last undone action
  Future<void> redo() async {
    await _widget?.redo();
  }

  /// Make selected text bold
  Future<void> bold() async {
    await executeCommand('bold');
  }

  /// Make selected text italic
  Future<void> italic() async {
    await executeCommand('italic');
  }

  /// Underline selected text
  Future<void> underline() async {
    await executeCommand('underline');
  }

  /// Strike through selected text
  Future<void> strikeThrough() async {
    await executeCommand('strikeThrough');
  }

  /// Set text color
  Future<void> setTextColor(String color) async {
    await executeCommand('foreColor', color);
  }

  /// Set background color
  Future<void> setBackgroundColor(String color) async {
    await executeCommand('hiliteColor', color);
  }

  /// Set font family
  Future<void> setFontFamily(String fontFamily) async {
    await executeCommand('fontName', fontFamily);
  }

  /// Set font size
  Future<void> setFontSize(String size) async {
    await executeCommand('fontSize', size);
  }

  /// Align text left
  Future<void> alignLeft() async {
    await executeCommand('justifyLeft');
  }

  /// Align text center
  Future<void> alignCenter() async {
    await executeCommand('justifyCenter');
  }

  /// Align text right
  Future<void> alignRight() async {
    await executeCommand('justifyRight');
  }

  /// Justify text
  Future<void> justify() async {
    await executeCommand('justifyFull');
  }

  /// Insert unordered list
  Future<void> insertUnorderedList() async {
    await executeCommand('insertUnorderedList');
  }

  /// Insert ordered list
  Future<void> insertOrderedList() async {
    await executeCommand('insertOrderedList');
  }

  /// Indent text
  Future<void> indent() async {
    await executeCommand('indent');
  }

  /// Outdent text
  Future<void> outdent() async {
    await executeCommand('outdent');
  }

  /// Insert a link
  Future<void> insertLink(String url, [String? text]) async {
    await _widget?.insertLink(url, text ?? url);
  }

  /// Insert an image
  Future<void> insertImage(String url, [String? alt]) async {
    await _widget?.insertImage(url, alt ?? '');
  }

  /// Insert a table
  Future<void> insertTable(int rows, int columns) async {
    await _widget?.insertTable(rows, columns);
  }

  /// Insert a horizontal rule
  Future<void> insertHorizontalRule() async {
    await executeCommand('insertHorizontalRule');
  }

  /// Remove formatting
  Future<void> removeFormat() async {
    await executeCommand('removeFormat');
  }

  /// Set heading level (1-6)
  Future<void> setHeading(int level) async {
    if (level >= 1 && level <= 6) {
      await executeCommand('formatBlock', 'h$level');
    }
  }

  /// Set paragraph format
  Future<void> setParagraph() async {
    await executeCommand('formatBlock', 'p');
  }

  /// Insert blockquote
  Future<void> insertBlockquote() async {
    await executeCommand('formatBlock', 'blockquote');
  }

  /// Insert code block
  Future<void> insertCodeBlock() async {
    await executeCommand('formatBlock', 'pre');
  }

  /// Toggle fullscreen mode
  Future<void> toggleFullscreen() async {
    // This would be handled by the parent widget
    debugPrint('Toggle fullscreen requested');
  }

  /// Clear all content
  Future<void> clear() async {
    await setHtml('');
  }

  /// Focus the editor
  Future<void> focus() async {
    await _widget?.focus();
  }

  /// Get plain text content
  Future<String> getText() async {
    final html = await getHtml();
    // Simple HTML to text conversion (you might want to use a proper HTML parser)
    return html.replaceAll(RegExp(r'<[^>]*>'), '').trim();
  }

  /// Check if editor has content
  Future<bool> hasContent() async {
    final text = await getText();
    return text.isNotEmpty;
  }

  /// Get word count
  Future<int> getWordCount() async {
    final text = await getText();
    if (text.isEmpty) {
      return 0;
    }
    return text.split(RegExp(r'\s+')).length;
  }

  /// Get character count
  Future<int> getCharacterCount() async {
    final text = await getText();
    return text.length;
  }

  /// Dispose resources
  void dispose() {
    _widget = null;
  }
}