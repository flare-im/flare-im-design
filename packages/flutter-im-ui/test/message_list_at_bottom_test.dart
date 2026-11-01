import 'dart:convert';
import 'dart:io';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Whether the reader is at the bottom (`spec/message-list-paging-vectors.json`
/// `atBottom`), as the widget tells the host through `onAtBottomChange`: once
/// after the first layout, false when the reader drags away from the bottom and
/// true when they come back, nothing while messages arrive under a reader
/// there, and not at the bottom of a window replaced without the reader asking,
/// or of a locate, until the reader scrolls the list.
void main() {
  final table =
      jsonDecode(
            File(
              '../../spec/message-list-paging-vectors.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  final within =
      ((table['atBottom'] as Map<String, dynamic>)['within'] as num).toDouble();

  List<FlareMessageData> rows(int from, int to, {String sender = 'ann'}) => [
    for (var i = from; i <= to; i++)
      FlareMessageData(
        id: 'm$i',
        senderId: sender,
        senderName: sender,
        content: FlareTextContent('第 $i 条'),
        // A second apart within one day: no date pill between the rows.
        sentAtMs: DateTime(2025, 1, 15).millisecondsSinceEpoch + i * 1000,
      ),
  ];

  late List<FlareMessageData> messages;
  late String? windowId;
  late List<bool> told;
  late FlareMessageListController controller;

  Future<void> render(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            height: 400,
            child: FlareMessageList(
              messages: messages,
              currentUserId: 'me',
              conversationId: 'c1',
              controller: controller,
              windowId: windowId,
              onAtBottomChange: told.add,
            ),
          ),
        ),
      ),
    ),
  );

  Future<void> open(WidgetTester tester, List<FlareMessageData> initial) async {
    messages = initial;
    windowId = 'timeline:1';
    told = [];
    controller = FlareMessageListController();
    addTearDown(controller.dispose);
    await render(tester);
    await tester.pumpAndSettle();
  }

  /// How far the end of the timeline is below the viewport.
  double fromBottom() {
    final position = controller.scroll.position;
    return position.pixels - position.minScrollExtent;
  }

  /// The reader drags the list: positive towards older messages.
  Future<void> drag(WidgetTester tester, double dy) async {
    await tester.drag(find.byType(CustomScrollView), Offset(0, dy));
    await tester.pumpAndSettle();
  }

  testWidgets('the first layout tells the bottom once', (tester) async {
    await open(tester, rows(1, 40));
    expect(fromBottom(), 0);
    expect(told, [true]);
  });

  testWidgets('an empty list is at its bottom', (tester) async {
    await open(tester, []);
    expect(told, [true]);
  });

  testWidgets(
    'dragging away tells false and coming back tells true, nothing within the distance',
    (tester) async {
      await open(tester, rows(1, 40));
      await drag(tester, within - 30);
      expect(fromBottom(), lessThanOrEqualTo(within));
      expect(told, [true]);
      await drag(tester, 300);
      expect(fromBottom(), greaterThan(within));
      expect(told, [true, false]);
      await drag(tester, -2000);
      expect(fromBottom(), 0);
      expect(told, [true, false, true]);
    },
  );

  testWidgets('messages arriving under a reader at the bottom keep them there', (
    tester,
  ) async {
    await open(tester, rows(1, 40));
    messages = [...messages, ...rows(41, 41)];
    await render(tester);
    await tester.pumpAndSettle();
    messages = [...messages, ...rows(42, 44)];
    await render(tester);
    await tester.pumpAndSettle();
    expect(find.text('第 44 条'), findsOneWidget);
    expect(told, [true]);
  });

  testWidgets(
    'a window replaced without the reader asking is not their bottom until they scroll it',
    (tester) async {
      await open(tester, rows(961, 1000));
      messages = rows(921, 960);
      windowId = 'timeline:2';
      await render(tester);
      await tester.pumpAndSettle();
      // The list opened the new window at its newest row; that is not the
      // reader arriving there.
      expect(fromBottom(), 0);
      expect(told, [true, false]);
      // The reader's own drag, towards the newest row they are already at.
      await drag(tester, -200);
      expect(told, [true, false, true]);
    },
  );

  testWidgets(
    'a locate holds the answer even at the last row, until a message of the reader\'s own',
    (tester) async {
      await open(tester, rows(1, 40));
      expect(controller.scrollToMessage('m40'), isTrue);
      await tester.pumpAndSettle();
      expect(told, [true, false]);
      messages = [...messages, ...rows(41, 41, sender: 'me')];
      await render(tester);
      await tester.pumpAndSettle();
      expect(told, [true, false, true]);
    },
  );
}
