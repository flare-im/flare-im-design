import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flare_im_ui/src/components/flare_search_date_range_filter.dart';
import 'package:flare_im_ui/src/components/flare_search_panel.dart';

const int cst = 480; // UTC+8, minutes east of UTC
const int est = -300; // UTC-5

String? iso(int? ms) => ms == null
    ? null
    : DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toIso8601String();

void main() {
  group('dayStartMs / dayEndMs', () {
    test('anchors a day to 00:00:00.000 and 23:59:59.999 of the given zone', () {
      expect(iso(dayStartMs('2026-03-15', 0)), '2026-03-15T00:00:00.000Z');
      expect(iso(dayEndMs('2026-03-15', 0)), '2026-03-15T23:59:59.999Z');
      expect(iso(dayStartMs('2026-03-15', cst)), '2026-03-14T16:00:00.000Z');
      expect(iso(dayEndMs('2026-03-15', cst)), '2026-03-15T15:59:59.999Z');
      expect(iso(dayStartMs('2026-03-15', est)), '2026-03-15T05:00:00.000Z');
      expect(iso(dayEndMs('2026-03-15', est)), '2026-03-16T04:59:59.999Z');
    });

    test('spans exactly one inclusive day in a fixed-offset zone', () {
      for (final tz in [0, cst, est]) {
        expect(dayEndMs('2026-03-15', tz)! - dayStartMs('2026-03-15', tz)!,
            86399999);
      }
    });

    test('handles epoch, month and leap-year boundaries', () {
      expect(iso(dayStartMs('1970-01-01', 0)), '1970-01-01T00:00:00.000Z');
      expect(iso(dayEndMs('2026-02-28', 0)), '2026-02-28T23:59:59.999Z');
      expect(iso(dayStartMs('2024-02-29', 0)), '2024-02-29T00:00:00.000Z');
      expect(iso(dayEndMs('2026-12-31', 0)), '2026-12-31T23:59:59.999Z');
    });

    test('rejects anything that is not a real YYYY-MM-DD date', () {
      for (final bad in [
        '', '   ', '2026-3-15', '15/03/2026', '2026-13-01', '2026-00-10',
        '2026-02-30', '2026-04-31', 'today',
      ]) {
        expect(dayStartMs(bad, 0), isNull, reason: bad);
        expect(dayEndMs(bad, 0), isNull, reason: bad);
      }
    });

    test('uses the device zone when no offset is given', () {
      final start = DateTime.fromMillisecondsSinceEpoch(dayStartMs('2026-03-15')!);
      final end = DateTime.fromMillisecondsSinceEpoch(dayEndMs('2026-03-15')!);
      expect([start.year, start.month, start.day], [2026, 3, 15]);
      expect([start.hour, start.minute, start.second, start.millisecond],
          [0, 0, 0, 0]);
      expect([end.day, end.hour, end.minute, end.second, end.millisecond],
          [15, 23, 59, 59, 999]);
    });
  });

  group('rangeFromDates', () {
    test('same day covers the whole day, both ends inclusive', () {
      final range = rangeFromDates('2026-03-15', '2026-03-15', cst)!;
      expect(iso(range.fromTime), '2026-03-14T16:00:00.000Z');
      expect(iso(range.toTime), '2026-03-15T15:59:59.999Z');
    });

    test('spans months and years', () {
      final month = rangeFromDates('2026-01-28', '2026-02-03', 0)!;
      expect(iso(month.fromTime), '2026-01-28T00:00:00.000Z');
      expect(iso(month.toTime), '2026-02-03T23:59:59.999Z');
      final year = rangeFromDates('2025-12-30', '2026-01-02', cst)!;
      expect(iso(year.fromTime), '2025-12-29T16:00:00.000Z');
      expect(iso(year.toTime), '2026-01-02T15:59:59.999Z');
    });

    test('keeps a single open end open', () {
      final fromOnly = rangeFromDates('2026-03-15', '', cst)!;
      expect(fromOnly.fromTime, dayStartMs('2026-03-15', cst));
      expect(fromOnly.toTime, isNull);
      final toOnly = rangeFromDates('', '2026-03-15', cst)!;
      expect(toOnly.fromTime, isNull);
      expect(toOnly.toTime, dayEndMs('2026-03-15', cst));
    });

    test('both blank is unrestricted, not an error', () {
      final range = rangeFromDates('', '', cst)!;
      expect(unrestrictedRange(range), isTrue);
    });

    test('refuses from > to, but accepts from == to', () {
      expect(rangeFromDates('2026-03-16', '2026-03-15', cst), isNull);
      expect(rangeFromDates('2027-01-01', '2026-12-31', 0), isNull);
      expect(rangeFromDates('2026-03-15', '2026-03-15', cst), isNotNull);
    });

    test('refuses unparsable dates and instants before the epoch', () {
      expect(rangeFromDates('2026-02-30', '2026-03-15', 0), isNull);
      expect(rangeFromDates('2026-03-15', 'tomorrow', 0), isNull);
      expect(rangeFromDates('1969-12-31', '', 0), isNull);
      expect(rangeFromDates('', '1969-12-31', 0), isNull);
    });
  });

  group('datesFromRange / matchedOptionId / shouldOpenCustomRange', () {
    test('round-trips the dates the pickers are bound to', () {
      for (final tz in [0, cst, est]) {
        final range = rangeFromDates('2026-03-15', '2026-04-02', tz)!;
        expect(datesFromRange(range, tz),
            const FlareSearchDateDraft(from: '2026-03-15', to: '2026-04-02'));
      }
      final local = rangeFromDates('2026-03-15', '2026-04-02')!;
      expect(datesFromRange(local),
          const FlareSearchDateDraft(from: '2026-03-15', to: '2026-04-02'));
    });

    test('leaves an absent bound blank and re-reads another zone', () {
      expect(datesFromRange(const FlareSearchTimeRange(), cst),
          const FlareSearchDateDraft(from: '', to: ''));
      expect(
          datesFromRange(
              FlareSearchTimeRange(fromTime: dayStartMs('2026-03-15', cst)), cst),
          const FlareSearchDateDraft(from: '2026-03-15', to: ''));
      expect(datesFromRange(rangeFromDates('2026-03-15', '2026-03-15', cst)!, est),
          const FlareSearchDateDraft(from: '2026-03-14', to: '2026-03-15'));
    });

    test('matches presets by value, not by id', () {
      final options = [
        const FlareSearchRangeOption(
            id: 'today', label: '今天', fromTime: 1000, toTime: 2000),
        const FlareSearchRangeOption(id: 'week', label: '近 7 天', fromTime: 500),
        const FlareSearchRangeOption(id: 'all', label: '不限时间'),
      ];
      expect(
          matchedOptionId(
              const FlareSearchTimeRange(fromTime: 1000, toTime: 2000), options),
          'today');
      expect(matchedOptionId(const FlareSearchTimeRange(fromTime: 500), options),
          'week');
      expect(matchedOptionId(const FlareSearchTimeRange(), options), 'all');
      expect(
          matchedOptionId(
              const FlareSearchTimeRange(fromTime: 1000, toTime: 2001), options),
          isNull);
      expect(matchedOptionId(const FlareSearchTimeRange(toTime: 500), options),
          isNull);
    });

    test('custom area opens only for an uncovered value or a forced host', () {
      final options = [
        const FlareSearchRangeOption(
            id: 'today', label: '今天', fromTime: 1000, toTime: 2000),
      ];
      expect(
          shouldOpenCustomRange(
              const FlareSearchTimeRange(fromTime: 7), options, false, true),
          isFalse);
      expect(
          shouldOpenCustomRange(
              const FlareSearchTimeRange(), options, true, true),
          isTrue);
      expect(
          shouldOpenCustomRange(
              const FlareSearchTimeRange(fromTime: 7, toTime: 9), options, true),
          isTrue);
      expect(
          shouldOpenCustomRange(
              const FlareSearchTimeRange(fromTime: 1000, toTime: 2000),
              options,
              true),
          isFalse);
      expect(shouldOpenCustomRange(const FlareSearchTimeRange(), options, true),
          isFalse);
    });
  });

  group('FlareSearchDateRangeFilter', () {
    final options = [
      FlareSearchRangeOption(
          id: 'today',
          label: '今天',
          fromTime: dayStartMs('2026-03-15', 0),
          toTime: dayEndMs('2026-03-15', 0)),
      const FlareSearchRangeOption(id: 'week', label: '近 7 天', fromTime: 1000),
    ];

    Widget host(FlareSearchDateRangeFilter child) =>
        MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child)));

    testWidgets('preset chips emit the option range and show a summary',
        (tester) async {
      final emitted = <FlareSearchTimeRange>[];
      await tester.pumpWidget(host(FlareSearchDateRangeFilter(
        value: const FlareSearchTimeRange(),
        options: options,
        tzOffsetMinutes: 0,
        onChange: emitted.add,
      )));
      expect(find.text('不限时间'), findsOneWidget);
      expect(find.text('起始日期'), findsNothing); // custom collapsed
      await tester.tap(find.text('今天'));
      expect(emitted.single.fromTime, dayStartMs('2026-03-15', 0));
      expect(emitted.single.toTime, dayEndMs('2026-03-15', 0));
    });

    testWidgets('custom area opens for a value no preset covers', (tester) async {
      await tester.pumpWidget(host(FlareSearchDateRangeFilter(
        value: FlareSearchTimeRange(
            fromTime: dayStartMs('2026-01-02', 0),
            toTime: dayEndMs('2026-01-09', 0)),
        options: options,
        tzOffsetMinutes: 0,
        onChange: (_) {},
      )));
      expect(find.text('起始日期'), findsWidgets);
      expect(find.text('2026-01-02'), findsOneWidget);
      expect(find.text('2026-01-09'), findsOneWidget);
      expect(find.textContaining('起始日期 2026-01-02'), findsOneWidget);
    });

    testWidgets('an illegal draft warns and emits nothing', (tester) async {
      final emitted = <FlareSearchTimeRange>[];
      await tester.pumpWidget(host(FlareSearchDateRangeFilter(
        value: FlareSearchTimeRange(
            fromTime: dayStartMs('2026-03-20', 0),
            toTime: dayEndMs('2026-03-25', 0)),
        options: options,
        tzOffsetMinutes: 0,
        customActive: true,
        onChange: emitted.add,
      )));
      expect(find.text('起始日期不能晚于结束日期'), findsNothing);
      // Clearing the end bound is legal and emits an open-ended range.
      await tester.tap(find.byTooltip('清除 结束日期'));
      await tester.pump();
      expect(emitted.single.fromTime, dayStartMs('2026-03-20', 0));
      expect(emitted.single.toTime, isNull);
      expect(tester.takeException(), isNull);
    });

    testWidgets('clear only appears with a restricted value and a callback',
        (tester) async {
      var cleared = 0;
      await tester.pumpWidget(host(FlareSearchDateRangeFilter(
        value: const FlareSearchTimeRange(),
        options: options,
        onChange: (_) {},
        onClear: () => cleared++,
      )));
      expect(find.text('清除'), findsNothing);

      await tester.pumpWidget(host(FlareSearchDateRangeFilter(
        value: const FlareSearchTimeRange(fromTime: 1000),
        options: options,
        onChange: (_) {},
        onClear: () => cleared++,
      )));
      // Chip label plus the summary line, which names the matched preset.
      expect(find.text('近 7 天'), findsNWidgets(2));
      await tester.tap(find.text('清除'));
      expect(cleared, 1);

      await tester.pumpWidget(host(FlareSearchDateRangeFilter(
        value: const FlareSearchTimeRange(fromTime: 1000),
        options: options,
        onChange: (_) {},
      )));
      expect(find.text('清除'), findsNothing);
    });

    testWidgets('disabled blocks every control', (tester) async {
      final emitted = <FlareSearchTimeRange>[];
      var cleared = 0;
      await tester.pumpWidget(host(FlareSearchDateRangeFilter(
        value: const FlareSearchTimeRange(fromTime: 1000),
        options: options,
        disabled: true,
        tzOffsetMinutes: 0,
        onChange: emitted.add,
        onClear: () => cleared++,
      )));
      await tester.tap(find.text('今天'), warnIfMissed: false);
      await tester.tap(find.text('清除'), warnIfMissed: false);
      expect(emitted, isEmpty);
      expect(cleared, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('allowCustom false hides the custom entry entirely',
        (tester) async {
      await tester.pumpWidget(host(FlareSearchDateRangeFilter(
        value: FlareSearchTimeRange(fromTime: dayStartMs('2026-01-02', 0)),
        options: options,
        allowCustom: false,
        customActive: true,
        tzOffsetMinutes: 0,
        onChange: (_) {},
      )));
      expect(find.text('自定义'), findsNothing);
      expect(find.text('起始日期'), findsNothing);
    });
  });
}
