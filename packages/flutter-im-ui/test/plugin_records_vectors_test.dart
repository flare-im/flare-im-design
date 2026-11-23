import 'dart:convert';
import 'dart:io';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// §4.7 of docs/plugin-experience.md: page tabs and record rows against
/// spec/plugin-view-vectors.json (rules.pageTabs, rules.rowsIcon,
/// rules.rowTap).
final Map<String, dynamic> vectors =
    jsonDecode(
          File(
            '${Directory.current.path}/../../spec/plugin-view-vectors.json',
          ).readAsStringSync(),
        )
        as Map<String, dynamic>;
final Map<String, dynamic> users = vectors['users'] as Map<String, dynamic>;

List<Map<String, dynamic>> cases(String name) => [
  for (final c in vectors[name] as List)
    if (((c as Map)['platforms'] as List?)?.contains('flutter') ?? true)
      c.cast<String, dynamic>(),
];

FlarePluginPageViewModel viewOf(Object? json) =>
    FlarePluginPageViewModel.fromJson({
      'available': true,
      'title': '',
      ...(json as Map).cast<String, Object?>(),
    });

FlarePluginRowsBlock blockOf(Object? json) =>
    FlarePluginBlock.fromJson((json as Map).cast<String, Object?>())!
        as FlarePluginRowsBlock;

String nameOf(String id) =>
    (users[id] as Map?)?['name'] as String? ?? flarePluginFallbackName(id);

FlarePluginUser? resolveUser(String id) => switch (users[id]) {
  final Map user => FlarePluginUser(name: user['name'] as String),
  _ => null,
};

Widget host(Widget child) => MaterialApp(
  home: MediaQuery(
    data: const MediaQueryData(size: Size(390, 900)),
    child: Scaffold(body: child),
  ),
);

void main() {
  group('pageTabs', () {
    for (final c in cases('pageTabs')) {
      test(c['name'] as String, () {
        final page = (c['page'] as Map)['page'] as String;
        final expected = (c['expect'] as Map).cast<String, dynamic>();
        if (c['views'] case final List views) {
          for (final view in views) {
            expect(flarePluginPageTabs(viewOf(view), page, const []), isEmpty);
          }
          return;
        }
        final last = c['previous'] == null
            ? const <FlarePluginPageTab>[]
            : flarePluginPageTabs(viewOf(c['previous']), 'previous', const []);
        final view = c['view'] == null ? null : viewOf(c['view']);
        final tabs = flarePluginPageTabs(view, page, last);
        expect([for (final tab in tabs) tab.label], expected['tabs']);
        expect(tabs.indexWhere((tab) => tab.selected), expected['selected']);
        if (c['choose'] case final int index) {
          expect(flarePluginPageTabChoice(tabs, index), expected['emitted']);
        }
      });
    }

    testWidgets('choosing a sibling tab asks the host for its page, the '
        'shown one asks nothing', (tester) async {
      final c = cases('pageTabs').first;
      final chosen = <String>[];
      await tester.pumpWidget(
        host(
          FlarePluginPage(
            page: const FlarePluginPageRef(
              pluginId: 'flare.redpacket',
              page: 'flare.redpacket.page.received',
            ),
            view: viewOf(c['view']),
            onTab: chosen.add,
          ),
        ),
      );
      expect(find.byKey(FlarePluginPage.tabsKey), findsOneWidget);
      await tester.tap(find.text('收到的'));
      await tester.tap(find.text('发出的'));
      expect(chosen, ['flare.redpacket.page.sent']);
      // The chosen page loads: the tabs stay, that page selected.
      await tester.pumpWidget(
        host(
          FlarePluginPage(
            page: const FlarePluginPageRef(
              pluginId: 'flare.redpacket',
              page: 'flare.redpacket.page.sent',
            ),
            loading: true,
            onTab: chosen.add,
          ),
        ),
      );
      expect(
        tester
            .widget<FlareSegmentedControl>(find.byKey(FlarePluginPage.tabsKey))
            .selectedIndex,
        1,
      );
    });
  });

  group('rowsIcon', () {
    for (final c in cases('rowsIcon')) {
      test(c['name'] as String, () {
        final block = blockOf(c['block']);
        final expected = (c['expect'] as Map).cast<String, dynamic>();
        if (expected['empty'] case final Map empty) {
          expect(block.rows, isEmpty);
          expect(block.icon, empty['icon']);
          expect(block.emptyText, empty['title']);
          return;
        }
        final rows = expected['rows'] as List;
        for (final (index, row) in block.rows.indexed) {
          final want = (rows[index] as Map).cast<String, dynamic>();
          expect(block.icon, want['icon']);
          if (want['icon'] == null) continue;
          final line = flarePluginRecordLine(
            block,
            row,
            vectors['nowMs'] as int,
            const FlareStrings(),
            nameOf: nameOf,
          );
          expect(line.title, want['title']);
          expect(line.line, want['line']);
          expect(line.value, want['value']);
          expect([
            for (final tag in line.tags)
              {'text': tag.text, 'tone': tag.tone?.name},
          ], want['tags']);
        }
      });
    }

    testWidgets('a record row draws the person, the value and the icon; an '
        'empty block its icon', (tester) async {
      final record = cases('rowsIcon').first;
      await tester.pumpWidget(
        host(
          SingleChildScrollView(
            child: FlarePluginView(
              embedded: true,
              resolveUser: resolveUser,
              view: viewOf({
                'blocks': [record['block']],
              }),
            ),
          ),
        ),
      );
      await tester.pump();
      final title = tester.widget<Text>(
        find.byKey(const ValueKey('flare-plugin-row-title:p1')),
      );
      expect(title.data, 'Alice');
      expect(find.text('u_alice01'), findsNothing);
      expect(
        tester
            .widget<Text>(
              find.byKey(const ValueKey('flare-plugin-row-value:p1')),
            )
            .data,
        '2.96',
      );
      expect(
        find.byKey(const ValueKey('flare-plugin-row-icon:p1')),
        findsOneWidget,
      );
      final empty = cases(
        'rowsIcon',
      ).firstWhere((c) => (c['expect'] as Map).containsKey('empty'));
      await tester.pumpWidget(
        host(
          FlarePluginView(
            embedded: true,
            view: viewOf({
              'blocks': [empty['block']],
            }),
          ),
        ),
      );
      final state = tester.widget<FlareEmptyState>(
        find.byKey(FlarePluginView.rowsEmptyKey),
      );
      expect(state.icon, 'red-packet');
      expect(state.title, '还没有红包记录');
    });
  });
  testWidgets('without icon a signed first line is a page row, never a '
      'self-detected ledger record (§12.24, rules.pageRows)', (tester) async {
    final plain = cases(
      'rowsIcon',
    ).firstWhere((c) => (c['block'] as Map)['icon'] == null);
    await tester.pumpWidget(
      host(
        SingleChildScrollView(
          child: FlarePluginView(
            embedded: true,
            view: viewOf({
              'blocks': [
                plain['block'],
                {
                  'kind': 'rows',
                  'source': 'ledger',
                  'columns': [
                    {'label': '金额'},
                    {'label': '备注'},
                  ],
                  'rows': [
                    for (final (key, amount) in [
                      ('in', '+5.00'),
                      ('out', '-6.00'),
                    ])
                      {
                        'key': key,
                        'cells': [
                          {'text': amount},
                          {'text': '红包'},
                        ],
                        'actions': [],
                      },
                  ],
                  'actions': [],
                },
              ],
            }),
          ),
        ),
      ),
    );
    await tester.pump();
    for (final key in ['p4', 'in', 'out']) {
      expect(
        find.byKey(ValueKey('flare-plugin-row-icon:$key')),
        findsNothing,
        reason: key,
      );
      expect(
        find.byKey(ValueKey('flare-plugin-row-title:$key')),
        findsNothing,
        reason: key,
      );
    }
    // R10 still reads the sign: income in success ink, a true minus.
    final context = tester.element(find.byType(FlarePluginView));
    final colors = FlareColors.of(context);
    final income = tester.widget<Text>(
      find.byKey(const ValueKey('flare-plugin-row-primary:in')),
    );
    final spending = tester.widget<Text>(
      find.byKey(const ValueKey('flare-plugin-row-primary:out')),
    );
    expect(income.data, '+5.00');
    expect(income.style?.color, colors.successText);
    expect(spending.data, '−6.00');
    expect(spending.style?.color, colors.textPrimary);
  });
  group('rowTap', () {
    for (final c in cases('rowTap')) {
      testWidgets(c['name'] as String, (tester) async {
        final block = blockOf(c['block']);
        final expected = (c['expect'] as Map).cast<String, dynamic>();
        final emitted = <(String, Object?)>[];
        final semantics = tester.ensureSemantics();
        await tester.pumpWidget(
          host(
            SingleChildScrollView(
              child: FlarePluginView(
                embedded: true,
                view: viewOf({
                  'blocks': [c['block']],
                }),
                onAction: (id, payload) =>
                    emitted.add((id, payload.toJson()['row'])),
              ),
            ),
          ),
        );
        await tester.pump();
        for (final want in (expected['rows'] as List).cast<Map>()) {
          final key = want['key'] as String;
          final drawn = [
            for (final element
                in find
                    .byWidgetPredicate(
                      (w) =>
                          w.key is ValueKey<String> &&
                          (w.key! as ValueKey<String>).value.startsWith(
                            'flare-plugin-row-action:$key:',
                          ),
                    )
                    .evaluate())
              (element.widget.key! as ValueKey<String>).value.split(':').last,
          ];
          expect(drawn, want['keys'], reason: key);
          expect(
            find.byKey(ValueKey('flare-plugin-row-chevron:$key')),
            want['chevron'] == true ? findsOneWidget : findsNothing,
            reason: key,
          );
          final control = find.descendant(
            of: find.byKey(FlarePluginView.rowKey(key)),
            matching: find.byType(InkWell),
          );
          if (want['tap'] == null) {
            expect(control, findsNothing, reason: key);
          } else {
            expect(
              tester.getSemantics(control),
              isSemantics(isButton: true, isEnabled: true),
              reason: key,
            );
          }
        }
        expect(block.rows.length, (expected['rows'] as List).length);
        if (expected['emit'] case final Map emit) {
          await tester.tap(
            find.byKey(FlarePluginView.rowKey(emit['rowKey'] as String)),
          );
          expect(emitted, hasLength(1));
          expect(emitted.single.$1, emit['actionId']);
          expect(emitted.single.$2, {
            'key': emit['rowKey'],
            'input': emit['input'],
          });
        }
        semantics.dispose();
      });
    }

    testWidgets('a tap row is disabled while busy', (tester) async {
      final c = cases('rowTap').first;
      final emitted = <String>[];
      await tester.pumpWidget(
        host(
          FlarePluginView(
            embedded: true,
            busy: true,
            view: viewOf({
              'blocks': [c['block']],
            }),
            onAction: (id, _) => emitted.add(id),
          ),
        ),
      );
      await tester.tap(find.byKey(FlarePluginView.rowKey('t1')));
      expect(emitted, isEmpty);
    });
  });

  testWidgets('R10: a money cell with its currency draws as the payment '
      'confirmation writes it', (tester) async {
    await tester.pumpWidget(
      host(
        FlarePluginView(
          embedded: true,
          view: viewOf({
            'blocks': [
              {
                'kind': 'rows',
                'source': 'flare.wallet.ui.home',
                'columns': [
                  {'label': '余额', 'format': 'text'},
                  {'label': '钱包', 'format': 'text'},
                ],
                'rows': [
                  {
                    'key': 'w1',
                    'cells': [
                      {
                        'text': '1234.56',
                        'format': {
                          'kind': 'money',
                          'minor': '123456',
                          'scale': 2,
                          'currency': 'CNY',
                        },
                      },
                      {
                        'text': '1234',
                        'format': {
                          'kind': 'money',
                          'minor': '1234',
                          'scale': 0,
                          'currency': 'LABPOINT',
                        },
                      },
                    ],
                    'actions': [],
                  },
                ],
                'actions': [],
              },
              {
                'kind': 'hero',
                'label': '可用余额',
                'value': '1234.56',
                'amount': true,
                'format': {
                  'kind': 'money',
                  'minor': '123456',
                  'scale': 2,
                  'currency': 'CNY',
                },
                'tone': 'neutral',
              },
            ],
          }),
        ),
      ),
    );
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('flare-plugin-row-primary:w1')),
          )
          .data,
      '¥1,234.56',
    );
    expect(find.text('1,234 LABPOINT'), findsOneWidget);
    expect(find.textContaining('¥1,234.56'), findsNWidgets(2));
  });
}
