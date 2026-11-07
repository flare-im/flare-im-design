import 'dart:convert';
import 'dart:ui' show Color;

import 'package:flutter/painting.dart' show NetworkImage;

import '../emoji_sticker/flare_emoji_sticker_catalog.dart';
import '../tokens/flare_resource_keys.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';

// What a resource pack may change, the same on four kits
// (`spec/resource-overlay-vectors.json`). A pack is data read by code already in
// the build: it replaces copy and colours that exist and adds emoji, and nothing
// else.

const String flareResourceSchema = 'flare.resource.v1';

final RegExp _placeholder = RegExp(r'\{[A-Za-z0-9_]+\}|%[sd@]');
final RegExp _color = RegExp(r'^#[0-9A-Fa-f]{6}(?:[0-9A-Fa-f]{2})?$');
final RegExp _safeId = RegExp(r'^[A-Za-z0-9_-]+$');
final RegExp _emojiKey = RegExp(r'^[a-z][a-z0-9_]*$');
final RegExp _httpsUrl = RegExp(
  r'^https://[A-Za-z0-9.-]+(?::[0-9]+)?(?:[/?#][!-~]*)?$',
);

/// One entry of `update.get_resources`, as the SDK returns it.
class FlareResourcePack {
  const FlareResourcePack({
    required this.id,
    required this.kind,
    this.packVersion = 0,
    required this.contentJson,
  });

  final String id;
  final String kind;
  final int packVersion;
  final String contentJson;
}

class FlareResourceEmoji {
  const FlareResourceEmoji({
    required this.key,
    required this.url,
    this.previewUrl,
    this.labels = const <String, String>{},
  });

  final String key;
  final String url;
  final String? previewUrl;
  final Map<String, String> labels;
}

class FlareResourceSticker {
  const FlareResourceSticker({
    required this.stickerId,
    required this.url,
    this.previewUrl,
    this.alt,
  });

  final String stickerId;
  final String url;
  final String? previewUrl;
  final String? alt;
}

class FlareResourceStickerPack {
  const FlareResourceStickerPack({
    required this.id,
    required this.title,
    this.iconUrl,
    required this.stickers,
  });

  final String id;
  final String title;
  final String? iconUrl;
  final List<FlareResourceSticker> stickers;
}

class FlareResourceEmojiResult {
  const FlareResourceEmojiResult({
    required this.emoji,
    required this.stickerPacks,
  });

  final List<FlareResourceEmoji> emoji;
  final List<FlareResourceStickerPack> stickerPacks;
}

/// The pack's content when it is the object its manifest entry promised, else null.
Map<String, dynamic>? flareResourceContent(String kind, String contentJson) {
  final Object? parsed;
  try {
    parsed = jsonDecode(contentJson);
  } on FormatException {
    return null;
  }
  if (parsed is! Map<String, dynamic>) return null;
  return parsed['schema'] == flareResourceSchema && parsed['kind'] == kind
      ? parsed
      : null;
}

/// The placeholders [text] carries, as a sorted set.
List<String> flareResourcePlaceholders(String text) =>
    _placeholder.allMatches(text).map((m) => m.group(0)!).toSet().toList()
      ..sort();

bool _samePlaceholders(String a, String b) =>
    flareResourcePlaceholders(a).join('\n') ==
    flareResourcePlaceholders(b).join('\n');

/// The entries of one language that may replace the built-in text [builtIn]
/// answers for each key.
Map<String, String> flareResourceStrings(
  String? Function(String key) builtIn,
  Object? entries,
) {
  final accepted = <String, String>{};
  if (entries is! Map<String, dynamic>) return accepted;
  entries.forEach((key, value) {
    final current = builtIn(key);
    if (current == null || value is! String || value.trim().isEmpty) return;
    if (_samePlaceholders(current, value)) accepted[key] = value;
  });
  return accepted;
}

String _normalizedTag(String tag) =>
    tag.trim().toLowerCase().replaceAll('_', '-');

/// The tag of [available] that speaks for [requested], or null: copy never
/// crosses into another language.
String? flareResourceLocale(String requested, Iterable<String> available) {
  final wanted = _normalizedTag(requested);
  if (wanted.isEmpty) return null;
  final tags = <String, String>{};
  for (final tag in available) {
    tags.putIfAbsent(_normalizedTag(tag), () => tag);
  }
  for (
    var cut = wanted;
    cut.isNotEmpty;
    cut = cut.contains('-') ? cut.substring(0, cut.lastIndexOf('-')) : ''
  ) {
    final exact = tags[cut];
    if (exact != null) return exact;
  }
  final sorted = tags.keys.toList()..sort();
  for (final tag in sorted) {
    if (tag.startsWith('$wanted-')) return tags[tag];
  }
  return null;
}

/// The colours of one group whose key is known and whose value is `#RRGGBB` or
/// `#RRGGBBAA`.
Map<String, String> flareResourceColors(Set<String> known, Object? group) {
  final accepted = <String, String>{};
  if (group is! Map<String, dynamic>) return accepted;
  group.forEach((key, value) {
    if (known.contains(key) && value is String && _color.hasMatch(value)) {
      accepted[key] = value;
    }
  });
  return accepted;
}

/// A colour the rules accepted as `0xAARRGGBB`: `#RRGGBB` is opaque, `#RRGGBBAA`
/// puts its alpha first.
int flareResourceColorArgb(String value) {
  final rgb = int.parse(value.substring(1, 7), radix: 16);
  final alpha = value.length == 9
      ? int.parse(value.substring(7), radix: 16)
      : 0xFF;
  return alpha * 0x1000000 + rgb;
}

bool _isHttps(Object? value) => value is String && _httpsUrl.hasMatch(value);

/// An image address an entry can keep: absent, or https.
bool _optionalUrlOk(Object? value) => value == null || _isHttps(value);

String? _filled(Object? value) {
  if (value is! String) return null;
  final text = value.trim();
  return text.isEmpty ? null : text;
}

FlareResourceSticker? _stickerOf(Object? raw, Set<String> seen) {
  if (raw is! Map<String, dynamic>) return null;
  final id = raw['stickerId'];
  if (id is! String || !_safeId.hasMatch(id) || seen.contains(id)) return null;
  if (!_isHttps(raw['url']) || !_optionalUrlOk(raw['previewUrl'])) return null;
  seen.add(id);
  return FlareResourceSticker(
    stickerId: id,
    url: raw['url'] as String,
    previewUrl: raw['previewUrl'] as String?,
    alt: _filled(raw['alt']),
  );
}

FlareResourceEmoji? _emojiOf(Object? raw, Set<String> seen) {
  if (raw is! Map<String, dynamic>) return null;
  final key = raw['key'];
  if (key is! String || !_emojiKey.hasMatch(key) || seen.contains(key)) {
    return null;
  }
  if (!_isHttps(raw['url']) || !_optionalUrlOk(raw['previewUrl'])) return null;
  seen.add(key);
  final labels = <String, String>{};
  final rawLabels = raw['labels'];
  if (rawLabels is Map<String, dynamic>) {
    rawLabels.forEach((tag, label) {
      final text = _filled(label);
      if (text != null) labels[tag] = text;
    });
  }
  return FlareResourceEmoji(
    key: key,
    url: raw['url'] as String,
    previewUrl: raw['previewUrl'] as String?,
    labels: labels,
  );
}

/// The emoji and sticker packs that add to the catalog. Nothing here replaces
/// what ships with the kit.
FlareResourceEmojiResult flareResourceEmoji(
  Iterable<String> builtInEmoji,
  Iterable<String> builtInPacks,
  Object? packs,
) {
  final emoji = <FlareResourceEmoji>[];
  final stickerPacks = <FlareResourceStickerPack>[];
  if (packs is List) {
    final seenKeys = builtInEmoji.toSet();
    final seenPacks = builtInPacks.toSet();
    for (final raw in packs) {
      if (raw is! Map<String, dynamic>) continue;
      final id = raw['id'];
      final title = _filled(raw['title']);
      if (id is! String || !_safeId.hasMatch(id) || seenPacks.contains(id)) {
        continue;
      }
      if (title == null || !_optionalUrlOk(raw['iconUrl'])) continue;
      final seenStickers = <String>{};
      final rawStickers = raw['stickers'];
      final stickers = <FlareResourceSticker>[
        if (rawStickers is List)
          for (final item in rawStickers)
            ?_stickerOf(item, seenStickers),
      ];
      final rawEmoji = raw['emoji'];
      final entries = <FlareResourceEmoji>[
        if (rawEmoji is List)
          for (final item in rawEmoji) ?_emojiOf(item, seenKeys),
      ];
      if (stickers.isEmpty && entries.isEmpty) continue;
      seenPacks.add(id);
      emoji.addAll(entries);
      if (stickers.isNotEmpty) {
        stickerPacks.add(
          FlareResourceStickerPack(
            id: id,
            title: title,
            iconUrl: raw['iconUrl'] as String?,
            stickers: stickers,
          ),
        );
      }
    }
  }
  return FlareResourceEmojiResult(emoji: emoji, stickerPacks: stickerPacks);
}

/// The resource packs of this run, folded over what ships with the kit. Build it
/// from `update.get_resources`, keep it in the root's state, and pass what it
/// returns to the existing scopes:
///
/// ```dart
/// FlareStringsScope(
///   strings: overlay.strings(flareStringsEnglish, locale: 'en'),
///   child: FlareTheme(mode: mode, brand: brand, colors: overlay.colors(colors, dark: dark), child: app),
/// )
/// ```
///
/// An entry or a pack the rules refuse is left out and the rest stands; this
/// never throws. A help pack is the host's. With nothing to apply [strings] and
/// [colors] hand back the object they were given, so a root that holds on to it
/// rebuilds nothing.
class FlareResourceOverlay {
  FlareResourceOverlay(Iterable<FlareResourcePack> packs) {
    for (final pack in packs) {
      final content = flareResourceContent(pack.kind, pack.contentJson);
      if (content == null) continue;
      switch (pack.kind) {
        case 'strings':
          final locales = content['locales'];
          if (locales is Map<String, dynamic>) _stringPacks.add(locales);
        case 'tokens':
          _tokenPacks.add(content);
        case 'emoji':
          final entries = content['packs'];
          if (entries is List) _emojiPacks.addAll(entries);
      }
    }
  }

  /// No packs: what a root starts from, before the packs are read.
  static final FlareResourceOverlay empty = FlareResourceOverlay(
    const <FlareResourcePack>[],
  );

  final List<Map<String, dynamic>> _stringPacks = <Map<String, dynamic>>[];
  final List<Map<String, dynamic>> _tokenPacks = <Map<String, dynamic>>[];
  final List<Object?> _emojiPacks = <Object?>[];

  bool get isEmpty =>
      _stringPacks.isEmpty && _tokenPacks.isEmpty && _emojiPacks.isEmpty;

  /// What the strings packs say for [locale], in pack order: a later pack wins a
  /// key. [builtIn] answers for a table's keys, so a host's own table takes its
  /// entries under the same rules: a known key, the same placeholders.
  Map<String, String> stringValues(
    String locale,
    String? Function(String key) builtIn,
  ) {
    final accepted = <String, String>{};
    for (final locales in _stringPacks) {
      final tag = flareResourceLocale(locale, locales.keys);
      if (tag != null) {
        accepted.addAll(flareResourceStrings(builtIn, locales[tag]));
      }
    }
    return accepted;
  }

  /// One mode's colours, in pack order: a later pack wins a key. `colors` is
  /// light and `dark` dark; neither reaches the other.
  Map<String, String> colorValues({
    required bool dark,
    required Set<String> known,
  }) {
    final accepted = <String, String>{};
    for (final pack in _tokenPacks) {
      accepted.addAll(flareResourceColors(known, pack[dark ? 'dark' : 'colors']));
    }
    return accepted;
  }

  /// [base] with what the packs say for [locale], the language [base] is written in.
  FlareStrings strings(FlareStrings base, {required String locale}) {
    final accepted = stringValues(
      locale,
      (key) => flareStringValue(base, key),
    );
    return accepted.isEmpty ? base : flareStringsApplying(base, accepted);
  }

  /// [base], a theme's colours for that mode, with what the packs set for it.
  FlareColors colors(FlareColors base, {required bool dark}) {
    final accepted = colorValues(dark: dark, known: flareColorKeys);
    if (accepted.isEmpty) return base;
    return flareColorsApplying(base, <String, Color>{
      for (final entry in accepted.entries)
        entry.key: Color(flareResourceColorArgb(entry.value)),
    });
  }

  /// Adds the packs' emoji and stickers to [catalog]. Waits for the bundled
  /// manifest first: it decides what may not be replaced.
  Future<void> registerEmoji([FlareEmojiStickerCatalog? catalog]) async {
    if (_emojiPacks.isEmpty) return;
    final target = catalog ?? FlareEmojiStickerCatalog.instance;
    await target.ensureLoaded();
    final result = flareResourceEmoji(
      target.bundledEmojiKeys,
      target.bundledStickerPackIds,
      _emojiPacks,
    );
    if (result.emoji.isNotEmpty) {
      target.registerEmojiAssets(
        result.emoji.map(
          (item) => FlareEmojiAssetRegistration(
            key: item.key,
            image: NetworkImage(item.url),
            previewImage: item.previewUrl == null
                ? null
                : NetworkImage(item.previewUrl!),
            labels: item.labels,
          ),
        ),
      );
    }
    if (result.stickerPacks.isNotEmpty) {
      target.registerStickerPacks(
        result.stickerPacks.map(
          (pack) => FlareStickerPackRegistration(
            id: pack.id,
            title: pack.title,
            stickers: pack.stickers
                .map(
                  (item) => FlareStickerAssetRegistration(
                    stickerId: item.stickerId,
                    image: NetworkImage(item.url),
                    previewImage: item.previewUrl == null
                        ? null
                        : NetworkImage(item.previewUrl!),
                  ),
                )
                .toList(growable: false),
          ),
        ),
      );
    }
  }
}
