import 'package:flutter/material.dart';
import 'package:flutter_advanced_html_editor/flutter_advanced_html_editor.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Advanced HTML Editor Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late HtmlEditorController _controller;
  HtmlEditorTheme _theme = HtmlEditorTheme.light();
  bool _isDarkMode = false;
  String _currentContent = '';

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

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
      _theme = _isDarkMode ? HtmlEditorTheme.dark() : HtmlEditorTheme.light();
    });
  }

  void _showContent() async {
    final content = await _controller.getHtml();
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Current Content'),
          content: SingleChildScrollView(
            child: Text(content),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }

  void _clearContent() async {
    await _controller.clear();
  }

  void _insertSampleContent() async {
    const sampleContent = '''
      <h1>Welcome to Flutter Advanced HTML Editor</h1>
      <p>This is a <strong>powerful</strong> and <em>flexible</em> HTML editor for Flutter applications.</p>
      <h2>Features:</h2>
      <ul>
        <li>Rich text formatting</li>
        <li>Image and link insertion</li>
        <li>Table support</li>
        <li>Customizable themes</li>
        <li>Toolbar customization</li>
      </ul>
      <blockquote>
        "A great editor makes writing a pleasure!" - Anonymous
      </blockquote>
      <p>Try editing this content with the toolbar above!</p>
    ''';
    await _controller.setHtml(sampleContent);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Advanced HTML Editor'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: _toggleTheme,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'show_content':
                  _showContent();
                  break;
                case 'clear_content':
                  _clearContent();
                  break;
                case 'insert_sample':
                  _insertSampleContent();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'insert_sample',
                child: Text('Insert Sample Content'),
              ),
              const PopupMenuItem(
                value: 'show_content',
                child: Text('Show HTML Content'),
              ),
              const PopupMenuItem(
                value: 'clear_content',
                child: Text('Clear Content'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Word count display
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Content: ${_currentContent.length} characters',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.right,
            ),
          ),
          // HTML Editor
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: FlutterAdvancedHtmlEditor(
                controller: _controller,
                theme: _theme,
                height: 500,
                initialContent: '<p>Start writing your content here...</p>',
                onContentChanged: (content) {
                  setState(() {
                    _currentContent = content;
                  });
                },
                onSelectionChanged: (selection) {
                  // Handle selection changes if needed
                  debugPrint('Selection changed: ${selection['selectedText']}');
                },
                customToolbarItems: const [
                  HtmlEditorToolbarItem.undo,
                  HtmlEditorToolbarItem.redo,
                  HtmlEditorToolbarItem.bold,
                  HtmlEditorToolbarItem.italic,
                  HtmlEditorToolbarItem.underline,
                  HtmlEditorToolbarItem.strikethrough,
                  HtmlEditorToolbarItem.textColor,
                  HtmlEditorToolbarItem.backgroundColor,
                  HtmlEditorToolbarItem.alignLeft,
                  HtmlEditorToolbarItem.alignCenter,
                  HtmlEditorToolbarItem.alignRight,
                  HtmlEditorToolbarItem.unorderedList,
                  HtmlEditorToolbarItem.orderedList,
                  HtmlEditorToolbarItem.link,
                  HtmlEditorToolbarItem.image,
                  HtmlEditorToolbarItem.table,
                  HtmlEditorToolbarItem.removeFormat,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}