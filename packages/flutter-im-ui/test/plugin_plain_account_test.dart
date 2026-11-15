import 'dart:convert';
import 'dart:io';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Entry times, day headings over page rows and the maskable hero
/// (spec/plugin-view-vectors.json rules.entryTime, rowsGroupByDay, heroMask
/// and the rowDays facts): what the account renderer showed, in plain blocks.
final Map<String, dynamic> vectors =
    jsonDecode(
          File(
            '${Directory.current.path}/../../spec/plugin-view-vectors.json',
          ).readAsStringSync(),
        )
        as Map<String, dynamic>;

const zh = FlareStrings();
const en = flareStringsEnglish;

Widget host(Widget child) => MaterialApp(
  home: FlareStringsScope(
    strings: zh,
    child: Scaffold(body: SingleChildScrollView(child: child)),
  ),
);

FlarePluginViewModel view(List<Map<String, Object?>> blocks) =>
    FlarePluginViewModel.fromJson({
      'available': true,
      'title': '钱包',
      'blocks': blocks,
    });

void main() {
  test('day headings follow the shared facts', () {
    final facts = (vectors['rowDays'] as Map).cast<String, dynamic>();
    final times = (facts['timesMs'] as List).cast<int?>();
    final block = FlarePluginRowsBlock(
      groupByDay: true,
      columns: const [
        FlarePluginColumn(label: '金额'),
        FlarePluginColumn(label: '时间', format: FlarePluginColumnFormat.time),
      ],
      rows: [
        for (final (i, ms) in times.indexed)
          FlarePluginRow(
            key: '$i',
            cells: [
              const FlarePluginRowCell(text: '1'),
              FlarePluginRowCell(text: '', timeMs: ms),
            ],
          ),
      ],
    );
    final now = vectors['nowMs'] as int;
    final offset = facts['utcOffsetMinutes'] as int;
    expect(
      flarePluginRowDayHeadings(block, now, zh, utcOffsetMinutes: offset),
      facts['zh'],
    );
    expect(
      flarePluginRowDayHeadings(block, now, en, utcOffsetMinutes: offset),
      facts['en'],
    );
    final flat = FlarePluginRowsBlock(columns: block.columns, rows: block.rows);
    expect(
      flarePluginRowDayHeadings(flat, now, zh, utcOffsetMinutes: offset),
      everyElement(isNull),
    );
  });

  testWidgets('a page list grouped by day heads the day once', (tester) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await tester.pumpWidget(
      host(
        FlarePluginView(
          view: view([
            {
              'kind': 'rows',
              'source': 'history',
              'groupByDay': true,
              'columns': [
                {'label': '金额', 'format': 'text'},
                {'label': '时间', 'format': 'time'},
              ],
              'actions': [],
              'rows': [
                for (final key in ['a', 'b'])
                  {
                    'key': key,
                    'actions': [],
                    'cells': [
                      {'text': '+1.00'},
                      {'text': '', 'timeMs': now},
                    ],
                  },
              ],
            },
          ]),
        ),
      ),
    );
    expect(
      find.byKey(const ValueKey('flare-plugin-row-day-0')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('flare-plugin-row-day-1')), findsNothing);
    expect(find.text(zh.accountToday), findsOneWidget);
  });

  testWidgets('an entry shows its time', (tester) async {
    await tester.pumpWidget(
      host(
        FlarePluginView(
          view: view([
            {
              'kind': 'entries',
              'numbered': false,
              'total': 2,
              'more': false,
              'items': [
                {'index': 1, 'text': '5.00', 'name': 'Bob', 'timeMs': 1},
                {'index': 2, 'text': '3.00', 'name': 'Carol'},
              ],
            },
          ]),
        ),
      ),
    );
    expect(
      find.byKey(const ValueKey('flare-plugin-entry-time-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('flare-plugin-entry-time-1')),
      findsNothing,
    );
  });

  testWidgets('a maskable hero hides its value behind the eye', (tester) async {
    Map<String, Object?> hero(bool maskable) => {
      'kind': 'hero',
      'label': '可用余额',
      'value': '12.00',
      'amount': true,
      'tone': 'brand',
      if (maskable) 'maskable': true,
    };
    await tester.pumpWidget(host(FlarePluginView(view: view([hero(true)]))));
    expect(find.text('12.00'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('flare-plugin-hero-mask')));
    await tester.pump();
    expect(find.text(flarePluginMaskedValue), findsOneWidget);
    expect(find.text('12.00'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('flare-plugin-hero-mask')));
    await tester.pump();
    expect(find.text('12.00'), findsOneWidget);
    await tester.pumpWidget(host(FlarePluginView(view: view([hero(false)]))));
    expect(find.byKey(const ValueKey('flare-plugin-hero-mask')), findsNothing);
  });
}
