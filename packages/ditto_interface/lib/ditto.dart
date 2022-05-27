import 'dart:async';

import 'package:flutter/services.dart';

enum ClipboardDataType { text, html }

/// A class to interact with the clipboard supporting multiple data formats.
/// Use [Ditto.instance] to interact with the system's clipboard.
abstract class Ditto {
  /// Platform-specific plugins should set this with their own platform-specific
  /// class that extends [Ditto] when they register themselves.
  static Ditto instance = _FallbackPlatformClipboard();

  /// Checks if the current clipboard content supports the given [type].
  Future<bool> hasDataType(ClipboardDataType type);

  /// Writes content to the clipboard in the specified [dataType].
  Future<void> setClipboard(ClipboardDataType dataType, String content);

  /// Writes clipboard content for all given data types.
  Future<void> setClipboardData(Map<ClipboardDataType, String> data);

  /// Gets the current clipboard content.
  /// Returns an empty string if [dataType] is not supported in the current
  /// clipboard data.
  Future<String?> getClipboardData(ClipboardDataType dataType);

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

/// A Ditto implementation for platforms where the plugin is not available.
/// Falls back to Flutter default clipboard implementation.
class _FallbackPlatformClipboard extends Ditto {
  @override
  Future<String?> getClipboardData(ClipboardDataType dataType) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    return data?.text;
  }

  @override
  Future<bool> hasDataType(ClipboardDataType type) =>
      Future.value(type == ClipboardDataType.text);

  @override
  Future<void> setClipboard(ClipboardDataType dataType, String content) =>
      Clipboard.setData(ClipboardData(text: content));

  @override
  Future<void> setClipboardData(Map<ClipboardDataType, String> data) =>
      Clipboard.setData(ClipboardData(text: data.values.first));

  @override
  Future<String?> getClipboardRawData(ClipboardDataType dataType) =>
      getClipboardData(dataType);
}
