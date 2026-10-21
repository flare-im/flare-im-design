import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A custom content builder can ask to be drawn without a bubble (`bare`),
/// and every builder learns which message and conversation it draws.
void main() {
  const bubblePadding = EdgeInsets.symmetric(
    horizontal: FlareSizes.componentBubblePaddingX,
    vertical: FlareSizes.componentBubblePaddingY,
  );
  final framed = find.byWidgetPredicate(
    (w) => w is Padding && w.padding == bubblePadding,
  );

  FlareMessageData message({String? serverId = 'server-1'}) => FlareMessageData(
    id: 'client-1',
    serverId: serverId,
    senderId: 'ivy',
    senderName: 'Ivy',
    timeLabel: '10:02',
    content: const FlareGenericContent(
      contentType: 'packet',
      label: 'Red packet',
    ),
  );

  FlareContentContext? seen;
  Widget probe(
    BuildContext context,
    FlareMessageContent content,
    FlareContentContext ctx,
  ) {
    seen = ctx;
    return const SizedBox(key: Key('probe'), width: 120, height: 60);
  }

  Widget host(Widget child) => MaterialApp(
    home: Scaffold(body: Center(child: child)),
  );

  setUp(() => seen = null);

  testWidgets('a builder registered bare loses the bubble and keeps the time', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        FlareContentScope(
          builders: {'packet': probe},
          bareTypes: const {'packet'},
          child: FlareMessageBubble(
            message: message(),
            currentUserId: 'me',
            conversationId: 'conv-9',
          ),
        ),
      ),
    );
    expect(find.byKey(const Key('probe')), findsOneWidget);
    expect(framed, findsNothing);
    expect(find.text('10:02'), findsOneWidget);
  });

  testWidgets('a builder without bare keeps the bubble', (tester) async {
    await tester.pumpWidget(
      host(
        FlareContentScope(
          builders: {'packet': probe},
          child: FlareMessageBubble(message: message(), currentUserId: 'me'),
        ),
      ),
    );
    expect(find.byKey(const Key('probe')), findsOneWidget);
    expect(framed, findsOneWidget);
  });

  testWidgets('the global registry takes bare too, and unregister clears it', (
    tester,
  ) async {
    FlareContentRegistry.register('packet', probe, bare: true);
    addTearDown(() => FlareContentRegistry.unregister('packet'));
    await tester.pumpWidget(
      host(FlareMessageBubble(message: message(), currentUserId: 'me')),
    );
    expect(framed, findsNothing);
    expect(FlareContentRegistry.isBare('packet'), isTrue);
    FlareContentRegistry.unregister('packet');
    expect(FlareContentRegistry.isBare('packet'), isFalse);
  });

  testWidgets('a scope builder decides over a bare global one', (tester) async {
    FlareContentRegistry.register('packet', probe, bare: true);
    addTearDown(() => FlareContentRegistry.unregister('packet'));
    await tester.pumpWidget(
      host(
        FlareContentScope(
          builders: {'packet': probe},
          child: FlareMessageBubble(message: message(), currentUserId: 'me'),
        ),
      ),
    );
    expect(framed, findsOneWidget);
  });

  testWidgets('builders receive the server id and the conversation', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        FlareContentScope(
          builders: {'packet': probe},
          child: FlareMessageBubble(
            message: message(),
            currentUserId: 'me',
            conversationId: 'conv-9',
          ),
        ),
      ),
    );
    expect(seen?.messageId, 'server-1');
    expect(seen?.conversationId, 'conv-9');

    await tester.pumpWidget(
      host(
        FlareContentScope(
          builders: {'packet': probe},
          child: FlareMessageBubble(
            message: message(serverId: null),
            currentUserId: 'me',
          ),
        ),
      ),
    );
    expect(seen?.messageId, 'client-1');
    expect(seen?.conversationId, isNull);
  });

  testWidgets('the message list hands its conversation to the builders', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        FlareContentScope(
          builders: {'packet': probe},
          child: SizedBox(
            width: 390,
            height: 600,
            child: FlareMessageList(
              conversationId: 'conv-list',
              currentUserId: 'me',
              messages: [message()],
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(seen?.conversationId, 'conv-list');
    expect(seen?.messageId, 'server-1');
  });
}
