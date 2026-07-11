import 'package:flutter/material.dart';

import '../emoji_sticker/emoji_sticker.dart';
import '../models/message_content.dart';
import '../tokens/flare_tokens.dart';

/// Context passed to every content renderer.
class FlareContentContext {
  const FlareContentContext({
    required this.self,
    this.previewMode = false,
    this.senderName,
    this.mediaState,
    this.onMediaAction,
    this.onLocate,
  });

  final bool self;
  final bool previewMode;
  final String? senderName;
  final FlareMediaDownloadState? mediaState;

  /// Host handles opening/downloading media (image preview, file save…).
  final void Function(FlareMessageContent content)? onMediaAction;

  /// Host focuses/locates this message (e.g. from a link card).
  final VoidCallback? onLocate;
}

/// A builder products register for a custom content [type].
typedef FlareContentBuilder = Widget Function(
  BuildContext context,
  FlareMessageContent content,
  FlareContentContext ctx,
);

/// Registry for product content types (`vote`, `task`, …). Built-in types are
/// rendered directly by [FlareMessageContentView]; register a builder to add or
/// override a type.
abstract final class FlareContentRegistry {
  static final Map<String, FlareContentBuilder> _builders = {};

  static void register(String type, FlareContentBuilder builder) =>
      _builders[type] = builder;

  static void unregister(String type) => _builders.remove(type);

  static FlareContentBuilder? lookup(String type) => _builders[type];
}

/// Content-type dispatcher — renders a message body by type. Spec:
/// Message/MessageContentView (`FlareMessageContentView`).
class FlareMessageContentView extends StatelessWidget {
  const FlareMessageContentView({
    super.key,
    required this.content,
    this.self = false,
    this.previewMode = false,
    this.senderName,
    this.mediaState,
    this.onMediaAction,
    this.onLocate,
  });

  final FlareMessageContent content;
  final bool self;
  final bool previewMode;
  final String? senderName;
  final FlareMediaDownloadState? mediaState;
  final void Function(FlareMessageContent content)? onMediaAction;
  final VoidCallback? onLocate;

  @override
  Widget build(BuildContext context) {
    final ctx = FlareContentContext(
      self: self,
      previewMode: previewMode,
      senderName: senderName,
      mediaState: mediaState,
      onMediaAction: onMediaAction,
      onLocate: onLocate,
    );

    final custom = FlareContentRegistry.lookup(content.type);
    if (custom != null) return custom(context, content, ctx);

    final colors = FlareColors.of(Theme.of(context).brightness);
    final onBubble = self ? Colors.white : colors.textPrimary;

    switch (content) {
      case FlareTextContent c:
        // Plain Text (not SelectableText) so the bubble's long-press opens the
        // action menu rather than the text-selection handles.
        return Text(
          c.text,
          style: TextStyle(
            // Flare thread body type: 15 / 1.45 (matches the reference app).
            fontSize: FlareSizes.fontSizeXl,
            height: 1.45,
            color: onBubble,
          ),
        );
      case FlareEmojiContent c:
        return FlareEmojiPackMessage(emoji: c.emoji);
      case FlareStickerContent c:
        return FlareStickerPackMessage(
          stickerId: c.stickerId ?? '',
          packageId: c.packageId,
          url: c.url,
          width: c.width,
          height: c.height,
        );
      case FlareImageContent c:
        return _image(context, c, colors);
      case FlareVideoContent c:
        return _video(context, c, colors);
      case FlareAudioContent c:
        return _audio(c, onBubble, colors);
      case FlareFileContent c:
        return _file(c, onBubble, colors);
      case FlareLocationContent c:
        return _location(c, onBubble, colors);
      case FlareCardContent c:
        return _card(context, c, colors);
      case FlareLinkCardContent c:
        return _linkCard(context, c, colors);
      case FlarePlaceholderContent c:
        return _chip(c.label, colors);
      case FlareGenericContent c:
        return _chip('[${c.label}]', colors);
      default:
        return _chip('[${content.type}]', colors);
    }
  }

  // --- built-in renderers ---------------------------------------------------

  Widget _image(BuildContext context, FlareImageContent c, FlareColors colors) {
    final src = c.thumbnailUrl ?? c.url;
    return GestureDetector(
      onTap: onMediaAction == null ? null : () => onMediaAction!(c),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
        child: Stack(
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 240, maxHeight: 240),
              child: _networkImage(src, colors, Icons.image_outlined),
            ),
            if (mediaState?.isDownloading ?? false)
              Positioned.fill(child: _progressScrim(mediaState!.progressPct)),
          ],
        ),
      ),
    );
  }

  Widget _video(BuildContext context, FlareVideoContent c, FlareColors colors) {
    return GestureDetector(
      onTap: onMediaAction == null ? null : () => onMediaAction!(c),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 240, maxHeight: 240),
              child: c.poster != null && c.poster!.isNotEmpty
                  ? _networkImage(c.poster!, colors, Icons.movie_outlined)
                  : Container(
                      width: 200,
                      height: 130,
                      color: colors.bgTertiary,
                    ),
            ),
            const _PlayGlyph(),
            if (c.durationSec > 0)
              Positioned(
                right: 6,
                bottom: 6,
                child: _durationChip(_formatDuration(c.durationSec)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _audio(FlareAudioContent c, Color fg, FlareColors colors) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.volume_up_outlined, size: 20, color: fg),
        const SizedBox(width: FlareSizes.spacingSm),
        Text(_formatDuration(c.durationSec),
            style: TextStyle(color: fg, fontSize: FlareSizes.fontSizeLg)),
      ],
    );
  }

  Widget _file(FlareFileContent c, Color fg, FlareColors colors) {
    return GestureDetector(
      onTap: onMediaAction == null ? null : () => onMediaAction!(c),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.insert_drive_file_outlined, size: 28, color: fg),
          const SizedBox(width: FlareSizes.spacingSm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 180),
                child: Text(c.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: fg,
                        fontSize: FlareSizes.fontSizeLg,
                        fontWeight: FontWeight.w500)),
              ),
              if (c.sizeBytes > 0)
                Text(_formatBytes(c.sizeBytes),
                    style: TextStyle(
                        color: fg.withValues(alpha: 0.7),
                        fontSize: FlareSizes.fontSizeSm)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _location(FlareLocationContent c, Color fg, FlareColors colors) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.location_on_outlined, size: 22, color: colors.error),
        const SizedBox(width: FlareSizes.spacingXs),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(c.name,
                style: TextStyle(
                    color: fg,
                    fontSize: FlareSizes.fontSizeLg,
                    fontWeight: FontWeight.w500)),
            if (c.address.isNotEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 200),
                child: Text(c.address,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: fg.withValues(alpha: 0.7),
                        fontSize: FlareSizes.fontSizeSm)),
              ),
          ],
        ),
      ],
    );
  }

  Widget _card(BuildContext context, FlareCardContent c, FlareColors colors) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 240),
      decoration: BoxDecoration(
        color: colors.bgPrimary,
        borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
        border: Border.all(color: colors.borderSecondary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (c.imageUrl != null && c.imageUrl!.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              child: _networkImage(c.imageUrl!, colors, Icons.image_outlined,
                  height: 120),
            ),
          Padding(
            padding: const EdgeInsets.all(FlareSizes.spacingMd),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(c.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: FlareSizes.fontSizeLg,
                        fontWeight: FontWeight.w600)),
                if (c.subtitle != null && c.subtitle!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(c.subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: FlareSizes.fontSizeSm)),
                ],
                if (c.sourceLabel != null && c.sourceLabel!.isNotEmpty) ...[
                  const SizedBox(height: FlareSizes.spacingSm),
                  Text(c.sourceLabel!,
                      style: TextStyle(
                          color: colors.textTertiary,
                          fontSize: FlareSizes.fontSizeXs)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _linkCard(
      BuildContext context, FlareLinkCardContent c, FlareColors colors) {
    return GestureDetector(
      onTap: onLocate,
      child: _card(
        context,
        FlareCardContent(
          title: c.title,
          subtitle: c.description,
          imageUrl: c.imageUrl,
          sourceLabel: c.url,
        ),
        colors,
      ),
    );
  }

  Widget _chip(String label, FlareColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: FlareSizes.spacingSm, vertical: FlareSizes.spacingXs),
      decoration: BoxDecoration(
        color: colors.bgTertiary,
        borderRadius: BorderRadius.circular(FlareSizes.radiusSm),
      ),
      child: Text(label,
          style: TextStyle(
              color: colors.textSecondary, fontSize: FlareSizes.fontSizeSm)),
    );
  }

  Widget _networkImage(String url, FlareColors colors, IconData fallback,
      {double? height}) {
    if (url.isEmpty) return _imageFallback(colors, fallback, height);
    return Image.network(
      url,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _imageFallback(colors, fallback, height),
    );
  }

  Widget _imageFallback(FlareColors colors, IconData icon, double? height) {
    return Container(
      height: height ?? 120,
      width: double.infinity,
      color: colors.bgTertiary,
      alignment: Alignment.center,
      child: Icon(icon, color: colors.textTertiary, size: 32),
    );
  }

  Widget _progressScrim(int pct) {
    return Container(
      color: Colors.black38,
      alignment: Alignment.center,
      child: Text('$pct%',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
    );
  }

  Widget _durationChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(FlareSizes.radiusSm),
      ),
      child: Text(text,
          style: const TextStyle(color: Colors.white, fontSize: 11)),
    );
  }

  static String _formatDuration(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    }
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(1)} GB';
  }
}

class _PlayGlyph extends StatelessWidget {
  const _PlayGlyph();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 30),
    );
  }
}
