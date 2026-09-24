import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart' show rootBundle;

/// One sticker pack from the manifest.
class FlareStickerManifestPack {
  const FlareStickerManifestPack({
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

/// A user-installed emoji asset. [image] may be animated; composer, inline and
/// picker surfaces always decode just its first frame. Only the standalone
/// emoji message view uses [image] directly.
class FlareEmojiAssetRegistration {
  const FlareEmojiAssetRegistration({
    required this.key,
    required this.image,
    this.previewImage,
    this.labels = const <String, String>{},
  });

  final String key;
  final ImageProvider<Object> image;
  final ImageProvider<Object>? previewImage;
  final Map<String, String> labels;
}

class FlareStickerAssetRegistration {
  const FlareStickerAssetRegistration({
    required this.stickerId,
    required this.image,
    this.previewImage,
  });

  final String stickerId;
  final ImageProvider<Object> image;
  final ImageProvider<Object>? previewImage;
}

class FlareStickerPackRegistration {
  const FlareStickerPackRegistration({
    required this.id,
    required this.title,
    required this.stickers,
  });

  final String id;
  final String title;
  final List<FlareStickerAssetRegistration> stickers;
}

/// Cross-platform emoji-pack + sticker catalog, backed by the flare-im-design
/// manifest bundled with this package (a symlink mirror of the single source
/// `flare-im-design/assets/emoji-sticker`).
///
/// Message views resolve assets by path convention (no load needed — a missing
/// file just triggers the widget's fallback). The picker and localized labels
/// use [ensureLoaded] to read the manifest + locales.
class FlareEmojiStickerCatalog extends ChangeNotifier {
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
  List<FlareStickerManifestPack> _stickerPacks =
      const <FlareStickerManifestPack>[];
  Map<String, dynamic> _locales = const <String, dynamic>{};
  final Map<String, FlareEmojiAssetRegistration> _runtimeEmoji =
      <String, FlareEmojiAssetRegistration>{};
  final Map<String, FlareStickerPackRegistration> _runtimeStickerPacks =
      <String, FlareStickerPackRegistration>{};

  bool get isLoaded => _loaded;
  List<String> get emojiKeys => <String>[
    ..._emojiKeys.where((key) => !_runtimeEmoji.containsKey(key)),
    ..._runtimeEmoji.keys,
  ];
  List<FlareStickerManifestPack> get stickerPacks => <FlareStickerManifestPack>[
    ..._stickerPacks.where(
      (pack) => !_runtimeStickerPacks.containsKey(pack.id),
    ),
    ..._runtimeStickerPacks.values.map(
      (pack) => FlareStickerManifestPack(
        id: pack.id,
        dir: '',
        title: pack.title,
        stickerIds: pack.stickers
            .map((item) => item.stickerId)
            .toList(growable: false),
      ),
    ),
  ];

  /// Loads the manifest + locale labels once. Safe to call repeatedly.
  Future<void> ensureLoaded() async {
    if (_loaded) return;
    final manifestStr = await rootBundle.loadString(
      'packages/$package/$_base/manifest.json',
    );
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
          return FlareStickerManifestPack(
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
      final localesStr = await rootBundle.loadString(
        'packages/$package/$_base/emoji-locales.json',
      );
      _locales = jsonDecode(localesStr) as Map<String, dynamic>;
    } catch (_) {
      _locales = const <String, dynamic>{};
    }

    _loaded = true;
    notifyListeners();
  }

  bool hasEmojiKey(String key) {
    final normalized = key.trim();
    return _runtimeEmoji.containsKey(normalized) ||
        _emojiKeySet.contains(normalized);
  }

  static bool _isSafeComponent(String value) =>
      RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(value);

  static bool _isEmojiKey(String value) =>
      RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(value);

  /// Adds or replaces per-user emoji resources. Protocol tokens remain `[key]`.
  void registerEmojiAssets(Iterable<FlareEmojiAssetRegistration> assets) {
    for (final asset in assets) {
      final key = asset.key.trim();
      if (!_isEmojiKey(key)) continue;
      _runtimeEmoji[key] = FlareEmojiAssetRegistration(
        key: key,
        image: asset.image,
        previewImage: asset.previewImage,
        labels: Map<String, String>.unmodifiable(asset.labels),
      );
    }
    notifyListeners();
  }

  void unregisterEmojiAsset(String key) {
    if (_runtimeEmoji.remove(key.trim()) != null) notifyListeners();
  }

  void clearRegisteredEmojiAssets() {
    if (_runtimeEmoji.isEmpty) return;
    _runtimeEmoji.clear();
    notifyListeners();
  }

  /// Adds or replaces a complete user sticker pack.
  void registerStickerPacks(Iterable<FlareStickerPackRegistration> packs) {
    for (final pack in packs) {
      final id = pack.id.trim();
      if (!_isSafeComponent(id) || pack.title.trim().isEmpty) continue;
      final stickers = pack.stickers
          .where((item) => _isSafeComponent(item.stickerId.trim()))
          .map(
            (item) => FlareStickerAssetRegistration(
              stickerId: item.stickerId.trim(),
              image: item.image,
              previewImage: item.previewImage,
            ),
          )
          .toList(growable: false);
      _runtimeStickerPacks[id] = FlareStickerPackRegistration(
        id: id,
        title: pack.title.trim(),
        stickers: stickers,
      );
    }
    notifyListeners();
  }

  void unregisterStickerPack(String packageId) {
    if (_runtimeStickerPacks.remove(packageId.trim()) != null)
      notifyListeners();
  }

  void clearRegisteredStickerPacks() {
    if (_runtimeStickerPacks.isEmpty) return;
    _runtimeStickerPacks.clear();
    notifyListeners();
  }

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

  ImageProvider<Object> emojiImageProvider(
    String key, {
    bool staticPreview = false,
  }) {
    final normalized = key.trim();
    final runtime = _runtimeEmoji[normalized];
    if (runtime != null) {
      return staticPreview
          ? (runtime.previewImage ?? runtime.image)
          : runtime.image;
    }
    return AssetImage(emojiAssetPath(normalized), package: package);
  }

  ImageProvider<Object> stickerImageProvider({
    required String stickerId,
    String? packageId,
    bool staticPreview = false,
  }) {
    final pid = packageId?.trim().isNotEmpty == true
        ? packageId!.trim()
        : stickerPackageGifs;
    final runtime = _runtimeStickerPacks[pid]?.stickers
        .where((item) => item.stickerId == stickerId.trim())
        .firstOrNull;
    if (runtime != null) {
      return staticPreview
          ? (runtime.previewImage ?? runtime.image)
          : runtime.image;
    }
    return AssetImage(
      stickerAssetPath(stickerId: stickerId, packageId: packageId),
      package: package,
    );
  }

  /// Localized emoji-pack label; falls back to the raw key.
  String emojiLabel(String key, {String? locale}) {
    final k = key.trim();
    if (k.isEmpty) return '';
    final runtimeLabels = _runtimeEmoji[k]?.labels;
    if (runtimeLabels != null && runtimeLabels.isNotEmpty) {
      final normalized = (locale ?? 'en').toLowerCase();
      final exact = runtimeLabels.entries
          .where((entry) => entry.key.toLowerCase() == normalized)
          .map((entry) => entry.value.trim())
          .where((value) => value.isNotEmpty)
          .firstOrNull;
      if (exact != null) return exact;
      final language = normalized.split('-').first;
      final compatible = runtimeLabels.entries
          .where(
            (entry) => entry.key.toLowerCase().split('-').first == language,
          )
          .map((entry) => entry.value.trim())
          .where((value) => value.isNotEmpty)
          .firstOrNull;
      if (compatible != null) return compatible;
      final english = runtimeLabels['en']?.trim();
      if (english != null && english.isNotEmpty) return english;
    }
    if (_locales.isEmpty) return k;
    final column = (locale ?? 'en').toLowerCase().startsWith('zh')
        ? 'zh-Hans'
        : 'en';
    final primary = (_locales[column] as Map<String, dynamic>?)?[k];
    if (primary is String && primary.trim().isNotEmpty) return primary.trim();
    final en = (_locales['en'] as Map<String, dynamic>?)?[k];
    if (en is String && en.trim().isNotEmpty) return en.trim();
    return k;
  }

  /// A plain line with `[pack_key]` tokens read in the reader's language: a conversation row or a
  /// reply strip shows 一百分, not `[hundred_points]`. The bubble draws the real image instead; this is
  /// for the places that are only text. Vue's `formatPackKeysInPlainTextForPreview`, same rule.
  String localizePackKeysInText(String text, {String? locale}) {
    if (text.isEmpty) return text;
    return text.replaceAllMapped(
      RegExp(r'\[([a-z][a-z0-9_]*)\]'),
      (m) => emojiLabel(m.group(1)!, locale: locale),
    );
  }

  String emojiBracketLabel(String key, {String? locale}) =>
      '[${emojiLabel(key, locale: locale)}]';
}
