import 'dart:convert';
import 'dart:io';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The shared connection notice table (`spec/connection-notice-vectors.json`):
/// statuses over time in, what the notice shows at each moment out. The Vue,
/// SwiftUI and Compose kits run the same file.
void main() {
  final table =
      jsonDecode(
            File(
              '../../spec/connection-notice-vectors.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  final cases = (table['cases'] as List).cast<Map<String, dynamic>>();

  T named<T extends Enum>(List<T> values, String name) =>
      values.firstWhere((v) => v.name == name);

  FlareConnectionStatus statusOf(Map<String, dynamic> raw) =>
      FlareConnectionStatus(
        phase: named(FlareConnectionPhase.values, raw['phase'] as String),
        quality: raw['quality'] == null
            ? null
            : named(FlareConnectionQuality.values, raw['quality'] as String),
        progress: (raw['progress'] as num?)?.toDouble(),
        nextRetryAt: raw['nextRetryAt'] as int?,
        attempt: raw['attempt'] as int?,
        reason: raw['reason'] as String?,
        developmentMode: raw['developmentMode'] as bool? ?? false,
      );

  test('the thresholds are the shared ones', () {
    final thresholds = table['thresholds'] as Map<String, dynamic>;
    expect(
      FlareConnectionNoticeTracker.syncingDelayMs,
      thresholds['syncingDelayMs'],
    );
    expect(
      FlareConnectionNoticeTracker.switchingDelayMs,
      thresholds['switchingDelayMs'],
    );
    expect(
      FlareConnectionNoticeTracker.reconnectingMinShownMs,
      thresholds['reconnectingMinShownMs'],
    );
    expect(cases.length, greaterThanOrEqualTo(23));
  });

  for (final vector in cases) {
    final name = vector['name'] as String;
    test(name, () {
      final tracker = FlareConnectionNoticeTracker();
      final steps = (vector['steps'] as List).cast<Map<String, dynamic>>();
      for (var i = 0; i < steps.length; i++) {
        final step = steps[i];
        final at = step['at'] as int;
        final status = step['status'] as Map<String, dynamic>?;
        if (status != null) tracker.observe(statusOf(status), at);
        final model = tracker.present(at);
        final want = step['expect'] as Map<String, dynamic>;
        final seen = {
          'visible': model.visible,
          'text': model.text?.name,
          'tone': model.tone?.name,
          'pulse': model.pulse,
          'countdown': model.countdown,
          'progress': model.progress,
          'action': model.action?.name,
          'badge': model.badge,
          'next': tracker.nextChangeAt(at),
        };
        final expected = {
          'visible': want['visible'],
          'text': want['text'],
          'tone': want['tone'],
          'pulse': want['pulse'] ?? false,
          'countdown': want['countdown'],
          'progress': (want['progress'] as num?)?.toDouble(),
          'action': want['action'],
          'badge': want['badge'] ?? false,
          'next': want['next'],
        };
        expect(seen, expected, reason: '$name — step $i at $at');
      }
    });
  }

  test('takes the engine reason as a string and words only actionRequired', () {
    FlareConnectionNoticeModel at(FlareConnectionStatus status) =>
        (FlareConnectionNoticeTracker()..observe(status, 0)).present(5000);
    // switching carries its own reasons; they change nothing on the banner.
    for (final reason in [
      'failure',
      'drain',
      'failback',
      'manual',
      'manifest',
    ]) {
      expect(
        at(
          FlareConnectionStatus(
            phase: FlareConnectionPhase.switching,
            reason: reason,
          ),
        ),
        at(const FlareConnectionStatus(phase: FlareConnectionPhase.switching)),
        reason: reason,
      );
    }
    expect(
      const FlareConnectionStatus(
        phase: FlareConnectionPhase.actionRequired,
        reason: 'upgradeRequired',
      ).actionReason,
      FlareConnectionActionReason.upgradeRequired,
    );
    // An unknown reason is no error: it reads as expired, like a missing one.
    final unknown = at(
      const FlareConnectionStatus(
        phase: FlareConnectionPhase.actionRequired,
        reason: 'somethingNew',
      ),
    );
    expect(unknown.text, FlareConnectionNoticeText.expired);
    expect(unknown.action, FlareConnectionNoticeAction.signIn);
    expect(FlareConnectionActionReason.parse(null), isNull);
    expect(FlareConnectionActionReason.parse('drain'), isNull);
  });

  test('the banner says the message, then the countdown or the progress', () {
    const zh = FlareStrings();
    expect(
      const FlareConnectionNoticeModel(
        visible: true,
        text: FlareConnectionNoticeText.reconnecting,
        countdown: 5,
      ).bannerText(zh),
      '连接已断开，正在重连… 5 秒后重试',
    );
    expect(
      const FlareConnectionNoticeModel(
        visible: true,
        text: FlareConnectionNoticeText.syncing,
        progress: 0.426,
      ).bannerText(zh),
      '正在同步消息… 43%',
    );
    // What a screen reader is told leaves the countdown out.
    expect(
      const FlareConnectionNoticeModel(
        visible: true,
        text: FlareConnectionNoticeText.reconnecting,
        countdown: 5,
      ).message(zh),
      '连接已断开，正在重连…',
    );
    expect(FlareConnectionNoticeModel.hidden.bannerText(zh), '');
    expect(
      const FlareConnectionNoticeModel(
        visible: true,
        text: FlareConnectionNoticeText.reconnecting,
        countdown: 1,
      ).bannerText(flareStringsEnglish),
      'Connection lost. Reconnecting… Retrying in 1s',
    );
    final han = RegExp(r'\p{Script=Han}', unicode: true);
    for (final text in FlareConnectionNoticeText.values) {
      final model = FlareConnectionNoticeModel(visible: true, text: text);
      expect(han.hasMatch(model.bannerText(zh)), isTrue, reason: '$text zh');
      expect(
        han.hasMatch(model.bannerText(flareStringsEnglish)),
        isFalse,
        reason: '$text en',
      );
    }
    for (final action in FlareConnectionNoticeAction.values) {
      expect(
        flareConnectionActionLabel(action, zh),
        isNot(flareConnectionActionLabel(action, flareStringsEnglish)),
        reason: '$action',
      );
    }
  });

  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets(
    'draws the banner with its action only while the host handles it',
    (tester) async {
      var retried = 0;
      final status = FlareConnectionStatus(
        phase: FlareConnectionPhase.reconnecting,
        nextRetryAt: DateTime.now().millisecondsSinceEpoch + 60000,
      );
      await tester.pumpWidget(
        host(FlareConnectionNotice(status: status, onRetry: () => retried++)),
      );
      expect(find.textContaining('连接已断开，正在重连…'), findsOneWidget);
      expect(find.textContaining('秒后重试'), findsOneWidget);
      await tester.tap(find.text('立即重试'));
      expect(retried, 1);

      await tester.pumpWidget(host(FlareConnectionNotice(status: status)));
      expect(find.text('立即重试'), findsNothing);
    },
  );

  testWidgets('online shows nothing; development mode wears its badge', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        const FlareConnectionNotice(
          status: FlareConnectionStatus(
            phase: FlareConnectionPhase.online,
            quality: FlareConnectionQuality.poor,
          ),
        ),
      ),
    );
    expect(find.byType(FlareStatusBanner), findsNothing);
    expect(find.text('开发模式'), findsNothing);

    var signedIn = 0;
    await tester.pumpWidget(
      host(
        FlareConnectionNotice(
          status: const FlareConnectionStatus(
            phase: FlareConnectionPhase.actionRequired,
            reason: 'kicked',
            developmentMode: true,
          ),
          onSignIn: () => signedIn++,
        ),
      ),
    );
    expect(find.text('已在其他设备登录'), findsOneWidget);
    expect(find.text('开发模式'), findsOneWidget);
    await tester.tap(find.text('重新登录'));
    expect(signedIn, 1);
  });

  testWidgets('the copy follows the host language', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlareStringsScope(
            strings: flareStringsEnglish,
            child: FlareConnectionNotice(
              status: const FlareConnectionStatus(
                phase: FlareConnectionPhase.actionRequired,
                reason: 'upgradeRequired',
              ),
              onUpdate: () {},
            ),
          ),
        ),
      ),
    );
    expect(find.text('Update the app to keep using it'), findsOneWidget);
    expect(find.text('Update now'), findsOneWidget);
  });
}
