import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// Lifecycle mutation and reactions as the thread renders them; fixtures only.

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

const _strings = FlareStrings();
const _recalled = FlareMessageLifecycle(
  mutation: FlareMessageMutationState.recalled,
);

FlareMessageData _message(
  String id,
  String sender,
  String text, {
  FlareMessageLifecycle? lifecycle,
  List<FlareReactionGroup> reactions = const [],
}) => FlareMessageData(
  id: id,
  senderId: sender,
  senderName: sender == 'me' ? 'Me' : 'Ann',
  content: FlareTextContent(text),
  lifecycle: lifecycle,
  reactions: reactions,
);

void main() {
  group('recalled messages', () {
    testWidgets('show a notice instead of their content and take no actions', (
      tester,
    ) async {
      final pressed = <String>[];
      await tester.pumpWidget(
        _host(
          FlareMessageList(
            currentUserId: 'me',
            conversationKind: FlareConversationKind.group,
            messages: [
              _message('1', 'ann', 'secret A', lifecycle: _recalled),
              _message('2', 'me', 'secret B', lifecycle: _recalled),
              _message('3', 'ann', 'still here'),
            ],
            onMessageLongPress: (message) => pressed.add(message.id),
            onSwipeReply: (_) {},
          ),
        ),
      );
      expect(find.textContaining('secret'), findsNothing);
      expect(_strings.messageRecalledGroupOther('Ann'), contains('Ann'));
      final groupOther = find.text(_strings.messageRecalledGroupOther('Ann'));
      expect(groupOther, findsOneWidget);
      expect(find.text(_strings.messageRecalledSelf), findsOneWidget);

      expect(find.byKey(const ValueKey('swipe-reply-1')), findsNothing);
      expect(find.byKey(const ValueKey('swipe-reply-2')), findsNothing);
      expect(find.byKey(const ValueKey('swipe-reply-3')), findsOneWidget);
      await tester.longPress(groupOther);
      await tester.longPress(find.text(_strings.messageRecalledSelf));
      await tester.longPress(find.text('still here'));
      expect(pressed, ['3']);
    });

    testWidgets('read as the peer in a single chat, without status, avatar '
        'or selection', (tester) async {
      final toggled = <String>[];
      await tester.pumpWidget(
        _host(
          Column(
            children: [
              FlareMessageBubble(
                message: _message('1', 'ann', 'secret A', lifecycle: _recalled),
                currentUserId: 'me',
                rowPresentation: const FlareMessageRowPresentation(
                  showAvatar: true,
                  reserveAvatarSpace: true,
                ),
                multiSelectMode: true,
                onToggleSelect: (message) => toggled.add(message.id),
              ),
              FlareMessageBubble(
                message: _message('2', 'me', 'secret B', lifecycle: _recalled),
                currentUserId: 'me',
                multiSelectMode: true,
                onToggleSelect: (message) => toggled.add(message.id),
              ),
            ],
          ),
        ),
      );
      expect(find.textContaining('secret'), findsNothing);
      expect(find.text(_strings.messageRecalledPeer), findsOneWidget);
      expect(find.text(_strings.messageRecalledSelf), findsOneWidget);
      expect(find.byType(FlareAvatar), findsNothing);
      expect(find.byType(FlareMessageStatus), findsNothing);
      expect(find.byIcon(Icons.radio_button_unchecked), findsNothing);
      await tester.tap(find.text(_strings.messageRecalledPeer));
      expect(toggled, isEmpty);
    });
  });

  group('reactions', () {
    const reactions = [
      FlareReactionGroup(emoji: '👍', count: 2, reactedBySelf: true),
      FlareReactionGroup(emoji: '🎉', count: 1),
    ];

    testWidgets('pills toggle the current user reaction', (tester) async {
      final toggled = <(String, String)>[];
      await tester.pumpWidget(
        _host(
          FlareMessageList(
            currentUserId: 'me',
            messages: [
              _message('1', 'ann', 'shipped', reactions: reactions),
              _message(
                '2',
                'me',
                'got it',
                reactions: const [FlareReactionGroup(emoji: '❤️', count: 1)],
              ),
            ],
            onReact: (message, emoji) => toggled.add((message.id, emoji)),
          ),
        ),
      );
      await tester.tap(find.text('🎉 1'));
      await tester.tap(find.text('❤️ 1'));
      expect(toggled, [('1', '🎉'), ('2', '❤️')]);
    });

    testWidgets('pills are display-only without a handler', (tester) async {
      await tester.pumpWidget(
        _host(
          FlareMessageList(
            currentUserId: 'me',
            messages: [_message('1', 'ann', 'shipped', reactions: reactions)],
          ),
        ),
      );
      expect(find.text('👍 2'), findsOneWidget);
      // Labels, not disabled buttons: nothing to announce as a control.
      expect(find.byType(TextButton), findsNothing);
    });

    testWidgets('pills do not toggle in multi-select mode', (tester) async {
      final toggled = <String>[];
      await tester.pumpWidget(
        _host(
          FlareMessageList(
            currentUserId: 'me',
            multiSelectMode: true,
            messages: [_message('1', 'ann', 'shipped', reactions: reactions)],
            onReact: (message, emoji) => toggled.add(emoji),
          ),
        ),
      );
      expect(find.byType(TextButton), findsNothing);
      expect(toggled, isEmpty);
    });
  });
}
