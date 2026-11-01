import 'dart:convert';
import 'dart:io';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flare_im_ui/src/components/flare_locate_highlight_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A window the host replaces as a whole and a locate that lands in it
/// (`spec/message-list-paging-vectors.json` `locateAfterReplace`), on the
/// widget: the list asks for no page by itself until the reader drags it, and
/// the located row ends in the viewport, marked, even when a page of older rows
/// lands while the list is still scrolling to it. Rows keep their own height;
/// the viewport is the table's.
void main() {
  final table =
      jsonDecode(
            File(
              '../../spec/message-list-paging-vectors.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  final spec = table['locateAfterReplace'] as Map<String, dynamic>;
  final viewport = (spec['viewportHeight'] as num).toDouble();
  final pageRows = spec['pageRows'] as int;
  final cases = (spec['cases'] as List).cast<Map<String, dynamic>>();

  List<FlareMessageData> rows(int from, int to) => [
    for (var i = from; i <= to; i++)
      FlareMessageData(
        id: 'm$i',
        senderId: i.isOdd ? 'ann' : 'lee',
        senderName: 'Ann',
        content: FlareTextContent('第 $i 条'),
        // A second apart within one day: no date pill between the rows.
        sentAtMs: DateTime(2025, 1, 15).millisecondsSinceEpoch + i * 1000,
      ),
  ];

  test('the table has its cases', () {
    expect(cases.length, greaterThanOrEqualTo(8));
  });

  for (final vector in cases) {
    testWidgets(vector['id'] as String, (tester) async {
      final before = vector['before'] as Map<String, dynamic>;
      final after = vector['after'] as Map<String, dynamic>;
      final expected = vector['expected'] as Map<String, dynamic>;
      final locate = vector['locate'] as int;
      final asked = <String>[];
      var messages = rows(before['from'] as int, before['to'] as int);
      var hasNewer = before['hasNewer'] as bool;
      var windowId = before['windowId'] as String?;
      var loadingOlder = false;
      final controller = FlareMessageListController();
      addTearDown(controller.dispose);
      Future<void> render() => tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                height: viewport,
                child: FlareMessageList(
                  messages: messages,
                  currentUserId: 'me',
                  conversationId: 'c1',
                  controller: controller,
                  hasOlder: true,
                  hasNewer: hasNewer,
                  windowId: windowId,
                  loadingOlder: loadingOlder,
                  onLoadOlder: () {
                    asked.add('older');
                    loadingOlder = true;
                  },
                  onLoadNewer: () => asked.add('newer'),
                  onJumpToLatest: () {},
                ),
              ),
            ),
          ),
        ),
      );
      final list = find.byType(CustomScrollView);
      // (1) The reader is at the bottom of `before`.
      await render();
      await tester.pumpAndSettle();
      // (2) The reader drags to the top, and the list asks for older history.
      if (vector['readerAskedOlder'] as bool) {
        await tester.drag(list, const Offset(0, 20000));
        await tester.pumpAndSettle();
        await render();
      }
      // (3) The host hands the list `after`.
      messages = rows(after['from'] as int, after['to'] as int);
      hasNewer = after['hasNewer'] as bool;
      windowId = after['windowId'] as String?;
      await render();
      await tester.pump();
      // (4) The locate trip asks the list once the window is drawn.
      expect(controller.scrollToMessage('m$locate'), isTrue);
      // A row the list has not built yet is approached first; the mark goes
      // on once the list reaches it.
      String? markedId() => tester
          .widget<FlareLocateHighlightScope>(
            find.byType(FlareLocateHighlightScope),
          )
          .messageId;
      for (var frame = 0; frame < 12 && markedId() == null; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      final marked = markedId() == 'm$locate';
      // (5) A page of older rows lands while the list is still moving.
      if (vector['pageLands'] as bool) {
        await tester.pump(const Duration(milliseconds: 16));
        final first = int.parse(messages.first.id.substring(1));
        messages = [...rows(first - pageRows, first - 1), ...messages];
        loadingOlder = false;
        await render();
      }
      await tester.pumpAndSettle();
      // (6) The reader drags the list themselves.
      final moves = vector['readerMovesTo'] as String?;
      if (moves != null) {
        await tester.drag(
          list,
          Offset(0, moves == 'top' ? 20000 : -20000),
        );
        await tester.pumpAndSettle();
      }
      final view = tester.getRect(list);
      final row = find.text('第 $locate 条');
      final inView =
          row.evaluate().isNotEmpty &&
          tester.getRect(row).top >= view.top &&
          tester.getRect(row).bottom <= view.bottom;
      expect({
        'requests': asked,
        'locatedInView': inView,
        'marked': marked,
      }, expected);
    });
  }
}
