import 'package:video_player/video_player.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'media_player_stub.dart'
    if (dart.library.io) 'media_player_native.dart'
    as platform;

/// The address the kit's own players load for [raw], or null.
///
/// Only `http` and `https` with a host: message content is written by someone
/// else, and a `file:` or `content:` reference in it would have the reader's
/// app open local data. A host that plays local or authenticated media passes
/// its own media handler or player.
///
/// Internal: not exported from the package.
Uri? flarePlayableMediaUri(String? raw, {String? localPath}) {
  // Only the separate host-owned cache field can opt into local playback.
  // A sender-controlled file:/content: URL remains rejected below.
  if (localPath != null && localPath.isNotEmpty) {
    if (kIsWeb || !localPath.startsWith('/') || localPath.contains('\u0000'))
      return null;
    return Uri.file(localPath);
  }
  final value = raw?.trim() ?? '';
  if (value.isEmpty || RegExp(r'\s').hasMatch(value)) return null;
  final uri = Uri.tryParse(value);
  if (uri == null || uri.host.isEmpty) return null;
  final scheme = uri.scheme.toLowerCase();
  return scheme == 'http' || scheme == 'https' ? uri : null;
}

/// Makes the platform player for a media address. The kit plays video and
/// voice through `video_player`; tests swap in a fake (and restore this).
VideoPlayerController Function(Uri source) flareMediaPlayerFactory =
    flareDefaultMediaPlayer;

VideoPlayerController flareDefaultMediaPlayer(Uri source) =>
    source.scheme == 'file'
    ? platform.localMediaPlayer(source)
    : VideoPlayerController.networkUrl(source);
