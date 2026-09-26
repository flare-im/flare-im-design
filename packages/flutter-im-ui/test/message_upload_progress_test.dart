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

  group('flareMediaImageProvider', () {
    test('reads remote, inline and local pictures', () {
      expect(
        flareMediaImageProvider('https://cdn.example/a.png'),
        isA<NetworkImage>(),
      );
      expect(
        flareMediaImageProvider('data:image/png;base64,iVBORw0KGgo='),
        isA<MemoryImage>(),
      );
      final local = flareMediaImageProvider('/tmp/picked.png');
      expect(local, isA<FileImage>());
      expect((local! as FileImage).file.path, '/tmp/picked.png');
      final uri = flareMediaImageProvider('file:///tmp/a%20b.png');
      expect((uri! as FileImage).file.path, File('/tmp/a b.png').path);
    });

    test('has no picture for anything it cannot load', () {
      expect(flareMediaImageProvider(null), isNull);
      expect(flareMediaImageProvider('  '), isNull);
      expect(flareMediaImageProvider('file-id-123'), isNull);
      expect(flareMediaImageProvider('ftp://host/a.png'), isNull);
    });
  });
}
