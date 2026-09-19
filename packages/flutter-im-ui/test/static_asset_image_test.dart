import 'dart:async';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('static sticker cache distinguishes decode sizes', (
    tester,
  ) async {
    Future<void> show(int size) async {
      await tester.pumpWidget(
        MaterialApp(
          home: FlareStaticAssetImage(
            assetPath: 'assets/emoji-sticker/emoji/grinning_face.webp',
            package: 'flare_im_ui',
            decodeSize: size,
          ),
        ),
      );
      for (var i = 0; i < 10; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 25)),
        );
        await tester.pump();
      }
    }

    await show(24);
    final first = tester.widget<Image>(find.byType(Image)).image;
    await show(48);
    final second = tester.widget<Image>(find.byType(Image)).image;
    expect(first, isNot(equals(second)));
    await show(24);
    expect(tester.widget<Image>(find.byType(Image)).image, equals(first));
    expect(tester.takeException(), isNull);
  });

  testWidgets('late asset failures cannot replace a newer decoded image', (
    tester,
  ) async {
    final pending = Completer<ByteData?>();
    final bytes = await tester.runAsync(
      () => rootBundle.load(
        'packages/flare_im_ui/assets/emoji-sticker/emoji/grinning_face.webp',
      ),
    );
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMessageHandler('flutter/assets', (message) async {
      final key = const StringCodec().decodeMessage(message);
      if (key == 'old.webp') return pending.future;
      return bytes;
    });
    addTearDown(() => messenger.setMockMessageHandler('flutter/assets', null));
    Widget host(String path) =>
        MaterialApp(home: FlareStaticAssetImage(assetPath: path));
    await tester.pumpWidget(host('old.webp'));
    await tester.pumpWidget(host('new.webp'));
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 25)),
      );
      await tester.pump();
    }
    expect(find.byType(Image), findsOneWidget);
    pending.complete(null);
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
    expect(find.byType(Image), findsOneWidget);
    expect(find.byIcon(Icons.broken_image_outlined), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
