import 'package:flutter/foundation.dart';
import 'html_editor_widget.dart';

/// Controller class for managing HTML editor operations with enhanced validation
///
/// Provides methods to interact with the HTML editor, including formatting,
/// content management, editor state control, and form validation capabilities.
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
    return _htmlToPlainText(html);
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

  /// Get line count from HTML content
  Future<int> getLineCount() async {
    final html = await getHtml();
    return _countLinesInHtml(html);
  }

  // VALIDATION METHODS FOR FORM INTEGRATION

  /// Validates the content against specified requirements
  /// Returns null if valid, otherwise returns error message
  Future<String?> validate({
    bool required = false,
    int? minLength,
    int? maxLength,
    int? minLines,
    int? maxLines,
    String? Function(String content)? customValidator,
  }) async {
    try {
      final html = await getHtml();
      final plainText = _htmlToPlainText(html);
      final lineCount = _countLinesInHtml(html);

      // Required validation
      if (required && plainText.trim().isEmpty) {
        return 'This field is required';
      }

      // Min length validation
      if (minLength != null && plainText.length < minLength) {
        return 'Minimum $minLength characters required (current: ${plainText.length})';
      }

      // Max length validation
      if (maxLength != null && plainText.length > maxLength) {
        return 'Maximum $maxLength characters allowed (current: ${plainText.length})';
      }

      // Min lines validation
      if (minLines != null && lineCount < minLines) {
        return 'Minimum $minLines lines required (current: $lineCount)';
      }

      // Max lines validation
      if (maxLines != null && lineCount > maxLines) {
        return 'Maximum $maxLines lines allowed (current: $lineCount)';
      }

      // Custom validation
      if (customValidator != null) {
        return customValidator(html);
      }

      return null; // Valid
    } catch (e) {
      debugPrint('Error during validation: $e');
      return 'Validation error occurred';
    }
  }

  /// Validates content is not empty
  Future<String?> validateRequired([String? message]) async {
    final text = await getText();
    if (text.trim().isEmpty) {
      return message ?? 'This field is required';
    }
    return null;
  }

  /// Validates minimum character length
  Future<String?> validateMinLength(int minLength, [String? message]) async {
    final text = await getText();
    if (text.length < minLength) {
      return message ?? 'Minimum $minLength characters required (current: ${text.length})';
    }
    return null;
  }

  /// Validates maximum character length
  Future<String?> validateMaxLength(int maxLength, [String? message]) async {
    final text = await getText();
    if (text.length > maxLength) {
      return message ?? 'Maximum $maxLength characters allowed (current: ${text.length})';
    }
    return null;
  }

  /// Validates minimum line count
  Future<String?> validateMinLines(int minLines, [String? message]) async {
    final lineCount = await getLineCount();
    if (lineCount < minLines) {
      return message ?? 'Minimum $minLines lines required (current: $lineCount)';
    }
    return null;
  }

  /// Validates maximum line count
  Future<String?> validateMaxLines(int maxLines, [String? message]) async {
    final lineCount = await getLineCount();
    if (lineCount > maxLines) {
      return message ?? 'Maximum $maxLines lines allowed (current: $lineCount)';
    }
    return null;
  }

  /// Validates word count range
  Future<String?> validateWordCount({
    int? minWords,
    int? maxWords,
    String? message,
  }) async {
    final wordCount = await getWordCount();

    if (minWords != null && wordCount < minWords) {
      return message ?? 'Minimum $minWords words required (current: $wordCount)';
    }

    if (maxWords != null && wordCount > maxWords) {
      return message ?? 'Maximum $maxWords words allowed (current: $wordCount)';
    }

    return null;
  }

  /// Validates that content matches a pattern
  Future<String?> validatePattern(RegExp pattern, [String? message]) async {
    final text = await getText();
    if (!pattern.hasMatch(text)) {
      return message ?? 'Content does not match required format';
    }
    return null;
  }

  /// Validates that content contains specific text
  Future<String?> validateContains(String requiredText, [String? message]) async {
    final text = await getText();
    if (!text.toLowerCase().contains(requiredText.toLowerCase())) {
      return message ?? 'Content must contain: $requiredText';
    }
    return null;
  }

  /// Validates that content does not contain specific text
  Future<String?> validateNotContains(String forbiddenText, [String? message]) async {
    final text = await getText();
    if (text.toLowerCase().contains(forbiddenText.toLowerCase())) {
      return message ?? 'Content must not contain: $forbiddenText';
    }
    return null;
  }

  /// Get comprehensive content statistics
  Future<Map<String, dynamic>> getContentStats() async {
    final html = await getHtml();
    final text = await getText();
    final wordCount = await getWordCount();
    final lineCount = await getLineCount();

    return {
      'html': html,
      'text': text,
      'characterCount': text.length,
      'wordCount': wordCount,
      'lineCount': lineCount,
      'isEmpty': text.trim().isEmpty,
      'htmlLength': html.length,
    };
  }

  /// Utility method to convert HTML to plain text
  String _htmlToPlainText(String html) {
    if (html.isEmpty) return '';

    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .trim();
  }

  /// Utility method to count lines in HTML content
  int _countLinesInHtml(String html) {
    if (html.isEmpty || html == '<br>' || html == '<p><br></p>' || html == '<div><br></div>') {
      return 1;
    }

    // Count block elements that create new lines
    final blockElementMatches = RegExp(r'<(?:p|div|h[1-6]|li|blockquote|pre|ul|ol)[^>]*>',
        caseSensitive: false).allMatches(html);
    int blockCount = blockElementMatches.length;

    // Count standalone <br> tags that aren't within block elements
    final brMatches = RegExp(r'<br\s*/?>', caseSensitive: false).allMatches(html);
    int brCount = brMatches.length;

    // If we have block elements, use that count as the primary line count
    if (blockCount > 0) {
      return blockCount;
    }

    // If no block elements but we have <br> tags, count them
    if (brCount > 0) {
      return brCount + 1; // +1 for the first line
    }

    // If we have content but no block elements or <br> tags, it's at least 1 line
    final plainText = _htmlToPlainText(html);
    return plainText.trim().isEmpty ? 1 : 1;
  }

  /// Dispose resources
  void dispose() {
    _widget = null;
  }
}