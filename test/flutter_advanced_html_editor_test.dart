import 'package:flutter_test/flutter_test.dart';


// Mock implementation for testing
class MockHtmlEditorWidgetState {
  String _content = '';

  void setMockContent(String content) {
    _content = content;
  }

  Future<String> getContent() async {
    return _content;
  }

  Future<void> setContent(String content) async {
    _content = content;
  }

  Future<void> executeCommand(String command, [String? value]) async {
    // Mock implementation
  }

  Future<void> insertHTML(String html) async {
    _content += html;
  }

  Future<void> undo() async {
    // Mock implementation
  }

  Future<void> redo() async {
    // Mock implementation
  }

  Future<void> insertTable(int rows, int cols) async {
    _content += '<table></table>';
  }

  Future<void> insertLink(String url, String text) async {
    _content += '<a href="$url">$text</a>';
  }

  Future<void> insertImage(String url, String alt) async {
    _content += '<img src="$url" alt="$alt">';
  }

  Future<void> focus() async {
    // Mock implementation
  }
}