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
        expect(find.text('2.0 KB'), findsOneWidget);
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
