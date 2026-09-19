import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// FR-096 (K1): one mapping from a connection phase to the banner's words,
// tone and way back, the same as Vue's `connectionNotice`.

const _strings = FlareStrings();

void main() {
  test('connected shows nothing; the others say what is happening', () {
    expect(
      flareConnectionNotice(FlareConnectionPhase.connected, _strings),
      isNull,
    );

    final connecting = flareConnectionNotice(
      FlareConnectionPhase.connecting,
      _strings,
    )!;
    expect(connecting.text, '正在连接…');
    expect(connecting.tone, FlareStatusTone.warning);
    expect(connecting.pulse, isTrue);
    expect(connecting.recovery, isNull);

    final reconnecting = flareConnectionNotice(
      FlareConnectionPhase.reconnecting,
      _strings,
    )!;
    expect(reconnecting.text, '连接已断开，正在重连…');
    expect(reconnecting.pulse, isTrue);

    final offline = flareConnectionNotice(
      FlareConnectionPhase.offline,
      _strings,
    )!;
    expect(offline.text, '网络不可用，恢复后会自动重连');
    expect(offline.tone, FlareStatusTone.warning);
    expect(offline.pulse, isFalse);
    expect(offline.recovery, isNull);
  });

  test('disconnected offers reconnect only when the host can, and names the '
      'reason', () {
    final plain = flareConnectionNotice(
      FlareConnectionPhase.disconnected,
      _strings,
    )!;
    expect(plain.text, '连接已断开');
    expect(plain.recovery, isNull);
    expect(plain.recoveryText, isNull);

    final withReason = flareConnectionNotice(
      FlareConnectionPhase.disconnected,
      _strings,
      reason: ' 网络超时 ',
      canReconnect: true,
    )!;
    expect(withReason.text, '连接已断开：网络超时');
    expect(withReason.recovery, FlareConnectionRecovery.reconnect);
    expect(withReason.recoveryText, '重新连接');
  });

  test('kicked and expired always offer sign in again', () {
    final kicked = flareConnectionNotice(
      FlareConnectionPhase.kicked,
      _strings,
    )!;
    expect(kicked.text, '账号已在其他设备登录');
    expect(kicked.tone, FlareStatusTone.danger);
    expect(kicked.recovery, FlareConnectionRecovery.signIn);
    expect(kicked.recoveryText, '重新登录');
    // A reason replaces the kicked default; reconnecting is never offered.
    final named = flareConnectionNotice(
      FlareConnectionPhase.kicked,
      _strings,
      reason: '在 iPad 上登录',
      canReconnect: true,
    )!;
    expect(named.text, '在 iPad 上登录');
    expect(named.recovery, FlareConnectionRecovery.signIn);

    final expired = flareConnectionNotice(
      FlareConnectionPhase.expired,
      _strings,
      canReconnect: true,
    )!;
    expect(expired.text, '登录已过期');
    expect(expired.tone, FlareStatusTone.danger);
    expect(expired.recovery, FlareConnectionRecovery.signIn);
  });

  test('a host that changes the language changes the notice', () {
    final english = _strings.copyWith(
      connectionExpired: 'Your sign-in has expired',
      connectionSignIn: 'Sign in again',
    );
    final notice = flareConnectionNotice(
      FlareConnectionPhase.expired,
      english,
    )!;
    expect(notice.text, 'Your sign-in has expired');
    expect(notice.recoveryText, 'Sign in again');
  });

  testWidgets('renders through the status banner with its action', (
    tester,
  ) async {
    final notice = flareConnectionNotice(
      FlareConnectionPhase.kicked,
      _strings,
    )!;
    var recovered = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlareStatusBanner(
            text: notice.text,
            tone: notice.tone,
            pulse: notice.pulse,
            actionText: notice.recoveryText,
            onAction: () => recovered++,
          ),
        ),
      ),
    );
    expect(find.text('账号已在其他设备登录'), findsOneWidget);
    await tester.tap(find.text('重新登录'));
    expect(recovered, 1);
  });
}
