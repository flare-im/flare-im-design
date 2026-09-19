import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Swiping a message to reply to it: what the reader sees while the finger is
/// down, and what the host is told when it comes up. The arithmetic itself is
/// the shared table (`swipe_reply_vectors_test.dart`); this is the gesture
/// reaching it and the row being drawn where it says.
Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

FlareMessageData _message(String id, String text) => FlareMessageData(
  id: id,
  senderId: 'ann',
  senderName: 'Ann',
  content: FlareTextContent(text),
);

Finder get _affordance => find.byKey(const ValueKey('swipe-reply-affordance'));

double _opacity(WidgetTester tester) =>
    tester.widget<Opacity>(_affordance.first).opacity;

void main() {
  testWidgets('a row follows the finger and replies when it is let go', (
    tester,
  ) async {
    final replied = <String>[];
    await tester.pumpWidget(
      _host(
        FlareMessageList(
          currentUserId: 'me',
          messages: [_message('m1', '第一条')],
          onSwipeReply: (message) => replied.add(message.id),
        ),
      ),
    );
    expect(_opacity(tester), 0);

    final gesture = await tester.startGesture(tester.getCenter(find.text('第一条')));
    // The move that crosses the touch slop starts the drag; travel counts from
    // there, so the row has not moved yet.
    await gesture.moveBy(const Offset(20, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(20, 0));
    await tester.pump();
    final followed = tester.getTopLeft(find.text('第一条')).dx;
    final armingOpacity = _opacity(tester);
    expect(armingOpacity, greaterThan(0));
    expect(armingOpacity, lessThan(1));

    // The row tracks the finger one for one below the arming distance.
    await gesture.moveBy(const Offset(12, 0));
    await tester.pump();
    expect(tester.getTopLeft(find.text('第一条')).dx - followed, closeTo(12, 0.001));

    // Past the arming distance the affordance is fully drawn, before release.
    await gesture.moveBy(const Offset(60, 0));
    await tester.pump();
    expect(_opacity(tester), 1);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(replied, ['m1']);
    expect(_opacity(tester), 0);
  });

  testWidgets('a drag that stops short goes back and says nothing', (
    tester,
  ) async {
    final replied = <String>[];
    await tester.pumpWidget(
      _host(
        FlareMessageList(
          currentUserId: 'me',
          messages: [_message('m1', '第一条')],
          onSwipeReply: (message) => replied.add(message.id),
        ),
      ),
    );
    final rest = tester.getTopLeft(find.text('第一条')).dx;
    final gesture = await tester.startGesture(tester.getCenter(find.text('第一条')));
    await gesture.moveBy(const Offset(20, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(30, 0));
    await tester.pump();
    final short = _opacity(tester);
    expect(short, greaterThan(0));
    expect(short, lessThan(1));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(replied, isEmpty);
    expect(tester.getTopLeft(find.text('第一条')).dx, rest);
  });

  testWidgets('dragging the other way never replies', (tester) async {
    final replied = <String>[];
    await tester.pumpWidget(
      _host(
        FlareMessageList(
          currentUserId: 'me',
          messages: [_message('m1', '第一条')],
          onSwipeReply: (message) => replied.add(message.id),
        ),
      ),
    );
    final rest = tester.getTopLeft(find.text('第一条')).dx;
    final gesture = await tester.startGesture(tester.getCenter(find.text('第一条')));
    await gesture.moveBy(const Offset(-20, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(-100, 0));
    await tester.pump();
    expect(_opacity(tester), 0);
    expect(tester.getTopLeft(find.text('第一条')).dx, rest);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(replied, isEmpty);
  });

  testWidgets('scrolling the thread never replies', (tester) async {
    final replied = <String>[];
    await tester.pumpWidget(
      _host(
        FlareMessageList(
          currentUserId: 'me',
          messages: [
            for (var i = 0; i < 40; i++) _message('m$i', '第 $i 条'),
          ],
          onSwipeReply: (message) => replied.add(message.id),
        ),
      ),
    );
    // A drag the list claims for its own scrolling is not a reply, however far
    // sideways it wanders on the way.
    await tester.drag(find.text('第 39 条'), const Offset(30, -220));
    await tester.pumpAndSettle();
    expect(replied, isEmpty);
    expect(
      tester.widgetList<Opacity>(_affordance).every((o) => o.opacity == 0),
      isTrue,
    );
  });

  testWidgets('a host that does not take the intent gets no gesture', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        FlareMessageList(currentUserId: 'me', messages: [_message('m1', '第一条')]),
      ),
    );
    expect(_affordance, findsNothing);
  });
}
