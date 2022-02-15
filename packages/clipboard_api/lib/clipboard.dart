import 'dart:async';

enum ClipboardDataType { text, html }

/// A class to interact with the clipboard supporting multiple data formats.
/// Use [Clipboard.instance] to interact with the system's clipboard.
abstract class Clipboard {
  /// Platform-specific plugins should set this with their own platform-specific
  /// class that extends [Clipboard] when they register themselves.
  static Clipboard instance = _UnsupportedPlatformClipboard();

  /// Checks if the current clipboard content supports the given [type].
  Future<bool> hasDataType(ClipboardDataType type);

  /// Gets the current clipboard content.
  /// Returns an empty string if [dataType] is not supported in the current
  /// clipboard data.
  Future<String?> getClipboardData(ClipboardDataType dataType);

  /// Writes content to the clipboard in the specified [dataType].
  Future<void> setClipboard(ClipboardDataType dataType, String content);

  /// Writes clipboard content for all given data types.
  Future<void> setClipboardData(Map<ClipboardDataType, String> data);

  /// Gets the current clipboard raw content.
  /// Returns the clipboard content for a given type without any data
  /// transformation, useful for debugging the operation system's
  /// clipboard content.
  Future<String?> getClipboardRawData(ClipboardDataType dataType);

  /// Gets the current clipboard content as text.
  /// Returns an empty string if text is not supported in the current
  /// clipboard data.
  Future<String?> get clipboardText => getClipboardData(ClipboardDataType.text);

  /// Gets the current clipboard content as HTML.
  /// Returns an empty string if HTML is not supported in the current
  /// clipboard data.
  Future<String?> get clipboardHtml => getClipboardData(ClipboardDataType.html);
}

/// Empty clipboard implementation that throws an exception for unsupported
/// platforms.
class _UnsupportedPlatformClipboard extends Clipboard {
  @override
  Future<String?> getClipboardData(ClipboardDataType dataType) {
    throw UnimplementedError(
      'Clipboard plugin not implemented in this platform.',
    );
  }

  @override
  Future<bool> hasDataType(ClipboardDataType type) {
    throw UnimplementedError(
      'Clipboard plugin not implemented in this platform.',
    );
  }

  @override
  Future<void> setClipboard(ClipboardDataType dataType, String content) {
    throw UnimplementedError(
      'Clipboard plugin not implemented in this platform.',
    );
  }

  @override
  Future<void> setClipboardData(Map<ClipboardDataType, String> data) {
    throw UnimplementedError(
      'Clipboard plugin not implemented in this platform.',
    );
  }

  @override
  Future<String?> getClipboardRawData(ClipboardDataType dataType) {
    throw UnimplementedError(
      'Clipboard plugin not implemented in this platform.',
    );
  }
}
