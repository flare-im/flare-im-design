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
import 'flare_location_map.dart';
import 'icon_control.dart';
import '../models/location.dart';

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
/// local file shows while the message is still uploading). Gapless: the host
/// re-resolves a picture's address (a re-signed URL, then the cached copy), and
/// the bubble must keep showing it through that rather than flash empty.
Widget _netImage(
  String? url, {
  required Widget placeholder,
  BoxFit fit = BoxFit.cover,
  bool allowLocalFile = false,
}) => flareMediaImage(
  url,
  placeholder: placeholder,
  fit: fit,
  gaplessPlayback: true,
  allowLocalFile: allowLocalFile,
);

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
///
/// Three states, the Vue `FlareImageMessage` rule: while the picture loads —
/// or while the message has no address for it yet — the tertiary placeholder
/// with the image glyph (never "unsupported message"); once it fails the
/// failure placeholder ([failedKey], named `imageLoadFailed`), and a tap there
/// loads it again instead of opening it; then the picture, whose tap is
/// [onTap].
class FlareImageMessage extends StatefulWidget {
  const FlareImageMessage({
    super.key,
    this.src,
    this.width = 132,
    this.height = 92,
    this.alt,
    this.onTap,
    this.allowLocalFile = false,
  });

  final String? src;
  final double width;
  final double height;
  final String? alt;
  final VoidCallback? onTap;

  /// [src] may be a file on this device: only for the sender's own picture
  /// while it uploads (see `flareMediaImageProvider`).
  final bool allowLocalFile;

  /// The failure placeholder (tap to retry).
  static const Key failedKey = ValueKey('flare-image-message-failed');

  @override
  State<FlareImageMessage> createState() => _FlareImageMessageState();
}

class _FlareImageMessageState extends State<FlareImageMessage> {
  /// Bumped by a retry: a new image element asks for the picture again.
  int _attempt = 0;
  bool _failed = false;

  @override
  void didUpdateWidget(FlareImageMessage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.src != widget.src) _failed = false;
  }

  void _retry(ImageProvider provider) {
    _evict(provider);
    setState(() {
      _failed = false;
      _attempt += 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final provider = flareMediaImageProvider(
      widget.src,
      allowLocalFile: widget.allowLocalFile,
    );
    final loading = ColoredBox(
      color: c.bgTertiary,
      child: Icon(Icons.image_outlined, color: c.textTertiary, size: 26),
    );
    Widget failed(ImageProvider provider) => Semantics(
      container: true,
      button: true,
      label: strings.imageLoadFailed,
      hint: strings.retry,
      child: GestureDetector(
        key: FlareImageMessage.failedKey,
        behavior: HitTestBehavior.opaque,
        onTap: () => _retry(provider),
        child: ColoredBox(
          color: c.bgTertiary,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.refresh_rounded, color: c.textTertiary, size: 22),
              const SizedBox(height: FlareSizes.spacingXs),
              Text(
                strings.retry,
                style: TextStyle(
                  color: c.textTertiary,
                  fontSize: FlareSizes.fontSizeXs,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    final Widget picture;
    if (provider == null) {
      picture = loading;
    } else if (_failed) {
      picture = failed(provider);
    } else {
      picture = Image(
        key: ValueKey(_attempt),
        image: provider,
        fit: BoxFit.cover,
        gaplessPlayback: true,
        frameBuilder: (_, child, frame, wasSynchronouslyLoaded) =>
            wasSynchronouslyLoaded || frame != null ? child : loading,
        errorBuilder: (_, _, _) {
          // Remember the failure so a tap retries rather than opens.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_failed) setState(() => _failed = true);
          });
          return failed(provider);
        },
      );
    }
    return _tap(
      provider == null || _failed ? null : widget.onTap,
      Semantics(
        label: widget.alt,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(FlareSizes.radiusCard),
          child: SizedBox(
            width: widget.width,
            height: widget.height,
            child: picture,
          ),
        ),
      ),
    );
  }
}

/// Drops [provider] from the image cache so the next load asks again.
void _evict(ImageProvider provider) {
  provider.evict().ignore();
}

/// video — a thumbnail with a play disc and duration badge; emits `onPlay`.
///
/// The poster fills [width] × [height] (16:9 at the image width by default);
/// without one the frame is the tertiary surface. The play affordance is a
/// round translucent dark disc with a white play glyph, centred. The badge
/// shows [duration] only when there is one: a video whose length is unknown
/// says nothing rather than `00:00`.
class FlareVideoMessage extends StatelessWidget {
  const FlareVideoMessage({
    super.key,
    this.duration,
    this.poster,
    this.alt,
    this.onPlay,
    this.width = 240,
    this.height = 135,
  });

  /// The length as shown (`01:05`); null or empty draws no badge.
  final String? duration;
  final String? poster;
  final String? alt;
  final VoidCallback? onPlay;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final c = FlareColors.of(context);
    final length = duration;
    return _tap(
      onPlay,
      Semantics(
        label: alt,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(FlareSizes.radiusCard),
          child: SizedBox(
            width: width,
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _netImage(poster, placeholder: ColoredBox(color: c.bgTertiary)),
                Center(
                  child: Container(
                    width: FlareSizes.touchTargetMin,
                    height: FlareSizes.touchTargetMin,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Color(0x73000000),
                      shape: BoxShape.circle,
                    ),
                    child: const FlareIcon(
                      'play',
                      color: Colors.white,
                      size: FlareSizes.iconSizeLg,
                    ),
                  ),
                ),
                if (length != null && length.isNotEmpty)
                  PositionedDirectional(
                    end: FlareSizes.spacing2xs,
                    bottom: FlareSizes.spacing2xs,
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
                        length,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: FlareSizes.fontSize2xs,
                          fontFeatures: [FontFeature.tabularFigures()],
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

/// file — icon / name / size / ext; emits `onOpen` (card), `onDownload` and
/// `onReveal`. Override the leading [icon] to show a per-file-type glyph.
///
/// The key on the right follows [downloadState]: a download key while the file
/// is not on this device ([onDownload]), progress while it downloads (not a
/// control), and once it is saved a folder key that shows it in its folder
/// ([onReveal]). A key with nothing to call is not drawn — a saved file without
/// [onReveal] has no key rather than a spent one. The line under the name keeps
/// the size and type and says "downloading" / "downloaded" after them.
class FlareFileMessage extends StatelessWidget {
  const FlareFileMessage({
    super.key,
    required this.name,
    this.size = '',
    this.ext,
    this.icon,
    this.downloadState,
    this.onOpen,
    this.onDownload,
    this.onReveal,
  });

  final String name;
  final String size;
  final String? ext;
  final Widget? icon;

  /// Where the file's download stands on this device; null is not downloaded.
  final FlareMediaDownloadState? downloadState;
  final VoidCallback? onOpen;
  final VoidCallback? onDownload;

  /// Shows the saved file in its folder (the key once [downloadState] is done).
  final VoidCallback? onReveal;

  @override
  Widget build(BuildContext context) {
    final c = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final status = downloadState?.status ?? FlareMediaDownloadStatus.idle;
    final pct = (downloadState?.progressPct ?? 0).clamp(0, 100);
    final downloading = status == FlareMediaDownloadStatus.downloading;
    final saved = status == FlareMediaDownloadStatus.done;
    final progress = pct > 0
        ? '${strings.downloading} $pct%'
        : strings.downloading;
    final sub = [
      if (size.isNotEmpty) size,
      if (ext != null && ext!.isNotEmpty) ext!,
      if (downloading) progress else if (saved) strings.downloaded,
    ].join(' · ');
    final key = _key(
      c,
      strings,
      downloading: downloading,
      saved: saved,
      pct: pct,
      progress: progress,
    );
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
                  if (sub.isNotEmpty)
                    Text(
                      sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: FlareSizes.fontSizeXs,
                        color: c.textTertiary,
                      ),
                    ),
                ],
              ),
            ),
            if (key != null) ...[
              const SizedBox(width: FlareSizes.spacingXs),
              key,
            ],
          ],
        ),
      ),
    );
  }

  /// The key on the right — progress, the folder or the download — or null
  /// when there is nothing to call. No tooltip: a long press on a message
  /// belongs to its bubble.
  Widget? _key(
    FlareColors c,
    FlareStrings strings, {
    required bool downloading,
    required bool saved,
    required int pct,
    required String progress,
  }) {
    if (downloading) {
      if (onDownload == null && onReveal == null) return null;
      // Not a control, but it keeps its place: a tap on the progress does not
      // fall through to the card and open the file.
      return GestureDetector(
        onTap: () {},
        excludeFromSemantics: true,
        child: FlareIconControl(
          label: progress,
          onTap: null,
          tooltip: false,
          child: SizedBox.square(
            dimension: FlareSizes.iconSizeMd,
            child: CircularProgressIndicator(
              value: pct > 0 ? pct / 100 : null,
              strokeWidth: 2,
              color: c.primary,
            ),
          ),
        ),
      );
    }
    final (icon, label, onTap, color) = saved
        ? ('folder', strings.showInFolder, onReveal, c.primary)
        : ('download', strings.download, onDownload, c.textTertiary);
    if (onTap == null) return null;
    return FlareIconControl(
      label: label,
      onTap: onTap,
      tooltip: false,
      child: FlareIcon(icon, size: FlareSizes.iconSizeMd, color: color),
    );
  }
}

/// location — the static map (or a drawn map with a centre pin), then the
/// place and its address. The card is a control only with [onOpen]; inside
/// [FlareMessageContentView] a host without its own handler gets the default
/// map link of the platform (`spec/location-vectors.json`) through `onOpenLink`.
/// Without an address the coordinate line stands in, so the second line is
/// never blank. Spec: Message/LocationMessage.
class FlareLocationMessage extends StatelessWidget {
  const FlareLocationMessage({
    super.key,
    required this.title,
    this.address = '',
    this.latitude,
    this.longitude,
    this.snapshotUrl,
    this.provider = FlareLocationProvider.osm,
    this.onOpen,
  });

  final String title;
  final String address;

  /// WGS-84 latitude, -90..90.
  final double? latitude;

  /// WGS-84 longitude, -180..180.
  final double? longitude;

  /// Signed static map from the host (the geo proxy); without it, or when it
  /// fails, the drawn map shows.
  final String? snapshotUrl;

  /// The tenant's map service: which web map the default link opens.
  final FlareLocationProvider provider;
  final VoidCallback? onOpen;

  /// The card's width and its map's height; request the snapshot at twice
  /// that.
  static const Size mapSize = Size(264, 132);

  /// The default links of this card, or null without a valid coordinate.
  FlareLocationMapLinks? get links => flareLocationMapLinks(
    latitude: latitude ?? double.nan,
    longitude: longitude ?? double.nan,
    title: title,
    provider: provider,
  );

  @override
  Widget build(BuildContext context) {
    final c = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final detail = address.trim().isNotEmpty
        ? address.trim()
        : (flareLocationCoordinateLabel(
                latitude ?? double.nan,
                longitude ?? double.nan,
              ) ??
              '');
    final card = ClipRRect(
      borderRadius: _bubbleRadius(),
      child: Container(
        width: mapSize.width,
        decoration: BoxDecoration(
          color: c.bgPrimary,
          border: Border.all(color: c.borderSecondary),
          borderRadius: _bubbleRadius(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: mapSize.height,
              child: FlareLocationMapSurface(
                src: snapshotUrl,
                // OpenStreetMap's licence (ODbL) asks for its credit wherever
                // its map shows; AMap's static map carries its own.
                attribution: provider == FlareLocationProvider.osm
                    ? strings.locationOsmAttribution
                    : null,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: FlareSizes.spacingMd,
                vertical: FlareSizes.spacingSm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: FlareSizes.fontSizeLg,
                      fontWeight: FontWeight.w500,
                      color: c.textPrimary,
                    ),
                  ),
                  if (detail.isNotEmpty)
                    Text(
                      detail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: FlareSizes.fontSizeSm,
                        color: c.textTertiary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    final label = [title, detail].where((part) => part.isNotEmpty).join(', ');
    return Semantics(
      container: true,
      button: onOpen != null,
      label: label,
      hint: onOpen == null ? null : strings.locationOpenInMaps,
      excludeSemantics: true,
      child: onOpen == null
          ? card
          : Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: onOpen,
                borderRadius: _bubbleRadius(),
                child: card,
              ),
            ),
    );
  }
}

/// contact / business card — avatar (image or pastel initials) + name /
/// subtitle. With [onOpen] the card is a control that reports [userId], so the
/// host opens the person's profile; without it the card only displays (and
/// draws no chevron). Spec: Message/ContactMessage.
class FlareContactMessage extends StatelessWidget {
  const FlareContactMessage({
    super.key,
    required this.name,
    this.subtitle,
    this.avatarUrl,
    this.userId = '',
    this.onOpen,
  });

  final String name;
  final String? subtitle;
  final String? avatarUrl;

  /// The person the card names; [onOpen] receives it.
  final String userId;
  final ValueChanged<String>? onOpen;

  @override
  Widget build(BuildContext context) {
    final c = FlareColors.of(context);
    final tint = FlareAvatar.seedTint(name, c);
    final open = onOpen;
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
      open == null ? null : () => open(userId),
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
            if (open != null) ...[
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, size: 16, color: c.textTertiary),
            ],
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
