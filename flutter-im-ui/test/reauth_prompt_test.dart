import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flare_im_ui/src/components/flare_reauth_prompt.dart';

void main() {
  group('reauthActions', () {
    for (final reason in FlareReauthReason.values) {
      for (final busy in [false, true]) {
        test('$reason busy=$busy', () {
          final reauthAllowed = reason != FlareReauthReason.accountDisabled;
          final both = reauthActions(reason, hasReauth: true, hasLogout: true, busy: busy);
          expect(both.reauthenticate, FlareReauthActionState(visible: reauthAllowed, enabled: reauthAllowed && !busy));
          expect(both.logout, FlareReauthActionState(visible: true, enabled: !busy));
          expect(both.primary, reauthAllowed);
          final none = reauthActions(reason, hasReauth: false, hasLogout: false, busy: busy);
          expect(none.reauthenticate, const FlareReauthActionState(visible: false, enabled: false));
          expect(none.logout, const FlareReauthActionState(visible: false, enabled: false));
          expect(none.primary, isFalse);
        });
      }
    }
    test('maps every reason to a tone and an icon', () {
      expect(FlareReauthReason.values.map(reauthTone).toList(),
          [FlareReauthTone.info, FlareReauthTone.warning, FlareReauthTone.warning, FlareReauthTone.danger]);
      expect(FlareReauthReason.values.map(reauthIcon).toList(), ['clock', 'devices', 'lock', 'block']);
    });
  });

  testWidgets('shows reason, keeps error, Enter dispatches, busy locks, Escape is swallowed', (tester) async {
    var reauth = 0, logout = 0;
    Widget build({required bool busy, String? error}) => MaterialApp(
          home: Scaffold(
            body: Center(
              child: FlareReauthPrompt(
                reason: FlareReauthReason.kicked,
                detail: 'iPad · 今天 10:24',
                accountLabel: 'hugo@flare.im',
                busy: busy,
                error: error,
                onReauthenticate: () => reauth++,
                onLogout: () => logout++,
              ),
            ),
          ),
        );
    await tester.pumpWidget(build(busy: false));
    expect(find.text('你的账号已在其它设备登录，当前设备已下线。'), findsOneWidget);
    expect(find.text('iPad · 今天 10:24'), findsOneWidget);
    expect(find.text('hugo@flare.im'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(reauth, 1);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.text('重新登录'), findsOneWidget);

    await tester.tap(find.text('退出登录'));
    await tester.pump();
    expect(logout, 1);

    await tester.pumpWidget(build(busy: true, error: '网络不可用，请稍后重试'));
    expect(find.text('正在重新登录…'), findsOneWidget);
    expect(find.text('网络不可用，请稍后重试'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.tap(find.text('退出登录'));
    await tester.pump();
    expect(reauth, 1);
    expect(logout, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('accountDisabled hides re-authentication; no callbacks means no buttons', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: FlareReauthPrompt(reason: FlareReauthReason.accountDisabled, onReauthenticate: _noop, onLogout: _noop)),
    ));
    expect(find.text('重新登录'), findsNothing);
    expect(find.text('退出登录'), findsOneWidget);
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: FlareReauthPrompt(reason: FlareReauthReason.sessionExpired)),
    ));
    expect(find.text('重新登录'), findsNothing);
    expect(find.text('退出登录'), findsNothing);
  });
}

void _noop() {}
