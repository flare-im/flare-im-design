import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// FR-080: core mention entities (offsets in code points) become string-index
// spans; valid ones are highlighted in text bodies, a mention of the reader or
// of everyone more strongly, and only in incoming bubbles.

FlareMentionEntity _user(int start, int length, [String userId = 'u1']) =>
    FlareMentionEntity(
      type: FlareMentionEntity.typeUser,
      userId: userId,
      start: start,
      length: length,
    );

Widget _host(Widget child) => MaterialApp(
  home: Scaffold(body: Center(child: child)),
);

/// The inline spans the body's paragraph was built from.
List<InlineSpan> _children(WidgetTester tester) {
  final rich = tester.widget<RichText>(
    find
        .descendant(
          of: find.byType(FlareTextMessage),
          matching: find.byType(RichText),
        )
        .first,
  );
  // Text.rich wraps the body's span in one carrying the default style.
  final body = (rich.text as TextSpan).children!.single as TextSpan;
  return body.children!;
}

void main() {
  group('flareTextMentionSpans', () {
    test('a surrogate-pair emoji before a mention keeps the range right', () {
      const text = '😀 @Ann hi';
      // Code points: 😀 0, space 1, "@Ann" 2..5.
      final spans = flareTextMentionSpans(text, [_user(2, 4)]);
      expect(spans, [const FlareTextMentionSpan(start: 3, length: 4)]);
      expect(text.substring(spans.single.start, spans.single.end), '@Ann');
    });

    test('a multi-scalar emoji before a mention keeps the range right', () {
      // A ZWJ family is five code points and eight UTF-16 units: "@Bo" starts
      // at code point 6 (string index 9), "@Cy" at 14 (index 17).
      const text = '👨‍👩‍👧 @Bo and @Cy';
      final spans = flareTextMentionSpans(text, [_user(6, 3), _user(14, 3)]);
      expect(spans.map((s) => s.start).toList(), [9, 17]);
      expect(spans.map((s) => text.substring(s.start, s.end)).toList(), [
        '@Bo',
        '@Cy',
      ]);
    });

    test('invalid and overlapping spans are ignored; the rest are sorted', () {
      const text = '@Ann @Bob hello';
      final spans = flareTextMentionSpans(text, [
        _user(5, 4), // @Bob
        _user(-1, 3), // before the text
        _user(0, 1), // shorter than two
        _user(12, 9), // past the end
        _user(10, 5), // "hello" does not start with @
        _user(0, 4), // @Ann
        _user(2, 5), // overlaps @Ann
      ]);
      expect(spans, [
        const FlareTextMentionSpan(start: 0, length: 4),
        const FlareTextMentionSpan(start: 5, length: 4),
      ]);
    });

    test('self is the reader by userId or userIds; all is type 2', () {
      const text = '@me @team @all';
      final spans = flareTextMentionSpans(text, [
        _user(0, 3, 'me'),
        const FlareMentionEntity(
          type: FlareMentionEntity.typeMulti,
          userIds: ['x', 'me'],
          start: 4,
          length: 5,
        ),
        const FlareMentionEntity(
          type: FlareMentionEntity.typeAll,
          start: 10,
          length: 4,
        ),
      ], currentUserId: 'me');
      expect(spans.map((s) => (s.self, s.all)).toList(), [
        (true, false),
        (true, false),
        (false, true),
      ]);
      // Without a reader, nobody is "self".
      expect(
        flareTextMentionSpans(text, [_user(0, 3, 'me')]).single.self,
        isFalse,
      );
    });
  });

  group('FlareTextMessage mentions', () {
    testWidgets('incoming: brand text at 500; self and all on the selected '
        'ground', (tester) async {
      const text = 'hi @Ann @me @all';
      final colors = FlareColors.light;
      await tester.pumpWidget(
        _host(
          FlareTextMessage(
            text: text,
            mentions: flareTextMentionSpans(text, [
              _user(3, 4, 'ann'),
              _user(8, 3, 'me'),
              const FlareMentionEntity(
                type: FlareMentionEntity.typeAll,
                start: 12,
                length: 4,
              ),
            ], currentUserId: 'me'),
          ),
        ),
      );
      final children = _children(tester);
      final plain = children.whereType<TextSpan>().firstWhere(
        (s) => s.text == '@Ann',
      );
      expect(plain.style!.color, colors.primaryText);
      expect(plain.style!.fontWeight, FontWeight.w500);

      final chips = children.whereType<WidgetSpan>().toList();
      expect(chips, hasLength(2));
      for (final (chip, label) in [(chips[0], '@me'), (chips[1], '@all')]) {
        final box = chip.child as Container;
        final decoration = box.decoration! as BoxDecoration;
        expect(decoration.color, colors.bgSelected);
        expect(
          decoration.borderRadius,
          BorderRadius.circular(FlareSizes.radiusSm),
        );
        expect(box.padding, const EdgeInsets.symmetric(horizontal: 2));
        final inner = box.child! as Text;
        expect(inner.data, label);
        expect(inner.style!.fontWeight, FontWeight.w500);
        expect(inner.style!.color, colors.primaryText);
      }
      expect(find.text('@me'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('outgoing: the bubble colour at 600 and no ground', (
      tester,
    ) async {
      const text = '@me look';
      await tester.pumpWidget(
        _host(
          FlareTextMessage(
            text: text,
            self: true,
            mentions: flareTextMentionSpans(text, [
              _user(0, 3, 'me'),
            ], currentUserId: 'me'),
          ),
        ),
      );
      final children = _children(tester);
      expect(children.whereType<WidgetSpan>(), isEmpty);
      final mention = children.whereType<TextSpan>().firstWhere(
        (s) => s.text == '@me',
      );
      expect(mention.style!.fontWeight, FontWeight.w600);
      // No colour of its own: it inherits the outgoing foreground.
      expect(mention.style!.color, isNull);
      expect(mention.style!.backgroundColor, isNull);
    });

    testWidgets('text outside the spans renders as before, links included', (
      tester,
    ) async {
      const text = 'see flare.im and @Ann';
      String? opened;
      await tester.pumpWidget(
        _host(
          FlareTextMessage(
            text: text,
            onLinkTap: (href) => opened = href,
            // One valid span, one invalid (past the end), one overlapping.
            mentions: const [
              FlareTextMentionSpan(start: 17, length: 4),
              FlareTextMentionSpan(start: 19, length: 9),
              FlareTextMentionSpan(start: 18, length: 2),
            ],
          ),
        ),
      );
      final children = _children(tester);
      expect(children.map((s) => (s as TextSpan).text).toList(), [
        'see ',
        'flare.im',
        ' and ',
        '@Ann',
      ]);
      final link = children[1] as TextSpan;
      (link.recognizer! as TapGestureRecognizer).onTap!();
      expect(opened, 'flare.im');

      // Without mentions the spans are exactly the plain linkified text.
      await tester.pumpWidget(
        _host(FlareTextMessage(text: text, onLinkTap: (_) {})),
      );
      expect(_children(tester).map((s) => (s as TextSpan).text).toList(), [
        'see ',
        'flare.im',
        ' and @Ann',
      ]);
    });

    testWidgets('the content view passes the content mentions through', (
      tester,
    ) async {
      const text = '@all hello';
      await tester.pumpWidget(
        _host(
          FlareMessageContentView(
            content: FlareTextContent(
              text,
              mentions: flareTextMentionSpans(text, const [
                FlareMentionEntity(
                  type: FlareMentionEntity.typeAll,
                  start: 0,
                  length: 4,
                ),
              ]),
            ),
          ),
        ),
      );
      expect(_children(tester).whereType<WidgetSpan>(), hasLength(1));
    });

    testWidgets('a highlighted mention scales with the text once', (
      tester,
    ) async {
      const text = 'x @me';
      Future<double> chipHeight(double scale) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: Scaffold(
                body: Center(
                  child: FlareTextMessage(
                    text: text,
                    mentions: flareTextMentionSpans(text, [
                      _user(2, 3, 'me'),
                    ], currentUserId: 'me'),
                  ),
                ),
              ),
            ),
          ),
        );
        // The global rect includes the scale the paragraph applies.
        return tester.getRect(find.text('@me')).height;
      }

      final normal = await chipHeight(1);
      final doubled = await chipHeight(2);
      expect(doubled, closeTo(normal * 2, 1));
    });
  });
}
