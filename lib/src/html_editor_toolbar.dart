import 'dart:async';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'html_editor_controller.dart';
import 'html_editor_theme.dart';

/// Enum defining available toolbar items
enum HtmlEditorToolbarItem {
  undo,
  redo,
  bold,
  italic,
  underline,
  strikethrough,
  textColor,
  backgroundColor,
  fontFamily,
  fontSize,
  alignLeft,
  alignCenter,
  alignRight,
  justify,
  unorderedList,
  orderedList,
  indent,
  outdent,
  link,
  image,
  table,
  code,
  removeFormat,
  heading1,
  heading2,
  heading3,
  paragraph,
  blockquote,
  horizontalRule,
}

/// Customizable toolbar widget for the HTML editor
/// 
/// Provides a comprehensive set of formatting tools including text styling,
/// alignment, lists, media insertion, and more.
class HtmlEditorToolbar extends StatefulWidget {
  final HtmlEditorController controller;
  final HtmlEditorTheme theme;
  final List<HtmlEditorToolbarItem>? customItems;
  final bool showLabels;
  final bool showDivider;
  final Widget? divider;
  final double height;
  final BoxDecoration? boxDecoration;

  const HtmlEditorToolbar({
    super.key,
    required this.controller,
    required this.theme,
    this.customItems,
    this.showDivider = false,
    this.showLabels = false,
    this.divider,
    this.boxDecoration,
    this.height = 60,
  });

  @override
  State<HtmlEditorToolbar> createState() => _HtmlEditorToolbarState();
}

class _HtmlEditorToolbarState extends State<HtmlEditorToolbar> {
  String _selectedFontFamily = 'Arial';
  String _selectedFontSize = '14px';
  Color _selectedTextColor = Colors.black;
  Color _selectedBackgroundColor = Colors.transparent;

  List<HtmlEditorToolbarItem> get _toolbarItems {
    return widget.customItems ?? [
      HtmlEditorToolbarItem.undo,
      HtmlEditorToolbarItem.redo,
      HtmlEditorToolbarItem.bold,
      HtmlEditorToolbarItem.italic,
      HtmlEditorToolbarItem.underline,
      HtmlEditorToolbarItem.strikethrough,
      HtmlEditorToolbarItem.textColor,
      HtmlEditorToolbarItem.backgroundColor,
      HtmlEditorToolbarItem.fontFamily,
      HtmlEditorToolbarItem.fontSize,
      HtmlEditorToolbarItem.alignLeft,
      HtmlEditorToolbarItem.alignCenter,
      HtmlEditorToolbarItem.alignRight,
      HtmlEditorToolbarItem.justify,
      HtmlEditorToolbarItem.unorderedList,
      HtmlEditorToolbarItem.orderedList,
      HtmlEditorToolbarItem.indent,
      HtmlEditorToolbarItem.outdent,
      HtmlEditorToolbarItem.link,
      HtmlEditorToolbarItem.image,
      HtmlEditorToolbarItem.table,
      HtmlEditorToolbarItem.code,
      HtmlEditorToolbarItem.removeFormat,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: widget.boxDecoration ??
          BoxDecoration(
            color: widget.theme.toolbarBackgroundColorValue,
            border: Border(
              bottom: BorderSide(
                color: widget.theme.borderColorValue,
                width: 1,
              ),
            ),
          ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: _buildToolbarItems(),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildToolbarItems() {
    final items = <Widget>[];

    for (int i = 0; i < _toolbarItems.length; i++) {
      final item = _toolbarItems[i];

      items.add(_buildToolbarItem(item));

      // Add divider after certain groups
      if (_shouldAddDivider(item, i) && widget.showDivider) {
        items.add(widget.divider ?? _buildDivider());
      }
    }

    return items;
  }

  bool _shouldAddDivider(HtmlEditorToolbarItem item, int index) {
    if (index == _toolbarItems.length - 1) {
      return false;
    }

    final dividerAfter = [
      HtmlEditorToolbarItem.redo,
      HtmlEditorToolbarItem.strikethrough,
      HtmlEditorToolbarItem.fontSize,
      HtmlEditorToolbarItem.justify,
      HtmlEditorToolbarItem.outdent,
      HtmlEditorToolbarItem.table,
    ];

    return dividerAfter.contains(item);
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: widget.theme.borderColorValue,
    );
  }

  Widget _buildToolbarItem(HtmlEditorToolbarItem item) {
    switch (item) {
      case HtmlEditorToolbarItem.fontFamily:
        return _buildFontFamilyDropdown();
      case HtmlEditorToolbarItem.fontSize:
        return _buildFontSizeDropdown();
      case HtmlEditorToolbarItem.textColor:
        return _buildColorPicker(
          color: _selectedTextColor,
          onColorChanged: (color) {
            setState(() {
              _selectedTextColor = color;
            });
            // Fixed color formatting
            final hexColor = '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
            unawaited(widget.controller.setTextColor(hexColor));
          },
          tooltip: 'Text Color',
        );
      case HtmlEditorToolbarItem.backgroundColor:
        return _buildColorPicker(
          color: _selectedBackgroundColor,
          onColorChanged: (color) {
            setState(() {
              _selectedBackgroundColor = color;
            });
            // Fixed color formatting
            final hexColor = '#${color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
            unawaited(widget.controller.setBackgroundColor(hexColor));
          },
          tooltip: 'Background Color',
        );
      case HtmlEditorToolbarItem.link:
        return _buildButton(
          icon: Icons.link,
          tooltip: 'Insert Link',
          onPressed: () => _showLinkDialog(),
        );
      case HtmlEditorToolbarItem.image:
        return _buildButton(
          icon: Icons.image,
          tooltip: 'Insert Image',
          onPressed: () => _showImageDialog(),
        );
      case HtmlEditorToolbarItem.table:
        return _buildButton(
          icon: Icons.table_chart,
          tooltip: 'Insert Table',
          onPressed: () => _showTableDialog(),
        );
      default:
        return _buildSimpleButton(item);
    }
  }

  Widget _buildSimpleButton(HtmlEditorToolbarItem item) {
    final config = _getButtonConfig(item);
    return _buildButton(
      icon: config['icon'] as IconData,
      tooltip: config['tooltip'] as String,
      onPressed: config['onPressed'] as VoidCallback,
    );
  }

  Map<String, dynamic> _getButtonConfig(HtmlEditorToolbarItem item) {
    switch (item) {
      case HtmlEditorToolbarItem.undo:
        return {
          'icon': Icons.undo,
          'tooltip': 'Undo',
          'onPressed': () => unawaited(widget.controller.undo()),
        };
      case HtmlEditorToolbarItem.redo:
        return {
          'icon': Icons.redo,
          'tooltip': 'Redo',
          'onPressed': () => unawaited(widget.controller.redo()),
        };
      case HtmlEditorToolbarItem.bold:
        return {
          'icon': Icons.format_bold,
          'tooltip': 'Bold',
          'onPressed': () => unawaited(widget.controller.bold()),
        };
      case HtmlEditorToolbarItem.italic:
        return {
          'icon': Icons.format_italic,
          'tooltip': 'Italic',
          'onPressed': () => unawaited(widget.controller.italic()),
        };
      case HtmlEditorToolbarItem.underline:
        return {
          'icon': Icons.format_underlined,
          'tooltip': 'Underline',
          'onPressed': () => unawaited(widget.controller.underline()),
        };
      case HtmlEditorToolbarItem.strikethrough:
        return {
          'icon': Icons.format_strikethrough,
          'tooltip': 'Strikethrough',
          'onPressed': () => unawaited(widget.controller.strikeThrough()),
        };
      case HtmlEditorToolbarItem.alignLeft:
        return {
          'icon': Icons.format_align_left,
          'tooltip': 'Align Left',
          'onPressed': () => unawaited(widget.controller.alignLeft()),
        };
      case HtmlEditorToolbarItem.alignCenter:
        return {
          'icon': Icons.format_align_center,
          'tooltip': 'Align Center',
          'onPressed': () => unawaited(widget.controller.alignCenter()),
        };
      case HtmlEditorToolbarItem.alignRight:
        return {
          'icon': Icons.format_align_right,
          'tooltip': 'Align Right',
          'onPressed': () => unawaited(widget.controller.alignRight()),
        };
      case HtmlEditorToolbarItem.justify:
        return {
          'icon': Icons.format_align_justify,
          'tooltip': 'Justify',
          'onPressed': () => unawaited(widget.controller.justify()),
        };
      case HtmlEditorToolbarItem.unorderedList:
        return {
          'icon': Icons.format_list_bulleted,
          'tooltip': 'Bullet List',
          'onPressed': () => unawaited(widget.controller.insertUnorderedList()),
        };
      case HtmlEditorToolbarItem.orderedList:
        return {
          'icon': Icons.format_list_numbered,
          'tooltip': 'Numbered List',
          'onPressed': () => unawaited(widget.controller.insertOrderedList()),
        };
      case HtmlEditorToolbarItem.indent:
        return {
          'icon': Icons.format_indent_increase,
          'tooltip': 'Indent',
          'onPressed': () => unawaited(widget.controller.indent()),
        };
      case HtmlEditorToolbarItem.outdent:
        return {
          'icon': Icons.format_indent_decrease,
          'tooltip': 'Outdent',
          'onPressed': () => unawaited(widget.controller.outdent()),
        };
      case HtmlEditorToolbarItem.code:
        return {
          'icon': Icons.code,
          'tooltip': 'Code Block',
          'onPressed': () => unawaited(widget.controller.insertCodeBlock()),
        };
      case HtmlEditorToolbarItem.removeFormat:
        return {
          'icon': Icons.format_clear,
          'tooltip': 'Clear Formatting',
          'onPressed': () => unawaited(widget.controller.removeFormat()),
        };
      case HtmlEditorToolbarItem.heading1:
        return {
          'icon': Icons.title,
          'tooltip': 'Heading 1',
          'onPressed': () => unawaited(widget.controller.setHeading(1)),
        };
      case HtmlEditorToolbarItem.heading2:
        return {
          'icon': Icons.title,
          'tooltip': 'Heading 2',
          'onPressed': () => unawaited(widget.controller.setHeading(2)),
        };
      case HtmlEditorToolbarItem.heading3:
        return {
          'icon': Icons.title,
          'tooltip': 'Heading 3',
          'onPressed': () => unawaited(widget.controller.setHeading(3)),
        };
      case HtmlEditorToolbarItem.paragraph:
        return {
          'icon': Icons.notes,
          'tooltip': 'Paragraph',
          'onPressed': () => unawaited(widget.controller.setParagraph()),
        };
      case HtmlEditorToolbarItem.blockquote:
        return {
          'icon': Icons.format_quote,
          'tooltip': 'Blockquote',
          'onPressed': () => unawaited(widget.controller.insertBlockquote()),
        };
      case HtmlEditorToolbarItem.horizontalRule:
        return {
          'icon': Icons.horizontal_rule,
          'tooltip': 'Horizontal Rule',
          'onPressed': () => unawaited(widget.controller.insertHorizontalRule()),
        };
      default:
        return {
          'icon': Icons.help,
          'tooltip': 'Unknown',
          'onPressed': () {},
        };
    }
  }

  Widget _buildButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: isActive ? widget.theme.primaryColorValue : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(4),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: widget.theme.borderColorValue.withOpacity(0.3),
                ),
              ),
              child: Icon(
                icon,
                size: 18,
                color: isActive ? Colors.white : widget.theme.toolbarTextColorValue,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFontFamilyDropdown() {
    final fontFamilies = [
      'Arial',
      'Helvetica',
      'Times New Roman',
      'Georgia',
      'Courier New',
      'Verdana',
      'Trebuchet MS',
      'Impact',
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: DropdownButton<String>(
        value: _selectedFontFamily,
        items: fontFamilies.map((font) {
          return DropdownMenuItem(
            value: font,
            child: Text(
              font,
              style: TextStyle(
                fontFamily: font,
                fontSize: 14,
                color: widget.theme.toolbarTextColorValue,
              ),
            ),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _selectedFontFamily = value;
            });
            unawaited(widget.controller.setFontFamily(value));
          }
        },
        underline: Container(),
        style: TextStyle(
          color: widget.theme.toolbarTextColorValue,
          fontSize: 14,
        ),
        dropdownColor: widget.theme.toolbarBackgroundColorValue,
      ),
    );
  }

  Widget _buildFontSizeDropdown() {
    final fontSizes = ['10px', '12px', '14px', '16px', '18px', '20px', '24px', '32px'];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: DropdownButton<String>(
        value: _selectedFontSize,
        items: fontSizes.map((size) {
          return DropdownMenuItem(
            value: size,
            child: Text(
              size,
              style: TextStyle(
                fontSize: 14,
                color: widget.theme.toolbarTextColorValue,
              ),
            ),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _selectedFontSize = value;
            });
            unawaited(widget.controller.setFontSize(value));
          }
        },
        underline: Container(),
        style: TextStyle(
          color: widget.theme.toolbarTextColorValue,
          fontSize: 14,
        ),
        dropdownColor: widget.theme.toolbarBackgroundColorValue,
      ),
    );
  }

  Widget _buildColorPicker({
    required Color color,
    required ValueChanged<Color> onColorChanged,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          child: InkWell(
            onTap: () => _showColorPicker(color, onColorChanged),
            borderRadius: BorderRadius.circular(4),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: widget.theme.borderColorValue.withOpacity(0.3),
                ),
              ),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(
                    color: widget.theme.borderColorValue,
                    width: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showColorPicker(Color currentColor, ValueChanged<Color> onColorChanged) {
    // Basic color picker without external dependencies
    final List<Color> colors = [
      Colors.black,
      Colors.white,
      Colors.red,
      Colors.green,
      Colors.blue,
      Colors.yellow,
      Colors.orange,
      Colors.purple,
      Colors.pink,
      Colors.teal,
      Colors.indigo,
      Colors.lime,
    ];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pick a color'),
          content: SizedBox(
            width: 300,
            height: 200,
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 6,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: colors.length,
              itemBuilder: (context, index) {
                final color = colors[index];
                return GestureDetector(
                  onTap: () {
                    onColorChanged(color);
                    Navigator.pop(context);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: currentColor == color ? Colors.black : Colors.grey,
                        width: currentColor == color ? 2 : 1,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showLinkDialog() {
    final textController = TextEditingController();
    final urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Insert Link'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textController,
                decoration: const InputDecoration(
                  labelText: 'Link Text',
                  hintText: 'Enter link text',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  labelText: 'URL',
                  hintText: 'https://example.com',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final text = textController.text.trim();
                final url = urlController.text.trim();
                if (url.isNotEmpty) {
                  unawaited(widget.controller.insertLink(url, text.isNotEmpty ? text : null));
                }
                Navigator.pop(context);
              },
              child: const Text('Insert'),
            ),
          ],
        );
      },
    );
  }

  void _showImageDialog() {
    final urlController = TextEditingController();
    final altController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Insert Image'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ElevatedButton(
                onPressed: () async {
                  try {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.image,
                    );
                    if (result != null && result.files.isNotEmpty) {
                      final file = result.files.first;
                      // In a real app, you'd upload this file and get a URL
                      urlController.text = file.path ?? '';
                    }
                  } catch (e) {
                    // Handle file picker errors gracefully
                    debugPrint('Error picking file: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Failed to pick file')),
                      );
                    }
                  }
                },
                child: const Text('Choose File'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  labelText: 'Image URL',
                  hintText: 'https://example.com/image.jpg',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: altController,
                decoration: const InputDecoration(
                  labelText: 'Alt Text',
                  hintText: 'Image description',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final url = urlController.text.trim();
                final alt = altController.text.trim();
                if (url.isNotEmpty) {
                  unawaited(widget.controller.insertImage(url, alt));
                }
                Navigator.pop(context);
              },
              child: const Text('Insert'),
            ),
          ],
        );
      },
    );
  }

  void _showTableDialog() {
    int rows = 3;
    int columns = 3;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Insert Table'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Text('Rows: '),
                      Expanded(
                        child: Slider(
                          value: rows.toDouble(),
                          min: 1,
                          max: 10,
                          divisions: 9,
                          label: rows.toString(),
                          onChanged: (value) {
                            setState(() {
                              rows = value.round();
                            });
                          },
                        ),
                      ),
                      Text(rows.toString()),
                    ],
                  ),
                  Row(
                    children: [
                      const Text('Columns: '),
                      Expanded(
                        child: Slider(
                          value: columns.toDouble(),
                          min: 1,
                          max: 10,
                          divisions: 9,
                          label: columns.toString(),
                          onChanged: (value) {
                            setState(() {
                              columns = value.round();
                            });
                          },
                        ),
                      ),
                      Text(columns.toString()),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    unawaited(widget.controller.insertTable(rows, columns));
                    Navigator.pop(context);
                  },
                  child: const Text('Insert'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}