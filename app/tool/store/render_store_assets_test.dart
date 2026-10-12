// Renders Play Store assets into ../store/ (repo root store/ folder):
//   - icon-512.png         (512x512 app icon)
//   - feature-graphic.png  (1024x500, no alpha)
//   - screenshots/*.png    (raw emulator captures in screenshots/raw/,
//                           re-encoded without alpha as Play requires)
// Run from app/: flutter test tool/store/render_store_assets_test.dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../icon/icon_painter.dart';

const _storeDir = '../store';

/// Encodes RGBA pixels as a 24-bit RGB PNG (Play rejects alpha channels).
Uint8List encodeRgbPng(Uint8List rgba, int width, int height) {
  final raw = BytesBuilder();
  for (var y = 0; y < height; y++) {
    raw.addByte(0); // filter: none
    for (var x = 0; x < width; x++) {
      final i = (y * width + x) * 4;
      raw
        ..addByte(rgba[i])
        ..addByte(rgba[i + 1])
        ..addByte(rgba[i + 2]);
    }
  }

  Uint8List chunk(String type, List<int> data) {
    final typeBytes = type.codeUnits;
    final out = BytesBuilder()
      ..add(_u32(data.length))
      ..add(typeBytes)
      ..add(data)
      ..add(_u32(_crc32([...typeBytes, ...data])));
    return out.toBytes();
  }

  final header = BytesBuilder()
    ..add(_u32(width))
    ..add(_u32(height))
    ..add([8, 2, 0, 0, 0]); // 8-bit, truecolor RGB
  return (BytesBuilder()
        ..add([137, 80, 78, 71, 13, 10, 26, 10])
        ..add(chunk('IHDR', header.toBytes()))
        ..add(chunk('IDAT', ZLibCodec(level: 9).encode(raw.toBytes())))
        ..add(chunk('IEND', const [])))
      .toBytes();
}

List<int> _u32(int v) => [v >> 24 & 255, v >> 16 & 255, v >> 8 & 255, v & 255];

final List<int> _crcTable = List.generate(256, (n) {
  var c = n;
  for (var k = 0; k < 8; k++) {
    c = c & 1 == 1 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
  }
  return c;
});

int _crc32(List<int> bytes) {
  var c = 0xFFFFFFFF;
  for (final b in bytes) {
    c = _crcTable[(c ^ b) & 0xFF] ^ (c >> 8);
  }
  return c ^ 0xFFFFFFFF;
}

Future<Uint8List> _rgba(ui.Image image) async =>
    (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!
        .buffer
        .asUint8List();

Future<void> _writeRgb(String path, ui.Image image) async {
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(
      encodeRgbPng(await _rgba(image), image.width, image.height),
    );
}

Future<ui.Image> _paint(int w, int h, void Function(Canvas) draw) {
  final recorder = ui.PictureRecorder();
  draw(Canvas(recorder));
  return recorder.endRecording().toImage(w, h);
}

Future<void> _loadRoboto() async {
  final sdk = File(Platform.resolvedExecutable).parent.parent.parent.parent;
  final font = File(
    '${sdk.path}/artifacts/material_fonts/roboto-black.ttf',
  );
  final loader = FontLoader('RobotoBlack')
    ..addFont(Future.value(ByteData.sublistView(font.readAsBytesSync())));
  await loader.load();
}

void _paintFeatureGraphic(Canvas canvas) {
  const size = Size(1024, 500);
  final rect = Offset.zero & size;
  canvas.drawRect(
    rect,
    Paint()
      ..shader = const RadialGradient(
        center: Alignment(-0.45, -0.1),
        radius: 1.2,
        colors: [Color(0xFF15724A), Color(0xFF062A19)],
      ).createShader(rect),
  );

  canvas
    ..save()
    ..translate(40, 10)
    ..clipRect(const Rect.fromLTWH(-40, -10, 520, 500));
  paintIcon(canvas, 480, background: false);
  canvas.restore();

  void text(String s, double x, double y, double size, Color color,
      {double spacing = 0}) {
    final painter = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          fontFamily: 'RobotoBlack',
          fontSize: size,
          color: color,
          letterSpacing: spacing,
          shadows: const [Shadow(color: Colors.black54, blurRadius: 12)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, Offset(x, y));
  }

  text('TONK', 470, 130, 150, const Color(0xFFF2C14E), spacing: 12);
  text('Knock. Spread. Talk your talk.', 478, 318, 34, Colors.white);
}

void main() {
  test('render Play Store assets', () async {
    await _loadRoboto();

    final icon = await _paint(512, 512, (c) => paintIcon(c, 512));
    final iconBytes = await icon.toByteData(format: ui.ImageByteFormat.png);
    File('$_storeDir/icon-512.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(iconBytes!.buffer.asUint8List());

    await _writeRgb(
      '$_storeDir/feature-graphic.png',
      await _paint(1024, 500, _paintFeatureGraphic),
    );

    final raw = Directory('$_storeDir/screenshots/raw');
    if (raw.existsSync()) {
      for (final file in raw.listSync().whereType<File>()) {
        if (!file.path.endsWith('.png')) continue;
        final codec = await ui.instantiateImageCodec(file.readAsBytesSync());
        final frame = await codec.getNextFrame();
        final name = file.uri.pathSegments.last;
        await _writeRgb('$_storeDir/screenshots/$name', frame.image);
      }
    }

    expect(File('$_storeDir/feature-graphic.png').existsSync(), isTrue);
  });
}
