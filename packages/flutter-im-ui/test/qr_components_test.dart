import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flare_im_ui/flare_im_ui.dart';
void main() {
  testWidgets('expired QR and rotation do not retain a scannable code', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: FlareQRCard(name: 'Code', qrPayload: 'https://scan.test/u/token', phase: 'ready', refreshInMs: 0))));
    expect(find.text(const FlareStrings().qrCardUnavailable), findsOneWidget);
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: FlareQRCard(name: 'Code', qrPayload: 'https://scan.test/u/token', phase: 'refreshing'))));
    expect(find.text(const FlareStrings().qrCardUnavailable), findsOneWidget);
  });
  testWidgets('plugin QR expires without a successful refresh', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: FlarePluginQr(token: 'opaque', ttlMs: 1000, encodeQr: (_) async => 'https://scan.test/p/demo/token'))));
    await tester.pump();
    expect(find.byType(FlareQrMatrix), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1100));
    expect(find.byType(FlareQrMatrix), findsNothing);
    expect(find.text(const FlareStrings().scanCodeExpired), findsOneWidget);
  });
}
