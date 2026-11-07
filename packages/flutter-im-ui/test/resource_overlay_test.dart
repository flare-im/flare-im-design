import 'dart:convert';
import 'dart:io';

import 'package:flare_im_ui/flare_im_ui.dart';
import 'package:flare_im_ui/src/components/flare_overlay.dart'
    show flareOverlayScopes;
import 'package:flare_im_ui/src/tokens/flare_resource_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The shared table (`spec/resource-overlay-vectors.json`): what a resource pack
/// may change. The Vue, SwiftUI and Compose kits run the same file.
void main() {
  final table =
      jsonDecode(
            File('../../spec/resource-overlay-vectors.json').readAsStringSync(),
          )
          as Map<String, dynamic>;
  List<Map<String, dynamic>> rows(String key) =>
      (table[key] as List).cast<Map<String, dynamic>>();
  Set<String> stringSet(Object? list) => (list as List).cast<String>().toSet();

  Map<String, dynamic> stickerJson(FlareResourceSticker item) => {
    'stickerId': item.stickerId,
    'url': item.url,
    if (item.previewUrl != null) 'previewUrl': item.previewUrl,
    if (item.alt != null) 'alt': item.alt,
  };
  Map<String, dynamic> emojiJson(FlareResourceEmoji item) => {
    'key': item.key,
    'url': item.url,
    if (item.previewUrl != null) 'previewUrl': item.previewUrl,
    if (item.labels.isNotEmpty) 'labels': item.labels,
  };
  Map<String, dynamic> packJson(FlareResourceStickerPack pack) => {
    'id': pack.id,
    'title': pack.title,
    if (pack.iconUrl != null) 'iconUrl': pack.iconUrl,
    'stickers': pack.stickers.map(stickerJson).toList(),
  };

  group('rules', () {
    for (final row in rows('content')) {
      test(row['name'] as String, () {
        final content = flareResourceContent(
          row['kind'] as String,
          row['contentJson'] as String,
        );
        expect(content != null, row['accepted']);
      });
    }

    for (final row in rows('placeholders')) {
      test('reads the placeholders of "${row['text']}"', () {
        expect(flareResourcePlaceholders(row['text'] as String), row['expect']);
      });
    }

    for (final row in rows('strings')) {
      test(row['name'] as String, () {
        final builtIn = (row['builtIn'] as Map).cast<String, String>();
        expect(
          flareResourceStrings((key) => builtIn[key], row['entries']),
          row['expect'],
        );
      });
    }

    for (final row in rows('locales')) {
      test('answers ${row['requested']} from ${row['available']}', () {
        expect(
          flareResourceLocale(
            row['requested'] as String,
            (row['available'] as List).cast<String>(),
          ),
          row['expect'],
        );
      });
    }

    for (final row in rows('colors')) {
      test(row['name'] as String, () {
        expect(
          flareResourceColors(stringSet(row['known']), row['group']),
          row['expect'],
        );
      });
    }

    for (final row in rows('argb')) {
      test('reads ${row['value']} as a colour', () {
        expect(flareResourceColorArgb(row['value'] as String), row['argb']);
      });
    }

    for (final row in rows('emoji')) {
      test(row['name'] as String, () {
        final result = flareResourceEmoji(
          stringSet(row['builtInEmoji']),
          stringSet(row['builtInPacks']),
          row['packs'],
        );
        final want = row['expect'] as Map<String, dynamic>;
        expect(result.emoji.map(emojiJson).toList(), want['emoji']);
        expect(result.stickerPacks.map(packJson).toList(), want['stickerPacks']);
      });
    }

    for (final row in rows('fold')) {
      test(row['name'] as String, () {
        final overlay = FlareResourceOverlay(
          (row['packs'] as List).cast<Map<String, dynamic>>().map(
            (pack) => FlareResourcePack(
              id: pack['id'] as String,
              kind: pack['kind'] as String,
              packVersion: pack['packVersion'] as int,
              contentJson: pack['contentJson'] as String,
            ),
          ),
        );
        final builtIn = (row['builtIn'] as Map).cast<String, String>();
        final known = stringSet(row['known']);
        final want = row['expect'] as Map<String, dynamic>;
        expect(
          overlay.stringValues(row['locale'] as String, (key) => builtIn[key]),
          want['strings'],
        );
        expect(overlay.colorValues(dark: false, known: known), want['light']);
        expect(overlay.colorValues(dark: true, known: known), want['dark']);
      });
    }
  });

  FlareResourcePack stringsPack(Map<String, Object?> locales) =>
      FlareResourcePack(
        id: 'strings',
        kind: 'strings',
        contentJson: jsonEncode(<String, Object?>{
          'schema': flareResourceSchema,
          'kind': 'strings',
          'locales': locales,
        }),
      );
  FlareResourcePack tokensPack(Map<String, Object?> groups) =>
      FlareResourcePack(
        id: 'tokens',
        kind: 'tokens',
        contentJson: jsonEncode(<String, Object?>{
          'schema': flareResourceSchema,
          'kind': 'tokens',
          ...groups,
        }),
      );

  group('strings', () {
    test('replaces a field by its name and leaves the others', () {
      final overlay = FlareResourceOverlay([
        stringsPack({
          'en': {'send': 'Post'},
        }),
      ]);
      final folded = overlay.strings(flareStringsEnglish, locale: 'en-US');
      expect(folded.send, 'Post');
      expect(folded.cancelReply, flareStringsEnglish.cancelReply);
    });

    test('keeps every field of the word list it folds over', () {
      final overlay = FlareResourceOverlay([
        stringsPack({
          'en': {'send': 'Post'},
        }),
      ]);
      final folded = overlay.strings(flareStringsEnglish, locale: 'en');
      expect(folded.report, flareStringsEnglish.report);
      expect(folded.readTab(3), flareStringsEnglish.readTab(3));
    });

    test('a function field is not a key', () {
      expect(flareStringValue(const FlareStrings(), 'readTab'), isNull);
      final overlay = FlareResourceOverlay([
        stringsPack({
          'en': {'readTab': 'Seen'},
        }),
      ]);
      expect(
        identical(
          overlay.strings(flareStringsEnglish, locale: 'en'),
          flareStringsEnglish,
        ),
        isTrue,
      );
    });

    test('hands back the same object when it has nothing to say', () {
      expect(
        identical(
          FlareResourceOverlay.empty.strings(
            flareStringsEnglish,
            locale: 'en',
          ),
          flareStringsEnglish,
        ),
        isTrue,
      );
    });
  });

  group('colors', () {
    final overlay = FlareResourceOverlay([
      tokensPack({
        'colors': {'primary': '#112233'},
        'dark': {'bgPrimary': '#44556677'},
      }),
    ]);

    test('keeps light and dark apart', () {
      final light = overlay.colors(FlareColors.light, dark: false);
      expect(light.primary, const Color(0xFF112233));
      expect(light.bgPrimary, FlareColors.light.bgPrimary);
      final dark = overlay.colors(FlareColors.dark, dark: true);
      expect(dark.primary, FlareColors.dark.primary);
      expect(dark.bgPrimary, const Color(0x77445566));
    });

    test('hands back the same object when it has nothing to set', () {
      expect(
        identical(
          FlareResourceOverlay.empty.colors(FlareColors.light, dark: false),
          FlareColors.light,
        ),
        isTrue,
      );
    });
  });

  group('what is on screen follows', () {
    testWidgets('a mounted subtree takes the copy and colours that arrive later', (
      tester,
    ) async {
      final overlay = ValueNotifier<FlareResourceOverlay>(
        FlareResourceOverlay.empty,
      );
      addTearDown(overlay.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: ValueListenableBuilder<FlareResourceOverlay>(
            valueListenable: overlay,
            builder: (context, value, child) => FlareStringsScope(
              strings: value.strings(flareStringsEnglish, locale: 'en'),
              child: FlareTheme(
                mode: FlareThemeMode.light,
                colors: value.colors(FlareColors.light, dark: false),
                child: child!,
              ),
            ),
            child: Builder(
              builder: (context) => Text(
                FlareStringsScope.of(context).send,
                style: TextStyle(color: FlareColors.of(context).primary),
              ),
            ),
          ),
        ),
      );
      expect(find.text(flareStringsEnglish.send), findsOneWidget);

      overlay.value = FlareResourceOverlay([
        stringsPack({
          'en': {'send': 'Post'},
        }),
        tokensPack({
          'colors': {'primary': '#112233'},
        }),
      ]);
      await tester.pump();

      expect(find.text('Post'), findsOneWidget);
      expect(
        tester.widget<Text>(find.text('Post')).style?.color,
        const Color(0xFF112233),
      );
    });
  });

  group('FlareTheme.darkColors', () {
    final lightSet = FlareColors.light.copyWith(primary: const Color(0xFF112233));
    final darkSet = FlareColors.dark.copyWith(primary: const Color(0xFF445566));

    Widget probed(Brightness brightness, FlareTheme Function(Widget) theme) =>
        MaterialApp(
          home: theme(
            Theme(
              data: ThemeData(brightness: brightness),
              child: Builder(
                builder: (context) =>
                    Text('${FlareColors.of(context).primary.toARGB32()}'),
              ),
            ),
          ),
        );

    testWidgets('each brightness takes its own colours', (tester) async {
      FlareTheme both(Widget child) =>
          FlareTheme(colors: lightSet, darkColors: darkSet, child: child);

      await tester.pumpWidget(probed(Brightness.light, both));
      expect(find.text('${lightSet.primary.toARGB32()}'), findsOneWidget);

      await tester.pumpWidget(probed(Brightness.dark, both));
      expect(find.text('${darkSet.primary.toARGB32()}'), findsOneWidget);
    });

    testWidgets('colours alone hold in either brightness', (tester) async {
      FlareTheme fixed(Widget child) =>
          FlareTheme(colors: lightSet, child: child);

      await tester.pumpWidget(probed(Brightness.dark, fixed));
      expect(find.text('${lightSet.primary.toARGB32()}'), findsOneWidget);
    });

    testWidgets('dark colours alone leave light mode built in', (tester) async {
      FlareTheme darkOnly(Widget child) =>
          FlareTheme(darkColors: darkSet, child: child);

      await tester.pumpWidget(probed(Brightness.light, darkOnly));
      expect(
        find.text('${FlareColors.light.primary.toARGB32()}'),
        findsOneWidget,
      );
    });

    testWidgets('a new set reaches who read the old one', (tester) async {
      FlareTheme first(Widget child) =>
          FlareTheme(colors: lightSet, darkColors: darkSet, child: child);
      final other = FlareColors.dark.copyWith(primary: const Color(0xFF778899));
      FlareTheme second(Widget child) =>
          FlareTheme(colors: lightSet, darkColors: other, child: child);

      await tester.pumpWidget(probed(Brightness.dark, first));
      await tester.pumpWidget(probed(Brightness.dark, second));
      expect(find.text('${other.primary.toARGB32()}'), findsOneWidget);
    });

    testWidgets('a route keeps both sets', (tester) async {
      late Widget Function(Widget) scopes;
      await tester.pumpWidget(
        MaterialApp(
          home: FlareTheme(
            colors: lightSet,
            darkColors: darkSet,
            child: Builder(
              builder: (context) {
                scopes = flareOverlayScopes(context);
                return const SizedBox();
              },
            ),
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: scopes(
            Builder(
              builder: (context) {
                final theme = FlareTheme.maybeOf(context);
                return Text(
                  '${theme?.colors?.primary.toARGB32()}'
                  ' ${theme?.darkColors?.primary.toARGB32()}',
                );
              },
            ),
          ),
        ),
      );
      expect(
        find.text(
          '${lightSet.primary.toARGB32()} ${darkSet.primary.toARGB32()}',
        ),
        findsOneWidget,
      );
    });
  });

  group('emoji', () {
    final catalog = FlareEmojiStickerCatalog.instance;

    setUpAll(catalog.ensureLoaded);
    tearDown(() {
      catalog.clearRegisteredEmojiAssets();
      catalog.clearRegisteredStickerPacks();
    });

    test('adds to the catalog and leaves what ships alone', () async {
      final builtIn = catalog.bundledEmojiKeys.first;
      final overlay = FlareResourceOverlay([
        FlareResourcePack(
          id: 'emoji',
          kind: 'emoji',
          contentJson: jsonEncode(<String, Object?>{
            'schema': flareResourceSchema,
            'kind': 'emoji',
            'packs': [
              {
                'id': 'acme',
                'title': 'Acme',
                'stickers': [
                  {'stickerId': 'wave', 'url': 'https://cdn.example/w.webp'},
                ],
                'emoji': [
                  {'key': 'acme_wave', 'url': 'https://cdn.example/e.webp'},
                  {'key': builtIn, 'url': 'https://cdn.example/b.webp'},
                ],
              },
            ],
          }),
        ),
      ]);

      await overlay.registerEmoji(catalog);

      expect(catalog.hasEmojiKey('acme_wave'), isTrue);
      expect(catalog.emojiImageProvider('acme_wave'), isA<NetworkImage>());
      expect(catalog.emojiImageProvider(builtIn), isA<AssetImage>());
      expect(
        catalog.stickerPacks.firstWhere((pack) => pack.id == 'acme').stickerIds,
        ['wave'],
      );
    });
  });
}
