import 'dart:convert';
import 'dart:io';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flare_im_ui/src/models/message_list_paging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The shared paging table (`spec/message-list-paging-vectors.json`): what the
/// two ends of the list draw, when the list asks for a page by itself, and what
/// the floating key at the bottom does. The four kits read the same table.
void main() {
  final table =
      jsonDecode(
            File(
              '../../spec/message-list-paging-vectors.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;

  FlareMessageListEnd end(Map<String, dynamic> raw) => FlareMessageListEnd(
    has: raw['has'] as bool,
    loading: raw['loading'] as bool,
    error: raw['error'] as String?,
    handled: raw['handled'] as bool,
  );

  test('the list asks within the distances the table names', () {
    final auto = table['autoRequest'] as Map<String, dynamic>;
    expect(auto['olderWithin'], flareMessageListOlderWithin);
    expect(auto['newerWithin'], flareMessageListNewerWithin);
    expect((table['edges'] as List).length, greaterThanOrEqualTo(11));
    expect((table['requests'] as List).length, greaterThanOrEqualTo(21));
    expect((table['jumpToLatest'] as List).length, greaterThanOrEqualTo(8));
  });

  for (final raw in (table['edges'] as List).cast<Map<String, dynamic>>()) {
    test('draws: ${raw['id']}', () {
      final expected = raw['expected'] as Map<String, dynamic>;
      expect(
        flareMessageListEdge(end(raw)),
        FlareMessageListEdge(
          spinner: expected['spinner'] as bool,
          error: expected['error'] as bool,
          button: expected['button'] as bool,
        ),
      );
    });
  }

  for (final raw in (table['requests'] as List).cast<Map<String, dynamic>>()) {
    test('asks: ${raw['id']}', () {
      final expected = raw['expected'] as Map<String, dynamic>;
      final wanted = flareMessageListRequests(
        fromTop: (raw['fromTop'] as num).toDouble(),
        fromBottom: (raw['fromBottom'] as num).toDouble(),
        older: end(raw['older'] as Map<String, dynamic>),
        newer: end(raw['newer'] as Map<String, dynamic>),
      );
      expect(
        (wanted.older, wanted.newer),
        (expected['older'] as bool, expected['newer'] as bool),
      );
    });
  }

  for (final raw
      in (table['jumpToLatest'] as List).cast<Map<String, dynamic>>()) {
    test('back to latest: ${raw['id']}', () {
      final expected = raw['expected'] as Map<String, dynamic>;
      final entry = flareMessageListLatestEntry(
        hasNewer: raw['hasNewer'] as bool,
        handled: raw['handled'] as bool,
        belowCount: raw['belowCount'] as int,
      );
      expect(
        (entry.shown, entry.count, entry.action?.name),
        (
          expected['shown'] as bool,
          expected['count'] as int,
          expected['action'] as String?,
        ),
      );
    });
  }

  final windows =
      ((table['windows'] as Map<String, dynamic>)['cases'] as List)
          .cast<Map<String, dynamic>>();
  test('the window table has its cases', () {
    expect(windows.length, greaterThanOrEqualTo(17));
  });
  for (final raw in windows) {
    test('window: ${raw['id']}', () {
      expect(
        flareMessageListWindowReplaced(
          (raw['previous'] as List).cast<String>(),
          (raw['next'] as List).cast<String>(),
          jumpRequested: raw['jumpRequested'] as bool? ?? false,
          hasNewer: raw['hasNewer'] as bool? ?? false,
          previousWindowId: raw['previousWindowId'] as String?,
          windowId: raw['windowId'] as String?,
        ),
        raw['expected'] as bool,
      );
    });
  }

  test('rows appended to a detached window are a newer page', () {
    const window = ['m1', 'm2', 'm3'];
    expect(
      flareMessageListNewerPage(window, [...window, 'm4'], wasDetached: true),
      isTrue,
    );
    expect(
      flareMessageListNewerPage(window, [...window, 'm4'], wasDetached: false),
      isFalse,
    );
    expect(
      flareMessageListNewerPage(window, ['m0', ...window], wasDetached: true),
      isFalse,
    );
    expect(
      flareMessageListNewerPage(window, [
        'x1',
        'x2',
        'x3',
        'x4',
      ], wasDetached: true),
      isFalse,
    );
  });

  group('the list', () {
    List<FlareMessageData> rows(int from, int to, {String sender = 'ann'}) => [
      for (var i = from; i <= to; i++)
        FlareMessageData(
          id: 'm$i',
          senderId: sender,
          senderName: sender,
          content: FlareTextContent('第 $i 条'),
          sentAtMs: 1736922600000 + i * 60000,
        ),
    ];
    const strings = FlareStrings();

    Widget host(Widget list) => MaterialApp(
      home: Scaffold(body: SizedBox(height: 400, child: list)),
    );

    testWidgets('a detached window offers newer pages and the latest', (
      tester,
    ) async {
      final asked = <String>[];
      await tester.pumpWidget(
        host(
          FlareMessageList(
            messages: rows(1, 30),
            currentUserId: 'me',
            hasNewer: true,
            onLoadNewer: () => asked.add('newer'),
            onJumpToLatest: () => asked.add('latest'),
          ),
        ),
      );
      await tester.tap(find.text(strings.messageListLoadNewer));
      await tester.tap(find.byType(FlareScrollToLatest));
      expect(asked, ['newer', 'latest']);
    });

    testWidgets('a list left at its defaults has no newer end and no key', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          FlareMessageList(
            messages: rows(1, 30),
            currentUserId: 'me',
            onLoadNewer: () {},
            onJumpToLatest: () {},
          ),
        ),
      );
      expect(find.text(strings.messageListLoadNewer), findsNothing);
      expect(find.byType(FlareScrollToLatest), findsNothing);
    });

    testWidgets('a detached window without a jump has no back-to-latest key', (
      tester,
    ) async {
      await tester.pumpWidget(
        host(
          FlareMessageList(
            messages: rows(1, 30),
            currentUserId: 'me',
            hasNewer: true,
            onLoadNewer: () {},
          ),
        ),
      );
      expect(find.byType(FlareScrollToLatest), findsNothing);
    });

    testWidgets('a newer page loading shows a spinner, a failure a retry', (
      tester,
    ) async {
      var calls = 0;
      var loading = true;
      String? error = '加载失败';
      Future<void> render() => tester.pumpWidget(
        host(
          FlareMessageList(
            messages: rows(1, 30),
            currentUserId: 'me',
            hasNewer: true,
            loadingNewer: loading,
            newerError: error,
            onLoadNewer: () => calls++,
          ),
        ),
      );
      await render();
      expect(find.text(strings.messageListLoadNewer), findsNothing);
      expect(find.text('加载失败'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      loading = false;
      await render();
      expect(find.text('加载失败'), findsOneWidget);
      await tester.tap(find.text(strings.messageListLoadNewer));
      expect(calls, 1);
    });

    testWidgets('a drag near the bottom of a detached window asks for newer', (
      tester,
    ) async {
      final asked = <String>[];
      await tester.pumpWidget(
        host(
          FlareMessageList(
            messages: rows(1, 30),
            currentUserId: 'me',
            hasNewer: true,
            hasOlder: true,
            onLoadNewer: () => asked.add('newer'),
            onLoadOlder: () => asked.add('older'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 60));
      await tester.pumpAndSettle();
      expect(asked, ['newer']);
    });

    testWidgets(
      'a window that does not overflow asks for older pages by itself',
      (tester) async {
        // `fill`: rows that fit the viewport cannot be dragged at all under
        // clamping physics, so without the list asking they never grow.
        final asked = <String>[];
        var messages = rows(29, 30);
        var loading = false;
        Future<void> render() => tester.pumpWidget(
          host(
            FlareMessageList(
              messages: messages,
              currentUserId: 'me',
              hasOlder: true,
              loadingOlder: loading,
              onLoadOlder: () => asked.add('older'),
            ),
          ),
        );
        await render();
        await tester.pumpAndSettle();
        expect(asked, ['older']);
        // A page that brings no rows does not ask again.
        loading = true;
        await render();
        loading = false;
        await render();
        await tester.pumpAndSettle();
        expect(asked, ['older']);
        // One that lands and still fits asks for the next.
        messages = rows(28, 30);
        await render();
        await tester.pumpAndSettle();
        expect(asked, ['older', 'older']);
      },
    );

    testWidgets('a newer page keeps the reader where they are', (tester) async {
      var messages = rows(1, 30);
      var hasNewer = true;
      Future<void> render() => tester.pumpWidget(
        host(
          FlareMessageList(
            messages: messages,
            currentUserId: 'me',
            hasNewer: hasNewer,
            onLoadNewer: () {},
            onJumpToLatest: () {},
          ),
        ),
      );
      await render();
      await tester.pumpAndSettle();
      final key = find.text('第 30 条');
      final y = tester.getTopLeft(key).dy;
      // The page ends in the reader's own messages and attaches the window.
      messages = [...messages, ...rows(31, 40, sender: 'me')];
      hasNewer = false;
      await render();
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(key).dy, closeTo(y, 1));
      expect(find.text('第 40 条'), findsNothing);
    });

    testWidgets('the latest window the reader asked for opens at its newest', (
      tester,
    ) async {
      var messages = rows(1, 30);
      var hasNewer = true;
      Future<void> render() => tester.pumpWidget(
        host(
          FlareMessageList(
            messages: messages,
            currentUserId: 'me',
            hasNewer: hasNewer,
            onLoadNewer: () {},
            onJumpToLatest: () {},
          ),
        ),
      );
      await render();
      await tester.pumpAndSettle();
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 300));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FlareScrollToLatest));
      messages = rows(500, 540);
      hasNewer = false;
      await render();
      await tester.pumpAndSettle();
      expect(find.text('第 540 条'), findsOneWidget);
      expect(find.byType(FlareScrollToLatest), findsNothing);
    });
  });

  group('at the bottom', () {
    final bottom = table['atBottom'] as Map<String, dynamic>;
    test('within the distance the table names', () {
      expect(bottom['within'], flareMessageListBottomWithin);
      expect((bottom['cases'] as List).length, greaterThanOrEqualTo(18));
    });
    for (final raw in (bottom['cases'] as List).cast<Map<String, dynamic>>()) {
      test('reports: ${raw['id']}', () {
        final report = FlareMessageListBottomReport();
        final steps = (raw['steps'] as List).cast<Map<String, dynamic>>();
        final told = [
          for (final step in steps)
            switch (step['do'] as String) {
              'layout' => report.layout((step['fromBottom'] as num).toDouble()),
              'replaced' => report.replaced(),
              'jumpedToLatest' => report.jumpedToLatest(),
              'located' => report.located(),
              'readerMoved' => report.readerMoved(),
              'wentToLatest' => report.wentToLatest(),
              'emptied' => report.emptied(),
              'anotherConversation' => (() {
                report.anotherConversation();
                return null;
              })(),
              final other => throw StateError('unknown step $other'),
            },
        ];
        expect(told, [for (final step in steps) step['reports'] as bool?]);
      });
    }
  });

  group('fill', () {
    final cases = ((table['fill'] as Map<String, dynamic>)['cases'] as List)
        .cast<Map<String, dynamic>>();
    test('the fill table has its cases', () {
      expect(cases.length, greaterThanOrEqualTo(7));
    });
    for (final raw in cases) {
      test('fills the viewport: ${raw['id']}', () {
        expect(
          flareMessageListFillsViewport(
            fromTop: (raw['fromTop'] as num?)?.toDouble(),
            fromBottom: (raw['fromBottom'] as num?)?.toDouble(),
          ),
          raw['expected'] as bool,
        );
      });
    }
  });
}
