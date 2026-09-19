import 'dart:convert';
import 'dart:io';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The shared table (`spec/rich-doc-vectors.json`) is what a rich-text body
/// draws for a RichDoc v2 document. Vue states the rule in the table's own
/// shape; this kit reads the same file and turns its model into that shape.
void main() {
  final table =
      jsonDecode(File('../../spec/rich-doc-vectors.json').readAsStringSync())
          as Map<String, dynamic>;
  final cases = (table['cases'] as List).cast<Map<String, dynamic>>();

  Map<String, Object?> outlineRun(FlareRichRun run) => {
    'text': run.text,
    if (run.marks.isNotEmpty) 'marks': [for (final m in run.marks) m.name],
    if (run.code) 'code': true,
    if (run.link != null) 'link': run.link,
    if (run.mention != null) 'mention': run.mention,
    if (run.emoji != null) 'emoji': run.emoji,
  };

  Object? outline(FlareRichBlock block) => switch (block) {
    FlareRichParagraph(:final runs) => {
      'kind': 'paragraph',
      'runs': [for (final r in runs) outlineRun(r)],
    },
    FlareRichHeading(:final level, :final runs) => {
      'kind': 'heading',
      'level': level,
      'runs': [for (final r in runs) outlineRun(r)],
    },
    FlareRichQuote(:final blocks) => {
      'kind': 'quote',
      'blocks': [for (final b in blocks) outline(b)],
    },
    FlareRichCode(:final text, :final language) => {
      'kind': 'code',
      if (language != null) 'language': language,
      'text': text,
    },
    FlareRichList(:final ordered, :final items) => {
      'kind': 'list',
      'ordered': ordered,
      'items': [
        for (final item in items) [for (final b in item) outline(b)],
      ],
    },
    FlareRichDivider() => {'kind': 'divider'},
  };

  Object generated(Map<String, dynamic> spec) {
    const text = {'type': 'text', 'text': 'a'};
    if (spec['nestedQuotes'] != null) {
      Object node = {
        'type': 'paragraph',
        'children': [text],
      };
      for (var level = 0; level < (spec['nestedQuotes'] as int); level++) {
        node = {
          'type': 'quote',
          'children': [node],
        };
      }
      return {
        'type': 'doc',
        'version': 2,
        'children': [node],
      };
    }
    return {
      'type': 'doc',
      'version': 2,
      'children': [
        {
          'type': 'paragraph',
          'children': List.filled(spec['paragraphTextNodes'] as int, text),
        },
      ],
    };
  }

  group('rich-text documents read into blocks and runs', () {
    test('the shared table is whole', () {
      expect(cases.length, greaterThanOrEqualTo(30));
    });
    test('a covered spoiler is blank space, keeping its whitespace', () {
      final covers = (table['spoilerCovers'] as List)
          .cast<Map<String, dynamic>>();
      expect(covers.length, greaterThanOrEqualTo(5));
      for (final cover in covers) {
        expect(
          flareRichSpoilerCover(cover['text'] as String),
          cover['cover'],
          reason: jsonEncode(cover['text']),
        );
      }
    });
    for (final vector in cases) {
      test(vector['id'], () {
        final generate = vector['generate'] as Map<String, dynamic>?;
        if (generate != null) {
          expect(
            flareParseRichDoc(generated(generate)) != null,
            vector['drawable'],
          );
          return;
        }
        final blocks = flareParseRichDoc(vector['doc']);
        final actual = blocks == null
            ? null
            : [for (final b in blocks) outline(b)];
        // Compare as JSON so key order does not matter and types line up.
        expect(jsonEncode(actual), jsonEncode(vector['blocks']));
      });
    }
  });

  group('FlareRichTextMessage', () {
    Map<String, Object?> t(String text, [List<String> marks = const []]) => {
      'type': 'text',
      'text': text,
      if (marks.isNotEmpty)
        'marks': [
          for (final m in marks) {'type': m},
        ],
    };
    final docJson = jsonEncode({
      'type': 'doc',
      'version': 2,
      'children': [
        {
          'type': 'heading',
          'level': 2,
          'children': [t('周会纪要')],
        },
        {
          'type': 'paragraph',
          'children': [
            t('结论 ', ['bold']),
            {
              'type': 'link',
              'href': 'https://flare.im/docs',
              'children': [t('文档')],
            },
            t(' '),
            {
              'type': 'link',
              'href': 'javascript:alert(1)',
              'children': [t('别点')],
            },
          ],
        },
        {
          'type': 'ordered_list',
          'children': [
            {
              'type': 'list_item',
              'children': [
                {
                  'type': 'paragraph',
                  'children': [t('第一项')],
                },
              ],
            },
          ],
        },
        {
          'type': 'code_block',
          'language': 'ts',
          'children': [t('const a = 1;')],
        },
        {
          'type': 'paragraph',
          'children': [
            t('谜底是 '),
            t('42', ['spoiler']),
          ],
        },
      ],
    });

    Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: SizedBox(width: 320, child: child)),
        ),
      ),
    );

    /// Every span under the first rich text whose plain text contains [needle].
    List<TextSpan> spansOf(WidgetTester tester, String needle) {
      final out = <TextSpan>[];
      for (final widget in tester.widgetList<RichText>(find.byType(RichText))) {
        if (!widget.text.toPlainText().contains(needle)) continue;
        widget.text.visitChildren((span) {
          if (span is TextSpan) out.add(span);
          return true;
        });
      }
      return out;
    }

    testWidgets('draws headings, marks, lists and code', (tester) async {
      await pump(tester, FlareRichTextMessage(docJson: docJson));
      expect(find.text('周会纪要'), findsOneWidget);
      expect(find.text('1.'), findsOneWidget);
      expect(find.text('const a = 1;'), findsOneWidget);
      final bold = spansOf(tester, '结论').firstWhere((s) => s.text == '结论 ');
      expect(bold.style?.fontWeight, FontWeight.w700);
    });

    testWidgets(
      'reports only an address safeExternalUrl accepts, and keeps a refused link\'s words',
      (tester) async {
        final opened = <String>[];
        await pump(
          tester,
          FlareRichTextMessage(docJson: docJson, onLinkTap: opened.add),
        );
        final spans = spansOf(tester, '文档');
        final link = spans.firstWhere((s) => s.text == '文档');
        (link.recognizer! as TapGestureRecognizer).onTap!();
        expect(opened, ['https://flare.im/docs']);
        final refused = spans.firstWhere((s) => s.text == '别点');
        expect(refused.recognizer, isNull);
      },
    );

    testWidgets('covers a spoiler, names it, and reveals it on tap', (
      tester,
    ) async {
      await pump(tester, FlareRichTextMessage(docJson: docJson));
      final covered = spansOf(
        tester,
        '谜底',
      ).firstWhere((s) => s.text == '\u3000\u3000');
      expect(covered.semanticsLabel, const FlareStrings().messageSpoilerReveal);
      expect(covered.style?.backgroundColor, isNotNull);
      // The words are nowhere in the drawn text while covered.
      expect(
        tester
            .widgetList<RichText>(find.byType(RichText))
            .any((w) => w.text.toPlainText().contains('42')),
        isFalse,
      );
      (covered.recognizer! as TapGestureRecognizer).onTap!();
      await tester.pump();
      final revealed = spansOf(tester, '谜底').firstWhere((s) => s.text == '42');
      expect(revealed.semanticsLabel, isNull);
      expect(revealed.style?.backgroundColor, isNull);
    });

    testWidgets(
      'shows the plain text when the document is not drawable, and the term with neither',
      (tester) async {
        await pump(
          tester,
          const FlareRichTextMessage(
            docJson: '{"type":"doc"',
            plainText: '周报已发出',
          ),
        );
        expect(find.text('周报已发出'), findsOneWidget);
        await pump(tester, const FlareRichTextMessage(docJson: ''));
        expect(find.text(const FlareStrings().previewRichText), findsOneWidget);
      },
    );

    testWidgets('the dispatcher draws rich-text content with the body', (
      tester,
    ) async {
      await pump(
        tester,
        FlareMessageContentView(
          content: FlareRichTextContent(
            docJson: docJson,
            plainText: '周会纪要',
            title: '项目周报',
          ),
        ),
      );
      expect(find.byType(FlareRichTextMessage), findsOneWidget);
      expect(find.text('项目周报'), findsOneWidget);
      expect(
        flareCopyableText(
          FlareRichTextContent(docJson: docJson, plainText: '周会纪要'),
        ),
        '周会纪要',
      );
    });
  });
}
