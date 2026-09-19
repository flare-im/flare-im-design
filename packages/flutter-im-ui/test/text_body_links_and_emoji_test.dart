import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

// K5: `[key]` emoji-pack tokens inside plain text are drawn as the emoji, not
// left as literal brackets; a key the pack does not have stays as text.
// K4: a link tapped in a text body reaches the host as an intent, and only an
// address the chat may open ever leaves the kit.

FlareMessageData _text(String text, {String id = 'm1'}) => FlareMessageData(
  id: id,
  senderId: 'bob',
  senderName: 'Bob',
  content: FlareTextContent(text),
  sentAtMs: DateTime(2026, 9, 15, 10).millisecondsSinceEpoch,
);

FlareMessageData _card(String url, {String id = 'c1'}) => FlareMessageData(
  id: id,
  senderId: 'bob',
  senderName: 'Bob',
  content: FlareLinkCardContent(url: url, title: 'Release notes'),
  sentAtMs: DateTime(2026, 9, 15, 10).millisecondsSinceEpoch,
);

Widget _chat(
  List<FlareMessageData> messages, {
  void Function(FlareMessageData, String)? onOpenLink,
}) => MaterialApp(
  home: Scaffold(
    body: FlareMessageList(
      messages: messages,
      currentUserId: 'me',
      locale: 'zh-CN',
      onOpenLink: onOpenLink,
    ),
  ),
);

/// Taps the middle of [needle] where it is drawn in the message paragraph.
Future<void> _tapLink(WidgetTester tester, String needle) async {
  RenderParagraph? paragraph;
  for (final element in find.byType(RichText).evaluate()) {
    final object = element.renderObject;
    if (object is RenderParagraph &&
        object.text.toPlainText().contains(needle)) {
      paragraph = object;
      break;
    }
  }
  if (paragraph == null) fail('no paragraph draws "$needle"');
  final start = paragraph.text.toPlainText().indexOf(needle);
  final boxes = paragraph.getBoxesForSelection(
    TextSelection(baseOffset: start, extentOffset: start + needle.length),
  );
  final box = boxes.first;
  await tester.tapAt(
    paragraph.localToGlobal(Offset.zero) +
        Offset((box.left + box.right) / 2, (box.top + box.bottom) / 2),
  );
  await tester.pump();
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await FlareEmojiStickerCatalog.instance.ensureLoaded();
  });

  group('inline emoji tokens (K5)', () {
    test('the catalog knows the keys the bodies render', () {
      expect(FlareEmojiStickerCatalog.instance.hasEmojiKey('alien'), isTrue);
      expect(
        FlareEmojiStickerCatalog.instance.hasEmojiKey('not_a_key'),
        isFalse,
      );
    });

    testWidgets('a known token renders the emoji, the text around it stays', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                child: FlareTextMessage(text: '早上好[alien]出发'),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(Image), findsOneWidget);
      final paragraph = tester.widget<Text>(find.byType(Text).first);
      final plain = paragraph.textSpan!.toPlainText(includePlaceholders: false);
      expect(plain, '早上好出发', reason: 'the token is drawn, not spelled out');
    });

    testWidgets('a key the pack does not have stays as its bracket text', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: FlareTextMessage(text: '版本 [build_42] 已发布')),
        ),
      );
      await tester.pump();
      expect(find.byType(Image), findsNothing);
      final paragraph = tester.widget<Text>(find.byType(Text).first);
      expect(
        paragraph.textSpan!.toPlainText(includePlaceholders: false),
        '版本 [build_42] 已发布',
      );
    });

    testWidgets('a mention next to a token keeps its highlight', (
      tester,
    ) async {
      const text = '@Ann [alien] 看看';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlareTextMessage(
              text: text,
              mentions: flareTextMentionSpans(text, const [
                FlareMentionEntity(
                  start: 0,
                  length: 4,
                  type: FlareMentionEntity.typeUser,
                  userId: 'me',
                ),
              ], currentUserId: 'me'),
            ),
          ),
        ),
      );
      await tester.pump();
      // The mention keeps its own ground (a widget span) and the token is an
      // image: both survive in one paragraph.
      expect(find.text('@Ann'), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });
  });

  group('link intent (K4)', () {
    testWidgets('a tapped link reaches the host, normalised', (tester) async {
      final opened = <String>[];
      await tester.pumpWidget(
        _chat([
          _text('see example.com/docs for more'),
        ], onOpenLink: (message, url) => opened.add('${message.id} $url')),
      );
      await tester.pumpAndSettle();
      await _tapLink(tester, 'example.com/docs');
      expect(opened, ['m1 https://example.com/docs']);
    });

    testWidgets('a link card opens through the same intent', (tester) async {
      final opened = <String>[];
      await tester.pumpWidget(
        _chat([
          _card('https://example.com/post', id: 'ok'),
        ], onOpenLink: (message, url) => opened.add('${message.id} $url')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Release notes'));
      await tester.pumpAndSettle();
      expect(opened, ['ok https://example.com/post']);
    });

    testWidgets('a link card the chat may not open never reaches the host', (
      tester,
    ) async {
      // The card's address comes straight off the wire: it is whatever the
      // sender put there.
      final opened = <String>[];
      await tester.pumpWidget(
        _chat([
          _card('javascript:alert(1)', id: 'evil'),
        ], onOpenLink: (message, url) => opened.add(url)),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Release notes'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(opened, isEmpty);
    });

    testWidgets('without a handler a link tap does nothing', (tester) async {
      await tester.pumpWidget(_chat([_text('see example.com now')]));
      await tester.pumpAndSettle();
      await _tapLink(tester, 'example.com');
      expect(tester.takeException(), isNull);
    });
  });
}
