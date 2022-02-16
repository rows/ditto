import 'package:clipboard_api/clipboard.dart';
import 'package:flutter/services.dart' hide Clipboard;

const _methodChannel = MethodChannel('clipboard_macos');

/// macOS implementation of the [Clipboard] api.
class MacosClipboard extends Clipboard {
  static void registerWith() {
    Clipboard.instance = MacosClipboard();
  }

  @override
  Future<String?> getClipboardData(ClipboardDataType dataType) {
    return _methodChannel.invokeMethod<String>('getClipboardData', {
      'dataType': dataType.index,
    });
  }

  @override
  Future<String?> getClipboardRawData(ClipboardDataType dataType) {
    // Data is not transformed on macos
    return getClipboardData(dataType);
  }

  @override
  Future<bool> hasDataType(ClipboardDataType dataType) async {
    final result = await _methodChannel.invokeMethod<bool>('hasDataType', {
      'dataType': dataType.index,
    });
    return result == true;
  }

  @override
  Future<void> setClipboard(ClipboardDataType dataType, String content) async {
    return setClipboardData({
      dataType: content,
    });
  }

  @override
  Future<void> setClipboardData(Map<ClipboardDataType, String> data) async {
    final dataMap = <int, String>{};
    for (final entry in data.entries) {
      dataMap[entry.key.index] = entry.value;
    }

    await _methodChannel.invokeMethod<void>('setClipboardData', {
      'dataMap': dataMap,
    });
  }
}
