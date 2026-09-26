import 'flare_avatar.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../models/message_content.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import '../emoji_sticker/emoji_sticker.dart';
import 'action_icon.dart';
import 'flare_media_image.dart';
import 'flare_icon.dart';
import 'icon_control.dart';

/// Canonical content-only message bodies. MessageBubble owns chrome and metadata.
/// Standalone, presentational per-type message bodies (clean params, no SDK /
/// media coupling) — drop any single one into your own layout. Interaction is
/// surfaced as callbacks: the host owns the URLs/handlers. The SDK-driven
/// dispatcher `FlareMessageContentView` stays the batteries-included path.
///
/// Spec: Message/MessageContentView content types, decomposed into components.

const Radius _tail = Radius.circular(4);
const double _corner = 16;

BorderRadius _bubbleRadius() => const BorderRadius.only(
  topLeft: Radius.circular(_corner),
  topRight: Radius.circular(_corner),
  bottomRight: Radius.circular(_corner),
  bottomLeft: _tail,
);

/// The message picture with a placeholder fallback (host provides the URL; a
/// local file shows while the message is still uploading).
Widget _netImage(
  String? url, {
  required Widget placeholder,
  BoxFit fit = BoxFit.cover,
}) => flareMediaImage(url, placeholder: placeholder, fit: fit);

Widget _tap(VoidCallback? onTap, Widget child) => onTap == null
    ? child
    : InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(FlareSizes.radiusMd),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: FlareSizes.touchTarget),
          child: child,
        ),
      );

/// text — a plain text bubble; linkifies bare URLs and reports `onLinkTap`,
/// and draws emoji-pack tokens (`[key]`) inline as their image. A token whose
/// key the pack does not have stays as its bracket text.
///
/// [mentions] highlight "@" names (build them with `flareTextMentionSpans`):
/// in an incoming bubble a mention takes the brand text colour at weight 500,
/// and a mention of the reader or of everyone also sits on the selected
/// ground; in an outgoing bubble ([self]) it keeps the bubble colour at weight
/// 600 with no ground. Text outside a mention renders as it would without any.
class FlareTextMessage extends StatefulWidget {
  const FlareTextMessage({
    super.key,
    required this.text,
    this.self = false,
    this.selectable = false,
    this.mentions = const [],
    this.onLinkTap,
  });

  final String text;
  final bool self;
  final bool selectable;
  final List<FlareTextMentionSpan> mentions;
  final ValueChanged<String>? onLinkTap;

  @override
  State<FlareTextMessage> createState() => _FlareTextMessageState();
}

class _FlareTextMessageState extends State<FlareTextMessage> {
  final _recognizers = <TapGestureRecognizer>[];

  static final _link = RegExp(
    r'((?:https?:\/\/)?[a-z0-9.-]+\.[a-z]{2,}(?:\/\S*)?)',
    caseSensitive: false,
  );

  /// Cheap pre-check before touching the emoji catalog.
  static final _emojiToken = RegExp(r'\[[a-z][a-z0-9_]*\]');

  @override
  void initState() {
    super.initState();
    FlareEmojiStickerCatalog.instance.addListener(_emojiCatalogChanged);
    _ensureEmojiCatalog();
  }

  void _emojiCatalogChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(FlareTextMessage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) _ensureEmojiCatalog();
  }

  /// `[key]` tokens need the pack manifest to tell an emoji from plain
  /// brackets; until it is there every token renders as its bracket text.
  void _ensureEmojiCatalog() {
    final catalog = FlareEmojiStickerCatalog.instance;
    if (catalog.isLoaded || !_emojiToken.hasMatch(widget.text)) return;
    catalog.ensureLoaded().then((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    FlareEmojiStickerCatalog.instance.removeListener(_emojiCatalogChanged);
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  /// The mentions that fit [FlareTextMessage.text], in order, none overlapping
  /// and none splitting a surrogate pair.
  List<FlareTextMentionSpan> _validMentions() {
    final text = widget.text;
    bool boundary(int index) =>
        index == 0 ||
        index == text.length ||
        !(text.codeUnitAt(index) >= 0xDC00 && text.codeUnitAt(index) <= 0xDFFF);
    final sorted =
        widget.mentions
            .where(
              (m) =>
                  m.start >= 0 &&
                  m.length > 0 &&
                  m.end <= text.length &&
                  boundary(m.start) &&
                  boundary(m.end),
            )
            .toList()
          ..sort((a, b) => a.start.compareTo(b.start));
    final kept = <FlareTextMentionSpan>[];
    for (final mention in sorted) {
      if (kept.isEmpty || mention.start >= kept.last.end) kept.add(mention);
    }
    return kept;
  }

  /// Plain text between mentions: emoji-pack tokens become inline images, the
  /// rest keeps its bare URLs as links.
  void _addPlain(
    List<InlineSpan> spans,
    String text,
    Color linkColor,
    double fontSize,
  ) {
    for (final segment in splitPlainTextForEmojiDisplay(text)) {
      switch (segment) {
        case FlarePlainTextRun(text: final run):
          _addLinked(spans, run, linkColor);
        case FlarePlainEmojiPack(:final key):
          spans.add(_inlineEmoji(key, fontSize));
        case FlarePlainEmojiUnknown(:final key):
          // Not an emoji the pack knows: it is just text in brackets.
          _addLinked(spans, '[$key]', linkColor);
      }
    }
  }

  /// One `[key]` emoji, drawn at the line's size so it sits in the sentence.
  InlineSpan _inlineEmoji(String key, double fontSize) {
    final side = fontSize * 1.25;
    return WidgetSpan(
      alignment: PlaceholderAlignment.middle,
      child: FlareStaticImage(
        image: FlareEmojiStickerCatalog.instance.emojiImageProvider(
          key,
          staticPreview: true,
        ),
        width: side,
        height: side,
        error: Text('[$key]', textScaler: TextScaler.noScaling),
      ),
    );
  }

  /// Bare URLs as links.
  void _addLinked(List<InlineSpan> spans, String text, Color linkColor) {
    var last = 0;
    for (final m in _link.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start)));
      }
      final href = m.group(0)!;
      final rec = TapGestureRecognizer()
        ..onTap = () => widget.onLinkTap?.call(href);
      _recognizers.add(rec);
      spans.add(
        TextSpan(
          text: href,
          style: TextStyle(
            color: linkColor,
            decoration: TextDecoration.underline,
          ),
          recognizer: rec,
        ),
      );
      last = m.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
  }

  InlineSpan _mention(
    String text,
    FlareTextMentionSpan mention,
    TextStyle base,
    FlareColors c,
  ) {
    if (widget.self) {
      return TextSpan(
        text: text,
        style: const TextStyle(fontWeight: FontWeight.w600),
      );
    }
    final style = TextStyle(color: c.primaryText, fontWeight: FontWeight.w500);
    if (!mention.self && !mention.all)
      return TextSpan(text: text, style: style);
    // A selectable body keeps the mention as text so it copies; the ground
    // there has no padding or radius.
    if (widget.selectable) {
      return TextSpan(
        text: text,
        style: style.copyWith(backgroundColor: c.bgSelected),
      );
    }
    return WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: c.bgSelected,
          borderRadius: BorderRadius.circular(FlareSizes.radiusSm),
        ),
        // The paragraph already scales its inline widgets with the text.
        child: Text(
          text,
          style: base.merge(style),
          textScaler: TextScaler.noScaling,
        ),
      ),
    );
  }

  List<InlineSpan> _spans(
    TextStyle base,
    Color linkColor,
    FlareColors c,
    double fontSize,
  ) {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
    final spans = <InlineSpan>[];
    final text = widget.text;
    var cursor = 0;
    for (final mention in _validMentions()) {
      if (mention.start > cursor) {
        _addPlain(
          spans,
          text.substring(cursor, mention.start),
          linkColor,
          fontSize,
        );
      }
      spans.add(
        _mention(text.substring(mention.start, mention.end), mention, base, c),
      );
      cursor = mention.end;
    }
    if (cursor < text.length) {
      _addPlain(spans, text.substring(cursor), linkColor, fontSize);
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final loneEmoji = resolveLoneEmojiPackInText(widget.text);
    if (loneEmoji != null) {
      return FlareEmojiPackMessage(emoji: loneEmoji, isSelf: widget.self);
    }
    final c = FlareColors.of(context);
    final base = TextStyle(
      color: widget.self
          ? c.messageOutgoingForeground
          : c.messageIncomingForeground,
      // 消息正文取 message 角色 —— 四端同一个出处(15/1.45)。
      fontSize: FlareTextRoles.message.fontSize,
      height: FlareTextRoles.message.lineHeight,
    );
    final linkColor = widget.self ? c.messageOutgoingForeground : c.primary;
    final span = TextSpan(
      style: base,
      children: _spans(base, linkColor, c, FlareTextRoles.message.fontSize),
    );
    return widget.selectable ? SelectableText.rich(span) : Text.rich(span);
  }
}

/// image — a rounded thumbnail; emits `onTap`.
class FlareImageMessage extends StatelessWidget {
  const FlareImageMessage({
    super.key,
    this.src,
    this.width = 132,
    this.height = 92,
    this.alt,
    this.onTap,
  });

  final String? src;
  final double width;
  final double height;
  final String? alt;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = FlareColors.of(context);
    return _tap(
      onTap,
      Semantics(
        label: alt,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(FlareSizes.radiusCard),
          child: SizedBox(
            width: width,
            height: height,
            child: _netImage(
              src,
              placeholder: ColoredBox(
                color: c.bgTertiary,
                child: Icon(
                  Icons.image_outlined,
                  color: c.textTertiary,
                  size: 26,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// video — a thumbnail with a play overlay and duration badge; emits `onPlay`.
class FlareVideoMessage extends StatelessWidget {
  const FlareVideoMessage({
    super.key,
    this.duration = '00:00',
    this.poster,
    this.alt,
    this.onPlay,
  });

  final String duration;
  final String? poster;
  final String? alt;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    final c = FlareColors.of(context);
    return _tap(
      onPlay,
      Semantics(
        label: alt,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(FlareSizes.radiusCard),
          child: SizedBox(
            width: 148,
            height: 92,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _netImage(
                  poster,
                  placeholder: ColoredBox(
                    color: c.bgTertiary,
                    child: Icon(
                      Icons.videocam_outlined,
                      color: c.textTertiary,
                      size: 24,
                    ),
                  ),
                ),
                const ColoredBox(color: Color(0x47000000)),
                const Center(
                  child: FlareIcon('play', color: Colors.white, size: 34),
                ),
                Positioned(
                  right: 6,
                  bottom: 5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0x73000000),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      duration,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: FlareSizes.fontSize2xs,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// audio / voice — waveform + duration; emits `onPlay`.
///
/// The body is one control named by what a tap does: 播放, 暂停 while
/// [playing], 重试 when [failed]. While playing it shows [elapsedSeconds] of
/// [seconds]; [loading] shows progress in place of the play glyph, and
/// [failed] says the message could not be played.
class FlareVoiceMessage extends StatelessWidget {
  const FlareVoiceMessage({
    super.key,
    this.seconds = 1,
    this.elapsedSeconds = 0,
    this.playing = false,
    this.loading = false,
    this.failed = false,
    this.onPlay,
  });

  final int seconds;

  /// Seconds played so far; shown next to [seconds] while [playing].
  final int elapsedSeconds;
  final bool playing;
  final bool loading;
  final bool failed;
  final VoidCallback? onPlay;

  static String _clock(int seconds) {
    final safe = seconds < 0 ? 0 : seconds;
    return '${safe ~/ 60}:${(safe % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final c = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final accent = playing ? c.primary : c.textSecondary;
    final time = failed
        ? strings.voicePlaybackFailed
        : playing && elapsedSeconds > 0 && seconds > 0
        ? '${_clock(elapsedSeconds)} / ${_clock(seconds)}'
        : '$seconds"';
    final Widget glyph = loading
        ? SizedBox.square(
            dimension: 17,
            child: CircularProgressIndicator(strokeWidth: 2, color: accent),
          )
        : Icon(
            failed
                ? flareIconGlyph('refresh')
                : playing
                ? Icons.volume_up_outlined
                : flareIconGlyph('play'),
            size: 17,
            color: accent,
          );
    return Semantics(
      container: true,
      button: true,
      enabled: onPlay != null,
      label: failed
          ? strings.retry
          : playing
          ? strings.pause
          : strings.play,
      value: time,
      onTap: onPlay,
      excludeSemantics: true,
      child: _tap(
        onPlay,
        Container(
          padding: EdgeInsets.zero,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              glyph,
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var n = 1; n <= 9; n++) ...[
                    Container(
                      width: 2,
                      height: 4 + ((n * 5) % 13).toDouble(),
                      decoration: BoxDecoration(
                        color: c.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    if (n < 9) const SizedBox(width: 2),
                  ],
                ],
              ),
              const SizedBox(width: 8),
              // Wraps rather than overflows a narrow bubble at large text.
              Flexible(
                child: Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: c.textTertiary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// file — icon / name / size / ext; emits `onOpen` (card) and `onDownload`.
/// Override the leading [icon] to show a per-file-type glyph. The download key
/// is drawn only when there is an [onDownload] to call.
class FlareFileMessage extends StatelessWidget {
  const FlareFileMessage({
    super.key,
    required this.name,
    this.size = '',
    this.ext,
    this.icon,
    this.onOpen,
    this.onDownload,
  });

  final String name;
  final String size;
  final String? ext;
  final Widget? icon;
  final VoidCallback? onOpen;
  final VoidCallback? onDownload;

  @override
  Widget build(BuildContext context) {
    final c = FlareColors.of(context);
    final sub = ext == null || ext!.isEmpty ? size : '$size · $ext';
    return _tap(
      onOpen,
      Container(
        constraints: const BoxConstraints(maxWidth: 300),
        padding: EdgeInsets.zero,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon ??
                Icon(
                  Icons.insert_drive_file_outlined,
                  size: 20,
                  color: c.primary,
                ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: FlareSizes.fontSizeLg,
                      fontWeight: FontWeight.w500,
                      color: c.textPrimary,
                    ),
                  ),
                  Text(
                    sub,
                    style: TextStyle(fontSize: 11, color: c.textTertiary),
                  ),
                ],
              ),
            ),
            // No tooltip: a long press on a message belongs to its bubble.
            if (onDownload != null)
              FlareIconControl(
                label: FlareStrings.of(context).download,
                onTap: onDownload,
                tooltip: false,
                child: FlareIcon('download', size: 17, color: c.textTertiary),
              ),
          ],
        ),
      ),
    );
  }
}

/// location — a map image (or placeholder) over title / address; emits `onOpen`.
class FlareLocationMessage extends StatelessWidget {
  const FlareLocationMessage({
    super.key,
    required this.title,
    this.address = '',
    this.mapImage,
    this.onOpen,
  });

  final String title;
  final String address;
  final String? mapImage;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final c = FlareColors.of(context);
    return _tap(
      onOpen,
      ClipRRect(
        borderRadius: _bubbleRadius(),
        child: Container(
          width: 264,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 84,
                child: _netImage(
                  mapImage,
                  placeholder: Container(
                    color: Color.alphaBlend(
                      c.primary.withValues(alpha: 0.08),
                      c.bgTertiary,
                    ),
                    child: Icon(
                      Icons.location_on_outlined,
                      color: c.primary,
                      size: 22,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: FlareSizes.fontSizeLg,
                        fontWeight: FontWeight.w500,
                        color: c.textPrimary,
                      ),
                    ),
                    Text(
                      address,
                      style: TextStyle(fontSize: 11, color: c.textTertiary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// contact / business card — avatar (image or pastel initials) + name /
/// subtitle; emits `onOpen`.
class FlareContactMessage extends StatelessWidget {
  const FlareContactMessage({
    super.key,
    required this.name,
    this.subtitle,
    this.avatarUrl,
    this.onOpen,
  });

  final String name;
  final String? subtitle;
  final String? avatarUrl;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final c = FlareColors.of(context);
    final tint = FlareAvatar.seedTint(name, c);
    final avatar = ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 44,
        height: 44,
        child: _netImage(
          avatarUrl,
          placeholder: Container(
            alignment: Alignment.center,
            color: tint.$1,
            child: Text(
              _initials(name),
              style: TextStyle(
                color: tint.$2,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
    return _tap(
      onOpen,
      Container(
        constraints: const BoxConstraints(minWidth: 240),
        padding: EdgeInsets.zero,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            avatar,
            const SizedBox(width: 12),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: FlareSizes.fontSizeXl,
                      fontWeight: FontWeight.w600,
                      color: c.textPrimary,
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty)
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: c.textTertiary),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, size: 16, color: c.textTertiary),
          ],
        ),
      ),
    );
  }
}

/// link card — thumbnail + title + optional description + domain; emits `onOpen`.
class FlareLinkCardMessage extends StatelessWidget {
  const FlareLinkCardMessage({
    super.key,
    required this.title,
    this.domain = '',
    this.thumb,
    this.description,
    this.onOpen,
    this.icon,
    this.descriptionMaxLines = 2,
  });

  final String title;
  final String domain;
  final String? thumb;
  final String? description;
  final VoidCallback? onOpen;
  final Widget? icon;
  final int? descriptionMaxLines;

  @override
  Widget build(BuildContext context) {
    final c = FlareColors.of(context);
    return _tap(
      onOpen,
      Container(
        constraints: const BoxConstraints(maxWidth: 300),
        padding: const EdgeInsets.symmetric(
          horizontal: FlareSizes.spacing2sm,
          vertical: 8,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              icon!
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: _netImage(
                    thumb,
                    placeholder: Container(
                      alignment: Alignment.center,
                      color: c.bgTertiary,
                      child: Icon(
                        Icons.image_outlined,
                        size: 22,
                        color: c.textTertiary,
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: FlareSizes.fontSizeLg,
                      fontWeight: FontWeight.w500,
                      color: c.textPrimary,
                    ),
                  ),
                  if (description != null && description!.isNotEmpty)
                    Text(
                      description!,
                      maxLines: descriptionMaxLines,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: c.textSecondary),
                    ),
                  const SizedBox(height: 3),
                  if (domain.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.link, size: 12, color: c.textTertiary),
                        const SizedBox(width: 3),
                        Flexible(
                          child: Text(
                            domain,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: c.textTertiary,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A vote option for [FlareVoteMessage].
class FlareVoteOption {
  const FlareVoteOption(this.text, [this.pct]);
  final String text;
  final int? pct;
}

/// vote — title over option rows with proportional bars; emits `onSelect`.
class FlareVoteMessage extends StatelessWidget {
  const FlareVoteMessage({
    super.key,
    required this.title,
    this.options = const [],
    this.total,
    this.onSelect,
  });

  final String title;
  final List<FlareVoteOption> options;
  final String? total;
  final void Function(FlareVoteOption option, int index)? onSelect;

  @override
  Widget build(BuildContext context) {
    final c = FlareColors.of(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 220),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: FlareSizes.spacing2sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bar_chart, size: 16, color: c.textPrimary),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: FlareSizes.fontSizeLg,
                    color: c.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < options.length; i++) ...[
            _tap(
              onSelect == null ? null : () => onSelect!(options[i], i),
              _VoteRow(option: options[i], colors: c),
            ),
            if (i < options.length - 1) const SizedBox(height: 6),
          ],
          if (total != null && total!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(total!, style: TextStyle(fontSize: 11, color: c.textTertiary)),
          ],
        ],
      ),
    );
  }
}

class _VoteRow extends StatelessWidget {
  const _VoteRow({required this.option, required this.colors});
  final FlareVoteOption option;
  final FlareColors colors;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(7),
      child: Stack(
        children: [
          Positioned.fill(
            child: ColoredBox(
              color: colors.textPrimary.withValues(alpha: 0.08),
            ),
          ),
          if (option.pct != null)
            Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: (option.pct!.clamp(0, 100)) / 100,
                child: ColoredBox(
                  color: colors.primary.withValues(alpha: 0.16),
                  child: const SizedBox(height: 30),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: FlareSizes.spacing2sm,
              vertical: 7,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    option.text,
                    style: TextStyle(fontSize: 13, color: colors.textPrimary),
                  ),
                ),
                if (option.pct != null)
                  Text(
                    '${option.pct}%',
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// task — checkbox + title (struck through when done) + meta; emits `onToggle`.
class FlareTaskMessage extends StatelessWidget {
  const FlareTaskMessage({
    super.key,
    required this.title,
    this.meta,
    this.done = false,
    this.onToggle,
  });

  final String title;
  final String? meta;
  final bool done;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final c = FlareColors.of(context);
    return Container(
      constraints: const BoxConstraints(minWidth: 220),
      padding: EdgeInsets.zero,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // A checkbox named by the task it completes; the title beside it is
          // what a screen reader reads with the checked state.
          FlareIconControl(
            label: title,
            checked: done,
            onTap: onToggle,
            tooltip: false,
            child: Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: done ? c.primary : null,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: done ? c.primary : c.borderPrimary,
                  width: 1.5,
                ),
              ),
              child: done
                  ? const FlareIcon('check', size: 13, color: Colors.white)
                  : null,
            ),
          ),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                ExcludeSemantics(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: FlareSizes.fontSizeLg,
                      fontWeight: FontWeight.w500,
                      color: done ? c.textTertiary : c.textPrimary,
                      decoration: done ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                if (meta != null && meta!.isNotEmpty)
                  Text(
                    meta!,
                    style: TextStyle(fontSize: 11, color: c.textTertiary),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// sticker — a bare, larger glyph/image (no bubble); emits `onTap`.
class FlareStickerMessage extends StatelessWidget {
  const FlareStickerMessage({
    super.key,
    this.emoji = '🐱',
    this.src,
    this.image,
    this.packageId,
    this.stickerId,
    this.width,
    this.height,
    this.onTap,
  });

  final String emoji;
  final String? src;
  final Widget? image;
  final String? packageId;
  final String? stickerId;
  final double? width;
  final double? height;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _tap(
      onTap,
      image ??
          (src == null && stickerId == null
              ? FlareEmojiMessage(emoji: emoji)
              : FlareStickerPackMessage(
                  stickerId: stickerId ?? '',
                  packageId: packageId,
                  url: src,
                  width: width,
                  height: height,
                )),
    );
  }
}

/// emoji — a bare, large emoji (no bubble); emits `onTap`.
class FlareEmojiMessage extends StatelessWidget {
  const FlareEmojiMessage({super.key, this.emoji = '🎉', this.onTap});

  final String emoji;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _tap(onTap, FlareEmojiPackMessage(emoji: emoji));
  }
}

/// notification / system — a centered pill.
class FlareSystemMessage extends StatelessWidget {
  const FlareSystemMessage({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = FlareColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: c.bgTertiary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(text, style: TextStyle(fontSize: 12, color: c.textTertiary)),
    );
  }
}

// 身份色板不再在这里复制一份 —— 与 FlareAvatar 同一个实现、同一组 token。

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
      .toUpperCase();
}
