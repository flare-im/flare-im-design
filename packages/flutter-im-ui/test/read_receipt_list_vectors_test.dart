import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// FlareReadReceiptListState against spec/read-receipt-list-vectors.json (the
/// Vue and Compose holders read the same file), step by step: every loader
/// call is held until a step settles it, so a case can leave answers in flight
/// across a close, a new key or the other column's paging. Then the sheet over
/// the holder: its keys ask the holder, and the tab numbers stay the host's.
final Map<String, dynamic> _table =
    jsonDecode(
          File('../../spec/read-receipt-list-vectors.json').readAsStringSync(),
        )
        as Map<String, dynamic>;

class _Call {
  _Call(this.column, this.cursor);
  final FlareReadReceiptColumn column;
  final String? cursor;
  final answer = Completer<FlareReadReceiptMembers?>();
  bool settled = false;
}

FlareReadReceiptColumn _column(String name) =>
    FlareReadReceiptColumn.values.byName(name);

FlareReadReceiptMembers _members(Map raw) => FlareReadReceiptMembers(
  people: [
    for (final id in (raw['people'] as List).cast<String>())
      FlareContact(id: id, name: id),
  ],
  nextCursor: raw['nextCursor'] as String?,
);

FlareReadReceiptPages? _pages(Object? raw) {
  if (raw == null) return null;
  final map = raw as Map;
  String? col(Object? name) => name as String?;
  return FlareReadReceiptPages(
    state: FlareReadReceiptState.values.byName(map['state'] as String),
    read: _members(map['read'] as Map),
    unread: _members(map['unread'] as Map),
    loadingMore: col(map['loadingMore']) == null
        ? null
        : _column(map['loadingMore'] as String),
    loadMoreFailed: col(map['loadMoreFailed']) == null
        ? null
        : _column(map['loadMoreFailed'] as String),
  );
}

/// Settles [call] as a vector answer says: a members page, null (not
/// offered), "throw" (failed) or "pending" (left in flight).
void _settle(_Call call, Object? answer) {
  if (answer == 'pending') return;
  call.settled = true;
  if (answer == 'throw') {
    call.answer.completeError(StateError('page failed'));
  } else {
    call.answer.complete(answer == null ? null : _members(answer as Map));
  }
}

/// Lets every settled answer land.
Future<void> _drain() async {
  for (var i = 0; i < 10; i += 1) {
    await Future<void>.delayed(Duration.zero);
  }
}

void main() {
  final cases = (_table['cases'] as List).cast<Map<String, dynamic>>();

  test('the vector file holds the cases this kit reads', () {
    expect(
      cases.where((c) => (c['platforms'] as List).contains('flutter')),
      hasLength(cases.length),
    );
    expect(cases, hasLength(greaterThanOrEqualTo(8)));
  });

  for (final v in cases) {
    test(v['id'], () async {
      final calls = <_Call>[];
      final list = FlareReadReceiptListState((column, cursor) {
        final call = _Call(column, cursor);
        calls.add(call);
        return call.answer.future;
      });
      addTearDown(list.dispose);
      final steps = (v['steps'] as List).cast<Map<String, dynamic>>();
      for (final (index, step) in steps.indexed) {
        final at = 'step $index (${step['do']})';
        final before = calls.length;
        final action = step['do'] as String;
        switch (action.split(':')) {
          case ['open']:
            list.open(step['key'] as String? ?? 'm1');
          case ['close']:
            list.open(null);
          case ['retry']:
            unawaited(list.retry());
          case ['loadMore', final column]:
            unawaited(list.loadMore(_column(column)));
          case ['settle', final column]:
            final call = calls.firstWhere(
              (c) => !c.settled && c.column == _column(column),
            );
            _settle(call, step['answer']);
          default:
            fail('$at: unknown step');
        }
        final made = calls.sublist(before);
        if (step.containsKey('asks')) {
          expect(
            [for (final c in made) [c.column.name, c.cursor]],
            step['asks'],
            reason: '$at asks',
          );
        }
        if (!action.startsWith('settle')) {
          if (step['answers'] case final Map answers) {
            for (final call in made) {
              _settle(call, answers[call.column.name]);
            }
          } else if (step.containsKey('answer')) {
            for (final call in made) {
              _settle(call, step['answer']);
            }
          }
        }
        await _drain();
        expect(list.pages, _pages(step['expect']), reason: '$at expect');
      }
    });
  }

  group('FlareReadReceiptSheet.list', () {
    Widget host(Widget child) => MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: 390, child: child),
        ),
      ),
    );

    testWidgets('draws the holder, asks it for the next page and a retry', (
      tester,
    ) async {
      final calls = <_Call>[];
      final list = FlareReadReceiptListState((column, cursor) {
        final call = _Call(column, cursor);
        calls.add(call);
        return call.answer.future;
      });
      addTearDown(list.dispose);
      await tester.pumpWidget(
        host(FlareReadReceiptSheet.list(list: list, readCount: 7)),
      );
      // Not opened yet: loading, with the host's number on the tab.
      expect(find.byKey(FlareReadReceiptSheet.spinnerKey), findsOneWidget);
      expect(find.text(const FlareStrings().readTab(7)), findsOneWidget);

      list.open('m1');
      await tester.pump();
      _settle(calls[0], {
        'people': ['r1'],
        'nextCursor': 'rc1',
      });
      _settle(calls[1], {
        'people': ['u1'],
      });
      await tester.pumpAndSettle();
      expect(find.byKey(FlareReadReceiptSheet.rowKey('r1')), findsOneWidget);
      // The number is the summary's, never the loaded rows'.
      expect(find.text(const FlareStrings().readTab(7)), findsOneWidget);

      await tester.tap(find.byKey(FlareReadReceiptSheet.tailKey));
      await tester.pump();
      expect(calls.last.cursor, 'rc1');
      expect(list.pages!.loadingMore, FlareReadReceiptColumn.read);
      _settle(calls.last, 'throw');
      await tester.pumpAndSettle();
      expect(list.pages!.loadMoreFailed, FlareReadReceiptColumn.read);
      expect(
        find.text(const FlareStrings().readReceiptLoadMoreFailed),
        findsOneWidget,
      );

      // A failed first read offers the retry key, which reads both again.
      unawaited(list.retry());
      await tester.pump();
      _settle(calls[calls.length - 2], 'throw');
      _settle(calls.last, {'people': <String>[]});
      await tester.pumpAndSettle();
      expect(find.byKey(FlareReadReceiptSheet.retryKey), findsOneWidget);
      final asked = calls.length;
      await tester.tap(find.byKey(FlareReadReceiptSheet.retryKey));
      await tester.pump();
      expect(
        [for (final c in calls.sublist(asked)) [c.column.name, c.cursor]],
        [
          ['read', null],
          ['unread', null],
        ],
      );
    });
  });
}
