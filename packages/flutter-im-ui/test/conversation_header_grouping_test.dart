import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

FlareMessageData message(
  String id,
  String sender,
  int time, {
  bool system = false,
}) => FlareMessageData(
  id: id,
  senderId: sender,
  senderName: sender,
  sentAtMs: time,
  content: system
      ? const FlareNotificationContent('boundary')
      : const FlareTextContent('hello'),
);

void main() {
  const group = FlareConversationIdentity(
    id: 'g1',
    title: 'Product room',
    kind: FlareConversationHeaderKind.group,
  );

  test(
    'header actions resolve defaults, capabilities and host configuration',
    () {
      final resolved = resolveConversationHeaderActions(
        identity: group,
        capabilities: const FlareConversationHeaderCapabilities(
          availableActionIds: {'search', 'addMember', 'share', 'task', 'pin'},
        ),
        configuration: const FlareConversationHeaderConfiguration(
          removeActionIds: {'share'},
          actionOverrides: [
            FlareConversationHeaderAction(
              id: 'addMember',
              label: 'Invite people',
              icon: 'person-add',
              placement: FlareConversationHeaderActionPlacement.add,
              order: 30,
              enabled: false,
              disabledReason: 'Read only',
            ),
          ],
        ),
        actions: const [
          FlareConversationHeaderAction(
            id: 'pin',
            label: 'Pin',
            placement: FlareConversationHeaderActionPlacement.primary,
            order: 5,
          ),
          FlareConversationHeaderAction(
            id: 'task',
            label: 'Create task',
            placement: FlareConversationHeaderActionPlacement.add,
            order: 40,
          ),
        ],
      );

      expect(resolved.map((action) => action.id), [
        'pin',
        'search',
        'addMember',
        'task',
      ]);
      expect(resolved[2].enabled, isFalse);
      expect(resolved[2].label, 'Invite people');
    },
  );

  testWidgets('compact header moves excess primary actions into More', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 360,
            child: FlareConversationHeader(identity: group, onAction: _ignore),
          ),
        ),
      ),
    );
    expect(find.text('Product room'), findsOneWidget);
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    expect(find.byIcon(Icons.more_horiz_rounded), findsOneWidget);
  });

  test('message grouping covers sender, time and system boundaries', () {
    final messages = [
      message('1', 'ivy', 1000),
      message('2', 'ivy', 2000),
      message('3', 'ivy', 400000),
      message('4', 'system', 401000, system: true),
      message('5', 'ivy', 402000),
      message('6', 'me', 403000),
    ];
    expect(
      flareMessageGroupPosition(messages, 0),
      FlareMessageGroupPosition.first,
    );
    expect(
      flareMessageGroupPosition(messages, 1),
      FlareMessageGroupPosition.last,
    );
    expect(
      flareMessageGroupPosition(messages, 2),
      FlareMessageGroupPosition.single,
    );
    expect(
      flareMessageGroupPosition(messages, 3),
      FlareMessageGroupPosition.single,
    );
    expect(
      flareMessageGroupPosition(messages, 4),
      FlareMessageGroupPosition.single,
    );

    // A recalled message is a notice: it stands alone and ends the sender's run.
    final recalledRun = [
      message('r1', 'ivy', 1000),
      message('r2', 'ivy', 2000),
      FlareMessageData(
        id: 'r3',
        senderId: 'ivy',
        senderName: 'ivy',
        sentAtMs: 3000,
        content: const FlareTextContent('gone'),
        lifecycle: const FlareMessageLifecycle(
          mutation: FlareMessageMutationState.recalled,
        ),
      ),
      message('r4', 'ivy', 4000),
    ];
    expect(
      [
        for (var i = 0; i < recalledRun.length; i++)
          flareMessageGroupPosition(recalledRun, i),
      ],
      [
        FlareMessageGroupPosition.first,
        FlareMessageGroupPosition.last,
        FlareMessageGroupPosition.single,
        FlareMessageGroupPosition.single,
      ],
    );

    final incoming = flareMessageRowPresentation(
      message: messages.first,
      position: FlareMessageGroupPosition.first,
      currentUserId: 'me',
      groupConversation: true,
    );
    final outgoing = flareMessageRowPresentation(
      message: messages.last,
      position: FlareMessageGroupPosition.single,
      currentUserId: 'me',
      groupConversation: true,
    );
    expect(incoming.showAvatar, isTrue);
    expect(incoming.showSenderName, isTrue);
    expect(incoming.reserveAvatarSpace, isTrue);
    expect(outgoing.showAvatar, isFalse);
    expect(outgoing.showSenderName, isFalse);
  });
}

void _ignore(FlareConversationHeaderAction action) {}
