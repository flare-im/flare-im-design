import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

void main() {
  group('standalone unicode emoji', () {
    test('recognises one glyph sequence but not adjacent emoji or text', () {
      for (final value in ['😖', '👽', '👍🏽', '👨‍👩‍👧‍👦', '🇨🇳', '1️⃣']) {
        expect(flareIsStandaloneUnicodeEmoji(value), isTrue, reason: value);
      }
      for (final value in ['hello', '😖 hello', '😖👽', '1', '[alien]']) {
        expect(flareIsStandaloneUnicodeEmoji(value), isFalse, reason: value);
      }
    });

    test('recognises a lone protocol emoji token as a complete emoji', () {
      expect(flareIsStandaloneEmojiMessage('[alien]'), isTrue);
      expect(flareIsStandaloneEmojiMessage(' [confounded_face] '), isTrue);
      expect(flareIsStandaloneEmojiMessage('[alien] hello'), isFalse);
      expect(flareIsStandaloneEmojiMessage('[not-an-emoji]'), isFalse);
    });

    testWidgets('text content with one emoji uses the large emoji body', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(const FlareMessageContentView(content: FlareTextContent(' 👽 '))),
      );
      expect(find.byType(FlareEmojiMessage), findsOneWidget);
      final emoji = tester.widget<Text>(find.text('👽'));
      expect(emoji.style?.fontSize, 48);

      await tester.pumpWidget(
        _host(const FlareMessageContentView(content: FlareTextContent('👽👽'))),
      );
      expect(find.byType(FlareEmojiMessage), findsNothing);
      expect(find.byType(FlareTextMessage), findsOneWidget);
    });

    testWidgets('a lone pack token uses the large emoji body', (tester) async {
      await tester.pumpWidget(
        _host(
          const FlareMessageContentView(content: FlareTextContent('[alien]')),
        ),
      );

      expect(find.byType(FlareEmojiMessage), findsOneWidget);
      final box = tester.getSize(find.byType(FlareEmojiPackMessage));
      expect(box, const Size(120, 120));
    });

    testWidgets('rich text containing only an emoji uses the same large body', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          const FlareMessageContentView(
            content: FlareRichTextContent(
              docJson: '{}',
              plainText: '[confounded_face]',
            ),
          ),
        ),
      );

      expect(find.byType(FlareEmojiMessage), findsOneWidget);
      expect(
        tester.getSize(find.byType(FlareEmojiPackMessage)),
        const Size(120, 120),
      );
    });
  });

  group('standalone message bodies', () {
    testWidgets('text renders its body', (tester) async {
      await tester.pumpWidget(
        _host(const FlareTextMessage(text: 'hello there')),
      );
      expect(find.text('hello there'), findsOneWidget);
    });

    testWidgets('file shows name / size / ext', (tester) async {
      await tester.pumpWidget(
        _host(
          const FlareFileMessage(name: 'spec.pdf', size: '2.4 MB', ext: 'PDF'),
        ),
      );
      expect(find.text('spec.pdf'), findsOneWidget);
      expect(find.text('2.4 MB · PDF'), findsOneWidget);
    });

    testWidgets('location shows title and address', (tester) async {
      await tester.pumpWidget(
        _host(const FlareLocationMessage(title: 'HQ', address: 'Beijing')),
      );
      expect(find.text('HQ'), findsOneWidget);
      expect(find.text('Beijing'), findsOneWidget);
    });

    testWidgets('contact derives initials from name', (tester) async {
      await tester.pumpWidget(
        _host(const FlareContactMessage(name: 'Ivy Chen', subtitle: '@ivy')),
      );
      expect(find.text('IC'), findsOneWidget);
      expect(find.text('Ivy Chen'), findsOneWidget);
    });

    testWidgets('vote renders each option with percentage', (tester) async {
      await tester.pumpWidget(
        _host(
          const FlareVoteMessage(
            title: 'When?',
            options: [FlareVoteOption('Thu', 62), FlareVoteOption('Fri', 38)],
          ),
        ),
      );
      expect(find.text('Thu'), findsOneWidget);
      expect(find.text('62%'), findsOneWidget);
      expect(find.text('Fri'), findsOneWidget);
    });

    testWidgets('task renders title and meta', (tester) async {
      await tester.pumpWidget(
        _host(
          const FlareTaskMessage(title: 'Sync notes', meta: 'done', done: true),
        ),
      );
      expect(find.text('Sync notes'), findsOneWidget);
      expect(find.text('done'), findsOneWidget);
    });

    testWidgets('sticker / emoji / system render', (tester) async {
      await tester.pumpWidget(_host(const FlareStickerMessage(emoji: '🐱')));
      expect(find.text('🐱'), findsOneWidget);
      await tester.pumpWidget(_host(const FlareEmojiMessage(emoji: '🎉')));
      expect(find.text('🎉'), findsOneWidget);
      await tester.pumpWidget(
        _host(const FlareSystemMessage(text: 'recalled')),
      );
      expect(find.text('recalled'), findsOneWidget);
    });

    testWidgets('media bodies mount (no SDK)', (tester) async {
      await tester.pumpWidget(_host(const FlareImageMessage()));
      await tester.pumpWidget(
        _host(const FlareVideoMessage(duration: '00:42')),
      );
      expect(find.text('00:42'), findsOneWidget);
      await tester.pumpWidget(_host(const FlareVoiceMessage(seconds: 7)));
      expect(find.text('7"'), findsOneWidget);
    });
  });
}
