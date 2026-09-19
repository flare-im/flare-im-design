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
  const FlareTextContent(this.text, {this.mentions = const []});
  final String text;

  /// Mentions to highlight in [text], as string indices; build them from the
  /// core's entities with [flareTextMentionSpans].
  final List<FlareTextMentionSpan> mentions;
  @override
  String get type => 'text';
}

/// A rich-text message: the RichDoc v2 document the core stores ([docJson]),
/// the core's flat [plainText] of it, and the message's own [title]. Drawn by
/// `FlareRichTextMessage`; the sender's Markdown source is not part of it.
class FlareRichTextContent extends FlareMessageContent {
  const FlareRichTextContent({
    required this.docJson,
    this.plainText = '',
    this.title = '',
  });

  /// The document's JSON text, as the core sends it.
  final String docJson;
  final String plainText;
  final String title;
  @override
  String get type => 'richText';
}

/// A mention entity as the core sends it on text content (`content.mentions`).
/// [start] and [length] count Unicode code points, not string indices.
class FlareMentionEntity {
  const FlareMentionEntity({
    required this.start,
    required this.length,
    this.type = 0,
    this.userId = '',
    this.userIds = const [],
    this.roleId = '',
  });

  /// flare-proto `MentionType`: [typeUser], [typeAll], [typeRole], [typeMulti].
  final int type;
  final String userId;
  final List<String> userIds;
  final String roleId;
  final int start;
  final int length;

  static const int typeUser = 1;
  static const int typeAll = 2;
  static const int typeRole = 3;
  static const int typeMulti = 4;
}

/// A mention inside a text body: [start] and [length] are UTF-16 indices into
/// the rendered text. [self] marks a mention of the current user, [all] one of
/// everyone; both are drawn with a stronger treatment.
class FlareTextMentionSpan {
  const FlareTextMentionSpan({
    required this.start,
    required this.length,
    this.self = false,
    this.all = false,
  });

  final int start;
  final int length;
  final bool self;
  final bool all;

  int get end => start + length;

  @override
  bool operator ==(Object other) =>
      other is FlareTextMentionSpan &&
      other.start == start &&
      other.length == length &&
      other.self == self &&
      other.all == all;

  @override
  int get hashCode => Object.hash(start, length, self, all);

  @override
  String toString() =>
      'FlareTextMentionSpan($start, $length${self ? ', self' : ''}${all ? ', all' : ''})';
}

/// The spans of the core mention [entities] in [text], for
/// [FlareTextContent.mentions].
///
/// Offsets arrive in code points and leave as string (UTF-16) indices, so an
/// emoji before a mention does not shift it. An entity is kept only when it
/// lies inside [text], is at least two code points long and starts at an "@";
/// anything else would highlight the wrong words. Spans come back sorted, and
/// one that overlaps the span before it is dropped. [currentUserId] marks the
/// mentions of the reader (`userId` or one of `userIds`).
List<FlareTextMentionSpan> flareTextMentionSpans(
  String text,
  Iterable<FlareMentionEntity> entities, {
  String currentUserId = '',
}) {
  if (text.isEmpty || entities.isEmpty) return const [];
  // String index of every code point boundary: offsets[i] is where code point
  // i starts, offsets.last is text.length.
  final offsets = <int>[0];
  for (final rune in text.runes) {
    offsets.add(offsets.last + (rune > 0xFFFF ? 2 : 1));
  }
  final codePoints = offsets.length - 1;
  final spans = <FlareTextMentionSpan>[];
  for (final entity in entities) {
    final start = entity.start;
    final length = entity.length;
    if (start < 0 || length < 2 || start + length > codePoints) continue;
    final from = offsets[start];
    if (text.codeUnitAt(from) != 0x40) continue; // "@"
    spans.add(
      FlareTextMentionSpan(
        start: from,
        length: offsets[start + length] - from,
        all: entity.type == FlareMentionEntity.typeAll,
        self:
            currentUserId.isNotEmpty &&
            (entity.userId == currentUserId ||
                entity.userIds.contains(currentUserId)),
      ),
    );
  }
  spans.sort((a, b) => a.start.compareTo(b.start));
  final kept = <FlareTextMentionSpan>[];
  for (final span in spans) {
    if (kept.isNotEmpty && span.start < kept.last.end) continue;
    kept.add(span);
  }
  return kept;
}

class FlareImageContent extends FlareMessageContent {
  const FlareImageContent({
    required this.url,
    this.thumbnailUrl,
    this.width,
    this.height,
    this.alt,
    this.animated = false,
  });
  final String url;
  final String? thumbnailUrl;
  final double? width;
  final double? height;

  /// What the image shows, in words — the caption the sender wrote or the
  /// core's description. A one-line summary prefers it over "[图片]".
  final String? alt;

  /// A motion image (GIF / animated WebP): summarised as "[动图]", not "[图片]".
  final bool animated;
  @override
  String get type => 'image';
}

/// An image-group (album) message: its [images] in order, each drawn and
/// opened like an image message, and the album's [description].
class FlareImageGroupContent extends FlareMessageContent {
  const FlareImageGroupContent({required this.images, this.description = ''});
  final List<FlareImageContent> images;
  final String description;
  @override
  String get type => 'imageGroup';
}

class FlareVideoContent extends FlareMessageContent {
  const FlareVideoContent({
    required this.url,
    this.poster,
    this.durationSec = 0,
  });
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
  const FlareStickerContent({
    required this.url,
    this.label,
    this.packageId,
    this.stickerId,
    this.width,
    this.height,
  });
  final String url;
  final String? label;

  /// Protocol pack identity — when set, the sticker resolves to a bundled pack
  /// asset (via [FlareEmojiStickerCatalog]) before falling back to [url].
  final String? packageId;
  final String? stickerId;
  final double? width;
  final double? height;
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

/// Read-only poll data; absent results are not rendered as zero-percent votes.
class FlarePollContent extends FlareMessageContent {
  const FlarePollContent({
    required this.id,
    required this.title,
    this.options = const [],
  });
  final String id;
  final String title;
  final List<String> options;
  @override
  String get type => 'vote';
}

class FlareTaskContent extends FlareMessageContent {
  const FlareTaskContent({
    required this.id,
    required this.title,
    this.detail = '',
    this.done = false,
  });
  final String id;
  final String title;
  final String detail;
  final bool done;
  @override
  String get type => 'task';
}

class FlareCalendarContent extends FlareMessageContent {
  const FlareCalendarContent({
    required this.id,
    required this.title,
    this.timeRange = '',
  });
  final String id;
  final String title;
  final String timeRange;
  @override
  String get type => 'schedule';
}

class FlareMiniAppContent extends FlareMessageContent {
  const FlareMiniAppContent({
    required this.appId,
    required this.title,
    this.pagePath = '',
    this.thumbnailUrl = null,
    this.description = null,
  });
  final String appId;
  final String title;
  final String pagePath;
  final String? thumbnailUrl;
  final String? description;
  @override
  String get type => 'miniProgram';
}

class FlareAnnouncementContent extends FlareMessageContent {
  const FlareAnnouncementContent({
    required this.id,
    required this.title,
    this.body = '',
  });
  final String id;
  final String title;
  final String body;
  @override
  String get type => 'announcement';
}

/// Unknown product content only. Stable built-ins use their typed models.
class FlareGenericContent extends FlareMessageContent {
  const FlareGenericContent({
    required this.contentType,
    required this.label,
    this.itemCount = 0,
  });
  final String contentType;
  final String label;

  /// How many things this content carries, for the types whose one-line
  /// summary is a count rather than a name — forwarded messages, an album.
  /// 0 means "not a counted type, or the count is unknown".
  final int itemCount;
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
