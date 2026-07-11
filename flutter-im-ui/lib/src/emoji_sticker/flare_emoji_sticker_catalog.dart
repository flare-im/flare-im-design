import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// One sticker pack from the manifest.
class FlareStickerPack {
  const FlareStickerPack({
    required this.id,
    required this.dir,
    required this.title,
    required this.stickerIds,
  });

  /// Protocol packageId (e.g. `gifs`, `classic`).
  final String id;

  /// On-disk dir relative to the resource root, e.g. `stickers/default`.
  final String dir;
  final String title;
  final List<String> stickerIds;
}

/// Cross-platform emoji-pack + sticker catalog, backed by the flare-im-design
/// manifest bundled with this package (a symlink mirror of the single source
/// `flare-im-design/assets/emoji-sticker`).
///
/// Message views resolve assets by path convention (no load needed — a missing
/// file just triggers the widget's fallback). The picker and localized labels
/// use [ensureLoaded] to read the manifest + locales.
class FlareEmojiStickerCatalog {
  FlareEmojiStickerCatalog._();

  static final FlareEmojiStickerCatalog instance = FlareEmojiStickerCatalog._();

  /// This package's name — used to key bundled assets.
  static const String package = 'flare_im_ui';
  static const String _base = 'assets/emoji-sticker';

  /// Protocol packageId whose on-disk dir is `default/` (matches every platform).
  static const String stickerPackageGifs = 'gifs';

  bool _loaded = false;
  List<String> _emojiKeys = const <String>[];
  Set<String> _emojiKeySet = const <String>{};
  List<FlareStickerPack> _stickerPacks = const <FlareStickerPack>[];
  Map<String, dynamic> _locales = const <String, dynamic>{};

  bool get isLoaded => _loaded;
  List<String> get emojiKeys => _emojiKeys;
  List<FlareStickerPack> get stickerPacks => _stickerPacks;

  /// Loads the manifest + locale labels once. Safe to call repeatedly.
  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final manifestStr =
        await rootBundle.loadString('packages/$package/$_base/manifest.json');
    final manifest = jsonDecode(manifestStr) as Map<String, dynamic>;

    final emoji = (manifest['emoji'] as Map<String, dynamic>?) ?? const {};
    _emojiKeys = ((emoji['keys'] as List?) ?? const [])
        .map((e) => e.toString())
        .toList(growable: false);
    _emojiKeySet = _emojiKeys.toSet();

    final packs = (manifest['stickerPacks'] as List?) ?? const [];
    _stickerPacks = packs
        .map((raw) {
          final map = raw as Map<String, dynamic>;
          final items = (map['items'] as List?) ?? const [];
          return FlareStickerPack(
            id: map['id']?.toString() ?? '',
            dir: map['dir']?.toString() ?? '',
            title: map['title']?.toString() ?? '',
            stickerIds: items
                .map((it) => (it as Map<String, dynamic>)['id'].toString())
                .toList(growable: false),
          );
        })
        .toList(growable: false);

    try {
      final localesStr =
          await rootBundle.loadString('packages/$package/$_base/emoji-locales.json');
      _locales = jsonDecode(localesStr) as Map<String, dynamic>;
    } catch (_) {
      _locales = const <String, dynamic>{};
    }

    _loaded = true;
  }

  bool hasEmojiKey(String key) => _emojiKeySet.contains(key.trim());

  /// On-disk sticker subdir for a protocol packageId (`gifs` → `default`).
  static String stickerSubdirForPackageId(String? packageId) {
    final p = packageId?.trim() ?? '';
    if (p.isEmpty || p == stickerPackageGifs) return 'default';
    return p;
  }

  /// Asset path for [Image.asset] (pair with `package: FlareEmojiStickerCatalog.package`).
  static String emojiAssetPath(String key) => '$_base/emoji/${key.trim()}.webp';

  static String stickerAssetPath({
    required String stickerId,
    String? packageId,
  }) =>
      '$_base/stickers/${stickerSubdirForPackageId(packageId)}/${stickerId.trim()}.webp';

  /// rootBundle key (for byte loads / first-frame decode).
  static String bundleKey(String assetPath) => 'packages/$package/$assetPath';

  /// Localized emoji-pack label; falls back to the raw key.
  String emojiLabel(String key, {String? locale}) {
    final k = key.trim();
    if (k.isEmpty) return '';
    if (_locales.isEmpty) return k;
    final column = (locale ?? 'en').toLowerCase().startsWith('zh') ? 'zh-Hans' : 'en';
    final primary = (_locales[column] as Map<String, dynamic>?)?[k];
    if (primary is String && primary.trim().isNotEmpty) return primary.trim();
    final en = (_locales['en'] as Map<String, dynamic>?)?[k];
    if (en is String && en.trim().isNotEmpty) return en.trim();
    return k;
  }

  String emojiBracketLabel(String key, {String? locale}) =>
      '[${emojiLabel(key, locale: locale)}]';
}
