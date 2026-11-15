import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flare_im_ui/src/components/flare_button.dart';
import 'package:flare_im_ui/src/components/flare_icon.dart';
import 'package:flare_im_ui/src/components/flare_permission_prompt.dart';

void main() {
  test('action visibility for 8 kinds x 5 states', () {
    for (final kind in FlarePermissionKind.values) {
      for (final state in FlarePermissionState.values) {
        final a = permissionActions(
          state,
          hasRequest: true,
          hasOpenSettings: true,
          hasDismiss: true,
        );
        expect(
          a.request,
          state == FlarePermissionState.undetermined,
          reason: '$kind/$state request',
        );
        expect(
          a.openSettings,
          state == FlarePermissionState.denied,
          reason: '$kind/$state openSettings',
        );
        expect(a.dismiss, state != FlarePermissionState.granted);
        expect(a.enabled, isTrue);
        final copy = defaultPermissionCopy(kind, state);
        expect(copy.title, isNotEmpty);
        expect(
          copy.description.isNotEmpty,
          state != FlarePermissionState.granted,
          reason: '$kind/$state description',
        );
        expect(
          copy.primaryLabel.isNotEmpty,
          state == FlarePermissionState.undetermined ||
              state == FlarePermissionState.denied,
        );
        expect(defaultPermissionStateLabel(state), isNotEmpty);
        expect(permissionIconName(kind), isNotEmpty);
        expect(permissionStateIconName(state), isNotEmpty);
      }
    }
  });

  test('kind and state icons are registry names', () {
    expect(FlarePermissionKind.values.map(permissionIconName).toList(), [
      'mic',
      'camera',
      'notification',
      'storage',
      'image',
      'people',
      'location',
      'screen-share',
    ]);
    expect(FlarePermissionState.values.map(permissionStateIconName).toList(), [
      'info',
      'error',
      'lock',
      'warning',
      'success',
    ]);
    for (final name in [
      ...FlarePermissionKind.values.map(permissionIconName),
      ...FlarePermissionState.values.map(permissionStateIconName),
    ]) {
      expect(flareIconNames, contains(name));
    }
  });

  test('hides unsupplied handlers, busy disables', () {
    final none = permissionActions(
      FlarePermissionState.undetermined,
      hasRequest: false,
      hasOpenSettings: true,
      hasDismiss: false,
    );
    expect(none.request, isFalse);
    expect(none.openSettings, isFalse);
    expect(none.dismiss, isFalse);
    final busy = permissionActions(
      FlarePermissionState.denied,
      hasRequest: true,
      hasOpenSettings: true,
      hasDismiss: true,
      busy: true,
    );
    expect(busy.openSettings, isTrue);
    expect(busy.enabled, isFalse);
    expect(
      defaultPermissionCopy(
        FlarePermissionKind.microphone,
        FlarePermissionState.undetermined,
        featureLabel: '发送语音消息',
      ).description,
      contains('发送语音消息'),
    );
    expect(
      defaultPermissionCopy(
        FlarePermissionKind.microphone,
        FlarePermissionState.denied,
        featureLabel: ' ',
      ).description,
      contains('此功能'),
    );
  });

  testWidgets(
    'renders request only when undetermined, settings only when denied, nothing when restricted',
    (tester) async {
      tester.view.physicalSize = const Size(360, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final log = <String>[];
      Widget host(
        FlarePermissionState state, {
        bool busy = false,
        bool compact = false,
      }) => MaterialApp(
        home: Scaffold(
          body: FlarePermissionPrompt(
            kind: FlarePermissionKind.microphone,
            state: state,
            busy: busy,
            compact: compact,
            featureLabel: '发送语音消息',
            onRequest: () => log.add('request'),
            onOpenSettings: () => log.add('openSettings'),
            onDismiss: () => log.add('dismiss'),
          ),
        ),
      );
      await tester.pumpWidget(host(FlarePermissionState.undetermined));
      expect(find.text('允许'), findsOneWidget);
      expect(find.text('前往设置'), findsNothing);
      expect(find.textContaining('发送语音消息'), findsOneWidget);
      await tester.tap(find.text('允许'));
      await tester.pump();
      expect(log, ['request']);
      await tester.tap(find.text('知道了'));
      await tester.pump();
      expect(log, ['request', 'dismiss']);

      await tester.pumpWidget(host(FlarePermissionState.denied, compact: true));
      expect(find.text('允许'), findsNothing);
      expect(find.text('前往设置'), findsOneWidget);
      await tester.tap(find.text('前往设置'));
      await tester.pump();
      expect(log.last, 'openSettings');

      await tester.pumpWidget(host(FlarePermissionState.restricted));
      expect(find.text('允许'), findsNothing);
      expect(find.text('前往设置'), findsNothing);
      expect(find.text('知道了'), findsOneWidget);
      expect(find.text('受限制'), findsOneWidget);

      log.clear();
      await tester.pumpWidget(host(FlarePermissionState.denied, busy: true));
      await tester.tap(find.text('前往设置'), warnIfMissed: false);
      await tester.tap(find.text('知道了'));
      await tester.pump();
      expect(log, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  test('granted draws nothing; a soft-ask only what the person can act on', () {
    expect(
      FlarePermissionState.values.where(permissionPromptShows).toList(),
      [
        FlarePermissionState.undetermined,
        FlarePermissionState.denied,
        FlarePermissionState.restricted,
        FlarePermissionState.unavailable,
      ],
    );
    expect(
      FlarePermissionState.values
          .where((s) => permissionPromptShows(s, softAsk: true))
          .toList(),
      [FlarePermissionState.undetermined, FlarePermissionState.denied],
    );
    final ask = defaultPermissionSoftAskCopy(
      FlarePermissionKind.notifications,
      FlarePermissionState.undetermined,
    );
    expect(ask.title, '及时收到新消息');
    expect(ask.description, '开启通知后，应用不在前台时也能收到新消息提醒。');
    expect(ask.primaryLabel, '开启通知');
  });

  testWidgets('the notification soft-ask: own copy, no chip, Not now', (
    tester,
  ) async {
    final log = <String>[];
    Widget host(FlarePermissionState state) => MaterialApp(
      home: Scaffold(
        body: FlarePermissionPrompt(
          kind: FlarePermissionKind.notifications,
          state: state,
          softAsk: true,
          compact: true,
          onRequest: () => log.add('request'),
          onOpenSettings: () => log.add('openSettings'),
          onDismiss: () => log.add('dismiss'),
        ),
      ),
    );
    await tester.pumpWidget(host(FlarePermissionState.undetermined));
    expect(find.text('开启通知'), findsOneWidget);
    expect(find.text('以后再说'), findsOneWidget);
    expect(find.text('未授权'), findsNothing);
    await tester.tap(find.text('开启通知'));
    await tester.tap(find.text('以后再说'));
    expect(log, ['request', 'dismiss']);

    await tester.pumpWidget(host(FlarePermissionState.denied));
    expect(find.text('前往设置'), findsOneWidget);
    expect(find.textContaining('允许通知'), findsOneWidget);

    await tester.pumpWidget(host(FlarePermissionState.granted));
    expect(find.byType(FlareButton), findsNothing);
    expect(find.text('以后再说'), findsNothing);
  });

  testWidgets('show asks in the kit sheet and hands back the choice', (
    tester,
  ) async {
    FlarePermissionChoice? choice;
    var shown = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              choice = await FlarePermissionPrompt.show(
                context,
                kind: FlarePermissionKind.notifications,
                state: FlarePermissionState.undetermined,
                softAsk: true,
              );
              shown = true;
            },
            child: const Text('ask'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('ask'));
    await tester.pumpAndSettle();
    expect(find.text('及时收到新消息'), findsWidgets);
    await tester.tap(find.text('开启通知'));
    await tester.pumpAndSettle();
    expect(shown, isTrue);
    expect(choice, FlarePermissionChoice.request);
  });
}
