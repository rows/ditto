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

---

## Ditto

A plugin to work with HTML clipboard format on Windows and MacOS.

On other platforms it falls back to default Flutter text clipboard.


### Usage

The `Ditto` class has a `instance` method to interact with the plugin.

Here is a quick example of writing and reading the HTML clipboard:

```dart
import 'package:ditto/ditto.dart';

// ...
final html = myHtmlContent();

await Ditto.instance.setClipboard(ClipboardDataType.html, html);
final content = await Ditto.instance.getClipboardData(ClipboardDataType.html);

```

Refer to the `Ditto` class to check other usefull methods to manage the clipboard.
