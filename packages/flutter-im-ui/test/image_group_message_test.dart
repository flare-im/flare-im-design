import 'dart:convert';
import 'dart:io';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The shared layout table (`spec/image-group-layout-vectors.json`) and the
/// album body built on it.
void main() {
  final table =
      jsonDecode(
            File(
              '../../spec/image-group-layout-vectors.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;

  group('image-group layout', () {
    test('draws at most the table\'s number of tiles', () {
      expect(flareImageGroupMaxVisible, table['maxVisible']);
    });
    for (final raw in (table['cases'] as List).cast<Map<String, dynamic>>()) {
      test('${raw['count']} image(s)', () {
        expect(
          flareImageGroupLayout(raw['count'] as int),
          FlareImageGroupLayout(
            columns: raw['columns'] as int,
            visible: raw['visible'] as int,
            more: raw['more'] as int,
          ),
        );
      });
    }
  });

  group('FlareImageGroupMessage', () {
    List<FlareImageContent> album(int count) => [
      for (var i = 0; i < count; i++) FlareImageContent(url: ''),
    ];

    Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Center(child: child)),
      ),
    );

    testWidgets('lays tiles out by the rule and covers the last', (
      tester,
    ) async {
      await pump(tester, FlareImageGroupMessage(images: album(12)));
      expect(find.text('+4'), findsOneWidget);
      // Nine tiles, three to a row: every tile is (240 - 2 gaps) / 3 wide.
      final tile = tester.getSize(find.bySemanticsLabel(RegExp('第 1 张图片')));
      expect(tile.width, closeTo((240 - 2 * FlareSizes.spacingXs) / 3, 0.01));
      expect(find.bySemanticsLabel(RegExp('第 9 张图片.*另有 4 张')), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('第 10 张图片')), findsNothing);

      await pump(tester, FlareImageGroupMessage(images: album(4)));
      expect(find.textContaining('+'), findsNothing);
      final square = tester.getSize(find.bySemanticsLabel(RegExp('第 1 张图片')));
      expect(square.width, closeTo((240 - FlareSizes.spacingXs) / 2, 0.01));
    });

    testWidgets('a tile opens its own image, the covered one included', (
      tester,
    ) async {
      final opened = <int>[];
      await pump(
        tester,
        FlareImageGroupMessage(
          images: album(12),
          description: '周末爬山',
          onOpen: opened.add,
        ),
      );
      await tester.tap(find.bySemanticsLabel(RegExp('第 2 张图片')));
      await tester.tap(find.text('+4'));
      expect(opened, [1, 8]);
      expect(find.text('周末爬山'), findsOneWidget);
      expect(find.bySemanticsLabel('12 张图片'), findsOneWidget);
    });

    testWidgets('an album without images draws nothing', (tester) async {
      await pump(tester, const FlareImageGroupMessage(images: []));
      expect(find.byType(Image), findsNothing);
      expect(tester.getSize(find.byType(FlareImageGroupMessage)), Size.zero);
    });

    testWidgets(
      'the dispatcher draws album content and hands the host the album',
      (tester) async {
        final content = FlareImageGroupContent(images: album(3));
        FlareMessageContent? handled;
        await pump(
          tester,
          FlareMessageContentView(
            content: content,
            onMediaAction: (value) => handled = value,
          ),
        );
        expect(find.byType(FlareImageGroupMessage), findsOneWidget);
        await tester.tap(find.bySemanticsLabel(RegExp('第 3 张图片')));
        expect(handled, same(content));
        expect(
          flareMessagePreviewText(content, const FlareStrings()),
          const FlareStrings().previewImageGroupCount(3),
        );
      },
    );
  });
}
