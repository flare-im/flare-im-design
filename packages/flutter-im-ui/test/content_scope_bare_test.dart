import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A host registers the surface of a content key the kit does not know
/// (`spec/message-surface-vectors.json` rules.registration); custom and plugin
/// content is a card without registering anything. Every builder learns which
/// message and conversation it draws.
void main() {
  const bubblePadding = EdgeInsets.symmetric(
    horizontal: FlareSizes.componentBubblePaddingX,
    vertical: FlareSizes.componentBubblePaddingY,
  );
  final framed = find.byWidgetPredicate(
    (w) => w is Padding && w.padding == bubblePadding,
  );

  FlareMessageData message({
    String? serverId = 'server-1',
    String type = 'packet',
    String senderName = 'Ivy',
  }) => FlareMessageData(
    id: 'client-1',
    serverId: serverId,
    senderId: 'ivy',
    senderName: senderName,
    timeLabel: '10:02',
    content: FlareGenericContent(contentType: type, label: 'Red packet'),
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

  testWidgets('a builder learns the sender: its id, and its name trimmed or '
      'none', (tester) async {
    for (final (name, expected) in [
      ('  Ivy  ', 'Ivy'),
      ('   ', null),
      ('', null),
    ]) {
      await tester.pumpWidget(
        host(
          FlareContentScope(
            builders: {'packet': probe},
            child: FlareMessageBubble(
              message: message(senderName: name),
              currentUserId: 'me',
            ),
          ),
        ),
      );
      expect(seen?.senderId, 'ivy');
      // Never the id or a placeholder word in place of a missing name.
      expect(seen?.senderName, expected, reason: '"$name"');
    }
  });

  testWidgets('a key registered as a card loses the bubble and keeps the time', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        FlareContentScope(
          builders: {'packet': probe},
          surfaces: const {'packet': FlareMessageSurface.card},
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
    expect(seen?.surface, FlareMessageSurface.card);
  });

  testWidgets('a custom subtype is a card without registering anything', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        FlareContentScope(
          builders: {'custom': probe},
          child: FlareMessageBubble(
            message: message(type: 'custom:flare.plugin.message.v1'),
            currentUserId: 'me',
          ),
        ),
      ),
    );
    expect(find.byKey(const Key('probe')), findsOneWidget);
    expect(framed, findsNothing);
    expect(find.byKey(FlareMessageBubble.bubbleSurfaceKey), findsNothing);
  });

  testWidgets('an unknown key without a registration keeps the bubble', (
    tester,
  ) async {
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

  testWidgets('the global registry takes a surface too, and unregister clears it', (
    tester,
  ) async {
    FlareContentRegistry.register(
      'packet',
      probe,
      surface: FlareMessageSurface.bareMedia,
    );
    addTearDown(() => FlareContentRegistry.unregister('packet'));
    await tester.pumpWidget(
      host(FlareMessageBubble(message: message(), currentUserId: 'me')),
    );
    expect(framed, findsNothing);
    expect(
      FlareContentRegistry.surfaceOf('packet'),
      FlareMessageSurface.bareMedia,
    );
    FlareContentRegistry.unregister('packet');
    expect(FlareContentRegistry.surfaceOf('packet'), isNull);
  });

  testWidgets('a scope builder decides over a global registration', (
    tester,
  ) async {
    FlareContentRegistry.register(
      'packet',
      probe,
      surface: FlareMessageSurface.bareMedia,
    );
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

  testWidgets('a registered bare media with a quote goes back in a bubble', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        FlareContentScope(
          builders: {'custom': probe},
          surfaces: const {'custom:acme.gif': FlareMessageSurface.bareMedia},
          child: FlareMessageBubble(
            message: FlareMessageData(
              id: 'q',
              senderId: 'ivy',
              senderName: 'Ivy',
              content: const FlareGenericContent(
                contentType: 'custom:acme.gif',
                label: 'gif',
              ),
              replyTo: const FlareReplyTarget(senderName: 'Bo', summary: 'hi'),
            ),
            currentUserId: 'me',
          ),
        ),
      ),
    );
    expect(find.byKey(FlareMessageBubble.bubbleSurfaceKey), findsOneWidget);
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
