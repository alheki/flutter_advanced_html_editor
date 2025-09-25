import 'package:flutter/material.dart';
import 'html_editor_widget.dart';
import 'html_editor_controller.dart';
import 'html_editor_theme.dart';
import 'html_editor_toolbar.dart';

/// A FormField wrapper for the HTML Editor that provides form validation
class FlutterAdvancedHtmlEditorForm extends FormField<String> {
  final HtmlEditorController controller;
  final HtmlEditorTheme theme;
  final double height;
  final int? minLines;
  final bool showToolbar;
  final List<HtmlEditorToolbarItem>? customToolbarItems;
  final BoxDecoration? boxDecoration;
  final BoxDecoration? errorBoxDecoration;
  final double? borderRadius;
  final Widget? loadingWidget;
  final Function(String)? onContentChanged;
  final Function(Map<String, dynamic>)? onSelectionChanged;
  final Function(String)? onLimitExceeded;
  final String initialContent;
  final TextStyle? validationErrorTextStyle;
  final Widget? validationErrorWidget;
  final String? hintText;

  FlutterAdvancedHtmlEditorForm({
    super.key,
    required this.controller,
    required this.theme,
    this.height = 400,
    this.showToolbar = true,
    this.customToolbarItems,
    this.boxDecoration,
    this.errorBoxDecoration,
    this.borderRadius,
    this.loadingWidget,
    this.onContentChanged,
    this.onSelectionChanged,
    this.onLimitExceeded,
    this.initialContent = '',
    this.validationErrorTextStyle,
    this.hintText,
    this.validationErrorWidget,
    this.minLines,

    // FormField properties
    String? initialValue,
    super.onSaved,
    FormFieldValidator<String>? validator,
    bool autovalidate = false,
    super.enabled,
    AutovalidateMode super.autovalidateMode = AutovalidateMode.disabled,

    // HTML Editor specific validation properties
    int? maxLength,
    int? minLength,
    bool required = false,
  }) : super(
    // FIX: Use initialContent as fallback for initialValue
    initialValue: initialValue ?? initialContent,
    validator: _buildValidator(
      validator: validator,
      required: required,
      minLength: minLength,
      maxLength: maxLength,
    ),
    builder: (FormFieldState<String> field) {
      final _HtmlEditorFormFieldState state = field as _HtmlEditorFormFieldState;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FlutterAdvancedHtmlEditor(
            controller: controller,
            // FIX: Use field.value if it has content, otherwise use initialContent
            initialContent: (field.value?.isNotEmpty == true) ? field.value! : initialContent,
            height: height,
            theme: theme,
            enabled: enabled,
            showToolbar: showToolbar,
            customToolbarItems: customToolbarItems,
            boxDecoration: boxDecoration,
            errorBoxDecoration: field.hasError?errorBoxDecoration:null,
            borderRadius: borderRadius,
            loadingWidget: loadingWidget,
            maxLength: maxLength,
            minLength: minLength,
            hintText: hintText,
            minLines: minLines,

            onContentChanged: (content) {
              state._updateValue(content);
              if (onContentChanged != null) {
                onContentChanged(content);
              }
            },
            onSelectionChanged: onSelectionChanged,
            onLimitExceeded: onLimitExceeded,
          ),
          if (field.hasError)
            validationErrorWidget??Padding(
              padding: const EdgeInsets.only(top: 8, left: 12),
              child: Text(
                field.errorText!,
                style: validationErrorTextStyle??const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      );
    },
  );

  @override
  FormFieldState<String> createState() => _HtmlEditorFormFieldState();

  /// Builds a comprehensive validator that combines custom validation with built-in constraints
  static FormFieldValidator<String>? _buildValidator({
    FormFieldValidator<String>? validator,
    bool required = false,
    int? minLength,
    int? maxLength,
    int? minLines,
    int? maxLines,
  }) {
    return (String? value) {
      // Convert HTML to plain text for validation
      final plainText = _htmlToPlainText(value ?? '');
      final lineCount = _countLines(value ?? '');

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

      // Custom validator
      if (validator != null) {
        return validator(value);
      }

      return null;
    };
  }

  /// Converts HTML content to plain text for validation
  static String _htmlToPlainText(String html) {
    if (html.isEmpty) return '';

    // Simple HTML to text conversion
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .trim();
  }

  /// Counts the number of lines in HTML content
  static int _countLines(String html) {
    if (html.isEmpty || html == '<br>' || html == '<p><br></p>') return 1;

    // Count block elements that create new lines
    final blockElementCount = RegExp(r'<(?:p|div|h[1-6]|li|blockquote|pre)[^>]*>')
        .allMatches(html).length;

    // Count standalone <br> tags
    final brCount = RegExp(r'<br\s*/?>')
        .allMatches(html).length;

    // If there are block elements, use that count, otherwise count by <br> tags
    if (blockElementCount > 0) {
      return blockElementCount;
    } else {
      return brCount + 1; // +1 for the first line
    }
  }
}

class _HtmlEditorFormFieldState extends FormFieldState<String> {
  void _updateValue(String newValue) {
    setValue(newValue);
  }
}