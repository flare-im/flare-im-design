import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../emoji_sticker/flare_emoji_sticker_catalog.dart';
import '../models/rich_doc.dart';
import '../models/url_safety.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';

/// rich text — the RichDoc v2 document the core stores for a rich-text message
/// ([docJson]), drawn as headings, paragraphs, quotes, code, lists
/// and rules with their marks, links, mentions and emoji
/// (`spec/rich-doc-vectors.json`), under the message's [title] when it has
/// one. A document that is not drawable shows [plainText], the core's own flat
/// text; a message with neither shows the rich-text term.
///
/// A link reaches [onLinkTap] only when `safeExternalUrl` accepts it; a
/// refused link keeps its words. A spoiler stays covered — named for assistive
/// technology — until the reader taps it. Colours follow [FlareTextMessage]:
/// the bubble's foreground, links in the brand colour when incoming, mentions
/// at weight 500 in the brand text colour (600 in the bubble colour when
/// outgoing).
class FlareRichTextMessage extends StatefulWidget {
  const FlareRichTextMessage({
    super.key,
    required this.docJson,
    this.plainText = '',
    this.title = '',
    this.self = false,
    this.selectable = false,
    this.onLinkTap,
  });

  final String docJson;
  final String plainText;
  final String title;
  final bool self;
  final bool selectable;
  final ValueChanged<String>? onLinkTap;

  @override
  State<FlareRichTextMessage> createState() => _FlareRichTextMessageState();
}

class _FlareRichTextMessageState extends State<FlareRichTextMessage> {
  final _recognizers = <TapGestureRecognizer>[];
  List<FlareRichBlock>? _blocks;
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _read();
  }

  @override
  void didUpdateWidget(FlareRichTextMessage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.docJson != widget.docJson) {
      _revealed = false;
      _read();
    }
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  void _read() {
    _blocks = flareParseRichDoc(widget.docJson);
    final catalog = FlareEmojiStickerCatalog.instance;
    if (!catalog.isLoaded && _holdsEmoji(_blocks ?? const [])) {
      catalog.ensureLoaded().then((_) {
        if (mounted) setState(() {});
      });
    }
  }

  static bool _holdsEmoji(List<FlareRichBlock> blocks) => blocks.any(
    (block) => switch (block) {
      FlareRichParagraph(:final runs) ||
      FlareRichHeading(:final runs) => runs.any((run) => run.emoji != null),
      FlareRichQuote(:final blocks) => _holdsEmoji(blocks),
      FlareRichList(:final items) => items.any(_holdsEmoji),
      _ => false,
    },
  );

  void _disposeRecognizers() {
    for (final recognizer in _recognizers) {
      recognizer.dispose();
    }
    _recognizers.clear();
  }

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final foreground = widget.self
        ? colors.messageOutgoingForeground
        : colors.messageIncomingForeground;
    final base = TextStyle(
      color: foreground,
      fontSize: FlareSizes.fontSizeXl,
      height: 1.45,
    );
    final paint = _Paint(
      colors: colors,
      strings: strings,
      foreground: foreground,
      link: widget.self ? foreground : colors.primary,
    );
    final blocks = _blocks;
    final title = widget.title.trim();
    if (blocks == null || blocks.isEmpty) {
      final fallback = widget.plainText.trim().isEmpty
          ? strings.previewRichText
          : widget.plainText.trim();
      return _column([
        if (title.isNotEmpty) _title(title, base),
        widget.selectable
            ? SelectableText(fallback, style: base)
            : Text(fallback, style: base),
      ]);
    }
    return _column([
      if (title.isNotEmpty) _title(title, base),
      for (final block in blocks) _block(block, base, paint),
    ]);
  }

  Widget _column(List<Widget> children) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    spacing: FlareSizes.spacing2xs,
    children: children,
  );

  Widget _title(String title, TextStyle base) => Text(
    title,
    style: base.copyWith(
      fontSize: FlareSizes.fontSizeXl * 1.12,
      fontWeight: FontWeight.w700,
      height: 1.28,
    ),
  );

  Widget _block(FlareRichBlock block, TextStyle base, _Paint paint) {
    switch (block) {
      case FlareRichParagraph(:final runs):
        return _text(runs, base, paint);
      case FlareRichHeading(:final level, :final runs):
        final scale = level == 1
            ? 1.18
            : level == 2
            ? 1.12
            : 1.04;
        return _text(
          runs,
          base.copyWith(
            fontSize: FlareSizes.fontSizeXl * scale,
            fontWeight: FontWeight.w700,
            height: 1.28,
          ),
          paint,
        );
      case FlareRichQuote(:final blocks):
        final quoted = base.copyWith(
          color: paint.foreground.withValues(alpha: 0.82),
        );
        return DecoratedBox(
          decoration: BoxDecoration(
            color: paint.foreground.withValues(alpha: 0.08),
            border: Border(
              left: BorderSide(
                color: paint.foreground.withValues(alpha: 0.42),
                width: 3,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: FlareSizes.spacingSm,
              vertical: FlareSizes.spacingXs,
            ),
            child: _column([
              for (final inner in blocks) _block(inner, quoted, paint),
            ]),
          ),
        );
      case FlareRichCode(:final text):
        return DecoratedBox(
          decoration: BoxDecoration(
            color: paint.foreground.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(FlareSizes.radiusSm),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: FlareSizes.spacingSm,
              vertical: FlareSizes.spacingXs,
            ),
            child: Text(
              text,
              softWrap: false,
              style: base.copyWith(
                fontFamily: 'monospace',
                fontSize: FlareSizes.fontSizeXl * 0.92,
              ),
            ),
          ),
        );
      case FlareRichList(:final ordered, :final items):
        return _column([
          for (var index = 0; index < items.length; index++)
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: FlareSizes.spacingXs),
                  child: Text(ordered ? '${index + 1}.' : '•', style: base),
                ),
                Flexible(
                  child: _column([
                    for (final inner in items[index])
                      _block(inner, base, paint),
                  ]),
                ),
              ],
            ),
        ]);
      case FlareRichDivider():
        return SizedBox(
          width: double.infinity,
          height: 1,
          child: ColoredBox(color: paint.foreground.withValues(alpha: 0.18)),
        );
    }
  }

  Widget _text(List<FlareRichRun> runs, TextStyle base, _Paint paint) {
    final span = TextSpan(
      style: base,
      children: [for (final run in runs) _run(run, base, paint)],
    );
    return widget.selectable ? SelectableText.rich(span) : Text.rich(span);
  }

  InlineSpan _run(FlareRichRun run, TextStyle base, _Paint paint) {
    final fontSize = base.fontSize ?? FlareSizes.fontSizeXl;
    if (run.has(FlareRichMark.spoiler) && !_revealed) {
      final reveal = TapGestureRecognizer()
        ..onTap = () => setState(() => _revealed = true);
      _recognizers.add(reveal);
      // The words are not drawn at all while covered: blank space as wide as
      // them, on a ground in the text colour.
      return TextSpan(
        text: flareRichSpoilerCover(run.text),
        semanticsLabel: paint.strings.messageSpoilerReveal,
        style: TextStyle(backgroundColor: paint.foreground),
        recognizer: reveal,
      );
    }
    final key = run.emoji;
    if (key != null &&
        key.isNotEmpty &&
        FlareEmojiStickerCatalog.instance.hasEmojiKey(key)) {
      final side = fontSize * 1.25;
      return WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Image.asset(
          FlareEmojiStickerCatalog.emojiAssetPath(key),
          package: FlareEmojiStickerCatalog.package,
          width: side,
          height: side,
          fit: BoxFit.contain,
          gaplessPlayback: true,
          semanticLabel: run.text,
          errorBuilder: (context, error, stackTrace) =>
              Text(run.text, textScaler: TextScaler.noScaling),
        ),
      );
    }
    final decorations = [
      if (run.has(FlareRichMark.underline) || run.link != null)
        TextDecoration.underline,
      if (run.has(FlareRichMark.strike)) TextDecoration.lineThrough,
    ];
    var style = TextStyle(
      fontWeight: run.has(FlareRichMark.bold) ? FontWeight.w700 : null,
      fontStyle: run.has(FlareRichMark.italic) ? FontStyle.italic : null,
      decoration: decorations.isEmpty
          ? null
          : TextDecoration.combine(decorations),
    );
    if (run.code) {
      style = style.copyWith(
        fontFamily: 'monospace',
        fontSize: fontSize * 0.92,
        backgroundColor: paint.foreground.withValues(alpha: 0.10),
      );
    }
    if (run.mention != null) {
      style = widget.self
          ? style.copyWith(fontWeight: FontWeight.w600)
          : style.copyWith(
              color: paint.colors.primaryText,
              fontWeight: FontWeight.w500,
            );
    }
    TapGestureRecognizer? open;
    final href = run.link;
    if (href != null) {
      style = style.copyWith(color: paint.link);
      final url = safeExternalUrl(href);
      if (url != null && widget.onLinkTap != null) {
        open = TapGestureRecognizer()..onTap = () => widget.onLinkTap!(url);
        _recognizers.add(open);
      }
    }
    return TextSpan(text: run.text, style: style, recognizer: open);
  }
}

class _Paint {
  const _Paint({
    required this.colors,
    required this.strings,
    required this.foreground,
    required this.link,
  });

  final FlareColors colors;
  final FlareStrings strings;
  final Color foreground;
  final Color link;
}
