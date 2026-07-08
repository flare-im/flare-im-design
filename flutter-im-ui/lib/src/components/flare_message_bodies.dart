import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';

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

BoxDecoration _cardDecoration(FlareColors c) => BoxDecoration(
      color: c.bgPrimary,
      borderRadius: _bubbleRadius(),
      border: Border.all(color: c.borderSecondary),
      boxShadow: const [
        BoxShadow(color: Color(0x0D000000), blurRadius: 10, offset: Offset(0, 2)),
      ],
    );

/// A network image with a placeholder fallback (host provides the URL).
Widget _netImage(String? url, {required Widget placeholder, BoxFit fit = BoxFit.cover}) {
  if (url == null || url.isEmpty) return placeholder;
  return Image.network(url, fit: fit, errorBuilder: (_, __, ___) => placeholder);
}

Widget _tap(VoidCallback? onTap, Widget child) =>
    onTap == null ? child : GestureDetector(onTap: onTap, behavior: HitTestBehavior.opaque, child: child);

/// text — a plain text bubble; linkifies bare URLs and reports `onLinkTap`.
class FlareTextMessage extends StatefulWidget {
  const FlareTextMessage({
    super.key,
    required this.text,
    this.self = false,
    this.selectable = false,
    this.onLinkTap,
  });

  final String text;
  final bool self;
  final bool selectable;
  final ValueChanged<String>? onLinkTap;

  @override
  State<FlareTextMessage> createState() => _FlareTextMessageState();
}

class _FlareTextMessageState extends State<FlareTextMessage> {
  final _recognizers = <TapGestureRecognizer>[];

  @override
  void dispose() {
    for (final r in _recognizers) {
      r.dispose();
    }
    super.dispose();
  }

  List<InlineSpan> _spans(Color linkColor) {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
    final spans = <InlineSpan>[];
    final re = RegExp(r'((?:https?:\/\/)?[a-z0-9.-]+\.[a-z]{2,}(?:\/\S*)?)', caseSensitive: false);
    var last = 0;
    for (final m in re.allMatches(widget.text)) {
      if (m.start > last) spans.add(TextSpan(text: widget.text.substring(last, m.start)));
      final href = m.group(0)!;
      final rec = TapGestureRecognizer()..onTap = () => widget.onLinkTap?.call(href);
      _recognizers.add(rec);
      spans.add(TextSpan(
        text: href,
        style: TextStyle(color: linkColor, decoration: TextDecoration.underline),
        recognizer: rec,
      ));
      last = m.end;
    }
    if (last < widget.text.length) spans.add(TextSpan(text: widget.text.substring(last)));
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final c = FlareColors.of(Theme.of(context).brightness);
    final base = TextStyle(
      color: widget.self ? Colors.white : c.textPrimary,
      fontSize: FlareSizes.fontSizeXl,
      height: 1.45,
    );
    final linkColor = widget.self ? Colors.white : c.primary;
    final span = TextSpan(style: base, children: _spans(linkColor));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: widget.self
          ? BoxDecoration(
              color: c.bubbleSelf,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(_corner),
                topRight: Radius.circular(_corner),
                bottomLeft: Radius.circular(_corner),
                bottomRight: _tail,
              ),
            )
          : _cardDecoration(c),
      child: widget.selectable
          ? SelectableText.rich(span)
          : Text.rich(span),
    );
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
    final c = FlareColors.of(Theme.of(context).brightness);
    return _tap(
      onTap,
      Semantics(
        label: alt,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: width,
            height: height,
            child: _netImage(src,
                placeholder: ColoredBox(
                  color: c.bgTertiary,
                  child: Icon(Icons.image_outlined, color: c.textTertiary, size: 26),
                )),
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
    final c = FlareColors.of(Theme.of(context).brightness);
    return _tap(
      onPlay,
      Semantics(
        label: alt,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 148,
            height: 92,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _netImage(poster,
                    placeholder: ColoredBox(
                      color: c.bgTertiary,
                      child: Icon(Icons.videocam_outlined, color: c.textTertiary, size: 24),
                    )),
                const ColoredBox(color: Color(0x47000000)),
                const Center(
                  child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 34),
                ),
                Positioned(
                  right: 6,
                  bottom: 5,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0x73000000),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(duration,
                        style: const TextStyle(color: Colors.white, fontSize: 10)),
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

/// audio / voice — waveform + duration; `playing` drives the active look,
/// emits `onPlay`.
class FlareVoiceMessage extends StatelessWidget {
  const FlareVoiceMessage({super.key, this.seconds = 1, this.playing = false, this.onPlay});

  final int seconds;
  final bool playing;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    final c = FlareColors.of(Theme.of(context).brightness);
    final accent = playing ? c.primary : c.textSecondary;
    return _tap(
      onPlay,
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: _cardDecoration(c),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(playing ? Icons.volume_up_outlined : Icons.play_arrow_rounded,
                size: 17, color: accent),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var n = 1; n <= 9; n++) ...[
                  Container(
                    width: 2,
                    height: 4 + ((n * 5) % 13).toDouble(),
                    decoration: BoxDecoration(
                        color: c.primary, borderRadius: BorderRadius.circular(2)),
                  ),
                  if (n < 9) const SizedBox(width: 2),
                ],
              ],
            ),
            const SizedBox(width: 8),
            Text('$seconds"', style: TextStyle(fontSize: 12, color: c.textTertiary)),
          ],
        ),
      ),
    );
  }
}

/// file — icon / name / size / ext; emits `onOpen` (card) and `onDownload`.
/// Override the leading [icon] to show a per-file-type glyph.
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
    final c = FlareColors.of(Theme.of(context).brightness);
    final sub = ext == null || ext!.isEmpty ? size : '$size · $ext';
    return _tap(
      onOpen,
      Container(
        constraints: const BoxConstraints(maxWidth: 300),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: _cardDecoration(c),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            icon ?? Icon(Icons.folder_outlined, size: 20, color: c.primary),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: FlareSizes.fontSizeLg,
                          fontWeight: FontWeight.w500,
                          color: c.textPrimary)),
                  Text(sub, style: TextStyle(fontSize: 11, color: c.textTertiary)),
                ],
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: onDownload,
              child: Icon(Icons.file_download_outlined, size: 17, color: c.textTertiary),
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
    final c = FlareColors.of(Theme.of(context).brightness);
    return _tap(
      onOpen,
      ClipRRect(
        borderRadius: _bubbleRadius(),
        child: Container(
          width: 264,
          decoration: _cardDecoration(c),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 84,
                child: _netImage(mapImage,
                    placeholder: Container(
                      color: Color.alphaBlend(c.primary.withValues(alpha: 0.08), c.bgTertiary),
                      child: Icon(Icons.location_on_outlined, color: c.primary, size: 22),
                    )),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: FlareSizes.fontSizeLg,
                            fontWeight: FontWeight.w500,
                            color: c.textPrimary)),
                    Text(address, style: TextStyle(fontSize: 11, color: c.textTertiary)),
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
    final c = FlareColors.of(Theme.of(context).brightness);
    final tint = _pastel(name);
    final avatar = ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: SizedBox(
        width: 44,
        height: 44,
        child: _netImage(avatarUrl,
            placeholder: Container(
              alignment: Alignment.center,
              color: tint.$1,
              child: Text(_initials(name),
                  style: TextStyle(color: tint.$2, fontWeight: FontWeight.w600, fontSize: 14)),
            )),
      ),
    );
    return _tap(
      onOpen,
      Container(
        constraints: const BoxConstraints(minWidth: 240),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: _cardDecoration(c),
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
                  Text(name,
                      style: TextStyle(
                          fontSize: FlareSizes.fontSizeXl,
                          fontWeight: FontWeight.w600,
                          color: c.textPrimary)),
                  if (subtitle != null && subtitle!.isNotEmpty)
                    Text(subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: c.textTertiary)),
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
  });

  final String title;
  final String domain;
  final String? thumb;
  final String? description;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final c = FlareColors.of(Theme.of(context).brightness);
    return _tap(
      onOpen,
      Container(
        constraints: const BoxConstraints(maxWidth: 300),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: _cardDecoration(c),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 48,
                height: 48,
                child: _netImage(thumb,
                    placeholder: Container(
                      alignment: Alignment.center,
                      color: c.bgTertiary,
                      child: Icon(Icons.image_outlined, size: 22, color: c.textTertiary),
                    )),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: FlareSizes.fontSizeLg,
                          fontWeight: FontWeight.w500,
                          color: c.textPrimary)),
                  if (description != null && description!.isNotEmpty)
                    Text(description!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: c.textSecondary)),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.link, size: 12, color: c.textTertiary),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(domain,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11, color: c.textTertiary)),
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
  const FlareVoteOption(this.text, this.pct);
  final String text;
  final int pct;
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
    final c = FlareColors.of(Theme.of(context).brightness);
    return Container(
      constraints: const BoxConstraints(minWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: _cardDecoration(c),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.bar_chart, size: 16, color: c.textPrimary),
              const SizedBox(width: 6),
              Text(title,
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: FlareSizes.fontSizeLg,
                      color: c.textPrimary)),
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
          Positioned.fill(child: ColoredBox(color: colors.bgSecondary)),
          Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: (option.pct.clamp(0, 100)) / 100,
              child: ColoredBox(
                color: colors.primary.withValues(alpha: 0.16),
                child: const SizedBox(height: 30),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            child: Row(
              children: [
                Expanded(
                  child: Text(option.text,
                      style: TextStyle(fontSize: 13, color: colors.textPrimary)),
                ),
                Text('${option.pct}%',
                    style: TextStyle(fontSize: 12, color: colors.textSecondary)),
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
    final c = FlareColors.of(Theme.of(context).brightness);
    return Container(
      constraints: const BoxConstraints(minWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: _cardDecoration(c),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: done ? c.primary : null,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: done ? c.primary : c.borderPrimary, width: 1.5),
              ),
              child: done ? const Icon(Icons.check, size: 13, color: Colors.white) : null,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    style: TextStyle(
                      fontSize: FlareSizes.fontSizeLg,
                      fontWeight: FontWeight.w500,
                      color: done ? c.textTertiary : c.textPrimary,
                      decoration: done ? TextDecoration.lineThrough : null,
                    )),
                if (meta != null && meta!.isNotEmpty)
                  Text(meta!, style: TextStyle(fontSize: 11, color: c.textTertiary)),
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
  const FlareStickerMessage({super.key, this.emoji = '🐱', this.image, this.onTap});

  final String emoji;
  final Widget? image;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _tap(onTap, image ?? Text(emoji, style: const TextStyle(fontSize: 72, height: 1)));
  }
}

/// emoji — a bare, large emoji (no bubble); emits `onTap`.
class FlareEmojiMessage extends StatelessWidget {
  const FlareEmojiMessage({super.key, this.emoji = '🎉', this.onTap});

  final String emoji;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _tap(onTap, Text(emoji, style: const TextStyle(fontSize: 40, height: 1)));
  }
}

/// notification / system — a centered pill.
class FlareSystemMessage extends StatelessWidget {
  const FlareSystemMessage({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final c = FlareColors.of(Theme.of(context).brightness);
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

// pastel identity (matches FlareAvatar).
(Color, Color) _pastel(String seed) {
  const pairs = <(Color, Color)>[
    (Color(0xFFDBEAFE), Color(0xFF1D4ED8)),
    (Color(0xFFE9D5FF), Color(0xFF6D28D9)),
    (Color(0xFFFBCFE8), Color(0xFFBE185D)),
    (Color(0xFFD1FAE5), Color(0xFF047857)),
    (Color(0xFFFEF3C7), Color(0xFFB45309)),
    (Color(0xFFE5E7EB), Color(0xFF374151)),
  ];
  var h = 0;
  for (final code in seed.codeUnits) {
    h = (h * 31 + code) & 0x7fffffff;
  }
  return pairs[h % pairs.length];
}

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
}
