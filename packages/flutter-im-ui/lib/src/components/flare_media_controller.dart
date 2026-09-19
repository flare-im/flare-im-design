import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:video_player/video_player.dart';

import '../models/image_gallery.dart';
import '../models/message_content.dart';
import 'flare_image_preview.dart';
import 'flare_message_bodies.dart';
import 'flare_video_player.dart';
import 'media_source.dart';

/// Coordinates the playback of received voice messages in one thread: a voice
/// message plays inside its own bubble and starting another stops the first.
///
/// `FlareMessageList` makes one when the host passes none and gives it to the
/// bubbles it builds, and stops playback when it is disposed or covered by
/// another screen. Images and videos open in the kit preview and player; a
/// host that takes the file tap passes `onOpenFile`, and a host that takes
/// every media tap passes `onMediaAction`, in which case nothing plays here.
///
/// Pass your own controller to the list only to stop its playback from the
/// outside ([stopVoice]), for example when a call starts.
class FlareMediaController extends ChangeNotifier {
  VideoPlayerController? _player;
  String? _voiceKey;
  _VoiceStatus _status = _VoiceStatus.idle;
  int _elapsedSeconds = 0;
  int _durationSeconds = 0;
  int _generation = 0;
  bool _disposed = false;

  /// Plays the voice message [key] from [url], or pauses it while it plays and
  /// resumes it while paused. Starting one stops the one before it; a failed
  /// one starts again.
  Future<void> toggleVoice(String key, String url) async {
    final player = _player;
    if (_voiceKey == key && player != null) {
      switch (_status) {
        case _VoiceStatus.playing:
          await player.pause();
          return;
        case _VoiceStatus.paused:
          await player.play();
          return;
        case _VoiceStatus.loading:
          return;
        case _VoiceStatus.idle:
        case _VoiceStatus.failed:
          break;
      }
    }
    await _startVoice(key, url);
  }

  /// Stops voice playback, if any, and releases its player.
  Future<void> stopVoice() async {
    if (_voiceKey == null && _player == null) return;
    _generation++;
    await _release();
    _notify();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation++;
    unawaited(_release());
    super.dispose();
  }

  Future<void> _startVoice(String key, String url) async {
    final generation = ++_generation;
    await _release();
    if (_disposed || generation != _generation) return;
    _voiceKey = key;
    _status = _VoiceStatus.loading;
    _elapsedSeconds = 0;
    _durationSeconds = 0;
    _notify();
    final source = flarePlayableMediaUri(url);
    if (source == null) {
      _status = _VoiceStatus.failed;
      _notify();
      return;
    }
    final player = flareMediaPlayerFactory(source);
    _player = player;
    player.addListener(_onPlayerValue);
    try {
      await player.initialize();
      if (_disposed || generation != _generation) return;
      await player.play();
    } catch (_) {
      if (_disposed || generation != _generation) return;
      _status = _VoiceStatus.failed;
      _notify();
    }
  }

  void _onPlayerValue() {
    final player = _player;
    if (player == null || _disposed) return;
    final value = player.value;
    if (value.hasError) {
      _status = _VoiceStatus.failed;
      _notify();
      return;
    }
    if (!value.isInitialized) return;
    // A finished message returns to its resting state, ready to play again.
    if (value.isCompleted) {
      _generation++;
      unawaited(_release().then((_) => _notify()));
      return;
    }
    _status = value.isPlaying ? _VoiceStatus.playing : _VoiceStatus.paused;
    _elapsedSeconds = value.position.inSeconds;
    _durationSeconds = value.duration.inSeconds;
    _notify();
  }

  Future<void> _release() async {
    final player = _player;
    _player = null;
    _voiceKey = null;
    _status = _VoiceStatus.idle;
    _elapsedSeconds = 0;
    _durationSeconds = 0;
    if (player == null) return;
    player.removeListener(_onPlayerValue);
    try {
      await player.pause();
    } catch (_) {
      // A player that never initialized has nothing to pause.
    }
    unawaited(player.dispose());
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  _VoiceView _viewOf(String key) => _voiceKey == key
      ? _VoiceView(_status, _elapsedSeconds, _durationSeconds)
      : const _VoiceView(_VoiceStatus.idle, 0, 0);
}

enum _VoiceStatus { idle, loading, playing, paused, failed }

@immutable
class _VoiceView {
  const _VoiceView(this.status, this.elapsedSeconds, this.durationSeconds);

  final _VoiceStatus status;
  final int elapsedSeconds;
  final int durationSeconds;

  @override
  bool operator ==(Object other) =>
      other is _VoiceView &&
      other.status == status &&
      other.elapsedSeconds == elapsedSeconds &&
      other.durationSeconds == durationSeconds;

  @override
  int get hashCode => Object.hash(status, elapsedSeconds, durationSeconds);
}

/// Opens [image] in the kit preview: its full-size address when it has one,
/// else its thumbnail. Returns false when it has neither. The preview offers a
/// download key only with [onDownload].
///
/// Internal: not exported from the package.
bool flarePresentImage(
  BuildContext context,
  FlareImageContent image, {
  VoidCallback? onDownload,
}) {
  final source = image.url.trim().isNotEmpty
      ? image.url
      : (image.thumbnailUrl ?? '');
  if (source.trim().isEmpty) return false;
  unawaited(
    FlareImagePreview.present(
      context,
      imageSrc: source,
      alt: image.alt,
      onDownload: onDownload,
    ),
  );
  return true;
}

/// Opens the picture at [index] of message [messageId]: inside a timeline
/// ([FlareImageGalleryScope]) as the conversation's gallery starting at that
/// picture, each picture downloadable through the timeline's handler; else —
/// or when the picture is not in the gallery — [image] alone, downloadable
/// through [onDownload]. Returns false when there is nothing to open.
///
/// Internal: not exported from the package.
bool flareOpenImage(
  BuildContext context,
  FlareImageContent image, {
  String? messageId,
  int index = 0,
  VoidCallback? onDownload,
}) {
  final gallery = FlareImageGalleryScope.maybeOf(context);
  final items = gallery?.items;
  final start = items == null || messageId == null
      ? null
      : flareImageGalleryStart(items, messageId, index);
  if (items == null || start == null) {
    return flarePresentImage(context, image, onDownload: onDownload);
  }
  final download = gallery!.download;
  unawaited(
    FlareImagePreview.presentGallery(
      context,
      images: [for (final item in items) item.image],
      initialIndex: start,
      onDownload: download == null ? null : (i) => download(items[i]),
    ),
  );
  return true;
}

/// Gives the bodies below it the gallery of the timeline they are drawn in.
///
/// Internal: not exported from the package.
class FlareImageGalleryScope extends InheritedWidget {
  const FlareImageGalleryScope({
    super.key,
    required this.items,
    this.download,
    required super.child,
  });

  final List<FlareImageGalleryItem> items;

  /// Saves a picture of the gallery through the timeline's download handler;
  /// null when the host offers none.
  final ValueChanged<FlareImageGalleryItem>? download;

  static FlareImageGalleryScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FlareImageGalleryScope>();

  @override
  bool updateShouldNotify(FlareImageGalleryScope oldWidget) =>
      !identical(items, oldWidget.items) ||
      (download == null) != (oldWidget.download == null);
}

/// Opens [video] in the kit player, which starts playing it.
///
/// Internal: not exported from the package.
void flarePresentVideo(BuildContext context, FlareVideoContent video) {
  unawaited(
    FlareVideoPlayer.present(
      context,
      videoSrc: video.url,
      poster: video.poster,
    ),
  );
}

/// Gives the bubbles below it the list's [FlareMediaController].
///
/// Internal: not exported from the package.
class FlareMediaScope extends InheritedWidget {
  const FlareMediaScope({
    super.key,
    required this.controller,
    required super.child,
  });

  final FlareMediaController controller;

  static FlareMediaController? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<FlareMediaScope>()?.controller;

  @override
  bool updateShouldNotify(FlareMediaScope oldWidget) =>
      !identical(controller, oldWidget.controller);
}

/// A received voice message that shows its playback state from the nearest
/// [FlareMediaScope] (or a controller of its own when there is none).
///
/// A tap goes to [onPlay] when the host handles media, else it plays or pauses
/// the message in place. Each bubble rebuilds only when its own state changes,
/// not on every position tick of the message playing elsewhere.
///
/// Internal: not exported from the package.
class FlareVoicePlaybackMessage extends StatefulWidget {
  const FlareVoicePlaybackMessage({
    super.key,
    required this.content,
    this.messageId,
    this.onPlay,
  });

  final FlareAudioContent content;
  final String? messageId;
  final VoidCallback? onPlay;

  @override
  State<FlareVoicePlaybackMessage> createState() =>
      _FlareVoicePlaybackMessageState();
}

class _FlareVoicePlaybackMessageState extends State<FlareVoicePlaybackMessage> {
  FlareMediaController? _scoped;
  FlareMediaController? _own;
  _VoiceView _view = const _VoiceView(_VoiceStatus.idle, 0, 0);

  FlareMediaController get _controller =>
      _scoped ?? (_own ??= FlareMediaController()..addListener(_sync));

  String get _key => widget.messageId ?? widget.content.url;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scoped = FlareMediaScope.maybeOf(context);
    if (identical(scoped, _scoped)) return;
    _scoped?.removeListener(_sync);
    _scoped = scoped;
    _scoped?.addListener(_sync);
    _view = _controller._viewOf(_key);
  }

  @override
  void didUpdateWidget(FlareVoicePlaybackMessage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.messageId != widget.messageId ||
        oldWidget.content.url != widget.content.url) {
      _view = _controller._viewOf(_key);
    }
  }

  void _sync() {
    final next = _controller._viewOf(_key);
    if (next != _view && mounted) setState(() => _view = next);
  }

  @override
  void dispose() {
    _scoped?.removeListener(_sync);
    // A bubble scrolled out of the list keeps the list's playback going; a
    // bubble playing on its own stops with it.
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final view = _view;
    final seconds = widget.content.durationSec > 0
        ? widget.content.durationSec
        : view.durationSeconds;
    return FlareVoiceMessage(
      seconds: seconds,
      elapsedSeconds: view.elapsedSeconds,
      playing: view.status == _VoiceStatus.playing,
      loading: view.status == _VoiceStatus.loading,
      failed: view.status == _VoiceStatus.failed,
      onPlay:
          widget.onPlay ??
          () => unawaited(_controller.toggleVoice(_key, widget.content.url)),
    );
  }
}
