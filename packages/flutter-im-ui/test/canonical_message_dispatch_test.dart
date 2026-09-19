import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(Widget child) => MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  testWidgets('runtime voice uses canonical body and forwards its action', (tester) async {
    FlareMessageContent? opened;
    const content = FlareAudioContent(url: 'test.webm', durationSec: 7);
    await tester.pumpWidget(host(FlareMessageContentView(
      content: content, onMediaAction: (value) => opened = value,
    )));
    expect(find.byType(FlareVoiceMessage), findsOneWidget);
    expect(find.text('7"'), findsOneWidget);
    await tester.tap(find.text('7"'));
    expect(opened, same(content));
    final body = find.descendant(of: find.byType(FlareVoiceMessage), matching: find.byType(Container));
    for (final widget in tester.widgetList<Container>(body)) {
      expect((widget.decoration as BoxDecoration?)?.border, isNull);
    }
  });

  testWidgets('built-in dispatcher uses public standalone bodies', (tester) async {
    final cases = <FlareMessageContent, Type>{
      const FlareTextContent('hello'): FlareTextMessage,
      const FlareImageContent(url: ''): FlareImageMessage,
      const FlareVideoContent(url: ''): FlareVideoMessage,
      const FlareFileContent(name: 'test.pdf', url: ''): FlareFileMessage,
      const FlareLocationContent(name: 'HQ'): FlareLocationMessage,
      const FlareCardContent(title: 'Ivy'): FlareContactMessage,
      const FlareLinkCardContent(url: '', title: 'Docs'): FlareLinkCardMessage,
      const FlareStickerContent(url: ''): FlareStickerMessage,
      const FlareEmojiContent('🙂'): FlareEmojiMessage,
      const FlareNotificationContent('notice'): FlareSystemMessage,
      const FlarePollContent(id: 'p', title: 'Lunch', options: ['A', 'B']): FlareVoteMessage,
      const FlareTaskContent(id: 't', title: 'Review', detail: 'Today'): FlareTaskMessage,
      const FlareCalendarContent(id: 'c', title: 'Planning', timeRange: '10:00'): FlareLinkCardMessage,
      const FlareMiniAppContent(appId: 'mini', title: 'Tracker'): FlareLinkCardMessage,
      const FlareAnnouncementContent(id: 'a', title: 'Maintenance', body: 'Tonight'): FlareLinkCardMessage,
    };
    for (final entry in cases.entries) {
      await tester.pumpWidget(host(FlareMessageContentView(content: entry.key)));
      expect(find.byType(entry.value), findsOneWidget, reason: entry.key.type);
      expect(tester.takeException(), isNull, reason: entry.key.type);
    }
  });

  testWidgets('unknown poll results stay unknown and business bodies fit narrow panes', (tester) async {
    final contents = <FlareMessageContent>[
      const FlarePollContent(id: 'p', title: 'A longer localized poll title that wraps', options: ['One', 'Two']),
      const FlareTaskContent(id: 't', title: 'A longer localized task title', detail: 'Today'),
      const FlareAnnouncementContent(id: 'a', title: 'Maintenance', body: 'Full announcement content must remain readable.'),
    ];
    for (final content in contents) {
      await tester.pumpWidget(host(SizedBox(width: 220, child: FlareMessageContentView(content: content, self: true))));
      expect(find.text('0%'), findsNothing);
      expect(tester.takeException(), isNull, reason: content.type);
    }
  });

  testWidgets('outgoing voice has one metadata owner and semantic foreground', (tester) async {
    await tester.pumpWidget(host(const FlareMessageBubble(
      currentUserId: 'self',
      message: FlareMessageData(id: 'voice', senderId: 'self', senderName: 'Self',
        content: FlareAudioContent(url: '', durationSec: 7), timeLabel: '12:34',
        status: FlareMessageDeliveryStatus.read),
    )));
    expect(find.byType(FlareMessageMeta), findsOneWidget);
    expect(find.text('12:34'), findsOneWidget);
    final text = tester.widget<Text>(find.text('7"'));
    expect(text.style!.color, FlareColors.light.messageOutgoingForeground.withValues(alpha: 0.8));
    expect(tester.takeException(), isNull);
  });
}
