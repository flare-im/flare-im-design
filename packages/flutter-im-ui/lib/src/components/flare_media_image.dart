import 'dart:io' show File;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';

/// Where a message picture comes from: the web (`http(s)`), inline bytes
/// (`data:`), or — while the message is still uploading — the file on this
/// device (`file://` or an absolute path). Anything else, or a local file on
/// the web, has no picture: the caller shows its placeholder.
ImageProvider? flareMediaImageProvider(String? url) {
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
  if (kIsWeb) return null;
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
/// or it fails to load.
Widget flareMediaImage(
  String? url, {
  required Widget placeholder,
  BoxFit fit = BoxFit.cover,
  bool gaplessPlayback = false,
}) {
  final provider = flareMediaImageProvider(url);
  if (provider == null) return placeholder;
  return Image(
    image: provider,
    fit: fit,
    gaplessPlayback: gaplessPlayback,
    errorBuilder: (_, __, ___) => placeholder,
  );
}
