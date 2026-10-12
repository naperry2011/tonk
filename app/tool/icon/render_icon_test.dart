// Renders the app icon to PNGs. Run from app/:
//   flutter test tool/icon/render_icon_test.dart
// then: dart run flutter_launcher_icons
//
// Drawn from shapes only (no fonts), so the output is ours and
// reproducible.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'icon_painter.dart';

Future<void> _render(String path, {required bool background}) async {
  const size = 1024.0;
  final recorder = ui.PictureRecorder();
  paintIcon(Canvas(recorder), size, background: background);
  final image =
      await recorder.endRecording().toImage(size.toInt(), size.toInt());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  test('render app icon PNGs', () async {
    await _render('assets/icon/icon.png', background: true);
    await _render('assets/icon/icon_foreground.png', background: false);
    expect(File('assets/icon/icon.png').lengthSync(), greaterThan(1000));
  });
}
