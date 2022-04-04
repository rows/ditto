import 'package:clipboard_api/clipboard.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final TextEditingController _textEditingController = TextEditingController();
  ClipboardDataType _clipboardDataType = ClipboardDataType.text;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Clipboard example app'),
        ),
        body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  DropdownButton<ClipboardDataType>(
                    value: _clipboardDataType,
                    items: ClipboardDataType.values
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text('$value'),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => _setClipboardDataType(value!),
                  ),
                  const SizedBox(
                    width: 8.0,
                  ),
                  ElevatedButton(
                    child: const Text('Copy'),
                    onPressed: _copy,
                  ),
                  const SizedBox(
                    width: 8.0,
                  ),
                  ElevatedButton(
                    child: const Text('Paste'),
                    onPressed: _paste,
                  ),
                  const Spacer(),
                  ElevatedButton(
                    child: const Text('Copy in all formats'),
                    onPressed: _copyAllFormats,
                  ),
                  const SizedBox(
                    width: 8.0,
                  ),
                  ElevatedButton(
                    child: const Text('Paste Raw'),
                    onPressed: _pasteRaw,
                  ),
                ],
              ),
              const SizedBox(
                height: 32.0,
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: TextField(
                    controller: _textEditingController,
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future _paste() async {
    final data = await Clipboard.instance.getClipboardData(_clipboardDataType);
    _textEditingController.text = data!;
  }

  Future _pasteRaw() async {
    final data = await Clipboard.instance.getClipboardRawData(
      _clipboardDataType,
    );
    _textEditingController.text = data!;
  }

  Future _copy() => Clipboard.instance.setClipboard(
        _clipboardDataType,
        _textEditingController.text,
      );

  Future _copyAllFormats() => Clipboard.instance.setClipboardData({
        for (var type in ClipboardDataType.values)
          type: _textEditingController.text
      });

  void _setClipboardDataType(ClipboardDataType type) {
    setState(() {
      _clipboardDataType = type;
    });
    _paste();
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }
}
