<p align="center">
  <a href="https://rows.com">
  <br />
  <img src="https://rows.com/media/logo.svg" alt="Rows" width="150"/>
  <br />

  </a>
</p>

<p align="center">
<sub><strong>The spreadsheet with superpowers ✨!</strong></sub>
<br />
<br />
</p>

<p align="center">
  <a title="Pub" href="https://pub.dev/packages/ditto" ><img src="https://img.shields.io/pub/v/ditto.svg?style=popout" /></a>
  <a title="Rows lint" href="https://pub.dev/packages/rows_lint" ><img src="https://img.shields.io/badge/Styled%20by-Rows-754F6C?style=popout" /></a>
</p>


---

## Ditto

A plugin to work with HTML clipboard format on Windwos and MacOS.


### Usage

The `Clipboard` class has a `instance` method to interact with the plugin.

Here is a quick example of writing and reading the HTML clipboard:

```dart
import 'package:clipboard_api/ditto_macos.dart';

// ...
final html = myHtmlContent();

await Clipboard.instance.setClipboard(ClipboardDataType.html, html);
final content = await Clipboard.instance.getClipboardData(ClipboardDataType.html);

```

Refer to the `Clipboard` class to check other usefull methods to manage the clipboard.
