import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flare_im_ui/flare_im_ui.dart';
void main() {
  testWidgets('image failure has its own status and keeps retry and choosing another image', (tester) async {
    var retries = 0, picks = 0;
    const strings = FlareStrings();
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: FlareScanViewfinder(state: 'imageError', capabilities: const FlareScanCapabilities(live: false, album: true, paste: false, myCode: false), preview: const SizedBox.shrink(), onClose: () {}, onRetry: () { retries++; }, onPickImage: () { picks++; }))));
    expect(find.text(strings.scanImageError), findsOneWidget);
    expect(find.text(strings.scanNoCodeInImage), findsNothing); expect(find.text(strings.scanCameraError), findsNothing);
    await tester.tap(find.text(strings.retry)); await tester.tap(find.text(strings.scanAlbum));
    expect(retries, 1); expect(picks, 1);
  });
  testWidgets('paused capture has an explicit retry action', (tester) async {
    var retries = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: FlareScanViewfinder(state: 'paused', capabilities: const FlareScanCapabilities(), preview: const SizedBox.shrink(), onClose: () {}, onRetry: () { retries++; }))));
    await tester.tap(find.text(const FlareStrings().retry));
    expect(retries, 1);
  });
  testWidgets('result dismissal is explicit and unavailable while an action owns the flow', (tester) async {
    var dismissed = 0;
    Widget surface(bool busy) => MaterialApp(home: Scaffold(body: FlareScanResultSheet(phase: busy ? 'acting' : 'ready', header: const FlareScanHeader(title: 'Person'), busy: busy, onAction: (_, _) {}, onDismiss: () { dismissed++; })));
    await tester.pumpWidget(surface(true));
    expect(tester.widget<FlareButton>(find.widgetWithText(FlareButton, const FlareStrings().close)).disabled, isTrue);
    await tester.pumpWidget(surface(false));
    await tester.tap(find.text(const FlareStrings().close));
    expect(dismissed, 1);
  });
  testWidgets('expired QR and rotation do not retain a scannable code', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: FlareQRCard(name: 'Code', qrPayload: 'https://scan.test/u/token', phase: 'ready', refreshInMs: 0))));
    expect(find.text(const FlareStrings().qrCardUnavailable), findsOneWidget);
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: FlareQRCard(name: 'Code', qrPayload: 'https://scan.test/u/token', phase: 'refreshing'))));
    expect(find.text(const FlareStrings().qrCardUnavailable), findsOneWidget);
  });
  testWidgets('unknown input types disable the whole action', (tester) async {
    var calls = 0;
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: FlareScanResultSheet(phase: 'ready', header: const FlareScanHeader(title: 'Person'), actions: const [FlareScanAction(id: 'add', label: 'Add', inputs: [FlareScanInput(id: 'password', kind: 'password', label: 'Password', maxLen: 10)])], onAction: (_, _) { calls++; }))));
    expect(find.byType(FlareInput), findsNothing);
    final button = tester.widget<FlareButton>(find.byType(FlareButton));
    expect(button.disabled, isTrue); expect(calls, 0);
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
