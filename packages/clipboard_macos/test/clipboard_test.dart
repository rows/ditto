import 'package:clipboard_api/clipboard.dart';
import 'package:clipboard_macos/clipboard_macos.dart';
import 'package:flutter/services.dart' hide Clipboard;
import 'package:flutter_test/flutter_test.dart';

void main() {
  const channel = MethodChannel('clipboard_macos');

  void setMockMethodCallHandler(
    Future<dynamic>? Function(MethodCall call)? handler,
  ) {
    channel.setMockMethodCallHandler(handler);

    addTearDown(() {
      channel.setMockMethodCallHandler(null);
    });
  }

  TestWidgetsFlutterBinding.ensureInitialized();

  group('Clipboard macOS', () {
    group('registration', () {
      test('registerWith registers on clipboard', () async {
        MacosClipboard.registerWith();
        final clipboardInstance = Clipboard.instance;
        expect(clipboardInstance, const TypeMatcher<MacosClipboard>());
      });
    });

    group('hasDataType', () {
      test('text', () async {
        Map<dynamic, dynamic>? methodChannelArguments;
        setMockMethodCallHandler((MethodCall methodCall) async {
          if (methodCall.method == 'hasDataType') {
            methodChannelArguments =
                methodCall.arguments as Map<dynamic, dynamic>?;
            return true;
          }
        });
        final macosClipboard = MacosClipboard();

        await macosClipboard.hasDataType(ClipboardDataType.text);

        expect(methodChannelArguments, {
          'dataType': 0,
        });
      });
      test('html', () async {
        Map<dynamic, dynamic>? methodChannelArguments;
        setMockMethodCallHandler((MethodCall methodCall) async {
          if (methodCall.method == 'hasDataType') {
            methodChannelArguments =
                methodCall.arguments as Map<dynamic, dynamic>?;
            return true;
          }
        });
        final macosClipboard = MacosClipboard();

        await macosClipboard.hasDataType(ClipboardDataType.html);

        expect(methodChannelArguments, {
          'dataType': 1,
        });
      });
    });

    test('setClipboard', () async {
      Map<dynamic, dynamic>? methodChannelArguments;
      setMockMethodCallHandler((MethodCall methodCall) async {
        if (methodCall.method == 'setClipboardData') {
          methodChannelArguments =
              methodCall.arguments as Map<dynamic, dynamic>?;
          return true;
        }
      });
      final macosClipboard = MacosClipboard();

      await macosClipboard.setClipboard(
        ClipboardDataType.html,
        '<html><p>Some <b>html</b> content</p></html>',
      );

      expect(methodChannelArguments, {
        'dataMap': {
          1: '<html><p>Some <b>html</b> content</p></html>',
        }
      });
    });

    test('setClipboardData', () async {
      Map<dynamic, dynamic>? methodChannelArguments;
      setMockMethodCallHandler((MethodCall methodCall) async {
        if (methodCall.method == 'setClipboardData') {
          methodChannelArguments =
              methodCall.arguments as Map<dynamic, dynamic>?;
          return true;
        }
      });
      final macosClipboard = MacosClipboard();

      await macosClipboard.setClipboardData({
        ClipboardDataType.text: 'Some text',
        ClipboardDataType.html: '<html><p>Some <b>html</b> content</p></html>',
      });

      expect(methodChannelArguments, {
        'dataMap': {
          0: 'Some text',
          1: '<html><p>Some <b>html</b> content</p></html>',
        }
      });
    });

    group('getClipboardData', () {
      test('clipboardText', () async {
        Map<dynamic, dynamic>? methodChannelArguments;
        setMockMethodCallHandler((MethodCall methodCall) async {
          if (methodCall.method == 'getClipboardData') {
            methodChannelArguments =
            methodCall.arguments as Map<dynamic, dynamic>?;
            return '';
          }
        });
        final macosClipboard = MacosClipboard();

        await macosClipboard.clipboardText;

        expect(methodChannelArguments, {
          'dataType': 0,
        });
      });
      test('clipboardHtml', () async {
        Map<dynamic, dynamic>? methodChannelArguments;
        setMockMethodCallHandler((MethodCall methodCall) async {
          if (methodCall.method == 'getClipboardData') {
            methodChannelArguments =
            methodCall.arguments as Map<dynamic, dynamic>?;
            return '';
          }
        });
        final macosClipboard = MacosClipboard();

        await macosClipboard.clipboardHtml;

        expect(methodChannelArguments, {
          'dataType': 1,
        });
      });
    });
  });
}
