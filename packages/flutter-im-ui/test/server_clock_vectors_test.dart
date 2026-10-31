import 'dart:convert';
import 'dart:io';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// The shared server clock table (spec/server-clock-vectors.json): server now
// from the device clock and the host's offset, and the plugin countdown and
// invite cooldown rules run at that now; then the widgets that judge
// server-issued instants, drawn with an offset handed in.
void main() {
  final file = File(
    '${Directory.current.path}/../../spec/server-clock-vectors.json',
  );
  final data = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
  List<Map<String, dynamic>> table(String key) =>
      (data[key] as List).cast<Map<String, dynamic>>();
  const zh = FlareStrings();
  final en = flareStringsEnglish;
  int deviceNow() => DateTime.now().millisecondsSinceEpoch;

  tearDown(() => FlareServerClock.setOffsetMs(null));

  test('server now is the device clock plus the offset', () {
    final rows = table('now');
    expect(rows, hasLength(5));
    for (final v in rows) {
      expect(
        FlareServerClock.now(v['deviceNowMs'] as int, v['offsetMs'] as int?),
        v['expected'],
        reason: v['id'] as String,
      );
    }
  });

  test('countdowns run on the server clock', () {
    final rows = table('countdown');
    expect(rows, hasLength(5));
    for (final v in rows) {
      final id = v['id'] as String;
      final at = v['atMs'] as int;
      final now = FlareServerClock.now(
        v['deviceNowMs'] as int,
        v['offsetMs'] as int?,
      );
      final shown = flarePluginCountdown(at, now, zh);
      expect(shown.text, v['zh'], reason: id);
      expect(shown.refreshMs, v['refreshMs'], reason: '$id refresh');
      expect(flarePluginCountdown(at, now, en).text, v['en'], reason: id);
      expect(
        flarePluginCountdown(at, v['deviceNowMs'] as int, zh).text,
        v['deviceClockZh'],
        reason: '$id device',
      );
    }
  });

  test('cooldowns run on the server clock', () {
    final rows = table('regenerate');
    expect(rows, hasLength(2));
    for (final v in rows) {
      final id = v['id'] as String;
      final expected = v['expected'] as Map<String, dynamic>;
      final remaining = expected['remaining'] as Map<String, dynamic>?;
      final now = FlareServerClock.now(
        v['deviceNowMs'] as int,
        v['offsetMs'] as int?,
      );
      final a = regenerateAvailability(
        v['canRegenerate'] as bool,
        v['availableAt'] as int,
        now,
      );
      expect(a.enabled, expected['enabled'], reason: id);
      expect(a.remaining?.count, remaining?['count'], reason: '$id count');
      expect(a.remaining?.unit.name, remaining?['unit'], reason: '$id unit');
      expect(
        regenerateAvailability(
          true,
          v['availableAt'] as int,
          v['deviceNowMs'] as int,
        ).enabled,
        v['deviceClockEnabled'],
        reason: '$id device',
      );
    }
  });

  test('the plugin view clock is the server clock', () {
    FlareServerClock.setOffsetMs(-300000);
    expect(FlareServerClock.offsetMs, -300000);
    final before = deviceNow();
    final now = flarePluginNowMs();
    expect(now, greaterThanOrEqualTo(before - 300000));
    expect(now, lessThanOrEqualTo(deviceNow() - 300000));
  });

  testWidgets('a time block counts down on the server clock', (tester) async {
    // The card closes 30 minutes after the server's now; this device runs 5
    // minutes fast.
    FlareServerClock.setOffsetMs(-300000);
    final view = FlarePluginViewModel.fromJson({
      'available': true,
      'title': 't',
      'fields': <Object?>[],
      'actions': <Object?>[],
      'blocks': [
        {
          'kind': 'time',
          'atMs': deviceNow() - 300000 + 1800500,
          'countdown': true,
        },
      ],
    });
    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: FlarePluginView(view: view))),
    );
    String countdown() => tester
        .widget<Text>(find.byKey(const ValueKey('flare-plugin-countdown')))
        .data!;
    expect(countdown(), '剩余 30:00');
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('the invite cooldown runs on the server clock', (tester) async {
    // Ten minutes of cooldown left on the server; this device runs 15 minutes
    // fast.
    FlareServerClock.setOffsetMs(-15 * 60000);
    final availableAt = deviceNow() - 15 * 60000 + 10 * 60000 - 5000;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: FlareMyInvitePanel(
              code: 'AB12CD',
              invitees: const [],
              canRegenerate: true,
              regenerateAvailableAt: availableAt,
            ),
          ),
        ),
      ),
    );
    expect(find.text('10 分钟 后可重新生成'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
