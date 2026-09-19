/// A conversation's image gallery: the pictures a full-screen preview opened
/// from a timeline pages through. The rule is shared with the other three kits
/// (`spec/image-gallery-vectors.json`).
library;

import 'message_content.dart';
import 'message_data.dart';

/// One picture of the gallery: the message it belongs to, its place in that
/// message (an album's image index; 0 for an image message), and the picture.
class FlareImageGalleryItem {
  const FlareImageGalleryItem({
    required this.messageId,
    required this.index,
    required this.image,
  });

  final String messageId;
  final int index;
  final FlareImageContent image;

  /// The address the preview loads: the full-size image, else its thumbnail.
  String get source => image.url.trim().isNotEmpty
      ? image.url
      : (image.thumbnailUrl ?? '').trim();
}

/// Every picture of every image and album message in [messages] (timeline
/// order, oldest first), skipping recalled messages and pictures with nothing
/// to load.
List<FlareImageGalleryItem> flareImageGalleryItems(
  Iterable<FlareMessageData> messages,
) {
  final items = <FlareImageGalleryItem>[];
  for (final message in messages) {
    if (message.isRecalled) continue;
    final images = switch (message.content) {
      FlareImageContent image => [image],
      FlareImageGroupContent album => album.images,
      _ => const <FlareImageContent>[],
    };
    for (var index = 0; index < images.length; index++) {
      final item = FlareImageGalleryItem(
        messageId: message.id,
        index: index,
        image: images[index],
      );
      if (item.source.isNotEmpty) items.add(item);
    }
  }
  return items;
}

/// Where a gallery of [items] starts for a tap on the picture at [index] of
/// message [messageId]; null when that picture is not in the gallery.
int? flareImageGalleryStart(
  List<FlareImageGalleryItem> items,
  String messageId,
  int index,
) {
  final at = items.indexWhere(
    (item) => item.messageId == messageId && item.index == index,
  );
  return at < 0 ? null : at;
}
