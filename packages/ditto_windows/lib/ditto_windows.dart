import 'dart:async';

import 'package:ditto_interface/ditto.dart';
import 'package:flutter/services.dart' hide Clipboard;

/// Windows implementation of [Clipboard]
class WindowsClipboard extends Ditto with Throttle {
  static const MethodChannel _channel = MethodChannel('clipboard_plugin');
  static const _startFragmentTag = '<!--StartFragment-->';
  static const _endFragmentTag = '<!--EndFragment-->';

  static void registerWith() {
    Ditto.instance = WindowsClipboard();
  }

  @override
  Future<bool> hasDataType(ClipboardDataType type) async {
    final isAvailable =
        await _channel.invokeMethod<bool>('hasDataType', type.index);
    return isAvailable ?? false;
  }

  @override
  Future<String?> getClipboardRawData(ClipboardDataType dataType) =>
      _channel.invokeMethod<String>(
        'getClipboardData',
        dataType.index,
      );

  @override
  Future<String?> getClipboardData(ClipboardDataType dataType) async {
    final text = await getClipboardRawData(dataType);
    if (dataType == ClipboardDataType.html && text != null) {
      return _removeHtmlFragmentHeaders(text);
    }
    return text;
  }

  @override
  Future<void> setClipboard(ClipboardDataType dataType, String content) =>
      setClipboardData({dataType: content});

  @override
  Future<void> setClipboardData(Map<ClipboardDataType, String> data) async {
    await throttle(() async {
      final cliboardContent = data.map((type, data) {
        var content = data;
        if (type == ClipboardDataType.html) {
          content = _createHtmlContent(content);
        }
        return MapEntry(type.index, content);
      });
      await _channel.invokeMethod<void>(
        'setClipboardData',
        cliboardContent,
      );
    });
  }

  /// Wraps the content in the standard HTML clipboard format.
  ///
  /// https://docs.microsoft.com/en-us/windows/win32/dataxchg/html-clipboard-format
  String _createHtmlContent(String fragment) {
    const htmlTag = '<html>';

    const header = 'Version:0.9\r\n'
        'StartHTML:00000000\r\n'
        'EndHTML:00000000\r\n'
        'StartFragment:00000000\r\n'
        'EndFragment:00000000\r\n'
        '$htmlTag\r\n'
        '<body>\r\n'
        '$_startFragmentTag';

    const footer = '$_endFragmentTag\r\n'
        '</body>\r\n'
        '</html>\r';

    var content = header + fragment + footer;
    final htmlStartIndex = content.indexOf(htmlTag);
    content = content.replaceFirst(
      'StartHTML:00000000',
      'StartHTML:${htmlStartIndex.toString().padLeft(8, '0')}',
    );

    content = content.replaceFirst(
      'EndHTML:00000000',
      'EndHTML:${(content.length - 1).toString().padLeft(8, '0')}',
    );

    final fragmentStartIndex =
        content.indexOf(_startFragmentTag) + _startFragmentTag.length;
    content = content.replaceFirst(
      'StartFragment:00000000',
      'StartFragment:${fragmentStartIndex.toString().padLeft(8, '0')}',
    );

    final fragmentEndIndex = content.indexOf(_endFragmentTag);
    return content.replaceFirst(
      'EndFragment:00000000',
      'EndFragment:${fragmentEndIndex.toString().padLeft(8, '0')}',
    );
  }

  String _removeHtmlFragmentHeaders(String data) {
    final htmlStartIndex = data.indexOf('<html>');
    if (htmlStartIndex == -1) {
      return data;
    }
    return data
        .substring(htmlStartIndex)
        .replaceAll(RegExp('$_startFragmentTag|$_endFragmentTag'), '');
  }
}

mixin Throttle {
  Completer<void>? throttleCompleter;

  Future<void> throttle(Future<void> Function() callback) async {
    var guardRunCompleter = throttleCompleter;

    final isAnyAsyncTaskRunning = guardRunCompleter?.isCompleted == false;
    if (isAnyAsyncTaskRunning) {
      // Skip tasks triggered whilst another task is running.
      return;
    }
    throttleCompleter = guardRunCompleter = Completer();
    try {
      await callback();
    } finally {
      guardRunCompleter.complete();
    }
  }
}
