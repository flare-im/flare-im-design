import 'dart:typed_data';
import 'dart:ui' as ui;
import 'flare_qr_encoder.dart';

/// Export the same level-M symbol as QRCard, with four light modules on each side.
Future<Uint8List> flareQrPng(String payload, {int size = 1024}) async {
  if (size < 64 || size > 4096) throw RangeError.range(size, 64, 4096, 'size');
  final symbol = QrEncoder.encodeText(payload);
  if (payload.isEmpty || symbol == null) throw ArgumentError('QR payload cannot be encoded');
  final modules = symbol.size + QrEncoder.quietZone * 2;
  final module = (size / modules).ceil();
  final side = modules * module;
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawColor(const ui.Color(0xffffffff), ui.BlendMode.src);
  final paint = ui.Paint()..color = const ui.Color(0xff000000)..isAntiAlias = false;
  for (var y = 0; y < symbol.size; y++) {
    for (var x = 0; x < symbol.size; x++) {
      if (symbol.isDark(x, y)) canvas.drawRect(ui.Rect.fromLTWH(((x + QrEncoder.quietZone) * module).toDouble(), ((y + QrEncoder.quietZone) * module).toDouble(), module.toDouble(), module.toDouble()), paint);
    }
  }
  final picture = recorder.endRecording();
  try {
    final image = await picture.toImage(side, side);
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) throw StateError('PNG encoding failed');
      return bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes);
    } finally { image.dispose(); }
  } finally { picture.dispose(); }
}
