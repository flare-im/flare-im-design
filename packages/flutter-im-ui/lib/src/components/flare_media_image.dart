import 'dart:io' show File;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';

import '../models/message_content.dart';

/// Where a message picture comes from: the web (`http(s)`), inline bytes
/// (`data:`), or — only with [allowLocalFile] — the file on this device
/// (`file://` or an absolute path). Anything else, or a local file on the web,
/// has no picture: the caller shows its placeholder.
///
/// A local file is drawn only for this device's own message while its upload
/// is still running (the bubble passes [allowLocalFile] then), or for the copy
/// the host resolved through the SDK cache ([flarePictureSource]). Message content
/// is written by someone else, and a `file:` reference in a received message
/// must not have the reader's app open local data — the same rule as the
/// kit's players (`flarePlayableMediaUri`).
ImageProvider? flareMediaImageProvider(
  String? url, {
  bool allowLocalFile = false,
}) {
  final value = url?.trim() ?? '';
  if (value.isEmpty) return null;
  final lower = value.toLowerCase();
  if (lower.startsWith('https://') || lower.startsWith('http://')) {
    return NetworkImage(value);
  }
  if (lower.startsWith('data:')) {
    try {
      return MemoryImage(UriData.parse(value).contentAsBytes());
    } on FormatException {
      return null;
    }
  }
  if (kIsWeb || !allowLocalFile) return null;
  if (lower.startsWith('file://')) {
    return FileImage(File(Uri.parse(value).toFilePath()));
  }
  final windowsDrive = RegExp(r'^[a-zA-Z]:[\\/]');
  if (value.startsWith('/') || windowsDrive.hasMatch(value)) {
    return FileImage(File(value));
  }
  return null;
}

/// [flareMediaImageProvider] drawn, or [placeholder] when there is no picture
/// or it fails to load. [allowLocalFile]: see [flareMediaImageProvider].
/// Where to draw [image] from: its local copy ([FlareImageContent.localPath],
/// resolved by the host through the SDK cache) when there is one, otherwise
/// its thumbnail then full-size address ([preferThumbnail]) or the reverse.
/// `local` says the source is that trusted local copy.
({String src, bool local}) flarePictureSource(
  FlareImageContent image, {
  bool preferThumbnail = true,
}) {
  final local = image.localPath?.trim() ?? '';
  if (local.isNotEmpty && !kIsWeb) return (src: local, local: true);
  final thumb = image.thumbnailUrl?.trim() ?? '';
  final full = image.url.trim();
  final src = preferThumbnail
      ? (thumb.isNotEmpty ? thumb : full)
      : (full.isNotEmpty ? full : thumb);
  return (src: src, local: false);
}

Widget flareMediaImage(
  String? url, {
  required Widget placeholder,
  BoxFit fit = BoxFit.cover,
  bool gaplessPlayback = false,
  bool allowLocalFile = false,
}) {
  final provider = flareMediaImageProvider(url, allowLocalFile: allowLocalFile);
  if (provider == null) return placeholder;
  return Image(
    image: provider,
    fit: fit,
    gaplessPlayback: gaplessPlayback,
    errorBuilder: (_, __, ___) => placeholder,
  );
}
