import 'dart:convert';
import 'dart:io';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The shared table (`spec/notification-alert-vectors.json`) behind
/// NotificationAlertSettings: the rows, times, the next-day end, the weekday
/// picks and their words. The Vue, SwiftUI and Compose kits run the same file.
void main() {
  final table =
      jsonDecode(
            File(
              '../../spec/notification-alert-vectors.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  List<Map<String, dynamic>> rows(String key) =>
      (table[key] as List).cast<Map<String, dynamic>>();

  group('rules', () {
    for (final c in rows('time')) {
      test('reads minute ${c['minute']} as ${c['text']}', () {
        expect(formatMinuteOfDay(c['minute'] as int), c['text']);
        if ((c['minute'] as int) < 1440) {
          expect(parseMinuteOfDay(c['text'] as String), c['minute']);
        }
      });
    }
    for (final c in rows('end')) {
      test('ends from ${c['start']} to ${c['end']}', () {
        final quiet = FlareQuietHours(
          startMinute: c['start'] as int,
          endMinute: c['end'] as int,
        );
        expect(quietHoursEndsNextDay(quiet), c['nextDay']);
        expect(quietHoursEndText(quiet), c['zh']);
        expect(quietHoursEndText(quiet, strings: flareStringsEnglish), c['en']);
      });
    }
    for (final c in rows('weekdayToggle')) {
      test('turns day ${c['day']} of ${c['mask']} to ${c['on']}', () {
        expect(
          weekdayToggle(c['mask'] as int, c['day'] as int, c['on'] as bool),
          c['result'],
        );
      });
    }
    for (final c in rows('weekdayOn')) {
      test('day ${c['day']} is in ${c['mask']}', () {
        expect(weekdayIsOn(c['mask'] as int, c['day'] as int), c['on']);
      });
    }
    for (final c in rows('summary')) {
      test('summarises ${c['mask']}', () {
        final mask = c['mask'] as int;
        expect(weekdaySummary(mask).kind.name, c['kind']);
        expect(weekdaySummaryText(mask), c['zh']);
        expect(weekdaySummaryText(mask, strings: flareStringsEnglish), c['en']);
      });
    }
  });

  Widget host(
    FlareNotificationAlertPreferences value, {
    ValueChanged<FlareNotificationAlertPreferences>? onChange,
    bool disabled = false,
  }) => MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: FlareNotificationAlertSettings(
          value: value,
          disabled: disabled,
          onChange: onChange,
        ),
      ),
    ),
  );

  for (final c in rows('rows')) {
    testWidgets('lists the rows with quiet hours ${c['quietHoursEnabled']}', (
      tester,
    ) async {
      List<List<String>>? seen;
      await tester.pumpWidget(
        MaterialApp(
          home: FlareNotificationAlertSettings(
            value: FlareNotificationAlertPreferences(
              quietHours: FlareQuietHours(
                enabled: c['quietHoursEnabled'] as bool,
              ),
            ),
            sectionsBuilder: (context, sections, select, toggle) {
              seen = [
                for (final section in sections)
                  [for (final item in section.items) item.key],
              ];
              return const SizedBox();
            },
          ),
        ),
      );
      expect(seen, [
        for (final keys in (c['sections'] as List)) (keys as List).cast<String>(),
      ]);
    });
  }

  testWidgets('reads each row and writes the whole value on a switch', (
    tester,
  ) async {
    final changes = <FlareNotificationAlertPreferences>[];
    const value = FlareNotificationAlertPreferences(
      quietHours: FlareQuietHours(enabled: true, weekdays: 0x1f),
      preview: FlareNotificationPreview.senderOnly,
      multiDevice: FlareMultiDeviceAlert.badgeOnly,
    );
    await tester.pumpWidget(host(value, onChange: changes.add));
    expect(find.text('22:00'), findsOneWidget);
    expect(find.text('次日 08:00'), findsOneWidget);
    expect(find.text('工作日'), findsOneWidget);
    expect(find.text('仅发送者'), findsOneWidget);
    expect(find.text('只更新角标'), findsOneWidget);
    expect(find.text('勿扰时段内新消息静默送达，不响铃也不振动；加急消息仍会提醒。'), findsOneWidget);
    await tester.tap(find.text('@我的消息照常提醒'));
    expect(changes.single.quietHours.allowMentions, isFalse);
    expect(changes.single.preview, FlareNotificationPreview.senderOnly);
  });

  testWidgets('applies a preview pick from the sheet', (tester) async {
    final changes = <FlareNotificationAlertPreferences>[];
    await tester.pumpWidget(
      host(const FlareNotificationAlertPreferences(), onChange: changes.add),
    );
    await tester.tap(find.text('通知预览'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('不显示'));
    await tester.pumpAndSettle();
    expect(changes.single.preview, FlareNotificationPreview.hidden);
    expect(find.text('不显示'), findsNothing);
  });

  testWidgets('turns a day off in the repeat sheet', (tester) async {
    final changes = <FlareNotificationAlertPreferences>[];
    await tester.pumpWidget(
      host(
        const FlareNotificationAlertPreferences(
          quietHours: FlareQuietHours(enabled: true),
        ),
        onChange: changes.add,
      ),
    );
    await tester.tap(find.text('重复'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('周日'));
    await tester.pumpAndSettle();
    expect(changes.single.quietHours.weekdays, 63);
  });

  testWidgets('takes no input while disabled', (tester) async {
    final changes = <FlareNotificationAlertPreferences>[];
    await tester.pumpWidget(
      host(
        const FlareNotificationAlertPreferences(),
        onChange: changes.add,
        disabled: true,
      ),
    );
    await tester.tap(find.text('勿扰时段'));
    await tester.tap(find.text('通知预览'));
    await tester.pumpAndSettle();
    expect(changes, isEmpty);
    expect(find.text('不显示'), findsNothing);
  });

  testWidgets('keeps an open repeat sheet working once disabled', (
    tester,
  ) async {
    final changes = <FlareNotificationAlertPreferences>[];
    const quiet = FlareNotificationAlertPreferences(
      quietHours: FlareQuietHours(enabled: true),
    );
    await tester.pumpWidget(host(quiet, onChange: changes.add));
    await tester.tap(find.text('重复'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(host(quiet, onChange: changes.add, disabled: true));
    await tester.pumpAndSettle();
    await tester.tap(find.text('周日'));
    await tester.pumpAndSettle();
    expect(changes.single.quietHours.weekdays, 63);
    expect(find.text('周日'), findsOneWidget);
  });

  testWidgets('applies a pick from a sheet open once disabled', (
    tester,
  ) async {
    final changes = <FlareNotificationAlertPreferences>[];
    const none = FlareNotificationAlertPreferences();
    await tester.pumpWidget(host(none, onChange: changes.add));
    await tester.tap(find.text('通知预览'));
    await tester.pumpAndSettle();
    await tester.pumpWidget(host(none, onChange: changes.add, disabled: true));
    await tester.pumpAndSettle();
    await tester.tap(find.text('不显示'));
    await tester.pumpAndSettle();
    expect(changes.single.preview, FlareNotificationPreview.hidden);
    expect(find.text('不显示'), findsNothing);
  });
}
