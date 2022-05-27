import 'package:ditto_interface/ditto.dart';
import 'package:flutter/services.dart' hide Clipboard;

const _methodChannel = MethodChannel('ditto_macos');

/// macOS implementation of the [Clipboard] api.
class MacosClipboard extends Ditto {
  static void registerWith() {
    Ditto.instance = MacosClipboard();
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
