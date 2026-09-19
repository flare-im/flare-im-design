import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// FR-082: the timeline dates the first loaded message and every message on a
// new local calendar day, and nothing else — every bubble already shows its
// time. The unread divider follows the date pill of the same message.

const _strings = FlareStrings();

FlareMessageData _msg(String id, DateTime at, {String sender = 'bob'}) =>
    FlareMessageData(
      id: id,
      senderId: sender,
      senderName: sender,
      content: FlareTextContent('text $id'),
      sentAtMs: at.millisecondsSinceEpoch,
    );

Widget _list(
  List<FlareMessageData> messages, {
  String? unreadFromId,
  String locale = 'zh-CN',
}) => MaterialApp(
  home: Scaffold(
    body: FlareMessageList(
      messages: messages,
      currentUserId: 'me',
      unreadFromId: unreadFromId,
      locale: locale,
    ),
  ),
);

/// Rows as the reader sees them, top to bottom. The timeline grows upwards
/// from the newest message (a reversed viewport with its centre at the
/// bottom), so element order is not reading order: assert on the geometry.
List<T> _topToBottom<T extends Widget>(WidgetTester tester) {
  final widgets = tester.widgetList<T>(find.byType(T)).toList();
  widgets.sort(
    (a, b) => tester
        .getTopLeft(find.byWidget(a))
        .dy
        .compareTo(tester.getTopLeft(find.byWidget(b)).dy),
  );
  return widgets;
}

List<String> _pills(WidgetTester tester) =>
    _topToBottom<FlareDatePill>(tester).map((pill) => pill.label).toList();

/// The lowest date pill on screen.
Finder _lastPill(WidgetTester tester) =>
    find.byWidget(_topToBottom<FlareDatePill>(tester).last);

void main() {
  group('FlareTimeFormat.timelineDate', () {
    final now = DateTime(2026, 9, 15, 9);
    String label(DateTime time, String locale) => FlareTimeFormat.timelineDate(
      time,
      today: 'Today',
      yesterday: 'Yesterday',
      locale: locale,
      now: now,
    );

    test('today and yesterday use the given words', () {
      expect(label(DateTime(2026, 9, 15, 0, 1), 'zh-CN'), 'Today');
      expect(label(DateTime(2026, 9, 14, 23, 59), 'en-US'), 'Yesterday');
      expect(
        FlareTimeFormat.timelineDate(
          DateTime(2026, 8, 31, 22),
          today: 'Today',
          yesterday: 'Yesterday',
          locale: 'de-DE',
          now: DateTime(2026, 9, 1, 8),
        ),
        'Yesterday',
      );
    });

    test('this year is month and day, an earlier year adds the year', () {
      expect(label(DateTime(2026, 3, 7, 10), 'zh-CN'), '3/7');
      expect(label(DateTime(2026, 3, 7, 10), 'en-GB'), '7/3');
      expect(label(DateTime(2025, 11, 2, 10), 'zh-CN'), '2025/11/2');
      expect(label(DateTime(2025, 11, 2, 10), 'en-US'), '11/2/2025');
    });

    test('sameDay compares the local calendar day', () {
      expect(
        FlareTimeFormat.sameDay(
          DateTime(2026, 9, 15, 0, 0),
          DateTime(2026, 9, 15, 23, 59),
        ),
        isTrue,
      );
      expect(
        FlareTimeFormat.sameDay(
          DateTime(2026, 9, 14, 23, 59),
          DateTime(2026, 9, 15, 0, 0),
        ),
        isFalse,
      );
    });
  });

  group('FlareMessageList date separators', () {
    testWidgets('the first loaded message is dated', (tester) async {
      final now = DateTime.now();
      await tester.pumpWidget(
        _list([_msg('a', DateTime(now.year, now.month, now.day, 0, 5))]),
      );
      expect(_pills(tester), [_strings.today]);
    });

    testWidgets('hours apart on the same day: one pill only', (tester) async {
      final base = DateTime(2024, 5, 1, 8);
      await tester.pumpWidget(
        _list([
          _msg('a', base),
          _msg('b', base.add(const Duration(hours: 3))),
          _msg('c', base.add(const Duration(hours: 9)), sender: 'me'),
        ]),
      );
      expect(_pills(tester), ['2024/5/1']);
    });

    testWidgets('crossing midnight starts a new day, minutes apart or not', (
      tester,
    ) async {
      await tester.pumpWidget(
        _list([
          _msg('a', DateTime(2024, 5, 1, 23, 55)),
          _msg('b', DateTime(2024, 5, 2, 0, 3)),
          _msg('c', DateTime(2024, 5, 2, 9)),
        ]),
      );
      expect(_pills(tester), ['2024/5/1', '2024/5/2']);
      // The second pill sits between the two messages it separates.
      final pill = tester.getRect(_lastPill(tester));
      expect(
        pill.top,
        greaterThanOrEqualTo(tester.getRect(find.text('text a')).bottom),
      );
      expect(
        pill.bottom,
        lessThanOrEqualTo(tester.getRect(find.text('text b')).top),
      );
    });

    testWidgets('yesterday and a previous year, in the given locale', (
      tester,
    ) async {
      final now = DateTime.now();
      final yesterday = DateTime(now.year, now.month, now.day - 1, 12);
      final lastYear = DateTime(now.year - 1, 3, 7, 10);
      await tester.pumpWidget(
        _list([_msg('a', lastYear), _msg('b', yesterday)], locale: 'en-US'),
      );
      expect(_pills(tester), ['3/7/${now.year - 1}', _strings.yesterday]);
    });

    testWidgets('a message without a time starts no day', (tester) async {
      await tester.pumpWidget(
        _list([
          _msg('a', DateTime(2024, 5, 1, 10)),
          const FlareMessageData(
            id: 'pending',
            senderId: 'me',
            senderName: 'me',
            content: FlareTextContent('sending'),
          ),
          _msg('b', DateTime(2024, 5, 1, 11)),
        ]),
      );
      expect(_pills(tester), ['2024/5/1']);
    });

    testWidgets('the unread divider comes after the date pill of its message', (
      tester,
    ) async {
      await tester.pumpWidget(
        _list([
          _msg('a', DateTime(2024, 5, 1, 10)),
          _msg('b', DateTime(2024, 5, 2, 9)),
          _msg('c', DateTime(2024, 5, 2, 9, 1), sender: 'me'),
          _msg('d', DateTime(2024, 5, 2, 9, 2)),
        ], unreadFromId: 'b'),
      );
      expect(_pills(tester), ['2024/5/1', '2024/5/2']);
      final divider = find.byType(FlareUnreadDivider);
      expect(divider, findsOneWidget);
      // Two unread messages from others below it; the reader's own is not
      // counted.
      expect(tester.widget<FlareUnreadDivider>(divider).count, 2);
      final pill = tester.getRect(_lastPill(tester));
      final line = tester.getRect(divider);
      final message = tester.getRect(find.text('text b'));
      expect(pill.bottom, lessThanOrEqualTo(line.top));
      expect(line.bottom, lessThanOrEqualTo(message.top));
    });

    testWidgets('the unread divider starts a new sender run', (tester) async {
      final base = DateTime(2024, 5, 1, 10);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlareMessageList(
              messages: [
                for (var i = 0; i < 3; i++)
                  _msg('m$i', base.add(Duration(minutes: i))),
              ],
              currentUserId: 'me',
              conversationKind: FlareConversationKind.group,
              unreadFromId: 'm1',
              locale: 'zh-CN',
            ),
          ),
        ),
      );
      final positions = _topToBottom<FlareMessageBubble>(
        tester,
      ).map((bubble) => bubble.groupPosition).toList();
      expect(positions, [
        FlareMessageGroupPosition.single,
        FlareMessageGroupPosition.first,
        FlareMessageGroupPosition.last,
      ]);
    });

    testWidgets('a sender run never continues across a date pill', (
      tester,
    ) async {
      // One minute apart, so only the new day separates them.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlareMessageList(
              messages: [
                _msg('a', DateTime(2024, 5, 1, 23, 58)),
                _msg('b', DateTime(2024, 5, 1, 23, 59)),
                _msg('c', DateTime(2024, 5, 2, 0, 0)),
                _msg('d', DateTime(2024, 5, 2, 0, 1)),
              ],
              currentUserId: 'me',
              conversationKind: FlareConversationKind.group,
              locale: 'zh-CN',
            ),
          ),
        ),
      );
      expect(_pills(tester), ['2024/5/1', '2024/5/2']);
      final positions = _topToBottom<FlareMessageBubble>(
        tester,
      ).map((bubble) => bubble.groupPosition).toList();
      expect(positions, [
        FlareMessageGroupPosition.first,
        FlareMessageGroupPosition.last,
        FlareMessageGroupPosition.first,
        FlareMessageGroupPosition.last,
      ]);
      // The new day's first message shows its sender again in a group.
      expect(find.text('bob'), findsNWidgets(2));
    });

    testWidgets('the timeline pill is a quiet chip; a floating one keeps its '
        'surface', (tester) async {
      BoxDecoration decoration(bool floating) {
        final chip = find.descendant(
          of: find.byWidgetPredicate(
            (widget) => widget is FlareDatePill && widget.floating == floating,
          ),
          matching: find.byType(Container),
        );
        return tester.widget<Container>(chip).decoration! as BoxDecoration;
      }

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                FlareDatePill(label: '今天'),
                FlareDatePill(label: '昨天', floating: true),
              ],
            ),
          ),
        ),
      );
      final colors = FlareColors.resolve(Brightness.light);
      final quiet = decoration(false);
      expect(quiet.color, colors.bgSecondary);
      expect(quiet.border, isNull);
      expect(quiet.boxShadow, isNull);
      final floating = decoration(true);
      expect(floating.border, isNotNull);
      expect(floating.boxShadow, isNotEmpty);
    });
  });
}
