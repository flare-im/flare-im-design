import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A picture, a video or a voice message the host has no address for (it
/// hands the kit [FlareGenericContent] under the media's wire type) is still
/// that kind of message: it says it is not available right now, in the host's
/// language, and never reads as "unsupported". The other three kits draw the
/// same body.
void main() {
  Widget host(FlareMessageContent content, {FlareStrings? strings}) =>
      MaterialApp(
        home: Scaffold(
          body: FlareStringsScope(
            strings: strings ?? const FlareStrings(),
            child: Center(child: FlareMessageContentView(content: content)),
          ),
        ),
      );

  const cases = {
    'image': ('图片暂时无法加载', "Image isn't available right now"),
    'video': ('视频暂时无法加载', "Video isn't available right now"),
    'audio': ('语音暂时无法加载', "Voice message isn't available right now"),
  };

  for (final entry in cases.entries) {
    testWidgets('${entry.key} without an address says it is not available', (
      tester,
    ) async {
      final content = FlareGenericContent(
        contentType: entry.key,
        label: entry.key,
      );
      await tester.pumpWidget(host(content));
      expect(find.text(entry.value.$1), findsOneWidget);
      expect(find.byType(FlareUnknownMessage), findsNothing);
      expect(find.bySemanticsLabel(entry.value.$1), findsOneWidget);

      await tester.pumpWidget(host(content, strings: flareStringsEnglish));
      expect(find.text(entry.value.$2), findsOneWidget);
    });
  }

  testWidgets('a type the kit cannot draw reads in the host\'s language', (
    tester,
  ) async {
    const content = FlareGenericContent(
      contentType: 'flare.poll.v9',
      label: '投票',
    );
    await tester.pumpWidget(host(content, strings: flareStringsEnglish));
    expect(find.byType(FlareUnknownMessage), findsOneWidget);
    expect(find.text('Unsupported message type'), findsOneWidget);
    expect(find.text('Message type'), findsOneWidget);
    expect(find.text('不支持的消息类型'), findsNothing);
  });
}
