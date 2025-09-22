import 'package:flutter/material.dart';

/// Theme configuration for the HTML editor
/// 
/// Defines colors and styling for the editor interface including
/// toolbar, text, backgrounds, and interactive elements.
class HtmlEditorTheme {
  final String primaryColor;
  final String secondaryColor;
  final String backgroundColor;
  final String surfaceColor;
  final String textColor;
  final String secondaryTextColor;
  final String borderColor;
  final String toolbarBackgroundColor;
  final String toolbarTextColor;
  final String buttonHoverColor;
  final String selectionColor;

  const HtmlEditorTheme({
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.textColor,
    required this.secondaryTextColor,
    required this.borderColor,
    required this.toolbarBackgroundColor,
    required this.toolbarTextColor,
    required this.buttonHoverColor,
    required this.selectionColor,
  });

  /// Creates a light theme configuration
  factory HtmlEditorTheme.light() {
    return const HtmlEditorTheme(
      primaryColor: '#2563eb',
      secondaryColor: '#6b7280',
      backgroundColor: '#ffffff',
      surfaceColor: '#f8fafc',
      textColor: '#0f172a',
      secondaryTextColor: '#64748b',
      borderColor: '#e2e8f0',
      toolbarBackgroundColor: '#ffffff',
      toolbarTextColor: '#0f172a',
      buttonHoverColor: '#2563eb',
      selectionColor: 'rgba(37, 99, 235, 0.2)',
    );
  }

  /// Creates a dark theme configuration
  factory HtmlEditorTheme.dark() {
    return const HtmlEditorTheme(
      primaryColor: '#3b82f6',
      secondaryColor: '#9ca3af',
      backgroundColor: '#0f172a',
      surfaceColor: '#1e293b',
      textColor: '#f1f5f9',
      secondaryTextColor: '#94a3b8',
      borderColor: '#334155',
      toolbarBackgroundColor: '#1e293b',
      toolbarTextColor: '#f1f5f9',
      buttonHoverColor: '#3b82f6',
      selectionColor: 'rgba(59, 130, 246, 0.2)',
    );
  }

  /// Creates a custom theme configuration
  factory HtmlEditorTheme.custom({
    String primaryColor = '#2563eb',
    String secondaryColor = '#6b7280',
    String backgroundColor = '#ffffff',
    String surfaceColor = '#f8fafc',
    String textColor = '#0f172a',
    String secondaryTextColor = '#64748b',
    String borderColor = '#e2e8f0',
    String toolbarBackgroundColor = '#ffffff',
    String toolbarTextColor = '#0f172a',
    String buttonHoverColor = '#2563eb',
    String selectionColor = 'rgba(37, 99, 235, 0.2)',
  }) {
    return HtmlEditorTheme(
      primaryColor: primaryColor,
      secondaryColor: secondaryColor,
      backgroundColor: backgroundColor,
      surfaceColor: surfaceColor,
      textColor: textColor,
      secondaryTextColor: secondaryTextColor,
      borderColor: borderColor,
      toolbarBackgroundColor: toolbarBackgroundColor,
      toolbarTextColor: toolbarTextColor,
      buttonHoverColor: buttonHoverColor,
      selectionColor: selectionColor,
    );
  }

  /// Creates a copy of this theme with the given fields replaced with new values
  HtmlEditorTheme copyWith({
    String? primaryColor,
    String? secondaryColor,
    String? backgroundColor,
    String? surfaceColor,
    String? textColor,
    String? secondaryTextColor,
    String? borderColor,
    String? toolbarBackgroundColor,
    String? toolbarTextColor,
    String? buttonHoverColor,
    String? selectionColor,
  }) {
    return HtmlEditorTheme(
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      textColor: textColor ?? this.textColor,
      secondaryTextColor: secondaryTextColor ?? this.secondaryTextColor,
      borderColor: borderColor ?? this.borderColor,
      toolbarBackgroundColor: toolbarBackgroundColor ?? this.toolbarBackgroundColor,
      toolbarTextColor: toolbarTextColor ?? this.toolbarTextColor,
      buttonHoverColor: buttonHoverColor ?? this.buttonHoverColor,
      selectionColor: selectionColor ?? this.selectionColor,
    );
  }

  // Color value getters for Flutter Color objects
  Color get primaryColorValue => Color(int.parse(primaryColor.substring(1), radix: 16) + 0xFF000000);
  Color get secondaryColorValue => Color(int.parse(secondaryColor.substring(1), radix: 16) + 0xFF000000);
  Color get backgroundColorValue => Color(int.parse(backgroundColor.substring(1), radix: 16) + 0xFF000000);
  Color get surfaceColorValue => Color(int.parse(surfaceColor.substring(1), radix: 16) + 0xFF000000);
  Color get textColorValue => Color(int.parse(textColor.substring(1), radix: 16) + 0xFF000000);
  Color get secondaryTextColorValue => Color(int.parse(secondaryTextColor.substring(1), radix: 16) + 0xFF000000);
  Color get borderColorValue => Color(int.parse(borderColor.substring(1), radix: 16) + 0xFF000000);
  Color get toolbarBackgroundColorValue => Color(int.parse(toolbarBackgroundColor.substring(1), radix: 16) + 0xFF000000);
  Color get toolbarTextColorValue => Color(int.parse(toolbarTextColor.substring(1), radix: 16) + 0xFF000000);
  Color get buttonHoverColorValue => Color(int.parse(buttonHoverColor.substring(1), radix: 16) + 0xFF000000);
}