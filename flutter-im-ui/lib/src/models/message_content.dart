/// Message body content model — the data behind `MessageContentView` and the
/// content-type registry (spec `contentTypes.registered`).
///
/// [FlareMessageContent] is an open base (products may subclass and register a
/// builder via `FlareContentRegistry`); [type] is the registry key. The package
/// ships built-in renderers for the common types; unknown types fall back to a
/// labelled chip unless a custom builder is registered.
library;

abstract class FlareMessageContent {
  const FlareMessageContent();

  /// Registry key (e.g. `text`, `image`, `card`).
  String get type;
}

class FlareTextContent extends FlareMessageContent {
  const FlareTextContent(this.text, {this.mentionsSelf = false});
  final String text;
  final bool mentionsSelf;
  @override
  String get type => 'text';
}

class FlareImageContent extends FlareMessageContent {
  const FlareImageContent({
    required this.url,
    this.thumbnailUrl,
    this.width,
    this.height,
    this.alt,
  });
  final String url;
  final String? thumbnailUrl;
  final double? width;
  final double? height;
  final String? alt;
  @override
  String get type => 'image';
}

class FlareVideoContent extends FlareMessageContent {
  const FlareVideoContent({required this.url, this.poster, this.durationSec = 0});
  final String url;
  final String? poster;
  final int durationSec;
  @override
  String get type => 'video';
}

class FlareAudioContent extends FlareMessageContent {
  const FlareAudioContent({required this.url, this.durationSec = 0});
  final String url;
  final int durationSec;
  @override
  String get type => 'audio';
}

class FlareFileContent extends FlareMessageContent {
  const FlareFileContent({
    required this.name,
    required this.url,
    this.sizeBytes = 0,
  });
  final String name;
  final String url;
  final int sizeBytes;
  @override
  String get type => 'file';
}

class FlareLocationContent extends FlareMessageContent {
  const FlareLocationContent({
    required this.name,
    this.address = '',
    this.latitude,
    this.longitude,
  });
  final String name;
  final String address;
  final double? latitude;
  final double? longitude;
  @override
  String get type => 'location';
}

class FlareStickerContent extends FlareMessageContent {
  const FlareStickerContent({required this.url, this.label});
  final String url;
  final String? label;
  @override
  String get type => 'sticker';
}

class FlareEmojiContent extends FlareMessageContent {
  const FlareEmojiContent(this.emoji, {this.label});
  final String emoji;
  final String? label;
  @override
  String get type => 'emoji';
}

class FlareCardContent extends FlareMessageContent {
  const FlareCardContent({
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.sourceLabel,
  });
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String? sourceLabel;
  @override
  String get type => 'card';
}

class FlareLinkCardContent extends FlareMessageContent {
  const FlareLinkCardContent({
    required this.url,
    required this.title,
    this.description,
    this.imageUrl,
  });
  final String url;
  final String title;
  final String? description;
  final String? imageUrl;
  @override
  String get type => 'linkCard';
}

/// System / notification line (recall, member joined, pin changed…). Rendered
/// centred without a bubble.
class FlareNotificationContent extends FlareMessageContent {
  const FlareNotificationContent(this.text);
  final String text;
  @override
  String get type => 'notification';
}

class FlarePlaceholderContent extends FlareMessageContent {
  const FlarePlaceholderContent(this.label);
  final String label;
  @override
  String get type => 'placeholder';
}

/// Carries a product/registered type (`vote`, `task`, `schedule`…) with a plain
/// fallback label. Register a custom builder for [contentType] to render it
/// natively; otherwise a labelled chip is shown.
class FlareGenericContent extends FlareMessageContent {
  const FlareGenericContent({required this.contentType, required this.label});
  final String contentType;
  final String label;
  @override
  String get type => contentType;
}

/// Status of a media (image/video/file) download, used to overlay progress.
enum FlareMediaDownloadStatus { idle, downloading, done, failed }

class FlareMediaDownloadState {
  const FlareMediaDownloadState({
    this.status = FlareMediaDownloadStatus.idle,
    this.progressPct = 0,
  });
  final FlareMediaDownloadStatus status;

  /// 0–100.
  final int progressPct;

  bool get isDownloading => status == FlareMediaDownloadStatus.downloading;
}
