import SwiftUI

/// Ordered list of the 61 semantic icon names supported by `IconView`.
public let flareIconNames: [String] = [
    "search", "send", "more", "back", "close",
    "check", "add", "remove", "edit", "delete",
    "heart", "heart-filled", "comment", "share", "camera",
    "image", "location", "mic", "phone", "video",
    "settings", "person", "people", "person-add", "star",
    "bookmark", "download", "link", "emoji", "file",
    "folder", "notification", "mute", "copy", "forward",
    "reply", "refresh", "chevron-down", "chevron-right", "arrow-down",
    "warning", "info", "success", "error", "calendar",
    "clock", "eye", "eye-off", "lock", "qr",
    "chats", "moments",
    "block", "tag", "announcement", "theme", "language", "devices", "logout",
    "pin", "poll",
]

/// Maps each semantic icon name to the closest SF Symbol name.
public let flareIconMap: [String: String] = [
    "search": "magnifyingglass",
    "send": "paperplane",
    "more": "ellipsis",
    "back": "chevron.left",
    "close": "xmark",
    "check": "checkmark",
    "add": "plus",
    "remove": "minus",
    "edit": "pencil",
    "delete": "trash",
    "heart": "heart",
    "heart-filled": "heart.fill",
    "comment": "bubble.left",
    "share": "square.and.arrow.up",
    "camera": "camera",
    "image": "photo",
    "location": "location",
    "mic": "mic",
    "phone": "phone",
    "video": "video",
    "settings": "gearshape",
    "person": "person",
    "people": "person.2",
    "person-add": "person.badge.plus",
    "star": "star",
    "bookmark": "bookmark",
    "download": "arrow.down.circle",
    "link": "link",
    "emoji": "face.smiling",
    "file": "doc",
    "folder": "folder",
    "notification": "bell",
    "mute": "bell.slash",
    "copy": "doc.on.doc",
    "forward": "arrowshape.turn.up.right",
    "reply": "arrowshape.turn.up.left",
    "refresh": "arrow.clockwise",
    "chevron-down": "chevron.down",
    "chevron-right": "chevron.right",
    "arrow-down": "arrow.down",
    "warning": "exclamationmark.triangle",
    "info": "info.circle",
    "success": "checkmark.circle",
    "error": "xmark.circle",
    "calendar": "calendar",
    "clock": "clock",
    "eye": "eye",
    "eye-off": "eye.slash",
    "lock": "lock",
    "qr": "qrcode",
    "chats": "bubble.left.and.bubble.right",
    "moments": "safari",
    "block": "nosign",
    "tag": "tag",
    "announcement": "megaphone",
    "theme": "moon",
    "language": "globe",
    "devices": "laptopcomputer",
    "logout": "rectangle.portrait.and.arrow.right",
    "pin": "pin",
    "poll": "chart.bar",
]

/// Renders a Flare semantic icon as an SF Symbol.
///
/// Unknown names fall back to `questionmark`. The default colour is the
/// theme-aware `textSecondary` token.
public struct IconView: View {
    private let name: String
    private let size: CGFloat
    private let color: Color?

    @Environment(\.colorScheme) private var scheme

    public init(_ name: String, size: CGFloat = 20, color: Color? = nil) {
        self.name = name
        self.size = size
        self.color = color
    }

    public var body: some View {
        Image(systemName: flareIconMap[name] ?? "questionmark")
            .font(.system(size: size))
            .foregroundColor(color ?? FlareColors.of(scheme).textSecondary)
    }
}
