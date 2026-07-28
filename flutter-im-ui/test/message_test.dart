import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

FlareMessageData _msg(
  String id,
  String sender,
  FlareMessageContent content, {
  FlareMessageDeliveryStatus status = FlareMessageDeliveryStatus.sent,
}) =>
    FlareMessageData(
      id: id,
      senderId: sender,
      senderName: sender,
      content: content,
      timeLabel: '14:32',
      status: status,
    );

void main() {
  group('FlareMessageContentView', () {
    testWidgets('renders text', (tester) async {
      await tester.pumpWidget(
        _host(const FlareMessageContentView(content: FlareTextContent('hello'))),
      );
      expect(find.text('hello'), findsOneWidget);
    });

    testWidgets('renders file name and size', (tester) async {
      await tester.pumpWidget(_host(const FlareMessageContentView(
        content: FlareFileContent(name: 'report.pdf', url: 'x', sizeBytes: 2048),
      )));
      expect(find.text('report.pdf'), findsOneWidget);
      expect(find.text('2.0 KB'), findsOneWidget);
    });

    testWidgets('unknown/generic type falls back to a labelled chip',
        (tester) async {
      await tester.pumpWidget(_host(const FlareMessageContentView(
        content: FlareGenericContent(contentType: 'vote', label: '投票: 午餐'),
      )));
      expect(find.text('[投票: 午餐]'), findsOneWidget);
    });

    testWidgets('registry override renders a custom type', (tester) async {
      FlareContentRegistry.register(
        'vote',
        (context, content, ctx) => const Text('CUSTOM-VOTE'),
      );
      addTearDown(() => FlareContentRegistry.unregister('vote'));
      await tester.pumpWidget(_host(const FlareMessageContentView(
        content: FlareGenericContent(contentType: 'vote', label: 'x'),
      )));
      expect(find.text('CUSTOM-VOTE'), findsOneWidget);
    });
  });

  group('FlareMessageBubble', () {
    testWidgets('own message shows delivery status', (tester) async {
      await tester.pumpWidget(_host(FlareMessageBubble(
        message: _msg('m1', 'me', const FlareTextContent('hi'),
            status: FlareMessageDeliveryStatus.read),
        currentUserId: 'me',
      )));
      expect(find.byIcon(Icons.done_all), findsOneWidget);
    });

    testWidgets("other's message shows no status tick", (tester) async {
      await tester.pumpWidget(_host(FlareMessageBubble(
        message: _msg('m1', 'bob', const FlareTextContent('hi')),
        currentUserId: 'me',
      )));
      expect(find.byIcon(Icons.done_all), findsNothing);
      expect(find.byIcon(Icons.check), findsNothing);
    });

    testWidgets('system/notification message renders centred, no bubble',
        (tester) async {
      await tester.pumpWidget(_host(FlareMessageBubble(
        message: _msg('m1', 'sys',
            const FlareNotificationContent('Bob 加入了群聊')),
        currentUserId: 'me',
      )));
      expect(find.text('Bob 加入了群聊'), findsOneWidget);
    });

    testWidgets('failed status is tappable to resend', (tester) async {
      var resent = false;
      await tester.pumpWidget(_host(FlareMessageBubble(
        message: _msg('m1', 'me', const FlareTextContent('hi'),
            status: FlareMessageDeliveryStatus.failed),
        currentUserId: 'me',
        onResend: (_) => resent = true,
      )));
      await tester.tap(find.byIcon(Icons.error_outline));
      expect(resent, isTrue);
    });
  });

  group('FlareMessageList', () {
    testWidgets('empty shows placeholder', (tester) async {
      await tester.pumpWidget(_host(const FlareMessageList(
        messages: [],
        currentUserId: 'me',
        emptyText: 'No messages yet',
      )));
      expect(find.text('No messages yet'), findsOneWidget);
    });

    testWidgets('renders each message', (tester) async {
      await tester.pumpWidget(_host(FlareMessageList(
        currentUserId: 'me',
        messages: [
          _msg('m1', 'bob', const FlareTextContent('one')),
          _msg('m2', 'me', const FlareTextContent('two')),
        ],
      )));
      expect(find.text('one'), findsOneWidget);
      expect(find.text('two'), findsOneWidget);
    });

    testWidgets('long-press reports the message', (tester) async {
      FlareMessageData? pressed;
      await tester.pumpWidget(_host(FlareMessageList(
        currentUserId: 'me',
        messages: [_msg('m1', 'bob', const FlareTextContent('one'))],
        onMessageLongPress: (m) => pressed = m,
      )));
      await tester.longPress(find.text('one'));
      expect(pressed?.id, 'm1');
    });
  });

  group('FlarePinnedMessageBar', () {
    testWidgets('empty renders nothing', (tester) async {
      await tester.pumpWidget(
        _host(const FlarePinnedMessageBar(items: [])),
      );
      expect(find.byIcon(Icons.push_pin_outlined), findsNothing);
    });

    testWidgets('tap focuses and cycles through many', (tester) async {
      final focused = <String>[];
      await tester.pumpWidget(_host(FlarePinnedMessageBar(
        items: const [
          FlarePinnedMessage(id: 'p1', summary: 'first'),
          FlarePinnedMessage(id: 'p2', summary: 'second'),
        ],
        onFocus: (i) => focused.add(i.id),
      )));
      expect(find.text('first'), findsOneWidget);
      expect(find.text('1/2'), findsOneWidget);
      await tester.tap(find.text('first'));
      await tester.pump();
      expect(focused, ['p1']);
      expect(find.text('second'), findsOneWidget);
    });
  });

  testWidgets('FlareChatHeader shows title and fires actions', (tester) async {
    var searched = false;
    await tester.pumpWidget(_host(FlareChatHeader(
      title: 'Team Flare',
      subtitle: '在线',
      presence: FlarePresence.online,
      onSearch: () => searched = true,
    )));
    expect(find.text('Team Flare'), findsOneWidget);
    expect(find.text('在线'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.search_rounded));
    expect(searched, isTrue);
  });
}
