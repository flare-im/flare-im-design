import 'dart:convert';
import 'dart:io';
import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('canonical swipe emits only enabled host-approved actions', (
    tester,
  ) async {
    final actions = <FlareConversationAction>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 360,
              child: FlareConversationRow(
                item: const ConversationRowData(
                  id: 'swipe',
                  title: 'Swipe conversation',
                ),
                swipeActions: const [
                  FlareConversationSwipeAction(
                    FlareConversationAction.pin,
                    'Pin',
                  ),
                  FlareConversationSwipeAction(
                    FlareConversationAction.delete,
                    'Delete',
                    enabled: false,
                  ),
                ],
                onAction: actions.add,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.drag(find.text('Swipe conversation'), const Offset(-220, 0));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete'));
    expect(actions, isEmpty);
    await tester.tap(find.text('Pin'));
    await tester.pumpAndSettle();
    expect(actions, [FlareConversationAction.pin]);
  });
  testWidgets('swipe draws clear history in the danger colour like delete', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 360,
              child: FlareConversationRow(
                item: const ConversationRowData(
                  id: 'swipe',
                  title: 'Swipe conversation',
                ),
                swipeActions: const [
                  FlareConversationSwipeAction(
                    FlareConversationAction.markUnread,
                    'Unread',
                  ),
                  FlareConversationSwipeAction(
                    FlareConversationAction.clearHistory,
                    'Clear',
                  ),
                ],
                onAction: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.drag(find.text('Swipe conversation'), const Offset(-220, 0));
    await tester.pumpAndSettle();
    final colors = FlareColors.of(
      tester.element(find.byType(FlareConversationRow)),
    );
    SlidableAction action(String label) => tester.widget<SlidableAction>(
      find.widgetWithText(SlidableAction, label),
    );
    expect(action('Unread').backgroundColor, colors.primary);
    expect(
      action('Unread').icon,
      FlareConversationActionSheet.iconFor(FlareConversationAction.markUnread),
    );
    expect(action('Clear').backgroundColor, colors.errorText);
    expect(
      action('Clear').icon,
      FlareConversationActionSheet.iconFor(
        FlareConversationAction.clearHistory,
      ),
    );
  });
  final vectors =
      jsonDecode(
            File(
              '../../spec/conversation-state-vectors.json',
            ).readAsStringSync(),
          )['cases']
          as List;
  for (final vector in vectors) {
    test('conversation ${vector['id']}', () {
      final item = ConversationRowData(
        id: vector['id'],
        title: 'Chat',
        failed: vector['failed'],
        draftPreview: vector['draft'],
        typing: vector['typing'],
        mentioned: vector['mentioned'],
        pinned: vector['pinned'],
        muted: vector['muted'],
        unreadCount: vector['unreadCount'],
      );
      expect(item.previewKind, vector['expectedKind']);
      expect(item.unreadLabel, vector['expectedUnread']);
      expect(item.titleEmphasis, vector['expectedEmphasis']);
    });
  }
  for (final width in [240.0, 280.0, 320.0, 360.0]) {
    testWidgets('conversation fits $width with combined state and large text', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: const MediaQueryData(
                size: Size(390, 844),
                textScaler: TextScaler.linear(2),
              ),
              child: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: width,
                  child: const FlareConversationRow(
                    item: ConversationRowData(
                      id: 'one',
                      title: 'Very long localized conversation title',
                      preview: 'Long sender: an even longer preview',
                      timestampLabel: 'Yesterday',
                      pinned: true,
                      muted: true,
                      mentioned: true,
                      unreadCount: 1200,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('999+'), findsOneWidget);
    });
  }
}
