import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// K1 (Round 5 Batch 6): the list follows the newest message itself — it opens
// at the bottom, new messages keep a bottom reader there, a reader who scrolled
// up keeps their rows and sees how many messages arrived below, older history
// and resizes never move the rows in view.

FlareMessageData _message(int i, {String sender = 'other'}) => FlareMessageData(
  id: 'm$i',
  senderId: sender,
  senderName: sender,
  content: FlareTextContent('message $i'),
);

List<FlareMessageData> _range(int from, int to) => [
  for (var i = from; i < to; i++) _message(i),
];

class _Harness {
  _Harness(this.tester);

  final WidgetTester tester;
  final controller = FlareMessageListController();
  List<FlareMessageData> messages = const [];
  String conversationId = 'c1';
  double height = 400;

  Future<void> pump() async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              height: height,
              child: FlareMessageList(
                messages: messages,
                conversationId: conversationId,
                currentUserId: 'me',
                controller: controller,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Rect get listRect => tester.getRect(find.byType(CustomScrollView));

  bool fullyVisible(String text) {
    final finder = find.text(text);
    if (finder.evaluate().isEmpty) return false;
    final rect = tester.getRect(finder);
    return rect.top >= listRect.top - 0.5 && rect.bottom <= listRect.bottom + 0.5;
  }

  double top(String text) => tester.getTopLeft(find.text(text)).dy;

  /// The first message row that starts inside the list.
  String firstVisible() {
    final visible = <(double, String)>[];
    for (final element in find.byType(FlareMessageBubble).evaluate()) {
      final bubble = element.widget as FlareMessageBubble;
      final rect = tester.getRect(find.byWidget(bubble));
      if (rect.top >= listRect.top && rect.bottom <= listRect.bottom) {
        visible.add((rect.top, (bubble.message.content as FlareTextContent).text));
      }
    }
    visible.sort((a, b) => a.$1.compareTo(b.$1));
    return visible.first.$2;
  }

  /// Towards older messages. The list runs bottom to top, so older rows are
  /// at larger offsets.
  Future<void> scrollUp(double by) async {
    controller.scroll.jumpTo(controller.scroll.position.pixels + by);
    await tester.pumpAndSettle();
  }

  void dispose() => controller.dispose();
}

void main() {
  testWidgets('opens at the newest message when there are more than fit', (
    tester,
  ) async {
    final h = _Harness(tester)..messages = _range(0, 60);
    addTearDown(h.dispose);
    await h.pump();
    expect(h.fullyVisible('message 59'), isTrue);
    expect(h.fullyVisible('message 0'), isFalse);
    // The newest row sits at the bottom of the list, not somewhere above it.
    expect(
      h.listRect.bottom - tester.getRect(find.text('message 59')).bottom,
      lessThan(48),
    );
    expect(find.byType(FlareScrollToLatest), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a message that arrives at the bottom stays in view', (
    tester,
  ) async {
    final h = _Harness(tester)..messages = _range(0, 60);
    addTearDown(h.dispose);
    await h.pump();
    h.messages = [...h.messages, _message(60)];
    await h.pump();
    expect(h.fullyVisible('message 60'), isTrue);
    h.messages = [...h.messages, _message(61), _message(62)];
    await h.pump();
    expect(h.fullyVisible('message 62'), isTrue);
    expect(find.byType(FlareScrollToLatest), findsNothing);
  });

  testWidgets('a reader who scrolled up keeps their rows and sees the count; '
      'the control goes to the newest', (tester) async {
    final semantics = tester.ensureSemantics();
    final h = _Harness(tester)..messages = _range(0, 60);
    addTearDown(h.dispose);
    await h.pump();
    await h.scrollUp(700);
    final reading = h.firstVisible();
    final y = h.top(reading);

    h.messages = [...h.messages, _message(60), _message(61)];
    await h.pump();
    expect(h.top(reading), closeTo(y, 0.5));
    expect(h.fullyVisible('message 61'), isFalse);
    final control = find.byType(FlareScrollToLatest);
    expect(control, findsOneWidget);
    expect(tester.widget<FlareScrollToLatest>(control).count, 2);
    const strings = FlareStrings();
    expect(
      tester.getSemantics(control),
      isSemantics(
        label: strings.scrollToLatest,
        value: strings.newMessages(2),
        isButton: true,
        hasTapAction: true,
      ),
    );
    expect(
      tester.getSize(control).height,
      greaterThanOrEqualTo(FlareSizes.touchTarget),
    );

    await tester.tap(control);
    await tester.pumpAndSettle();
    expect(h.fullyVisible('message 61'), isTrue);
    expect(find.byType(FlareScrollToLatest), findsNothing);
    // Back at the bottom, the next message is followed again.
    h.messages = [...h.messages, _message(62)];
    await h.pump();
    expect(h.fullyVisible('message 62'), isTrue);
    semantics.dispose();
  });

  testWidgets('scrolling back to the bottom clears the count', (tester) async {
    final h = _Harness(tester)..messages = _range(0, 60);
    addTearDown(h.dispose);
    await h.pump();
    await h.scrollUp(700);
    h.messages = [...h.messages, _message(60)];
    await h.pump();
    expect(find.byType(FlareScrollToLatest), findsOneWidget);
    h.controller.scroll.jumpTo(h.controller.scroll.position.minScrollExtent);
    await tester.pumpAndSettle();
    expect(find.byType(FlareScrollToLatest), findsNothing);
    expect(h.fullyVisible('message 60'), isTrue);
  });

  testWidgets('loading older messages keeps the row being read in place', (
    tester,
  ) async {
    final h = _Harness(tester)..messages = _range(40, 80);
    addTearDown(h.dispose);
    await h.pump();
    await h.scrollUp(500);
    final reading = h.firstVisible();
    final y = h.top(reading);
    h.messages = [..._range(0, 40), ...h.messages];
    await h.pump();
    expect(h.top(reading), closeTo(y, 0.5));
    expect(find.byType(FlareScrollToLatest), findsNothing);
  });

  testWidgets('older messages leave a bottom reader at the newest message', (
    tester,
  ) async {
    final h = _Harness(tester)..messages = _range(40, 80);
    addTearDown(h.dispose);
    await h.pump();
    final newestTop = h.top('message 79');
    h.messages = [..._range(0, 40), ...h.messages];
    await h.pump();
    expect(h.top('message 79'), closeTo(newestTop, 0.5));
    expect(h.fullyVisible('message 79'), isTrue);
  });

  testWidgets('the current user\'s own message brings a reader who scrolled '
      'up to the newest', (tester) async {
    final h = _Harness(tester)..messages = _range(0, 60);
    addTearDown(h.dispose);
    await h.pump();
    await h.scrollUp(900);
    h.messages = [...h.messages, _message(60, sender: 'me')];
    await h.pump();
    expect(h.fullyVisible('message 60'), isTrue);
    expect(find.byType(FlareScrollToLatest), findsNothing);
  });

  testWidgets('another conversation opens at its newest message', (
    tester,
  ) async {
    final h = _Harness(tester)..messages = _range(0, 60);
    addTearDown(h.dispose);
    await h.pump();
    await h.scrollUp(900);
    h
      ..conversationId = 'c2'
      ..messages = _range(100, 160);
    await h.pump();
    expect(h.fullyVisible('message 159'), isTrue);
    expect(find.byType(FlareScrollToLatest), findsNothing);
  });

  testWidgets('a shorter list keeps a bottom reader at the newest message and '
      'a reader who scrolled up at their rows', (tester) async {
    final h = _Harness(tester)..messages = _range(0, 60);
    addTearDown(h.dispose);
    await h.pump();
    h.height = 250;
    await h.pump();
    expect(h.fullyVisible('message 59'), isTrue);

    h.height = 400;
    await h.pump();
    await h.scrollUp(700);
    final reading = h.firstVisible();
    final y = h.top(reading);
    h.height = 300;
    await h.pump();
    expect(h.top(reading), closeTo(y, 0.5));
    expect(tester.takeException(), isNull);
  });
}
