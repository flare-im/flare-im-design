import 'package:video_player/video_player.dart';

/// The address the kit's own players load for [raw], or null.
///
/// Only `http` and `https` with a host: message content is written by someone
/// else, and a `file:` or `content:` reference in it would have the reader's
/// app open local data. A host that plays local or authenticated media passes
/// its own media handler or player.
///
/// Internal: not exported from the package.
Uri? flarePlayableMediaUri(String? raw) {
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
    VideoPlayerController.networkUrl;
