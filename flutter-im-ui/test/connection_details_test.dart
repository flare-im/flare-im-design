import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flare_im_ui/src/components/flare_connection_details.dart';
import 'package:flare_im_ui/src/components/flare_status_banner.dart';

void main() {
  List<FlareConnectionAction> actions(FlareConnectionState s,
          {bool busy = false, bool all = true}) =>
      availableConnectionActions(s,
          hasReconnect: all, hasReauth: all, hasDiagnostics: all, busy: busy);

  test('every state exposes only state-appropriate actions', () {
    const c = FlareConnectionAction.copyDiagnostics;
    expect(actions(FlareConnectionState.connected), [c]);
    expect(actions(FlareConnectionState.connecting), [c]);
    expect(actions(FlareConnectionState.reconnecting),
        [FlareConnectionAction.reconnect, c]);
    expect(actions(FlareConnectionState.offline),
        [FlareConnectionAction.reconnect, c]);
    expect(actions(FlareConnectionState.sessionExpired),
        [FlareConnectionAction.reauth, c]);
    expect(
        actions(FlareConnectionState.kicked), [FlareConnectionAction.reauth, c]);
    expect(actions(FlareConnectionState.sdkUnready), isEmpty);
  });

  test('busy or missing capabilities expose nothing', () {
    for (final s in FlareConnectionState.values) {
      expect(actions(s, busy: true), isEmpty, reason: '$s busy');
      expect(actions(s, all: false), isEmpty, reason: '$s no capabilities');
    }
  });

  test('tone and progress per state', () {
    expect(connectionTone(FlareConnectionState.connected), FlareStatusTone.success);
    expect(connectionTone(FlareConnectionState.connecting), FlareStatusTone.warning);
    expect(connectionTone(FlareConnectionState.reconnecting), FlareStatusTone.warning);
    expect(connectionTone(FlareConnectionState.offline), FlareStatusTone.danger);
    expect(connectionTone(FlareConnectionState.sessionExpired), FlareStatusTone.danger);
    expect(connectionTone(FlareConnectionState.kicked), FlareStatusTone.danger);
    expect(connectionTone(FlareConnectionState.sdkUnready), FlareStatusTone.neutral);
    expect(FlareConnectionState.values.where(connectionInProgress).toList(),
        [FlareConnectionState.connecting, FlareConnectionState.reconnecting]);
  });

  Widget host(FlareConnectionDetails child) => MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)));

  testWidgets('offline shows reconnect, diagnostics collapsed, busy disables',
      (tester) async {
    var reconnects = 0, copies = 0;
    await tester.pumpWidget(host(FlareConnectionDetails(
      state: FlareConnectionState.offline,
      endpoint: 'wss://gateway.example.com/very/long/path/that/does/not/fit',
      diagnostics: 'ws close 1006\nretry 3/5',
      onReconnect: () => reconnects++,
      onCopyDiagnostics: () => copies++,
    )));
    expect(find.text('离线'), findsOneWidget);
    expect(find.text('重新登录'), findsNothing);
    expect(find.textContaining('ws close 1006'), findsNothing);
    await tester.tap(find.text('诊断信息'));
    await tester.pump();
    expect(find.textContaining('ws close 1006'), findsOneWidget);
    await tester.tap(find.text('重新连接'));
    await tester.tap(find.text('复制诊断信息'));
    expect(reconnects, 1);
    expect(copies, 1);

    await tester.pumpWidget(host(FlareConnectionDetails(
      state: FlareConnectionState.offline,
      busy: true,
      diagnostics: 'x',
      onReconnect: () => reconnects++,
      onCopyDiagnostics: () => copies++,
    )));
    await tester.tap(find.text('重新连接'), warnIfMissed: false);
    await tester.tap(find.text('复制诊断信息'), warnIfMissed: false);
    expect(reconnects, 1);
    expect(copies, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sdkUnready shows no action; kicked without onReauth hides button',
      (tester) async {
    await tester.pumpWidget(host(FlareConnectionDetails(
      state: FlareConnectionState.sdkUnready,
      diagnostics: 'boot',
      onReconnect: () {},
      onReauth: () {},
      onCopyDiagnostics: () {},
    )));
    expect(find.text('客户端尚未就绪'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);
    expect(find.byType(OutlinedButton), findsNothing);

    await tester.pumpWidget(host(const FlareConnectionDetails(
        state: FlareConnectionState.kicked, reason: '账号在另一台设备登录')));
    expect(find.text('已在其他设备登录'), findsOneWidget);
    expect(find.text('账号在另一台设备登录'), findsOneWidget);
    expect(find.byType(FilledButton), findsNothing);

    await tester.pumpWidget(host(const FlareConnectionDetails(
        state: FlareConnectionState.reconnecting)));
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
