import 'dart:convert';
import 'dart:io';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The shared gallery table (`spec/image-gallery-vectors.json`) and the paging
/// preview a timeline opens.
void main() {
  final table =
      jsonDecode(
            File('../../spec/image-gallery-vectors.json').readAsStringSync(),
          )
          as Map<String, dynamic>;
  final cases = (table['cases'] as List).cast<Map<String, dynamic>>();

  FlareMessageData message(Map<String, dynamic> raw) {
    final refs = (raw['images'] as List? ?? const []).cast<String>();
    final content = switch (raw['kind']) {
      'image' => FlareImageContent(url: refs.first),
      'imageGroup' => FlareImageGroupContent(
        images: [for (final ref in refs) FlareImageContent(url: ref)],
      ),
      'sticker' => const FlareStickerContent(url: 'https://cdn.example/s.webp'),
      'video' => const FlareVideoContent(url: 'https://cdn.example/v.mp4'),
      _ => const FlareTextContent('明天见'),
    };
    return FlareMessageData(
      id: raw['id'] as String,
      senderId: 'u',
      senderName: 'U',
      content: content,
      lifecycle: raw['recalled'] == true
          ? const FlareMessageLifecycle(
              mutation: FlareMessageMutationState.recalled,
            )
          : null,
    );
  }

  group('a conversation\'s image gallery', () {
    test('the shared table is whole', () {
      expect(cases.length, greaterThanOrEqualTo(4));
    });
    for (final c in cases) {
      test(c['id'], () {
        final messages = [
          for (final raw
              in (c['messages'] as List).cast<Map<String, dynamic>>())
            message(raw),
        ];
        final items = flareImageGalleryItems(messages);
        expect([
          for (final item in items) '${item.messageId}#${item.index}',
        ], c['items']);
        for (final open in (c['opens'] as List).cast<Map<String, dynamic>>()) {
          expect(
            flareImageGalleryStart(
              items,
              open['message'] as String,
              open['index'] as int,
            ),
            open['start'],
            reason: '${open['message']}#${open['index']}',
          );
        }
      });
    }
  });

  group('gallery preview', () {
    final images = [
      for (var i = 0; i < 3; i++)
        FlareImageContent(url: 'https://cdn.example/$i.jpg'),
    ];

    testWidgets('pages with its side keys and says where it is', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => FlareImagePreview.presentGallery(
                context,
                images: images,
                initialIndex: 1,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('2 / 3'), findsOneWidget);
      expect(find.bySemanticsLabel('第 2 张，共 3 张'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('下一张'));
      await tester.pump();
      expect(find.text('3 / 3'), findsOneWidget);
      // At the last image the next key does nothing.
      await tester.tap(find.bySemanticsLabel('下一张'));
      await tester.pump();
      expect(find.text('3 / 3'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('上一张'));
      await tester.tap(find.bySemanticsLabel('上一张'));
      await tester.pump();
      expect(find.text('1 / 3'), findsOneWidget);
    });

    testWidgets('a sideways swipe pages', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  FlareImagePreview.presentGallery(context, images: images),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('1 / 3'), findsOneWidget);
      await tester.fling(
        find.byType(InteractiveViewer),
        const Offset(-300, 0),
        1500,
      );
      await tester.pumpAndSettle();
      expect(find.text('2 / 3'), findsOneWidget);
    });

    testWidgets('a single image shows no paging chrome', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: FlareImagePreview(
            show: true,
            imageSrc: 'https://cdn.example/a.jpg',
          ),
        ),
      );
      expect(find.bySemanticsLabel('下一张'), findsNothing);
      expect(find.textContaining(' / '), findsNothing);
    });

    testWidgets('a picture outside a timeline offers the download its body '
        'was given, and none without one', (tester) async {
      final downloads = <String>[];
      final picture = FlareImageContent(
        url: 'https://cdn.example/solo.jpg',
        alt: '海边',
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                FlareMessageContentView(
                  content: picture,
                  onMediaDownload: (content) =>
                      downloads.add((content as FlareImageContent).url),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.bySemanticsLabel('海边'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('下载'));
      await tester.pump();
      expect(downloads, ['https://cdn.example/solo.jpg']);

      // A new app, not the same one rebuilt: the first preview's route must not survive.
      await tester.pumpWidget(
        MaterialApp(
          key: UniqueKey(),
          home: Scaffold(
            body: Column(children: [FlareMessageContentView(content: picture)]),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('海边'));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('下载'), findsNothing);
    });

    testWidgets('the timeline gallery saves the picture on screen with the '
        'message it belongs to', (tester) async {
      final downloads = <String>[];
      final messages = [
        FlareMessageData(
          id: 'm1',
          senderId: 'u',
          senderName: 'U',
          content: images[0],
        ),
        FlareMessageData(
          id: 'm2',
          senderId: 'u',
          senderName: 'U',
          content: FlareImageGroupContent(images: [images[1], images[2]]),
        ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlareMessageList(
              messages: messages,
              currentUserId: 'me',
              onMediaDownload: (message, content) => downloads.add(
                '${message.id}:${(content as FlareImageContent).url}',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel(RegExp('第 2 张图片')));
      await tester.pumpAndSettle();
      expect(find.text('3 / 3'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('下载'));
      await tester.tap(find.bySemanticsLabel('上一张'));
      await tester.tap(find.bySemanticsLabel('上一张'));
      await tester.pump();
      expect(find.text('1 / 3'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('下载'));
      await tester.pump();
      expect(downloads, [
        'm2:https://cdn.example/2.jpg',
        'm1:https://cdn.example/0.jpg',
      ]);
    });

    testWidgets('an image in a timeline opens the timeline\'s gallery at it', (
      tester,
    ) async {
      final messages = [
        FlareMessageData(
          id: 'm1',
          senderId: 'u',
          senderName: 'U',
          content: images[0],
        ),
        FlareMessageData(
          id: 'm2',
          senderId: 'u',
          senderName: 'U',
          content: FlareImageGroupContent(images: [images[1], images[2]]),
        ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlareMessageList(messages: messages, currentUserId: 'me'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel(RegExp('第 2 张图片')));
      await tester.pumpAndSettle();
      expect(find.text('3 / 3'), findsOneWidget);
    });
  });
}
