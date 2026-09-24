import 'dart:typed_data';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final catalog = FlareEmojiStickerCatalog.instance;

  setUpAll(catalog.ensureLoaded);
  tearDown(() {
    catalog.clearRegisteredEmojiAssets();
    catalog.clearRegisteredStickerPacks();
  });

  MemoryImage memory(int value) =>
      MemoryImage(Uint8List.fromList(<int>[value]));

  test(
    'runtime emoji keeps separate animation and static preview providers',
    () {
      final animated = memory(1);
      final preview = memory(2);
      catalog.registerEmojiAssets(<FlareEmojiAssetRegistration>[
        FlareEmojiAssetRegistration(
          key: 'user_wave',
          image: animated,
          previewImage: preview,
          labels: const <String, String>{'en': 'User wave', 'zh-Hans': '用户挥手'},
        ),
      ]);

      expect(catalog.hasEmojiKey('user_wave'), isTrue);
      expect(catalog.emojiImageProvider('user_wave'), same(animated));
      expect(
        catalog.emojiImageProvider('user_wave', staticPreview: true),
        same(preview),
      );
      expect(catalog.emojiLabel('user_wave', locale: 'zh-CN'), '用户挥手');
      expect(resolveLoneEmojiPackInText('[user_wave]'), 'user_wave');
    },
  );

  test('runtime sticker pack is merged into the picker contract', () {
    final animated = memory(3);
    final preview = memory(4);
    catalog.registerStickerPacks(<FlareStickerPackRegistration>[
      FlareStickerPackRegistration(
        id: 'my_pack',
        title: 'My Pack',
        stickers: <FlareStickerAssetRegistration>[
          FlareStickerAssetRegistration(
            stickerId: 'party',
            image: animated,
            previewImage: preview,
          ),
        ],
      ),
    ]);

    expect(
      catalog.stickerPacks
          .singleWhere((pack) => pack.id == 'my_pack')
          .stickerIds,
      <String>['party'],
    );
    expect(
      catalog.stickerImageProvider(stickerId: 'party', packageId: 'my_pack'),
      same(animated),
    );
    expect(
      catalog.stickerImageProvider(
        stickerId: 'party',
        packageId: 'my_pack',
        staticPreview: true,
      ),
      same(preview),
    );
  });

  testWidgets(
    'plain text promotes only a lone emoji to the animated message body',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: FlareTextMessage(text: '[alien]')),
      );
      expect(find.byType(FlareEmojiPackMessage), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(home: FlareTextMessage(text: 'hello [alien]')),
      );
      expect(find.byType(FlareEmojiPackMessage), findsNothing);
      expect(find.byType(FlareStaticImage), findsOneWidget);
    },
  );
}
