import 'dart:async';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/directory_data.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_button.dart';
import 'flare_icon.dart';
import 'flare_icon_button.dart';
import 'icon_control.dart';
import 'media_source.dart';

/// Full-screen video player — poster, title, close, and playback.
/// Spec: Media/VideoPlayerModal (`FlareVideoPlayer`).
///
/// With neither [playerBuilder] nor [onPlay], the kit plays [videoSrc] itself
/// (http or https) as soon as it is shown: a tap on the picture or the named
/// play / pause key toggles playback, and an address that cannot be played
/// shows 重试 and 关闭 instead of a blank screen. A host that decodes the
/// video passes [playerBuilder]; one that starts playback itself passes
/// [onPlay] and gets the poster with a play key.
class FlareVideoPlayer extends StatefulWidget {
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

  /// Host-supplied player for [videoSrc], in place of the kit's.
  final Widget Function(BuildContext context, String videoSrc)? playerBuilder;

  /// Host-owned play key: the poster and a play control call it instead of
  /// the kit playing the video.
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
  State<FlareVideoPlayer> createState() => _FlareVideoPlayerState();
}

class _FlareVideoPlayerState extends State<FlareVideoPlayer> {
  VideoPlayerController? _player;
  bool _failed = false;
  int _generation = 0;

  bool get _kitPlays =>
      widget.show && widget.playerBuilder == null && widget.onPlay == null;

  @override
  void initState() {
    super.initState();
    if (_kitPlays) unawaited(_start());
  }

  @override
  void didUpdateWidget(FlareVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasPlaying =
        oldWidget.show &&
        oldWidget.playerBuilder == null &&
        oldWidget.onPlay == null;
    if (!_kitPlays) {
      if (wasPlaying) _stop();
    } else if (!wasPlaying || oldWidget.videoSrc != widget.videoSrc) {
      unawaited(_start());
    }
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  void _stop() {
    _generation++;
    final player = _player;
    _player = null;
    if (player == null) return;
    player.removeListener(_onValue);
    unawaited(player.dispose());
  }

  /// Loads [FlareVideoPlayer.videoSrc] and plays it. Callers that are not
  /// already rebuilding (retry) call setState themselves.
  Future<void> _start() async {
    _stop();
    final generation = _generation;
    final source = flarePlayableMediaUri(widget.videoSrc);
    _failed = source == null;
    if (source == null) return;
    final player = flareMediaPlayerFactory(source);
    _player = player;
    player.addListener(_onValue);
    try {
      await player.initialize();
      if (!mounted || generation != _generation) return;
      await player.play();
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() => _failed = true);
    }
  }

  void _retry() {
    unawaited(_start());
    setState(() {});
  }

  void _onValue() {
    final player = _player;
    if (player == null || !mounted) return;
    setState(() => _failed = _failed || player.value.hasError);
  }

  Future<void> _togglePlay() async {
    final player = _player;
    if (player == null || !player.value.isInitialized) return;
    if (player.value.isPlaying) {
      await player.pause();
    } else {
      // At the end, play starts over.
      await player.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.show) return const SizedBox.shrink();
    final strings = FlareStrings.of(context);
    final top = MediaQuery.of(context).padding.top;
    return Material(
      color: Colors.black,
      child: Stack(
        children: [
          Positioned.fill(
            child: Center(
              child: widget.playerBuilder != null
                  ? widget.playerBuilder!(context, widget.videoSrc)
                  : widget.onPlay != null
                  ? _posterWithPlay(strings.play, widget.onPlay)
                  : _kitPlayer(strings),
            ),
          ),
          Positioned(
            top: top + FlareSizes.spacingSm,
            left: FlareSizes.spacingSm,
            child: FlareIconButton(
              icon: 'close',
              semanticLabel: strings.close,
              onPressed: widget.onClose,
              tintColor: Colors.white,
              backgroundColor: Colors.white24,
              customSize: FlareSizes.touchTarget,
            ),
          ),
          if (widget.title != null && widget.title!.isNotEmpty)
            Positioned(
              top: top + FlareSizes.spacingMd,
              left: 56,
              right: FlareSizes.spacingMd,
              child: Text(
                widget.title!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: FlareSizes.fontSize2xl,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _kitPlayer(FlareStrings strings) {
    final player = _player;
    if (_failed) return _failure(strings);
    final value = player?.value;
    if (player == null || value == null || !value.isInitialized) {
      return Stack(
        alignment: Alignment.center,
        children: [
          _poster(),
          const CircularProgressIndicator(color: Colors.white),
        ],
      );
    }
    final playing = value.isPlaying;
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => unawaited(_togglePlay()),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AspectRatio(
                    aspectRatio: value.aspectRatio,
                    child: VideoPlayer(player),
                  ),
                  if (!playing)
                    const IgnorePointer(
                      child: FlareIcon(
                        'play',
                        color: Colors.white,
                        size: FlareSizes.iconSizeXl + FlareSizes.spacingMd,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              FlareSizes.spacingSm,
              0,
              FlareSizes.spacingLg,
              FlareSizes.spacingSm,
            ),
            child: Row(
              children: [
                FlareIconButton(
                  icon: playing ? 'pause' : 'play',
                  semanticLabel: playing ? strings.pause : strings.play,
                  onPressed: () => unawaited(_togglePlay()),
                  tintColor: Colors.white,
                  customSize: FlareSizes.touchTarget,
                ),
                const SizedBox(width: FlareSizes.spacingSm),
                Expanded(
                  child: VideoProgressIndicator(
                    player,
                    allowScrubbing: true,
                    colors: const VideoProgressColors(
                      playedColor: Colors.white,
                      bufferedColor: Colors.white38,
                      backgroundColor: Colors.white12,
                    ),
                  ),
                ),
                const SizedBox(width: FlareSizes.spacingMd),
                Text(
                  '${_clock(value.position)} / ${_clock(value.duration)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: FlareSizes.fontSizeSm,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _failure(FlareStrings strings) {
    return Padding(
      padding: const EdgeInsets.all(FlareSizes.spacing2xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const FlareIcon(
            'error',
            color: Colors.white70,
            size: FlareSizes.iconSizeXl,
          ),
          const SizedBox(height: FlareSizes.spacingMd),
          Text(
            strings.videoLoadFailed,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: FlareSizes.fontSizeLg,
            ),
          ),
          const SizedBox(height: FlareSizes.spacingLg),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: FlareSizes.spacingMd,
            runSpacing: FlareSizes.spacingSm,
            children: [
              FlareButton(
                label: strings.retry,
                size: FlareControlSize.lg,
                onPressed: _retry,
              ),
              FlareButton(
                label: strings.close,
                size: FlareControlSize.lg,
                variant: FlareButtonVariant.secondary,
                onPressed: widget.onClose,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _poster() {
    final poster = widget.poster;
    if (poster == null || flarePlayableMediaUri(poster) == null) {
      return const SizedBox.shrink();
    }
    return Image.network(
      poster,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
  }

  static String _clock(Duration duration) {
    final seconds = duration.inSeconds < 0 ? 0 : duration.inSeconds;
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  /// The poster is the play control: the whole surface takes the tap.
  Widget _posterWithPlay(String playLabel, VoidCallback? onPlay) {
    return FlareIconControl(
      label: playLabel,
      onTap: onPlay,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (widget.poster != null && widget.poster!.isNotEmpty)
            Image.network(
              widget.poster!,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
            ),
            child: const FlareIcon('play', color: Colors.white, size: 44),
          ),
        ],
      ),
    );
  }
}
