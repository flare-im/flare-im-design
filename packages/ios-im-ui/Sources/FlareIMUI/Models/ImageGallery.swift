import Foundation

// A conversation's image gallery: the pictures a full-screen preview opened from a timeline pages through. The rule
// is shared with the other three kits (`spec/image-gallery-vectors.json`).

/// One picture of the gallery: the message it belongs to, its place in that message, and the picture.
public struct FlareImageGalleryItem: Equatable {
    public let messageId: String
    public let index: Int
    public let image: FlareImageContent

    public init(messageId: String, index: Int, image: FlareImageContent) {
        self.messageId = messageId; self.index = index; self.image = image
    }

    /// The address the preview loads: the full-size image, else its thumbnail.
    public var source: String {
        image.url.trimmingCharacters(in: .whitespaces).isEmpty
            ? (image.thumbnailURL ?? "").trimmingCharacters(in: .whitespaces) : image.url
    }

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.messageId == rhs.messageId && lhs.index == rhs.index && lhs.source == rhs.source && lhs.image.alt == rhs.image.alt
    }
}

/// Every picture of every image and album message in `messages` (timeline order, oldest first), skipping recalled
/// messages and pictures with nothing to load.
public func flareImageGalleryItems(_ messages: [FlareMessageData]) -> [FlareImageGalleryItem] {
    var items: [FlareImageGalleryItem] = []
    for message in messages where !message.isRecalled {
        let images: [FlareImageContent]
        switch message.content {
        case let image as FlareImageContent: images = [image]
        case let album as FlareImageGroupContent: images = album.images
        default: images = []
        }
        for (index, image) in images.enumerated() {
            let item = FlareImageGalleryItem(messageId: message.id, index: index, image: image)
            if !item.source.isEmpty { items.append(item) }
        }
    }
    return items
}

/// Where a gallery of `items` starts for a tap on the picture at `index` of message `messageId`; nil when it is not
/// in the gallery.
public func flareImageGalleryStart(_ items: [FlareImageGalleryItem], messageId: String, index: Int) -> Int? {
    items.firstIndex { $0.messageId == messageId && $0.index == index }
}

/// The gallery of the timeline a message body is drawn in: the timeline's messages, read only when a picture opens,
/// and the host's download handler for a picture of one of them.
struct FlareImageGallerySource {
    let messages: [FlareMessageData]
    let download: ((FlareMessageData, FlareMessageContent) -> Void)?
}
