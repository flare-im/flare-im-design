import 'dart:convert';
import 'dart:io';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// FlareReadReceiptSheet against spec/read-receipt-vectors.json (the Vue,
/// SwiftUI and Compose kits read the same file): the layout facts as a pure
/// function, then the drawn sheet — tabs and their numbers, the body, the rows,
/// the tail — and the events real taps emit.
final Map<String, dynamic> _table =
    jsonDecode(File('../../spec/read-receipt-vectors.json').readAsStringSync())
        as Map<String, dynamic>;

FlareReadReceiptColumn? _column(Object? name) =>
    name == null ? null : FlareReadReceiptColumn.values.byName(name as String);

List<FlareContact> _people(String prefix, int count) => [
  for (var i = 1; i <= count; i += 1)
    FlareContact(id: '$prefix$i', name: '$prefix$i'),
];

Widget _host(Widget child, {double width = 390}) => MaterialApp(
  home: Scaffold(
    body: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: width, child: child),
    ),
  ),
);

void main() {
  final cases = (_table['cases'] as List).cast<Map<String, dynamic>>();

  test('the vector file holds the cases this kit reads', () {
    expect(cases, hasLength(greaterThanOrEqualTo(13)));
  });

  for (final v in cases) {
    final id = v['id'] as String;
    final input = v['input'] as Map<String, dynamic>;
    final expected = v['expect'] as Map<String, dynamic>;
    final state = FlareReadReceiptState.values.byName(input['state'] as String);
    final initial = _column(input['initialTab']) ?? FlareReadReceiptColumn.read;

    FlareReadReceiptLayout layoutFor(FlareReadReceiptColumn active) =>
        flareReadReceiptLayout(
          state: state,
          active: active,
          readers: input['readers'] as int,
          unread: input['unread'] as int,
          readCount: input['readCount'] as int?,
          unreadCount: input['unreadCount'] as int?,
          readHasMore: input['readHasMore'] as bool? ?? false,
          unreadHasMore: input['unreadHasMore'] as bool? ?? false,
          loadingMore: _column(input['loadingMore']),
          loadMoreFailed: _column(input['loadMoreFailed']),
        );

    void checkFacts(FlareReadReceiptLayout layout, Map<String, dynamic> facts) {
      if (facts.containsKey('tabs')) {
        final tabs = facts['tabs'] as List?;
        expect(
          layout.tabs,
          tabs == null
              ? isNull
              : [
                  for (final t in tabs.cast<Map<String, dynamic>>())
                    FlareReadReceiptTab(
                      _column(t['value'])!,
                      t['count'] as int?,
                    ),
                ],
          reason: '$id tabs',
        );
      }
      expect(layout.body.name, facts['body'], reason: '$id body');
      expect(layout.rows, facts['rows'], reason: '$id rows');
      expect(layout.tail.name, facts['tail'], reason: '$id tail');
    }

    test('layout $id', () {
      checkFacts(layoutFor(initial), expected);
      for (final step
          in (v['taps'] as List? ?? const []).cast<Map<String, dynamic>>()) {
        final tap = step['tap'] as String;
        if (tap.startsWith('tab:') && step['then'] != null) {
          checkFacts(
            layoutFor(_column(tap.substring(4))!),
            (step['then'] as Map).cast<String, dynamic>(),
          );
        }
      }
    });

    testWidgets('drawn $id', (tester) async {
      final events = <List<String>>[];
      final strings = const FlareStrings();
      await tester.pumpWidget(
        _host(
          FlareReadReceiptSheet(
            readers: _people('r', input['readers'] as int),
            unread: _people('u', input['unread'] as int),
            readCount: input['readCount'] as int?,
            unreadCount: input['unreadCount'] as int?,
            state: state,
            readHasMore: input['readHasMore'] as bool? ?? false,
            unreadHasMore: input['unreadHasMore'] as bool? ?? false,
            loadingMore: _column(input['loadingMore']),
            loadMoreFailed: _column(input['loadMoreFailed']),
            initialTab: initial,
            onLoadMore: (column) => events.add(['loadMore', column.name]),
            onRetry: () => events.add(['retry']),
          ),
        ),
      );

      void checkDrawn(Map<String, dynamic> facts, FlareReadReceiptColumn on) {
        if (facts.containsKey('tabs')) {
          final tabs = facts['tabs'] as List?;
          for (final column in FlareReadReceiptColumn.values) {
            expect(
              find.byKey(FlareReadReceiptSheet.tabKey(column)),
              tabs == null ? findsNothing : findsOneWidget,
              reason: '$id tab ${column.name}',
            );
          }
          for (final t in (tabs ?? const []).cast<Map<String, dynamic>>()) {
            final column = _column(t['value'])!;
            final count = t['count'] as int?;
            final label = switch ((column, count)) {
              (FlareReadReceiptColumn.read, final int n) => strings.readTab(n),
              (FlareReadReceiptColumn.read, null) => strings.readReceiptRead,
              (FlareReadReceiptColumn.unread, final int n) => strings.unreadTab(
                n,
              ),
              (FlareReadReceiptColumn.unread, null) =>
                strings.readReceiptUnread,
            };
            expect(
              find.descendant(
                of: find.byKey(FlareReadReceiptSheet.tabKey(column)),
                matching: find.text(label),
              ),
              findsOneWidget,
              reason: '$id tab label $label',
            );
          }
        }
        final body = facts['body'] as String;
        expect(
          find.byKey(FlareReadReceiptSheet.spinnerKey),
          body == 'spinner' ? findsOneWidget : findsNothing,
          reason: '$id spinner',
        );
        expect(
          find.byKey(FlareReadReceiptSheet.errorKey),
          body == 'error' ? findsOneWidget : findsNothing,
          reason: '$id error',
        );
        expect(
          find.byKey(FlareReadReceiptSheet.retryKey),
          body == 'error' ? findsOneWidget : findsNothing,
          reason: '$id retry key',
        );
        expect(
          find.byKey(FlareReadReceiptSheet.unavailableKey),
          body == 'unavailable' ? findsOneWidget : findsNothing,
          reason: '$id unavailable',
        );
        if (body == 'error') {
          expect(find.text(strings.readReceiptLoadFailed), findsOneWidget);
        }
        if (body == 'unavailable') {
          expect(find.text(strings.readReceiptUnavailable), findsOneWidget);
        }
        expect(
          find.byKey(FlareReadReceiptSheet.emptyKey),
          body == 'empty' ? findsOneWidget : findsNothing,
          reason: '$id empty',
        );
        if (facts['empty'] case final String which) {
          expect(
            find.text(
              which == 'read'
                  ? strings.noReadersYet
                  : strings.everyoneHasRead,
            ),
            findsOneWidget,
            reason: '$id empty notice',
          );
        }
        final prefix = on == FlareReadReceiptColumn.read ? 'r' : 'u';
        final rows = facts['rows'] as int;
        for (var i = 1; i <= rows; i += 1) {
          expect(
            find.byKey(FlareReadReceiptSheet.rowKey('$prefix$i')),
            findsOneWidget,
            reason: '$id row $prefix$i',
          );
        }
        expect(
          find.byWidgetPredicate(
            (w) =>
                w.key is ValueKey<String> &&
                (w.key! as ValueKey<String>).value.startsWith(
                  'flare-read-receipt-row-',
                ),
          ),
          findsNWidgets(rows),
          reason: '$id row count',
        );
        final tail = facts['tail'] as String;
        final tailFinder = find.byKey(FlareReadReceiptSheet.tailKey);
        expect(
          tailFinder,
          tail == 'none' ? findsNothing : findsOneWidget,
          reason: '$id tail',
        );
        if (tail == 'busy') {
          expect(
            find.descendant(
              of: tailFinder,
              matching: find.byType(CircularProgressIndicator),
            ),
            findsOneWidget,
          );
          expect(tester.widget(tailFinder), isNot(isA<FlareButton>()));
        }
        if (tail == 'loadMore' || tail == 'retry') {
          expect(tester.widget(tailFinder), isA<FlareButton>());
          expect(
            find.descendant(
              of: tailFinder,
              matching: find.text(
                tail == 'retry'
                    ? strings.readReceiptLoadMoreFailed
                    : strings.readReceiptLoadMore,
              ),
            ),
            findsOneWidget,
          );
        }
      }

      checkDrawn(expected, initial);
      var active = initial;
      for (final step
          in (v['taps'] as List? ?? const []).cast<Map<String, dynamic>>()) {
        events.clear();
        final tap = step['tap'] as String;
        if (tap == 'tail') {
          await tester.tap(
            find.byKey(FlareReadReceiptSheet.tailKey),
            warnIfMissed: false,
          );
        } else if (tap == 'retry') {
          await tester.tap(find.byKey(FlareReadReceiptSheet.retryKey));
        } else if (tap.startsWith('tab:')) {
          active = _column(tap.substring(4))!;
          await tester.tap(find.byKey(FlareReadReceiptSheet.tabKey(active)));
        } else {
          fail('$id: unknown tap $tap');
        }
        await tester.pump();
        expect(events, [
          for (final e in step['emits'] as List) (e as List).cast<String>(),
        ], reason: '$id tap $tap');
        if (step['then'] case final Map then) {
          checkDrawn(then.cast<String, dynamic>(), active);
        }
      }
    });
  }

  testWidgets('English copy for the states and the tail', (tester) async {
    Future<void> pump(Widget sheet) => tester.pumpWidget(
      MaterialApp(
        home: FlareStringsScope(
          strings: flareStringsEnglish,
          child: Scaffold(body: sheet),
        ),
      ),
    );
    final en = (_table['strings'] as Map)['en'] as Map;
    await pump(
      const FlareReadReceiptSheet(
        readers: [],
        unread: [],
        state: FlareReadReceiptState.error,
      ),
    );
    expect(find.text(en['readReceiptLoadFailed'] as String), findsOneWidget);
    await pump(
      const FlareReadReceiptSheet(
        readers: [],
        unread: [],
        state: FlareReadReceiptState.unavailable,
      ),
    );
    expect(find.text(en['readReceiptUnavailable'] as String), findsOneWidget);
    await pump(
      const FlareReadReceiptSheet(readers: [], unread: [], readHasMore: true),
    );
    expect(find.text(en['readReceiptLoadMore'] as String), findsOneWidget);
    expect(find.text('Read'), findsOneWidget);
    expect(find.text('Unread'), findsOneWidget);
    await pump(
      const FlareReadReceiptSheet(
        readers: [],
        unread: [],
        readHasMore: true,
        loadMoreFailed: FlareReadReceiptColumn.read,
      ),
    );
    expect(
      find.text(en['readReceiptLoadMoreFailed'] as String),
      findsOneWidget,
    );
  });

  test('the Chinese defaults are the vector copy', () {
    final zh = (_table['strings'] as Map)['zh'] as Map;
    const s = FlareStrings();
    expect(s.readReceiptLoadFailed, zh['readReceiptLoadFailed']);
    expect(s.readReceiptUnavailable, zh['readReceiptUnavailable']);
    expect(s.readReceiptLoadMore, zh['readReceiptLoadMore']);
    expect(s.readReceiptLoadMoreFailed, zh['readReceiptLoadMoreFailed']);
  });

  group('shell and width', () {
    testWidgets('standing alone: a card at most 320 wide', (tester) async {
      await tester.pumpWidget(
        _host(
          FlareReadReceiptSheet(readers: _people('r', 3), unread: const []),
        ),
      );
      final shell = find.byKey(FlareReadReceiptSheet.shellKey);
      expect(shell, findsOneWidget);
      expect(tester.getSize(shell).width, 320);
    });

    testWidgets('a narrower container shrinks the card', (tester) async {
      await tester.pumpWidget(
        _host(
          FlareReadReceiptSheet(readers: _people('r', 3), unread: const []),
          width: 260,
        ),
      );
      expect(
        tester.getSize(find.byKey(FlareReadReceiptSheet.shellKey)).width,
        260,
      );
    });

    testWidgets('standing alone the rows scroll within 320', (tester) async {
      await tester.pumpWidget(
        _host(
          FlareReadReceiptSheet(readers: _people('r', 40), unread: const []),
        ),
      );
      final list = find.byType(ListView);
      expect(tester.getSize(list).height, lessThanOrEqualTo(320));
    });

    testWidgets(
      'in a kit sheet: no shell, the sheet width, its own header and the '
      'remaining height',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () => FlareBottomSheet.show<void>(
                      context,
                      title: '已读回执',
                      fill: true,
                      presentation: FlareSheetPresentation.sheet,
                      builder: (_) => FlareReadReceiptSheet(
                        readers: _people('r', 40),
                        unread: const [],
                      ),
                    ),
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        expect(find.byKey(FlareReadReceiptSheet.shellKey), findsNothing);
        // The title is drawn once: the sheet's own heading stays hidden.
        expect(find.text('已读回执'), findsOneWidget);
        final sheet = tester.getSize(find.byType(FlareReadReceiptSheet));
        final surface = tester.getSize(find.byType(FlareBottomSheet));
        expect(sheet.width, surface.width);
        // The rows take what the header and tabs leave: well past 320.
        expect(tester.getSize(find.byType(ListView)).height, greaterThan(320));
      },
    );
  });

  testWidgets('a row tap selects that member; a tab switch keeps both lists', (
    tester,
  ) async {
    final selected = <String>[];
    await tester.pumpWidget(
      _host(
        FlareReadReceiptSheet(
          readers: _people('r', 2),
          unread: _people('u', 1),
          onSelect: selected.add,
        ),
      ),
    );
    await tester.tap(find.byKey(FlareReadReceiptSheet.rowKey('r2')));
    await tester.tap(
      find.byKey(FlareReadReceiptSheet.tabKey(FlareReadReceiptColumn.unread)),
    );
    await tester.pump();
    await tester.tap(find.byKey(FlareReadReceiptSheet.rowKey('u1')));
    await tester.tap(
      find.byKey(FlareReadReceiptSheet.tabKey(FlareReadReceiptColumn.read)),
    );
    await tester.pump();
    expect(find.byKey(FlareReadReceiptSheet.rowKey('r1')), findsOneWidget);
    expect(selected, ['r2', 'u1']);
  });
}
