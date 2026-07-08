import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';

/// Standalone, presentational per-type message bodies (clean params, no SDK /
/// media coupling) — drop any single one into your own layout. The SDK-driven
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

/// text — a plain text bubble (self flips to the brand-purple side).
class FlareTextMessage extends StatelessWidget {
  const FlareTextMessage({super.key, required this.text, this.self = false});

  final String text;
  final bool self;

  @override
  Widget build(BuildContext context) {
    final c = FlareColors.of(Theme.of(context).brightness);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: self
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
      child: Text(
        text,
        style: TextStyle(
          color: self ? Colors.white : c.textPrimary,
          fontSize: FlareSizes.fontSizeXl,
          height: 1.45,
        ),
      ),
    );
  }
}

/// image — a rounded thumbnail placeholder (pass your own child via [image]).
class FlareImageMessage extends StatelessWidget {
  const FlareImageMessage({
    super.key,
    this.width = 132,
    this.height = 92,
    this.image,
  });

  final double width;
  final double height;
  final Widget? image;

  @override
  Widget build(BuildContext context) {
    final c = FlareColors.of(Theme.of(context).brightness);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: width,
        height: height,
        child: image ??
            ColoredBox(
              color: c.bgTertiary,
              child: Icon(Icons.image_outlined, color: c.textTertiary, size: 26),
            ),
      ),
    );
  }
}

/// video — a thumbnail with a play overlay and a duration badge.
class FlareVideoMessage extends StatelessWidget {
  const FlareVideoMessage({super.key, this.duration = '00:00', this.poster});

  final String duration;
  final Widget? poster;

  @override
  Widget build(BuildContext context) {
    final c = FlareColors.of(Theme.of(context).brightness);
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 148,
        height: 92,
        child: Stack(
          fit: StackFit.expand,
          children: [
            poster ??
                ColoredBox(
                  color: c.bgTertiary,
                  child: Icon(Icons.videocam_outlined, color: c.textTertiary, size: 24),
                ),
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
                child: Text(
                  duration,
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// audio / voice — a compact bubble with a waveform and duration.
class FlareVoiceMessage extends StatelessWidget {
  const FlareVoiceMessage({super.key, this.seconds = 1});

  final int seconds;

  @override
  Widget build(BuildContext context) {
    final c = FlareColors.of(Theme.of(context).brightness);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: _cardDecoration(c),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.volume_up_outlined, size: 17, color: c.textSecondary),
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
          Text('$seconds"',
              style: TextStyle(fontSize: 12, color: c.textTertiary)),
        ],
      ),
    );
  }
}

/// file — a file card with name / size / ext and a download affordance.
class FlareFileMessage extends StatelessWidget {
  const FlareFileMessage({
    super.key,
    required this.name,
    this.size = '',
    this.ext,
  });

  final String name;
  final String size;
  final String? ext;

  @override
  Widget build(BuildContext context) {
    final c = FlareColors.of(Theme.of(context).brightness);
    final sub = ext == null || ext!.isEmpty ? size : '$size · $ext';
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: _cardDecoration(c),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_outlined, size: 20, color: c.primary),
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
                Text(sub,
                    style: TextStyle(fontSize: 11, color: c.textTertiary)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Icon(Icons.file_download_outlined, size: 17, color: c.textTertiary),
        ],
      ),
    );
  }
}

/// location — a map placeholder over a title / address.
class FlareLocationMessage extends StatelessWidget {
  const FlareLocationMessage({super.key, required this.title, this.address = ''});

  final String title;
  final String address;

  @override
  Widget build(BuildContext context) {
    final c = FlareColors.of(Theme.of(context).brightness);
    return ClipRRect(
      borderRadius: _bubbleRadius(),
      child: Container(
        width: 264,
        decoration: _cardDecoration(c),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 84,
              color: Color.alphaBlend(c.primary.withValues(alpha: 0.08), c.bgTertiary),
              child: Icon(Icons.location_on_outlined, color: c.primary, size: 22),
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
                  Text(address,
                      style: TextStyle(fontSize: 11, color: c.textTertiary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// contact / business card — pastel avatar + name / id.
class FlareContactMessage extends StatelessWidget {
  const FlareContactMessage({super.key, required this.name, this.flareId});

  final String name;
  final String? flareId;

  @override
  Widget build(BuildContext context) {
    final c = FlareColors.of(Theme.of(context).brightness);
    final tint = _pastel(name);
    return Container(
      constraints: const BoxConstraints(minWidth: 240),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: _cardDecoration(c),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: tint.$1,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(_initials(name),
                style: TextStyle(
                    color: tint.$2, fontWeight: FontWeight.w600, fontSize: 14)),
          ),
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
                if (flareId != null && flareId!.isNotEmpty)
                  Text('Flare ID: $flareId',
                      style: TextStyle(fontSize: 11, color: c.textTertiary)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, size: 16, color: c.textTertiary),
        ],
      ),
    );
  }
}

/// link card — thumbnail + title + domain.
class FlareLinkCardMessage extends StatelessWidget {
  const FlareLinkCardMessage({
    super.key,
    required this.title,
    this.domain = '',
  });

  final String title;
  final String domain;

  @override
  Widget build(BuildContext context) {
    final c = FlareColors.of(Theme.of(context).brightness);
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: _cardDecoration(c),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: c.bgTertiary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.image_outlined, size: 22, color: c.textTertiary),
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
    );
  }
}

/// A vote option for [FlareVoteMessage].
class FlareVoteOption {
  const FlareVoteOption(this.text, this.pct);
  final String text;
  final int pct;
}

/// vote — a title over option rows with proportional bars.
class FlareVoteMessage extends StatelessWidget {
  const FlareVoteMessage({
    super.key,
    required this.title,
    this.options = const [],
  });

  final String title;
  final List<FlareVoteOption> options;

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
          for (final o in options) ...[
            _VoteRow(option: o, colors: c),
            if (o != options.last) const SizedBox(height: 6),
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

/// task — checkbox + title (struck through when done) + meta.
class FlareTaskMessage extends StatelessWidget {
  const FlareTaskMessage({
    super.key,
    required this.title,
    this.meta,
    this.done = false,
  });

  final String title;
  final String? meta;
  final bool done;

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
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: done ? c.primary : null,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: done ? c.primary : c.borderPrimary, width: 1.5),
            ),
            child: done
                ? const Icon(Icons.check, size: 13, color: Colors.white)
                : null,
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
                  Text(meta!,
                      style: TextStyle(fontSize: 11, color: c.textTertiary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// sticker — a bare, larger glyph/image (no bubble).
class FlareStickerMessage extends StatelessWidget {
  const FlareStickerMessage({super.key, this.emoji = '🐱', this.image});

  final String emoji;
  final Widget? image;

  @override
  Widget build(BuildContext context) {
    return image ??
        Text(emoji, style: const TextStyle(fontSize: 72, height: 1));
  }
}

/// emoji — a bare, large emoji (no bubble).
class FlareEmojiMessage extends StatelessWidget {
  const FlareEmojiMessage({super.key, this.emoji = '🎉'});

  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Text(emoji, style: const TextStyle(fontSize: 40, height: 1));
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
