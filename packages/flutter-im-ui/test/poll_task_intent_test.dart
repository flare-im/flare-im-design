import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

/// A poll's options and a task's checkbox are controls in a timeline only when
/// the host takes the intent (R9-B8): `onVote` with the option's index,
/// `onTaskToggle` with the state asked for. Without a handler, and in
/// multi-select mode, they are read-only.
void main() {
  const poll = FlarePollContent(
    id: 'vote-1',
    title: '周五聚餐',
    options: ['火锅', '烤肉', '日料'],
  );
  const openTask = FlareTaskContent(
    id: 'task-1',
    title: '提交周报',
    detail: '今天 18:00',
  );
  const doneTask = FlareTaskContent(id: 'task-2', title: '订会议室', done: true);

  FlareMessageData message(String id, FlareMessageContent content) =>
      FlareMessageData(
        id: id,
        senderId: 'ann',
        senderName: 'Ann',
        content: content,
      );

  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('without handlers polls and tasks are read-only', (tester) async {
    await tester.pumpWidget(
      host(
        const Column(
          children: [
            FlareMessageContentView(content: poll),
            FlareMessageContentView(content: openTask),
          ],
        ),
      ),
    );
    expect(find.byType(InkWell), findsNothing);
    final checkbox = tester.getSemantics(find.bySemanticsLabel('提交周报'));
    expect(checkbox.getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
  });

  testWidgets(
    'a vote names the tapped option and a toggle asks for the other state',
    (tester) async {
      final intents = <String>[];
      await tester.pumpWidget(
        host(
          Column(
            children: [
              FlareMessageContentView(
                content: poll,
                onVote: (index) => intents.add('vote $index'),
              ),
              FlareMessageContentView(
                content: openTask,
                onTaskToggle: (done) => intents.add('open $done'),
              ),
              FlareMessageContentView(
                content: doneTask,
                onTaskToggle: (done) => intents.add('done $done'),
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.text('烤肉'));
      await tester.tap(find.bySemanticsLabel('提交周报'));
      await tester.tap(find.bySemanticsLabel('订会议室'));
      expect(intents, ['vote 1', 'open true', 'done false']);
      // Each option is a full-size target.
      expect(
        tester.getSize(find.byType(InkWell).first).height,
        greaterThanOrEqualTo(FlareSizes.touchTarget),
      );
    },
  );

  testWidgets(
    'the list hands the host the message, and multi-select turns the controls off',
    (tester) async {
      final intents = <String>[];
      Widget list({bool selecting = false}) => host(
        FlareMessageList(
          messages: [message('m1', poll), message('m2', openTask)],
          currentUserId: 'me',
          multiSelectMode: selecting,
          onToggleSelect: (_) {},
          onVote: (m, index) => intents.add('vote ${m.id}:$index'),
          onTaskToggle: (m, done) => intents.add('task ${m.id}:$done'),
        ),
      );
      await tester.pumpWidget(list());
      await tester.pumpAndSettle();
      await tester.tap(find.text('日料'));
      await tester.tap(find.bySemanticsLabel('提交周报'));
      expect(intents, ['vote m1:2', 'task m2:true']);

      await tester.pumpWidget(list(selecting: true));
      await tester.pumpAndSettle();
      expect(
        tester
            .getSemantics(find.bySemanticsLabel('提交周报'))
            .getSemanticsData()
            .hasAction(SemanticsAction.tap),
        isFalse,
      );
    },
  );
}
