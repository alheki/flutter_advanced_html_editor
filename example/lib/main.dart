// Import required packages
import 'package:flutter/material.dart';
import 'package:flutter_advanced_html_editor/flutter_advanced_html_editor.dart';

// Entry point of the application
void main() {
  runApp(const MyApp());
}

/// Root application widget that sets up the MaterialApp
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

/// Main page widget that demonstrates both basic and form HTML editors
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

/// State class for MyHomePage with tab controller functionality
class _MyHomePageState extends State<MyHomePage> with TickerProviderStateMixin {
  // Tab controller for switching between basic and form editor examples
  late TabController _tabController;

  // HTML editor controllers - separate controllers for each tab
  late HtmlEditorController _basicController;
  late HtmlEditorController _formController;

  // Form key for validation in the form editor tab
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Theme and mode state variables
  HtmlEditorTheme _theme = HtmlEditorTheme.light();
  bool _isDarkMode = false;

  // Content tracking variables
  String _basicContent = '';
  String _formContent = '';

  @override
  void initState() {
    super.initState();
    // Initialize tab controller with 2 tabs (Basic Editor and Form Editor)
    _tabController = TabController(length: 2, vsync: this);

    // Initialize HTML editor controllers for both tabs
    _basicController = HtmlEditorController();
    _formController = HtmlEditorController();
  }

  @override
  void dispose() {
    // Dispose of controllers to free up resources
    _tabController.dispose();
    _basicController.dispose();
    _formController.dispose();
    super.dispose();
  }

  /// Toggles between light and dark theme for the HTML editor
  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
      _theme = _isDarkMode ? HtmlEditorTheme.dark() : HtmlEditorTheme.light();
    });
  }

  /// Shows the current HTML content in a dialog
  /// [controller] - The HTML editor controller to get content from
  /// [title] - The title to display in the dialog
  void _showContent(HtmlEditorController controller, String title) async {
    final content = await controller.getHtml();
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: SelectableText(content),
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

  /// Clears all content from the specified HTML editor
  /// [controller] - The HTML editor controller to clear
  void _clearContent(HtmlEditorController controller) async {
    await controller.clear();
  }

  /// Inserts sample HTML content into the specified editor
  /// [controller] - The HTML editor controller to insert content into
  void _insertSampleContent(HtmlEditorController controller) async {
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
    await controller.setHtml(sampleContent);
  }

  /// Callback function for when form editor content changes
  /// [content] - The new HTML content
  void _onFormContentChanged(String content) {
    setState(() {
      _formContent = content;
    });
  }

  /// Handles form submission with validation
  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      // Form is valid, show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Form submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter Advanced HTML Editor'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Theme toggle button
          IconButton(
            icon: Icon(_isDarkMode ? Icons.light_mode : Icons.dark_mode),
            onPressed: _toggleTheme,
          ),
        ],
        // Tab bar for switching between examples
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.edit),
              text: 'Basic Editor',
            ),
            Tab(
              icon: Icon(Icons.assignment),
              text: 'Form Editor',
            ),
          ],
        ),
      ),
      // Tab view containing both editor examples
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBasicEditorTab(),
          _buildFormEditorTab(),
        ],
      ),
    );
  }

  /// Builds the basic HTML editor tab with content management options
  Widget _buildBasicEditorTab() {
    return Column(
      children: [
        // Action bar with character count and menu options
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              // Display current content character count
              Text(
                'Content: ${_basicContent.length} characters',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const Spacer(),
              // Popup menu with content management options
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'show_content':
                      _showContent(_basicController, 'Basic Editor Content');
                      break;
                    case 'clear_content':
                      _clearContent(_basicController);
                      break;
                    case 'insert_sample':
                      _insertSampleContent(_basicController);
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
        ),
        // Main HTML Editor widget
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: FlutterAdvancedHtmlEditor(
              controller: _basicController,
              theme: _theme,
              height: 500,
              initialContent: '<p>Start writing your content here...</p>',
              // Callback when content changes
              onContentChanged: (content) {
                setState(() {
                  _basicContent = content;
                });
              },
              // Callback when text selection changes
              onSelectionChanged: (selection) {
                debugPrint('Selection changed: ${selection['selectedText']}');
              },
              // Custom toolbar configuration with commonly used tools
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
    );
  }

  /// Builds the form editor tab demonstrating validation and form integration
  Widget _buildFormEditorTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Form title and description
            Text(
              'Form with HTML Editor Validation',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'This example shows how to use the HTML editor within a form with validation.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),

            // Content information and action buttons
            Row(
              children: [
                // Character count display
                Text(
                  'Content: ${_formContent.length} characters',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                // Preview content button
                TextButton.icon(
                  onPressed: () => _showContent(_formController, 'Form Editor Content'),
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('Preview'),
                ),
                // Clear content button
                TextButton.icon(
                  onPressed: () => _clearContent(_formController),
                  icon: const Icon(Icons.clear, size: 16),
                  label: const Text('Clear'),
                ),
              ],
            ),
            //kereka8393@excederm.com
            const SizedBox(height: 8),

            // Form-integrated HTML Editor with validation
            Expanded(
              child: FlutterAdvancedHtmlEditorForm(
                controller: _formController,
                height: 400,
                maxLength: 200, // Maximum character limit
                borderRadius: 30, // Rounded corners
                hintText: 'Enter your content here',
                // Custom error text styling
                validationErrorTextStyle: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                // Validation logic
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'This field is required';
                  }
                  if (value.length < 10) {
                    return 'Content must be at least 10 characters long';
                  }
                  return null; // Validation passed
                },
                theme: _theme,
                // Error state styling
                errorBoxDecoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.redAccent,
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                enabled: true,
                // Content change callback
                onContentChanged: _onFormContentChanged,
              ),
            ),
            const SizedBox(height: 16),

            // Form submission button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitForm,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Submit Form',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Information panel explaining form validation
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This form validates that the content is not empty and has at least 10 characters.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}