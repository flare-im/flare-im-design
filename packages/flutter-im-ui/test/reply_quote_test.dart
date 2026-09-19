import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child, {bool reduceMotion = false}) => MaterialApp(
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
      child: Scaffold(body: child),
    ),
  ),
);

FlareMessageData _message(
  String id, {
  String sender = 'ann',
  String? serverId,
  FlareMessageContent? content,
  FlareReplyTarget? replyTo,
}) => FlareMessageData(
  id: id,
  serverId: serverId,
  senderId: sender,
  senderName: sender,
  content: content ?? FlareTextContent('message $id'),
  replyTo: replyTo,
);

const _quote = FlareReplyTarget(
  senderName: 'Bob',
  summary: 'see you at nine',
  messageId: 'm0',
);

void main() {
  group('FlareMessageBubble quote', () {
    testWidgets('shows who said what, and drops an unknown sender line', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              FlareMessageBubble(
                message: _message('m1', replyTo: _quote),
                currentUserId: 'me',
              ),
              FlareMessageBubble(
                message: _message(
                  'm2',
                  replyTo: const FlareReplyTarget(
                    senderName: '',
                    summary: 'no name here',
                  ),
                ),
                currentUserId: 'me',
              ),
            ],
          ),
        ),
      );
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('see you at nine'), findsOneWidget);
      expect(find.text('no name here'), findsOneWidget);
      expect(find.text('message m1'), findsOneWidget);
      expect(find.text('message m2'), findsOneWidget);
    });

    testWidgets('is a named button that locates the quoted message', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final located = <String>[];
      await tester.pumpWidget(
        _host(
          FlareMessageBubble(
            message: _message('m1', replyTo: _quote),
            currentUserId: 'me',
            onLocateMessage: located.add,
          ),
        ),
      );
      final label = const FlareStrings().quotedMessage(
        'Bob',
        'see you at nine',
      );
      expect(
        tester.getSemantics(find.bySemanticsLabel(label)),
        isSemantics(isButton: true, hasTapAction: true),
      );
      expect(
        tester.getSize(find.bySemanticsLabel(label)).height,
        greaterThanOrEqualTo(FlareSizes.touchTarget),
      );
      await tester.tap(find.text('see you at nine'));
      expect(located, ['m0']);
      semantics.dispose();
    });

    testWidgets('is plain text without an id, a callback or while selecting', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final label = const FlareStrings().quotedMessage(
        'Bob',
        'see you at nine',
      );
      for (final bubble in [
        FlareMessageBubble(
          message: _message('m1', replyTo: _quote),
          currentUserId: 'me',
        ),
        FlareMessageBubble(
          message: _message(
            'm1',
            replyTo: const FlareReplyTarget(
              senderName: 'Bob',
              summary: 'see you at nine',
            ),
          ),
          currentUserId: 'me',
          onLocateMessage: (_) {},
        ),
        FlareMessageBubble(
          message: _message('m1', replyTo: _quote),
          currentUserId: 'me',
          multiSelectMode: true,
          onLocateMessage: (_) => fail('selecting must not locate'),
        ),
      ]) {
        await tester.pumpWidget(_host(bubble));
        expect(find.bySemanticsLabel(label), findsNothing);
        expect(find.text('see you at nine'), findsOneWidget);
      }
      await tester.tap(find.text('see you at nine'));
      semantics.dispose();
    });

    testWidgets('keeps the bubble frame around quoted media', (tester) async {
      final fill = FlareColors.resolve(
        Brightness.light,
      ).messageIncomingBackground;
      Finder frame() => find.byWidgetPredicate(
        (widget) =>
            widget is DecoratedBox &&
            widget.decoration is BoxDecoration &&
            (widget.decoration as BoxDecoration).color == fill,
      );
      await tester.pumpWidget(
        _host(
          FlareMessageBubble(
            message: _message('m1', content: const FlareEmojiContent('🙂')),
            currentUserId: 'me',
          ),
        ),
      );
      expect(frame(), findsNothing);
      await tester.pumpWidget(
        _host(
          FlareMessageBubble(
            message: _message(
              'm1',
              content: const FlareEmojiContent('🙂'),
              replyTo: _quote,
            ),
            currentUserId: 'me',
          ),
        ),
      );
      expect(frame(), findsOneWidget);
      expect(find.text('see you at nine'), findsOneWidget);
    });

    testWidgets('never shows on recalled messages or notices', (tester) async {
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              FlareMessageBubble(
                message: FlareMessageData(
                  id: 'm1',
                  senderId: 'ann',
                  senderName: 'ann',
                  content: const FlareTextContent('gone'),
                  lifecycle: const FlareMessageLifecycle(
                    mutation: FlareMessageMutationState.recalled,
                  ),
                  replyTo: _quote,
                ),
                currentUserId: 'me',
              ),
              FlareMessageBubble(
                message: _message(
                  'm2',
                  content: const FlareNotificationContent('joined'),
                  replyTo: _quote,
                ),
                currentUserId: 'me',
              ),
            ],
          ),
        ),
      );
      expect(find.text('see you at nine'), findsNothing);
    });
  });

  group('FlareMessageList locate', () {
    List<FlareMessageData> thread({required String quoted}) => [
      for (var i = 0; i < 80; i++) _message('m$i'),
      _message(
        'last',
        replyTo: FlareReplyTarget(
          senderName: 'ann',
          summary: 'the quote',
          messageId: quoted,
        ),
      ),
    ];

    Future<FlareMessageListController> pumpAtBottom(
      WidgetTester tester, {
      required List<FlareMessageData> messages,
      ValueChanged<String>? onLocateMessage,
      bool reduceMotion = false,
    }) async {
      tester.view.physicalSize = const Size(400, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final controller = FlareMessageListController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        _host(
          FlareMessageList(
            // A list of its own each time, opened at the newest message.
            key: UniqueKey(),
            messages: messages,
            currentUserId: 'me',
            controller: controller,
            onLocateMessage: onLocateMessage,
          ),
          reduceMotion: reduceMotion,
        ),
      );
      // The list opens at the newest message.
      await tester.pumpAndSettle();
      expect(find.text('message m0'), findsNothing);
      return controller;
    }

    bool onScreen(WidgetTester tester, Finder finder) {
      if (finder.evaluate().isEmpty) return false;
      final rect = tester.getRect(finder);
      final list = tester.getRect(find.byType(CustomScrollView));
      return rect.top >= list.top && rect.bottom <= list.bottom;
    }

    /// The same thread with one row as a host draws a message this device
    /// sent: keyed by the client id, while the core — and every quote of it —
    /// names it 's40'. A row far below it carries a core id that collides with
    /// that row key, which a row's own id has to outrank.
    List<FlareMessageData> selfSentThread({required String quoted}) =>
        thread(quoted: quoted)
          ..[40] = _message('c40', sender: 'me', serverId: 's40')
          ..[5] = _message('m5', serverId: 'c40');

    testWidgets('scrolls a loaded quoted message into view without the host', (
      tester,
    ) async {
      final host = <String>[];
      await pumpAtBottom(
        tester,
        messages: thread(quoted: 'm0'),
        onLocateMessage: host.add,
      );
      await tester.tap(find.text('the quote'));
      await tester.pumpAndSettle();
      expect(onScreen(tester, find.text('message m0')), isTrue);
      expect(host, isEmpty);
    });

    testWidgets('asks the host for a quoted message that is not loaded', (
      tester,
    ) async {
      final host = <String>[];
      await pumpAtBottom(
        tester,
        messages: thread(quoted: 'older'),
        onLocateMessage: host.add,
      );
      await tester.tap(find.text('the quote'));
      await tester.pumpAndSettle();
      expect(host, ['older']);
    });

    testWidgets('a quote naming a loaded row by its core id is the list\'s own '
        'to show, and never reaches the host', (tester) async {
      // The row id and the core id differ for a message this device sent; the
      // quote carries the core's. Reading only the row keys reports a message
      // that is right there as one the host has to go and find.
      final host = <String>[];
      await pumpAtBottom(
        tester,
        messages: selfSentThread(quoted: 's40'),
        onLocateMessage: host.add,
      );
      expect(onScreen(tester, find.text('message c40')), isFalse);
      await tester.tap(find.text('the quote'));
      await tester.pumpAndSettle();
      expect(onScreen(tester, find.text('message c40')), isTrue);
      expect(host, isEmpty, reason: 'the row is loaded, under its other id');
    });

    testWidgets('a quote naming a loaded row by its core id is a control '
        'without a host callback', (tester) async {
      // Same rule, the other reader of it: the quote is a button because some
      // row answers to that id, not because a host stands ready to be asked.
      final semantics = tester.ensureSemantics();
      await pumpAtBottom(tester, messages: selfSentThread(quoted: 's40'));
      expect(
        tester.getSemantics(
          find.bySemanticsLabel(
            const FlareStrings().quotedMessage('ann', 'the quote'),
          ),
        ),
        isSemantics(isButton: true, hasTapAction: true),
      );
      semantics.dispose();
    });

    testWidgets('scrollToMessage takes either of a row\'s two ids', (
      tester,
    ) async {
      // The host hands back whichever id the quote reported, unchanged.
      final byCoreId = await pumpAtBottom(
        tester,
        messages: selfSentThread(quoted: 's40'),
      );
      expect(byCoreId.scrollToMessage('s40'), isTrue);
      await tester.pumpAndSettle();
      expect(onScreen(tester, find.text('message c40')), isTrue);

      final byRowId = await pumpAtBottom(
        tester,
        messages: selfSentThread(quoted: 's40'),
      );
      expect(byRowId.scrollToMessage('c40'), isTrue);
      await tester.pumpAndSettle();
      expect(
        onScreen(tester, find.text('message c40')),
        isTrue,
        reason: 'a row key outranks the core id of the row below it',
      );
      expect(onScreen(tester, find.text('message m5')), isFalse);
    });

    testWidgets('the host reads the history and shows the message itself, '
        'without a second tap', (tester) async {
      // The list reports the miss once and never scrolls to an unloaded row on
      // its own; the host pages that history in and finishes the same tap with
      // `scrollToMessage`.
      tester.view.physicalSize = const Size(400, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final controller = FlareMessageListController();
      addTearDown(controller.dispose);
      final host = <String>[];
      var messages = thread(quoted: 'older');
      late StateSetter rebuild;
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return FlareMessageList(
                key: const ValueKey('one list across the host page'),
                messages: messages,
                currentUserId: 'me',
                controller: controller,
                onLocateMessage: host.add,
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('the quote'));
      await tester.pumpAndSettle();
      expect(host, ['older'], reason: 'the quoted row is not loaded');
      expect(
        controller.scrollToMessage('older'),
        isFalse,
        reason: 'the host has not read that history yet',
      );

      // The host pages the older history in; the list stays at the newest.
      rebuild(() => messages = [_message('older'), ...messages]);
      await tester.pumpAndSettle();
      expect(onScreen(tester, find.text('message older')), isFalse);

      // The same tap ends here: the host asks for the row it just read.
      expect(controller.scrollToMessage('older'), isTrue);
      await tester.pumpAndSettle();
      expect(onScreen(tester, find.text('message older')), isTrue);
      expect(host, ['older'], reason: 'the host is not asked twice');
    });

    testWidgets('scrollToMessage shows a row far above the window, on the '
        'anchor a tapped quote uses', (tester) async {
      final controller = await pumpAtBottom(
        tester,
        messages: thread(quoted: 'm0'),
      );
      expect(onScreen(tester, find.text('message m40')), isFalse);

      expect(controller.scrollToMessage('m40'), isTrue);
      await tester.pumpAndSettle();
      expect(onScreen(tester, find.text('message m40')), isTrue);
      // The list's own locate centres the row; so does the host's.
      expect(
        tester.getRect(find.byKey(const ValueKey('m40'))).center.dy,
        closeTo(tester.getRect(find.byType(CustomScrollView)).center.dy, 8),
      );
    });

    testWidgets('scrollToMessage animates to a nearby row, and jumps under '
        'reduced motion', (tester) async {
      // The same rows and the same assertions as the tapped quote above it:
      // the handle is that path's entrance, not a second implementation.
      final messages = thread(quoted: 'm0');
      final animated = await pumpAtBottom(tester, messages: messages);
      expect(onScreen(tester, find.text('message m64')), isFalse);
      expect(animated.scrollToMessage('m64'), isTrue);
      await tester.pump();
      expect(animated.scroll.position.isScrollingNotifier.value, isTrue);
      await tester.pumpAndSettle();
      expect(onScreen(tester, find.text('message m64')), isTrue);

      final still = await pumpAtBottom(
        tester,
        messages: [...messages],
        reduceMotion: true,
      );
      expect(still.scrollToMessage('m64'), isTrue);
      await tester.pump();
      expect(still.scroll.position.isScrollingNotifier.value, isFalse);
      expect(onScreen(tester, find.text('message m64')), isTrue);
    });

    testWidgets('scrollToMessage says no for a message that is not loaded, and '
        'nothing moves', (tester) async {
      final controller = await pumpAtBottom(
        tester,
        messages: thread(quoted: 'm0'),
      );
      final offset = controller.scroll.position.pixels;
      expect(controller.scrollToMessage('older'), isFalse);
      expect(controller.scrollToMessage(''), isFalse);
      await tester.pumpAndSettle();
      expect(controller.scroll.position.pixels, offset);
      expect(tester.takeException(), isNull);
    });

    testWidgets('scrollToMessage is false before a list is built and after it '
        'is gone', (tester) async {
      tester.view.physicalSize = const Size(400, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final controller = FlareMessageListController();
      addTearDown(controller.dispose);
      // The host may ask before it builds the list, and must not be punished.
      expect(controller.scrollToMessage('m40'), isFalse);

      await tester.pumpWidget(
        _host(
          FlareMessageList(
            messages: thread(quoted: 'm0'),
            currentUserId: 'me',
            controller: controller,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(controller.scrollToMessage('m40'), isTrue);
      await tester.pumpAndSettle();

      // The handle outlives the list; it then answers for no rows at all.
      await tester.pumpWidget(_host(const SizedBox()));
      await tester.pumpAndSettle();
      expect(controller.scrollToMessage('m40'), isFalse);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a row shown on request leaves the tail, so the next message '
        'does not pull the reader back', (tester) async {
      tester.view.physicalSize = const Size(400, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final controller = FlareMessageListController();
      addTearDown(controller.dispose);
      var messages = thread(quoted: 'm0');
      late StateSetter rebuild;
      await tester.pumpWidget(
        _host(
          StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return FlareMessageList(
                messages: messages,
                currentUserId: 'me',
                controller: controller,
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(controller.scrollToMessage('m40'), isTrue);
      await tester.pumpAndSettle();
      // The row's place on screen, not the offset: the list re-pivots around
      // the row being read, so its scroll offset is measured from elsewhere.
      final reading = tester.getTopLeft(find.byKey(const ValueKey('m40'))).dy;

      rebuild(() => messages = [...messages, _message('newest')]);
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('m40'))).dy,
        closeTo(reading, 1),
      );
      expect(onScreen(tester, find.text('message m40')), isTrue);
      expect(find.byType(FlareScrollToLatest), findsOneWidget);
    });

    testWidgets('an unloaded quote without a host callback is not a control', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpAtBottom(tester, messages: thread(quoted: 'older'));
      expect(
        find.bySemanticsLabel(
          const FlareStrings().quotedMessage('ann', 'the quote'),
        ),
        findsNothing,
      );
      semantics.dispose();
    });

    testWidgets('animates to a nearby row, and jumps under reduced motion', (
      tester,
    ) async {
      // Just above the rows in view at the newest message: built, not shown.
      final messages = thread(quoted: 'm64');
      final animated = await pumpAtBottom(tester, messages: messages);
      expect(onScreen(tester, find.text('message m64')), isFalse);
      await tester.tap(find.text('the quote'));
      await tester.pump();
      expect(animated.scroll.position.isScrollingNotifier.value, isTrue);
      await tester.pumpAndSettle();
      expect(onScreen(tester, find.text('message m64')), isTrue);

      final still = await pumpAtBottom(
        tester,
        messages: [...messages],
        reduceMotion: true,
      );
      await tester.tap(find.text('the quote'));
      await tester.pump();
      expect(still.scroll.position.isScrollingNotifier.value, isFalse);
      expect(onScreen(tester, find.text('message m64')), isTrue);
    });
  });
}
