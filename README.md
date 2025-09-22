Flutter Advanced HTML Editor



A powerful and customizable HTML editor for Flutter.




A comprehensive and feature-rich HTML editor for Flutter applications.
It provides a powerful rich text editing experience with extensive formatting options, customizable themes, and a flexible toolbar system.

✨ Features

🎨 Rich Text Formatting: Bold, italic, underline, strikethrough, colors, fonts, and sizes

📝 Content Structure: Headings, paragraphs, lists, blockquotes, and code blocks

🔗 Media Support: Insert links, images, and tables

🎭 Customizable Themes: Light, dark, and custom theme support

🛠️ Flexible Toolbar: Choose only the buttons you need

↩️ Undo/Redo: Full history support

📱 Responsive: Works across all screen sizes

🔧 Easy Integration: Simple API with clear documentation

🚀 Quick Demo
HtmlEditorWidget(
controller: HtmlEditorController(),
theme: HtmlEditorTheme.light(),
initialContent: '<p>Hello <b>World</b> 👋</p>',
)

📦 Installation

Add this to your pubspec.yaml:

dependencies:
flutter_advanced_html_editor: ^1.0.0


Run:

flutter pub get

📘 Basic Usage
import 'package:flutter/material.dart';
import 'package:flutter_advanced_html_editor/flutter_advanced_html_editor.dart';

class MyEditorPage extends StatefulWidget {
@override
_MyEditorPageState createState() => _MyEditorPageState();
}

class _MyEditorPageState extends State<MyEditorPage> {
late HtmlEditorController _controller;

@override
void initState() {
super.initState();
_controller = HtmlEditorController();
}

@override
void dispose() {
_controller.dispose();
super.dispose();
}

@override
Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(title: Text('HTML Editor')),
body: HtmlEditorWidget(
controller: _controller,
theme: HtmlEditorTheme.light(),
height: 400,
initialContent: '<p>Start writing...</p>',
onContentChanged: (content) {
print('Content changed: $content');
},
),
);
}
}

⚡ Advanced Usage
🎨 Custom Theme
HtmlEditorWidget(
controller: _controller,
theme: HtmlEditorTheme.custom(
primaryColor: '#2196F3',
backgroundColor: '#FFFFFF',
textColor: '#000000',
toolbarBackgroundColor: '#F5F5F5',
),
)

🛠️ Custom Toolbar
HtmlEditorWidget(
controller: _controller,
theme: HtmlEditorTheme.light(),
customToolbarItems: [
HtmlEditorToolbarItem.bold,
HtmlEditorToolbarItem.italic,
HtmlEditorToolbarItem.underline,
HtmlEditorToolbarItem.textColor,
HtmlEditorToolbarItem.alignLeft,
HtmlEditorToolbarItem.alignCenter,
HtmlEditorToolbarItem.alignRight,
HtmlEditorToolbarItem.unorderedList,
HtmlEditorToolbarItem.orderedList,
HtmlEditorToolbarItem.link,
HtmlEditorToolbarItem.image,
],
)

🎮 Controller Methods
// Get HTML content
String htmlContent = await _controller.getHtml();

// Set HTML content
await _controller.setHtml('<h1>New Content</h1>');

// Insert at cursor
await _controller.insertHtml('<strong>Bold text</strong>');

// Formatting
await _controller.bold();
await _controller.italic();
await _controller.underline();
await _controller.setTextColor('#FF0000');

// Undo/Redo & Management
await _controller.undo();
await _controller.redo();
await _controller.clear();
await _controller.focus();

// Stats
int wordCount = await _controller.getWordCount();
int charCount = await _controller.getCharacterCount();
bool hasContent = await _controller.hasContent();

🛠️ Toolbar Items

Full list of available items:

undo, redo, bold, italic, underline, strikethrough, textColor, backgroundColor,
fontFamily, fontSize, alignLeft, alignCenter, alignRight, justify,
unorderedList, orderedList, indent, outdent, link, image, table,
code, removeFormat, heading1, heading2, heading3, paragraph, blockquote, horizontalRule.

🎭 Themes
// Predefined
HtmlEditorTheme.light();
HtmlEditorTheme.dark();

// Custom
HtmlEditorTheme.custom(
primaryColor: '#2196F3',
backgroundColor: '#FFFFFF',
textColor: '#000000',
toolbarBackgroundColor: '#F5F5F5',
);

🔔 Callbacks
HtmlEditorWidget(
onContentChanged: (content) => print("Changed: $content"),
onSelectionChanged: (selection) {
print("Selected: ${selection['selectedText']}");
},
)

💻 Platform Support

✅ Android

✅ iOS

✅ Web

✅ macOS

✅ Windows

✅ Linux

📋 Requirements

Flutter >=3.0.0

Dart >=3.0.0

📚 Dependencies

webview_flutter: ^4.4.2 – Render HTML editor

file_picker: ^6.1.1 – Image/file selection

## 🎬 Demo

<img src="https://raw.githubusercontent.com/alheki/flutter_advanced_html_editor/main/doc/demo.gif" width="300" />


🛤️ Roadmap

RTL support improvements

Insert videos & embeds

Extend plugin system (custom buttons)

Export to Markdown

❓ FAQ

Q: Does it support RTL (Arabic)?
A: Basic support exists.

Q: Can I get plain text instead of HTML?
A: Yes, use the controller methods.

Q: Does it work on both mobile & web?
A: Yes, fully supported.

🤝 Contributing

Contributions are welcome! Please open an Issue
or submit a PR.

📜 License

This project is licensed under the MIT License – see LICENSE.

📌 Changelog

See CHANGELOG.md
for details.