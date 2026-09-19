import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flare_im_ui/src/components/qr/flare_qr_encoder.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

const _payload = 'https://flare.im/add-friend?token=qr-card-test';
const _strings = FlareStrings();

Widget _host(
  Widget card, {
  bool dark = false,
  GlobalKey? boundary,
  FlareStrings strings = _strings,
}) => FlareStringsScope(
  strings: strings,
  child: MaterialApp(
    theme: ThemeData(brightness: dark ? Brightness.dark : Brightness.light),
    home: FlareTheme(
      mode: dark ? FlareThemeMode.dark : FlareThemeMode.light,
      child: Scaffold(
        body: Center(
          child: RepaintBoundary(key: boundary, child: card),
        ),
      ),
    ),
  ),
);

Finder _codePaint() => find.byWidgetPredicate(
  (widget) =>
      widget is CustomPaint &&
      widget.painter?.runtimeType.toString() == '_QrCodePainter',
);

int _argb(Color color) => color.toARGB32();

/// Captures the card and checks every module centre of the painted code,
/// quiet zone included, against the encoder output.
Future<void> _expectPaintedCode(
  WidgetTester tester,
  GlobalKey boundaryKey,
  String payload,
) async {
  final symbol = QrEncoder.encodeText(payload)!;
  final light = FlareColors.light;
  final ratio = tester.view.devicePixelRatio;
  final boundary =
      boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = (await tester.runAsync(
    () => boundary.toImage(pixelRatio: ratio),
  ))!;
  final bytes = (await tester.runAsync(
    () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
  ))!;

  final origin = boundary.localToGlobal(Offset.zero);
  final paintRect = tester.getRect(_codePaint()).shift(-origin);
  final count = symbol.size + 2 * QrEncoder.quietZone;
  final inset = FlareSizes.radiusLg * (1 - math.sqrt1_2);
  final side = math.min(paintRect.width, paintRect.height) - 2 * inset;
  final devicePixels = (side * ratio / count).floorToDouble();
  expect(devicePixels, greaterThanOrEqualTo(1));
  final module = devicePixels / ratio;
  final left = paintRect.left + (paintRect.width - module * count) / 2;
  final top = paintRect.top + (paintRect.height - module * count) / 2;

  int pixel(int mx, int my) {
    final x = ((left + (mx + 0.5) * module) * ratio).floor();
    final y = ((top + (my + 0.5) * module) * ratio).floor();
    final i = (y * image.width + x) * 4;
    return (bytes.getUint8(i + 3) << 24) |
        (bytes.getUint8(i) << 16) |
        (bytes.getUint8(i + 1) << 8) |
        bytes.getUint8(i + 2);
  }

  const q = QrEncoder.quietZone;
  var mismatches = 0;
  for (var my = 0; my < count; my++) {
    for (var mx = 0; mx < count; mx++) {
      final inside =
          mx >= q && my >= q && mx < q + symbol.size && my < q + symbol.size;
      final dark = inside && symbol.isDark(mx - q, my - q);
      final expected = _argb(dark ? light.textPrimary : light.bgPrimary);
      if (pixel(mx, my) != expected) mismatches++;
    }
  }
  expect(mismatches, 0, reason: 'module centres that differ from the symbol');
  image.dispose();
}

void main() {
  testWidgets('a payload renders a real QR code with a light quiet zone', (
    tester,
  ) async {
    final boundary = GlobalKey();
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        const FlareQRCard(name: 'Alice', qrPayload: _payload),
        boundary: boundary,
      ),
    );

    expect(_codePaint(), findsOneWidget);
    expect(find.text(_strings.qrCardUnavailable), findsNothing);
    expect(find.text(_strings.qrCardHint), findsOneWidget);
    final label = '${_strings.qrCode}, Alice';
    expect(
      tester.getSemantics(find.bySemanticsLabel(label)),
      isSemantics(label: label, isImage: true),
    );
    await _expectPaintedCode(tester, boundary, _payload);
    semantics.dispose();
  });

  testWidgets('the code stays dark on a light panel in the dark theme', (
    tester,
  ) async {
    final boundary = GlobalKey();
    await tester.pumpWidget(
      _host(
        const FlareQRCard(name: 'Alice', qrPayload: _payload),
        dark: true,
        boundary: boundary,
      ),
    );

    final panel = tester.widget<Container>(
      find.ancestor(of: _codePaint(), matching: find.byType(Container)).first,
    );
    final decoration = panel.decoration! as BoxDecoration;
    expect(decoration.color, FlareColors.light.bgPrimary);
    expect(FlareColors.dark.bgPrimary, isNot(FlareColors.light.bgPrimary));
    await _expectPaintedCode(tester, boundary, _payload);
  });

  testWidgets(
    'without a payload the frame says unavailable and draws no code',
    (tester) async {
      for (final payload in <String?>[null, '', 'x' * 2332]) {
        await tester.pumpWidget(
          _host(FlareQRCard(name: 'Alice', qrPayload: payload)),
        );
        expect(_codePaint(), findsNothing, reason: 'payload "$payload"');
        expect(find.text(_strings.qrCardUnavailable), findsOneWidget);
        expect(find.text(_strings.qrCardHint), findsNothing);
      }
    },
  );

  testWidgets('copy comes from FlareStrings and a new payload re-encodes', (
    tester,
  ) async {
    final boundary = GlobalKey();
    final english = const FlareStrings().copyWith(
      qrCode: 'QR code',
      qrCardHint: 'Scan to add me',
      qrCardUnavailable: 'QR code unavailable',
    );
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(
        const FlareQRCard(name: 'Alice'),
        strings: english,
        boundary: boundary,
      ),
    );
    expect(find.text('QR code unavailable'), findsOneWidget);

    await tester.pumpWidget(
      _host(
        const FlareQRCard(name: 'Alice', qrPayload: 'flare://add/u_1'),
        strings: english,
        boundary: boundary,
      ),
    );
    expect(find.text('Scan to add me'), findsOneWidget);
    expect(find.bySemanticsLabel('QR code, Alice'), findsOneWidget);
    await _expectPaintedCode(tester, boundary, 'flare://add/u_1');

    await tester.pumpWidget(
      _host(
        const FlareQRCard(
          name: 'Alice',
          qrPayload: 'flare://add/u_2',
          hint: 'Custom hint',
        ),
        strings: english,
        boundary: boundary,
      ),
    );
    expect(find.text('Custom hint'), findsOneWidget);
    await _expectPaintedCode(tester, boundary, 'flare://add/u_2');
    semantics.dispose();
  });
}
