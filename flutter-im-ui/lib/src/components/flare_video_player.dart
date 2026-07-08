import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';

/// Full-screen video player chrome — poster, title, close, and a play surface.
/// Spec: Media/VideoPlayerModal (`FlareVideoPlayer`).
///
/// The package stays dependency-free, so actual decoding is provided by the
/// host through [playerBuilder] (e.g. a `video_player`/`media_kit` widget);
/// without it, the poster + play affordance is shown and [onPlay] fires on tap.
class FlareVideoPlayer extends StatelessWidget {
  const FlareVideoPlayer({
    super.key,
    required this.show,
    required this.videoSrc,
    this.poster,
    this.title,
    this.playerBuilder,
    this.onPlay,
    this.onClose,
  });

  final bool show;
  final String videoSrc;
  final String? poster;
  final String? title;

  /// Host-supplied real player for [videoSrc]; when null, poster + play glyph.
  final Widget Function(BuildContext context, String videoSrc)? playerBuilder;

  final VoidCallback? onPlay;
  final VoidCallback? onClose;

  static Future<void> present(
    BuildContext context, {
    required String videoSrc,
    String? poster,
    String? title,
    Widget Function(BuildContext, String)? playerBuilder,
  }) {
    return showGeneralDialog(
      context: context,
      barrierColor: Colors.black,
      pageBuilder: (ctx, _, __) => FlareVideoPlayer(
        show: true,
        videoSrc: videoSrc,
        poster: poster,
        title: title,
        playerBuilder: playerBuilder,
        onClose: () => Navigator.of(ctx).maybePop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!show) return const SizedBox.shrink();
    return Material(
      color: Colors.black,
      child: Stack(
        children: [
          Positioned.fill(
            child: Center(
              child: playerBuilder != null
                  ? playerBuilder!(context, videoSrc)
                  : _posterWithPlay(),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + FlareSizes.spacingSm,
            left: FlareSizes.spacingSm,
            child: _circleButton(Icons.close_rounded, onClose),
          ),
          if (title != null && title!.isNotEmpty)
            Positioned(
              top: MediaQuery.of(context).padding.top + FlareSizes.spacingMd,
              left: 56,
              right: FlareSizes.spacingMd,
              child: Text(
                title!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: FlareSizes.fontSize2xl,
                    fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }

  Widget _posterWithPlay() {
    return GestureDetector(
      onTap: onPlay,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (poster != null && poster!.isNotEmpty)
            Image.network(poster!,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const SizedBox.shrink()),
          Container(
            width: 64,
            height: 64,
            decoration:
                const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
            child: const Icon(Icons.play_arrow_rounded,
                color: Colors.white, size: 44),
          ),
        ],
      ),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback? onTap) {
    return Material(
      color: Colors.white24,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
