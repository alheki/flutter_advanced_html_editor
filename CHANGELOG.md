# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-09-22

### Added
- Initial release of Flutter Advanced HTML Editor.
- Rich text formatting: **bold**, *italic*, underline, strikethrough.
- Text color and background color selection.
- Font family and font size selection.
- Text alignment options: left, center, right, justify.
- List support: ordered and unordered.
- Link insertion and editing.
- Image insertion with URL and file support.
- Table creation and editing.
- Code block and blockquote support.
- Undo/redo functionality with full history management.
- Customizable toolbar with extensive options.
- Light and dark theme support.
- Custom theme configuration.
- Content change and selection change callbacks.
- Comprehensive controller API.
- Word count and character count utilities.
- Focus management and editor state control.
- Cross-platform support: Android, iOS, Web, Windows, macOS, Linux.
- Example app demonstrating all features.
- Comprehensive documentation.

### Technical Details
- Built with `webview_flutter` for cross-platform compatibility.
- Integrated `file_picker` for image/file selection.
- Modular architecture with separate controller, theme, and toolbar components.
- Implemented comprehensive error handling and fallback mechanisms.
- Optimized performance with debounced content updates.
- Improved memory efficiency with proper resource cleanup.
- Added support for keyboard shortcuts (Ctrl+Z for undo, Ctrl+Y for redo).
- Implemented smart paste handling for HTML and plain text.
- Added customizable placeholder text.
- Introduced smooth animations and transitions.
