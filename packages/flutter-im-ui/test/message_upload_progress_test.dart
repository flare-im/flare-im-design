import 'dart:io';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

FlareMessageData _mine(FlareMessageContent content, {int? uploadProgress}) =>
    FlareMessageData(
      id: 'm1',
      senderId: 'me',
      senderName: 'me',
      content: content,
      timeLabel: '14:32',
      status: FlareMessageDeliveryStatus.sending,
      uploadProgress: uploadProgress,
    );

void main() {
  group('upload progress on the bubble', () {
    testWidgets(
      'a file uploading shows its name, size and the percent under it',
      (tester) async {
        await tester.pumpWidget(
          _host(
            FlareMessageBubble(
              currentUserId: 'me',
              message: _mine(
                const FlareFileContent(
                  name: '季度报表.xlsx',
                  url: '/tmp/季度报表.xlsx',
                  sizeBytes: 2048,
                ),
                uploadProgress: 37,
              ),
            ),
          ),
        );
        expect(find.text('季度报表.xlsx'), findsOneWidget);
        expect(find.text('2.0 KB · XLSX'), findsOneWidget);
        final progress = tester.widget<FlareUploadProgress>(
          find.byType(FlareUploadProgress),
        );
        expect(progress.percent, 37);
        expect(progress.overlay, isFalse);
        expect(find.text('37%'), findsOneWidget);
      },
    );

    testWidgets('an image uploading carries the percent over the picture', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          FlareMessageBubble(
            currentUserId: 'me',
            message: _mine(
              const FlareImageContent(url: '/tmp/none.png'),
              uploadProgress: 5,
            ),
          ),
        ),
      );
      final progress = tester.widget<FlareUploadProgress>(
        find.byType(FlareUploadProgress),
      );
      expect(progress.overlay, isTrue);
      expect(find.text('5%'), findsOneWidget);
    });

    testWidgets('nothing is drawn once the upload is over', (tester) async {
      await tester.pumpWidget(
        _host(
          FlareMessageBubble(
            currentUserId: 'me',
            message: _mine(
              const FlareFileContent(name: 'a.pdf', url: 'https://x/a.pdf'),
            ),
          ),
        ),
      );
      expect(find.byType(FlareUploadProgress), findsNothing);
    });
  });

  group('pictures from a file on this device', () {
    FlareMessageData message(String sender, {int? uploadProgress}) =>
        FlareMessageData(
          id: 'm-$sender',
          senderId: sender,
          senderName: sender,
          content: const FlareImageContent(url: '/tmp/picked.png'),
          uploadProgress: uploadProgress,
        );
    Iterable<ImageProvider> providers(WidgetTester tester) =>
        tester.widgetList<Image>(find.byType(Image)).map((i) => i.image);

    testWidgets('are drawn for my own picture while it uploads', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          FlareMessageBubble(
            currentUserId: 'me',
            message: message('me', uploadProgress: 10),
          ),
        ),
      );
      expect(providers(tester).whereType<FileImage>(), hasLength(1));
    });

    testWidgets('are never drawn for a message someone else wrote', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(FlareMessageBubble(currentUserId: 'me', message: message('ivy'))),
      );
      expect(providers(tester).whereType<FileImage>(), isEmpty);
    });

    testWidgets('the copy the host resolved through the SDK cache is drawn '
        'for anyone\'s picture, bubble and preview', (tester) async {
      await tester.pumpWidget(
        _host(
          FlareMessageBubble(
            currentUserId: 'me',
            message: const FlareMessageData(
              id: 'm-cached',
              senderId: 'ivy',
              senderName: 'ivy',
              content: FlareImageContent(
                url: 'https://cdn.example/a.png?sig=1',
                localPath: '/tmp/cache/a.png',
              ),
            ),
          ),
        ),
      );
      final drawn = providers(tester).whereType<FileImage>().toList();
      expect(drawn.single.file.path, '/tmp/cache/a.png');

      await tester.tap(find.byType(FlareImageMessage));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      final preview = tester.widget<FlareImagePreview>(
        find.byType(FlareImagePreview),
      );
      expect(preview.imageSrc, '/tmp/cache/a.png');
      expect(preview.allowLocalFile, isTrue);
    });

    test('a picture source prefers the local copy, then thumbnail or full', () {
      const remote = FlareImageContent(
        url: 'https://cdn.example/full.png',
        thumbnailUrl: 'https://cdn.example/thumb.png',
      );
      expect(flarePictureSource(remote), (
        src: 'https://cdn.example/thumb.png',
        local: false,
      ));
      expect(flarePictureSource(remote, preferThumbnail: false), (
        src: 'https://cdn.example/full.png',
        local: false,
      ));
      const cached = FlareImageContent(url: '', localPath: '/c/p.png');
      expect(flarePictureSource(cached), (src: '/c/p.png', local: true));
    });

    test('need an explicit request', () {
      expect(
        flareMediaImageProvider('https://cdn.example/a.png'),
        isA<NetworkImage>(),
      );
      expect(
        flareMediaImageProvider('data:image/png;base64,iVBORw0KGgo='),
        isA<MemoryImage>(),
      );
      expect(flareMediaImageProvider('/tmp/picked.png'), isNull);
      expect(flareMediaImageProvider('file:///tmp/picked.png'), isNull);
      final local = flareMediaImageProvider(
        '/tmp/picked.png',
        allowLocalFile: true,
      );
      expect((local! as FileImage).file.path, '/tmp/picked.png');
      final uri = flareMediaImageProvider(
        'file:///tmp/a%20b.png',
        allowLocalFile: true,
      );
      expect((uri! as FileImage).file.path, File('/tmp/a b.png').path);
    });

    test('have no picture for anything else', () {
      expect(flareMediaImageProvider(null), isNull);
      expect(flareMediaImageProvider('  '), isNull);
      expect(
        flareMediaImageProvider('file-id-123', allowLocalFile: true),
        isNull,
      );
      expect(
        flareMediaImageProvider('ftp://host/a.png', allowLocalFile: true),
        isNull,
      );
    });
  });

  testWidgets('the video player offers a download key only with a handler', (
    tester,
  ) async {
    FlareMessageContent? saved;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FlareMessageContentView(
            content: const FlareVideoContent(url: 'https://cdn.example/v.mp4'),
            onMediaDownload: (c) => saved = c,
          ),
        ),
      ),
    );
    await tester.tap(find.byType(FlareVideoMessage));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    final player = tester.widget<FlareVideoPlayer>(
      find.byType(FlareVideoPlayer),
    );
    expect(player.onDownload, isNotNull);
    player.onDownload!();
    expect(saved, isA<FlareVideoContent>());
  });

  testWidgets('an uploading video is its card, and does not play yet', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        FlareMessageBubble(
          currentUserId: 'me',
          message: _mine(const FlareVideoContent(url: ''), uploadProgress: 40),
        ),
      ),
    );
    final video = tester.widget<FlareVideoMessage>(
      find.byType(FlareVideoMessage),
    );
    expect(video.onPlay, isNull);
    expect(find.text('40%'), findsOneWidget);
  });
}
