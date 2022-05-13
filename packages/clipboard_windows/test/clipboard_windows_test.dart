import 'package:clipboard_api/clipboard.dart';
import 'package:clipboard_windows/clipboard_windows.dart';
import 'package:flutter/services.dart' hide Clipboard;
import 'package:flutter_test/flutter_test.dart';

void main() {
  const expectedHtml = 'Version:0.9\r\n'
      'StartHTML:00000097\r\n'
      'EndHTML:00000428\r\n'
      'StartFragment:00000133\r\n'
      'EndFragment:00000392\r\n'
      '<html>\r\n'
      '<body>\r\n'
      '<!--StartFragment--><div style="color: #d4d4d4;background-color: '
      '#1e1e1e;font-family: Source Code Pro, Consolas, '
      "Consolas, 'Courier New', monospace;font-weight: normal;font-size: "
      '14px;line-height: 19px;white-space: pre;"><div><span style="color: '
      '#d4d4d4;">test</span></div></div><!--EndFragment-->\r\n'
      '</body>\r\n'
      '</html>\r';

  const htmlFragment =
      '<div style="color: #d4d4d4;background-color: #1e1e1e;font-family: '
      "Source Code Pro, Consolas, Consolas, 'Courier New', "
      'monospace;font-weight: normal;font-size: 14px;line-height: '
      '19px;white-space: pre;"><div><span style="color: '
      '#d4d4d4;">test</span></div></div>';

  late List<MethodCall> channelCallLog;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();

    channelCallLog = <MethodCall>[];
    const channel = MethodChannel('clipboard_plugin');
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      channelCallLog.add(methodCall);
    });
    WindowsClipboard.registerWith();
  });

  group('Windows Clipboard', () {
    test('creates html fragment', () async {
      await Ditto.instance.setClipboard(
        ClipboardDataType.html,
        htmlFragment,
      );
      expect(channelCallLog, hasLength(1));

      final call = channelCallLog.first;
      expect(call.method, 'setClipboardData');

      final arguments = call.arguments as Map;
      expect(arguments, hasLength(1));
      expect(arguments[ClipboardDataType.html.index], expectedHtml);
    });

    test('set clipboard text data', () async {
      const text = 'some content to paste';
      await Ditto.instance.setClipboard(ClipboardDataType.text, text);

      expect(channelCallLog, hasLength(1));
      final call = channelCallLog.first;
      expect(call.method, 'setClipboardData');

      final arguments = call.arguments as Map;
      expect(arguments, hasLength(1));
      expect(arguments[ClipboardDataType.text.index], text);
    });

    test('set clipboard data', () async {
      const text = 'this is the expected original text';
      await Ditto.instance.setClipboardData({
        ClipboardDataType.text: text,
        ClipboardDataType.html: htmlFragment,
      });

      expect(channelCallLog, hasLength(1));
      final call = channelCallLog.first;
      expect(call.method, 'setClipboardData');

      final arguments = call.arguments as Map;
      expect(arguments, hasLength(2));
      expect(arguments[ClipboardDataType.text.index], text);
      expect(arguments[ClipboardDataType.html.index], expectedHtml);
    });

    test('read html from clipboard removes the Windows header', () async {
      const expectedHtmlFragment =
          '<html>\r\n<body>\r\n$htmlFragment\r\n</body>\r\n</html>\r';

      const channel = MethodChannel('clipboard_plugin');
      channel.setMockMethodCallHandler((MethodCall methodCall) async {
        channelCallLog.add(methodCall);
        return expectedHtml;
      });

      final content = await Ditto.instance.getClipboardData(
        ClipboardDataType.html,
      );
      expect(channelCallLog, hasLength(1));
      expect(channelCallLog.first.method, 'getClipboardData');

      final type = channelCallLog.first.arguments as int;
      expect(type, ClipboardDataType.html.index);
      expect(content, isNotNull);
      expect(content, expectedHtmlFragment);
    });

    test("read invalid html won't change the data", () async {
      const text = 'This is not an html';
      const channel = MethodChannel('clipboard_plugin');
      channel.setMockMethodCallHandler((MethodCall methodCall) async {
        channelCallLog.add(methodCall);
        return text;
      });

      final content = await Ditto.instance.getClipboardData(
        ClipboardDataType.html,
      );
      expect(channelCallLog, hasLength(1));
      expect(channelCallLog.first.method, 'getClipboardData');

      final type = channelCallLog.first.arguments as int;
      expect(type, ClipboardDataType.html.index);
      expect(content, isNotNull);
      expect(content, text);
    });

    test("read raw clipboard data won't transform the data", () async {
      const channel = MethodChannel('clipboard_plugin');
      channel.setMockMethodCallHandler((MethodCall methodCall) async {
        channelCallLog.add(methodCall);
        return expectedHtml;
      });

      final content = await Ditto.instance.getClipboardRawData(
        ClipboardDataType.html,
      );
      expect(channelCallLog, hasLength(1));
      expect(channelCallLog.first.method, 'getClipboardData');

      final type = channelCallLog.first.arguments as int;
      expect(type, ClipboardDataType.html.index);
      expect(content, isNotNull);
      expect(content, expectedHtml);
    });
  });
}
