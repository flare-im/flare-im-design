import 'dart:convert';
import 'dart:io';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The merged-forward record against spec/message-forward-vectors.json (the
/// Vue, SwiftUI and Compose kits read the same file): the layout and copy as a
/// pure function, then the drawn card, its accessible name and the drawer.
final Map<String, dynamic> _table =
    jsonDecode(
          File('../../spec/message-forward-vectors.json').readAsStringSync(),
        )
        as Map<String, dynamic>;

/// What a host does: the core's forward content → FlareForwardContent, each
/// item's content through the host's own content mapping.
FlareForwardContent _record(Map<String, dynamic> input) {
  final forward = (input['forward'] as Map).cast<String, dynamic>();
  FlareMessageContent? content(Object? raw) {
    if (raw is! Map) return null;
    final c = raw.cast<String, dynamic>();
    return switch (c['contentType']) {
      'text' => FlareTextContent(((c['text'] as Map)['text'] as String?) ?? ''),
      'image' => FlareImageContent(
        url: ((c['image'] as Map)['url'] as String?) ?? '',
      ),
      _ => null,
    };
  }

  return FlareForwardContent(
    title: forward['title'] as String? ?? '',
    mode: FlareForwardMode.fromWire(forward['mode'] as int?),
    items: [
      for (final raw in (forward['items'] as List).cast<Map>())
        FlareForwardItem(
          senderName: raw['sourceSenderName'] as String? ?? '',
          sentAtMs: (raw['sourceMessageTimeMs'] as num?)?.toInt() ?? 0,
          plainText: raw['plainText'] as String? ?? '',
          content: content(raw['content']),
        ),
    ],
  );
}

Widget _host(Widget child, {FlareStrings strings = const FlareStrings()}) =>
    MaterialApp(
      home: FlareStringsScope(
        strings: strings,
        child: Scaffold(body: Center(child: child)),
      ),
    );

void main() {
  final cases = (_table['cases'] as List).cast<Map<String, dynamic>>();
  const languages = {'zh': 'zh-CN', 'en': 'en-US'};
  FlareStrings stringsOf(String lang) =>
      lang == 'zh' ? const FlareStrings() : flareStringsEnglish;

  test('reads every case', () => expect(cases, hasLength(greaterThan(5))));

  for (final v in cases) {
    final id = v['id'] as String;
    final record = _record(v['input'] as Map<String, dynamic>);
    final expected = v['expect'] as Map<String, dynamic>;
    for (final lang in languages.keys) {
      final locale = languages[lang]!;
      final strings = stringsOf(lang);

      test('$id ($lang) facts', () {
        final view = flareForwardRecordView(record, strings, locale: locale);
        expect(view.layout.name, expected['layout']);
        if (expected['layout'] != 'card') return;
        final facts = (expected[lang] as Map).cast<String, dynamic>();
        expect(view.title, facts['title']);
        expect(view.subtitle, facts['subtitle']);
        expect(
          [
            for (final p in view.previews) {'sender': p.sender, 'text': p.text},
          ],
          [
            for (final p in (facts['previews'] as List).cast<Map>())
              {'sender': p['sender'], 'text': p['text']},
          ],
        );
        expect(view.more, facts['more']);
        expect(view.hint, facts['hint']);
        expect(view.label, facts['label']);
        expect(view.drawerTitle, facts['drawerTitle']);
      });

      testWidgets('$id ($lang) drawn', (tester) async {
        await tester.pumpWidget(
          _host(FlareMessageContentView(content: record), strings: strings),
        );
        final layout = expected['layout'] as String;
        if (layout != 'card') {
          final text = (expected['text'] as Map)[lang] as String;
          expect(find.text(text, findRichText: true), findsOneWidget);
          expect(find.byKey(FlareForwardMessage.cardKey), findsNothing);
          return;
        }
        final facts = (expected[lang] as Map).cast<String, dynamic>();
        expect(find.byKey(FlareForwardMessage.cardKey), findsOneWidget);
        expect(find.text(facts['title'] as String), findsOneWidget);
        if (facts['subtitle'] case final String subtitle) {
          expect(find.text(subtitle), findsOneWidget);
        }
        if (facts['more'] case final String more) {
          expect(find.text(more), findsOneWidget);
        }
        expect(find.text(facts['hint'] as String), findsOneWidget);
        final previews = (facts['previews'] as List).cast<Map>();
        for (final p in previews) {
          expect(
            find.textContaining(
              '${p['sender']}: ${p['text']}',
              findRichText: true,
            ),
            findsOneWidget,
            reason: '${p['sender']}',
          );
        }
        // One button, named "title, subtitle".
        final semantics = tester.ensureSemantics();
        final node = tester.getSemantics(
          find.byKey(FlareForwardMessage.cardKey),
        );
        expect(node.label, facts['label']);
        expect(node.getSemanticsData().flagsCollection.isButton, isTrue);
        semantics.dispose();

        // A tap opens the kit drawer with every item.
        await tester.tap(find.byKey(FlareForwardMessage.cardKey));
        await tester.pumpAndSettle();
        expect(find.byType(FlareDrawer), findsOneWidget);
        expect(find.text(facts['drawerTitle'] as String), findsOneWidget);
        for (var i = 0; i < record.items.length; i += 1) {
          expect(find.byKey(FlareForwardMessage.itemKey(i)), findsOneWidget);
        }
      });
    }
  }

  testWidgets('in selection mode the card does not open', (tester) async {
    final record = _record(
      (cases.firstWhere((c) => c['id'] == 'two-items-titled')['input'] as Map)
          .cast<String, dynamic>(),
    );
    await tester.pumpWidget(
      _host(FlareMessageContentView(content: record, selectionMode: true)),
    );
    await tester.tap(
      find.byKey(FlareForwardMessage.cardKey),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    expect(find.byType(FlareDrawer), findsNothing);
  });

  testWidgets('the drawer lists the initial, sender, time, summary and a '
      'non-text content', (tester) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 9, 5);
    final record = FlareForwardContent(
      mode: FlareForwardMode.merged,
      items: [
        FlareForwardItem(
          senderName: 'lin',
          sentAtMs: today.millisecondsSinceEpoch,
          plainText: '早',
        ),
        FlareForwardItem(
          sentAtMs: today.millisecondsSinceEpoch,
          content: const FlareFileContent(name: '方案.pdf', url: ''),
        ),
      ],
    );
    await tester.pumpWidget(_host(FlareMessageContentView(content: record)));
    await tester.tap(find.byKey(FlareForwardMessage.cardKey));
    await tester.pumpAndSettle();
    final first = find.byKey(FlareForwardMessage.itemKey(0));
    expect(
      find.descendant(of: first, matching: find.text('L')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: first, matching: find.text('lin')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: first,
        matching: find.text(
          FlareTimeFormat.messageTime(
            today,
            locale: Localizations.localeOf(
              tester.element(first),
            ).toLanguageTag(),
          ),
        ),
      ),
      findsOneWidget,
    );
    final second = find.byKey(FlareForwardMessage.itemKey(1));
    expect(
      find.descendant(of: second, matching: find.text('?')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: second, matching: find.text('未知发送者')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: second, matching: find.byType(FlareFileMessage)),
      findsOneWidget,
    );
  });

  // rules.palette: a record's items are someone else's messages whoever
  // forwarded it — inline and in the drawer, never the outgoing white.
  testWidgets('a record the viewer forwarded draws its items in the neutral '
      'palette', (tester) async {
    const rich = FlareRichTextContent(docJson: '', plainText: '周报');
    Color? colorOf(Finder body) {
      final text = tester.widget<Text>(
        find.descendant(of: body, matching: find.text('周报')),
      );
      return text.style?.color;
    }

    await tester.pumpWidget(
      _host(
        const FlareMessageContentView(
          self: true,
          content: FlareForwardContent(
            mode: FlareForwardMode.single,
            items: [FlareForwardItem(senderName: '林夏', content: rich)],
          ),
        ),
      ),
    );
    expect(
      colorOf(find.byType(FlareRichTextMessage)),
      FlareColors.light.messageIncomingForeground,
      reason: 'the one item drawn inline',
    );

    await tester.pumpWidget(
      _host(
        const FlareMessageContentView(
          self: true,
          content: FlareForwardContent(
            mode: FlareForwardMode.merged,
            items: [
              FlareForwardItem(senderName: '林夏', content: rich),
              FlareForwardItem(senderName: '周屿', plainText: '收到'),
            ],
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(FlareForwardMessage.cardKey));
    await tester.pumpAndSettle();
    expect(
      colorOf(
        find.descendant(
          of: find.byKey(FlareForwardMessage.itemKey(0)),
          matching: find.byType(FlareRichTextMessage),
        ),
      ),
      FlareColors.light.messageIncomingForeground,
      reason: 'a drawer row',
    );
  });

  test('the record previews as its one message, or a count', () {
    const s = FlareStrings();
    const one = FlareForwardContent(
      items: [FlareForwardItem(senderName: 'a', plainText: '明天见')],
    );
    expect(flareMessagePreviewText(one, s), '明天见');
    const many = FlareForwardContent(
      items: [
        FlareForwardItem(plainText: '1'),
        FlareForwardItem(plainText: '2'),
      ],
    );
    expect(flareMessagePreviewText(many, s), s.previewForwardCount(2));
    expect(flareMessagePreviewText(const FlareForwardContent(), s), '[转发]');
  });

  test('the drawer initial follows senderInitials', () {
    final block = (_table['senderInitials'] as Map).cast<String, dynamic>();
    final cases = (block['cases'] as List).cast<Map>();
    expect(cases, isNotEmpty);
    for (final c in cases) {
      expect(
        flareForwardSenderInitial(
          FlareForwardItem(senderName: c['senderName'] as String),
        ),
        c['initial'],
        reason: '"${c['senderName']}"',
      );
    }
  });

  test('a forward record is a card surface', () {
    expect(
      flareMessageSurface(
        FlareMessageSurfaceInput(
          contentType: flareMessageContentKey(
            const FlareForwardContent(),
          ).contentType,
        ),
      ),
      FlareMessageSurface.card,
    );
    expect(FlareForwardMode.fromWire(2), FlareForwardMode.merged);
    expect(FlareForwardMode.fromWire(1), FlareForwardMode.single);
    expect(FlareForwardMode.fromWire(0), FlareForwardMode.unspecified);
    expect(FlareForwardMode.fromWire(9), FlareForwardMode.unspecified);
  });
}
