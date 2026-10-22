import 'dart:convert';
import 'dart:io';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Grouping, row presentation and date pills against the shared
/// spec/message-grouping-vectors.json (the Vue, SwiftUI and Compose kits read
/// the same file).
void main() {
  final table =
      jsonDecode(
            File('../../spec/message-grouping-vectors.json').readAsStringSync(),
          )
          as Map<String, dynamic>;
  final nowMs = table['nowMs'] as int;
  final offset = table['utcOffsetMinutes'] as int;
  final gap = table['timeGapMs'] as int;

  test('the gap is the kit\'s', () {
    expect(flareMessageGroupGapMs, gap);
  });

  Map<String, Object?> rowFact(FlareTimelineRow row) => switch (row) {
    FlareTimelineDateRow r => {'kind': 'date', 'label': r.label.name},
    FlareTimelineUnreadRow r => {'kind': 'unread', 'count': r.count},
    FlareTimelineMessageRow r => {
      'kind': 'message',
      'id': r.id,
      'position': r.position.name,
      'showAvatar': r.presentation.showAvatar,
      'showSenderName': r.presentation.showSenderName,
      'reserveAvatarSpace': r.presentation.reserveAvatarSpace,
      'avatarPlacement': r.presentation.avatarPlacement.name,
      'tail': r.presentation.tail,
    },
  };

  for (final v in (table['cases'] as List).cast<Map<String, dynamic>>()) {
    test(v['name'] as String, () {
      final options = v['options'] as Map<String, dynamic>? ?? const {};
      final items = [
        for (final m in (v['messages'] as List).cast<Map<String, dynamic>>())
          FlareTimelineItem(
            id: m['id'] as String,
            senderId: m['senderId'] as String,
            atMs: m['atMs'] as int,
            surface: FlareMessageSurface.values.byName(m['surface'] as String),
          ),
      ];
      final rows = flareTimelineRows(
        items,
        currentUserId: v['currentUserId'] as String,
        groupConversation: v['conversationKind'] == 'group',
        unreadFromId: v['unreadFromId'] as String?,
        showIncomingAvatar: options['showIncomingAvatar'] as bool? ?? true,
        showSelfAvatar: options['showSelfAvatar'] as bool? ?? false,
        showGroupSenderName: options['showGroupSenderName'] as bool? ?? true,
        nowMs: nowMs,
        utcOffsetMinutes: offset,
      );
      expect(rows.map(rowFact).toList(), v['rows']);
    });
  }

  // The list draws what the rules say: the tail only on a bubble ending its
  // run, and a date pill whose ground differs from the timeline canvas.
  testWidgets('the date pill stands off the timeline canvas', (tester) async {
    for (final colors in [FlareColors.light, FlareColors.dark]) {
      await tester.pumpWidget(
        MaterialApp(
          home: FlareTheme(
            colors: colors,
            child: const Scaffold(body: FlareDatePill(label: '今天')),
          ),
        ),
      );
      final pill = tester.widget<Container>(
        find.descendant(
          of: find.byType(FlareDatePill),
          matching: find.byType(Container),
        ),
      );
      final ground = (pill.decoration! as BoxDecoration).color;
      // FlareMessageList paints the canvas with bgSecondary.
      expect(ground, isNot(colors.bgSecondary));
      expect(ground, colors.bgTertiary);
    }
  });

  testWidgets('a list breaks the run at a card and draws tails on bubbles', (
    tester,
  ) async {
    FlareMessageData m(String id, int at, FlareMessageContent content) =>
        FlareMessageData(
          id: id,
          senderId: 'u1',
          senderName: 'U1',
          sentAtMs: at,
          timeLabel: '09:0$id',
          content: content,
        );
    const base = 1792632600000;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlareMessageList(
            currentUserId: 'me',
            conversationKind: FlareConversationKind.group,
            messages: [
              m('1', base, const FlareTextContent('hi')),
              m(
                '2',
                base + 60000,
                const FlareCardContent(userId: 'u9', title: 'Card'),
              ),
              m('3', base + 120000, const FlareTextContent('there')),
            ],
          ),
        ),
      ),
    );
    final bubbles = tester
        .widgetList<FlareMessageBubble>(find.byType(FlareMessageBubble))
        .toList();
    expect(bubbles.map((b) => b.groupPosition), [
      FlareMessageGroupPosition.single,
      FlareMessageGroupPosition.single,
      FlareMessageGroupPosition.single,
    ]);
    expect(bubbles.map((b) => b.surface), [
      FlareMessageSurface.bubble,
      FlareMessageSurface.card,
      FlareMessageSurface.bubble,
    ]);
    expect(bubbles.map((b) => b.rowPresentation.tail), [true, false, true]);
  });
}
