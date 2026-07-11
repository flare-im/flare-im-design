import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';
import 'flare_emoji_sticker_catalog.dart';

const double _kStickerLikeMaxSide = 120;

final RegExp _kBracketKey = RegExp(r'^\[([a-z][a-z0-9_]*)\]$');
final RegExp _kBareKey = RegExp(r'^([a-z][a-z0-9_]*)$');

String? _resolvePackKey(String raw) {
  final t = raw.trim();
  final b = _kBracketKey.firstMatch(t);
  if (b != null) return b.group(1);
  final n = _kBareKey.firstMatch(t);
  if (n != null) return n.group(1);
  return null;
}

/// Emoji-pack message body (`[key]` / bare key / a raw unicode emoji). A known
/// pack key renders the animated webp; otherwise the localized `[label]` or a
/// large unicode glyph.
class FlareEmojiPackMessage extends StatefulWidget {
  const FlareEmojiPackMessage({super.key, required this.emoji, this.isSelf = false});

  final String emoji;
  final bool isSelf;

  @override
  State<FlareEmojiPackMessage> createState() => _FlareEmojiPackMessageState();
}

class _FlareEmojiPackMessageState extends State<FlareEmojiPackMessage> {
  @override
  void initState() {
    super.initState();
    // Load labels/locales in the background; a raw key shows until then.
    FlareEmojiStickerCatalog.instance.ensureLoaded().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    final locale = Localizations.maybeLocaleOf(context)?.toLanguageTag();
    final packKey = _resolvePackKey(widget.emoji);

    if (packKey != null) {
      final label = FlareEmojiStickerCatalog.instance.emojiBracketLabel(packKey, locale: locale);
      return SizedBox(
        width: _kStickerLikeMaxSide,
        height: _kStickerLikeMaxSide,
        child: Image.asset(
          FlareEmojiStickerCatalog.emojiAssetPath(packKey),
          package: FlareEmojiStickerCatalog.package,
          fit: BoxFit.contain,
          gaplessPlayback: true,
          errorBuilder: (context, error, stackTrace) => Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w500,
                color: colors.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    return Text(widget.emoji, style: const TextStyle(fontSize: 48));
  }
}

/// Sticker message body — resolves a bundled pack sticker by `packageId` +
/// `stickerId`, falling back to a network url, then a placeholder.
class FlareStickerPackMessage extends StatelessWidget {
  const FlareStickerPackMessage({
    super.key,
    required this.stickerId,
    this.packageId,
    this.url,
    this.width,
    this.height,
    this.isSelf = false,
  });

  final String stickerId;
  final String? packageId;
  final String? url;
  final double? width;
  final double? height;
  final bool isSelf;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    double w = (width ?? 0) > 0 ? width! : 68;
    double h = (height ?? 0) > 0 ? height! : 68;
    if (w > _kStickerLikeMaxSide || h > _kStickerLikeMaxSide) {
      final scale = _kStickerLikeMaxSide / (w > h ? w : h);
      w *= scale;
      h *= scale;
    }

    final net = url?.trim() ?? '';
    final hasNet = net.startsWith('http://') || net.startsWith('https://');

    if (stickerId.trim().isNotEmpty) {
      return Image.asset(
        FlareEmojiStickerCatalog.stickerAssetPath(stickerId: stickerId, packageId: packageId),
        package: FlareEmojiStickerCatalog.package,
        width: w,
        height: h,
        fit: BoxFit.contain,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => hasNet
            ? Image.network(net, width: w, height: h, fit: BoxFit.contain,
                errorBuilder: (c, e, s) => _placeholder(colors, w, h))
            : _placeholder(colors, w, h),
      );
    }
    if (hasNet) {
      return Image.network(net, width: w, height: h, fit: BoxFit.contain,
          errorBuilder: (c, e, s) => _placeholder(colors, w, h));
    }
    return _placeholder(colors, w, h);
  }

  Widget _placeholder(FlareColors colors, double w, double h) => Container(
        width: w,
        height: h,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.bgHover,
          borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
          border: Border.all(color: colors.borderPrimary),
        ),
        child: Icon(Icons.insert_emoticon_outlined, size: 32, color: colors.textSecondary),
      );
}

// --- inline `[key]` emoji inside plain text -------------------------------

sealed class FlarePlainTextEmojiSegment {
  const FlarePlainTextEmojiSegment();
}

class FlarePlainTextRun extends FlarePlainTextEmojiSegment {
  FlarePlainTextRun(this.text);
  String text;
}

/// `[key]` with a bundled webp.
class FlarePlainEmojiPack extends FlarePlainTextEmojiSegment {
  const FlarePlainEmojiPack(this.key);
  final String key;
}

/// `[key]` with no bundled webp (renders as its localized label).
class FlarePlainEmojiUnknown extends FlarePlainTextEmojiSegment {
  const FlarePlainEmojiUnknown(this.key);
  final String key;
}

final RegExp _kEmojiToken = RegExp(r'\[([a-z][a-z0-9_]*)\]');

/// Splits plain text into runs + `[pack_key]` tokens. Call only after excluding
/// Markdown. A key is "pack" only if the catalog has the webp (else "unknown").
List<FlarePlainTextEmojiSegment> splitPlainTextForEmojiDisplay(String text) {
  if (text.isEmpty) return const [];
  final catalog = FlareEmojiStickerCatalog.instance;
  final out = <FlarePlainTextEmojiSegment>[];
  var cursor = 0;
  for (final m in _kEmojiToken.allMatches(text)) {
    if (m.start > cursor) _appendRun(out, text.substring(cursor, m.start));
    final key = m.group(1)!;
    out.add(catalog.hasEmojiKey(key) ? FlarePlainEmojiPack(key) : FlarePlainEmojiUnknown(key));
    cursor = m.end;
  }
  if (cursor < text.length) _appendRun(out, text.substring(cursor));
  return out;
}

void _appendRun(List<FlarePlainTextEmojiSegment> out, String chunk) {
  if (chunk.isEmpty) return;
  if (out.isNotEmpty && out.last is FlarePlainTextRun) {
    (out.last as FlarePlainTextRun).text += chunk;
  } else {
    out.add(FlarePlainTextRun(chunk));
  }
}

/// Whole trimmed text is a single known `[key]` → its pack key, else null.
String? resolveLoneEmojiPackInText(String text) {
  final t = text.trim();
  final m = _kBracketKey.firstMatch(t);
  if (m == null) return null;
  final key = m.group(1)!;
  return FlareEmojiStickerCatalog.instance.hasEmojiKey(key) ? key : null;
}

/// Renders plain text with inline `[key]` emoji images (unknown keys show their
/// localized label). Loads the catalog lazily; before load, text shows verbatim.
class FlarePlainTextEmojiRich extends StatefulWidget {
  const FlarePlainTextEmojiRich({
    super.key,
    required this.text,
    this.style,
    this.inlineSize = 20,
  });

  final String text;
  final TextStyle? style;
  final double inlineSize;

  @override
  State<FlarePlainTextEmojiRich> createState() => _FlarePlainTextEmojiRichState();
}

class _FlarePlainTextEmojiRichState extends State<FlarePlainTextEmojiRich> {
  @override
  void initState() {
    super.initState();
    FlareEmojiStickerCatalog.instance.ensureLoaded().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.maybeLocaleOf(context)?.toLanguageTag();
    final segments = splitPlainTextForEmojiDisplay(widget.text);
    if (segments.isEmpty) return Text(widget.text, style: widget.style);

    final spans = <InlineSpan>[];
    for (final seg in segments) {
      switch (seg) {
        case FlarePlainTextRun():
          spans.add(TextSpan(text: seg.text));
        case FlarePlainEmojiPack():
          spans.add(WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Image.asset(
              FlareEmojiStickerCatalog.emojiAssetPath(seg.key),
              package: FlareEmojiStickerCatalog.package,
              width: widget.inlineSize,
              height: widget.inlineSize,
              fit: BoxFit.contain,
              gaplessPlayback: true,
              errorBuilder: (context, error, stackTrace) => Text(
                FlareEmojiStickerCatalog.instance.emojiBracketLabel(seg.key, locale: locale),
                style: widget.style,
              ),
            ),
          ));
        case FlarePlainEmojiUnknown():
          spans.add(TextSpan(
            text: FlareEmojiStickerCatalog.instance.emojiBracketLabel(seg.key, locale: locale),
          ));
      }
    }
    return Text.rich(TextSpan(style: widget.style, children: spans));
  }
}
