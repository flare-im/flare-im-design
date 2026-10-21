import SwiftUI

/// Ordered list of the 106 semantic icon names supported by `IconView`.
public let flareIconNames: [String] = [
    "search", "send", "more", "back", "close",
    "check", "add", "remove", "edit", "delete",
    "heart", "comment", "chats", "moments", "share", "camera",
    "image", "location", "mic", "phone", "video",
    "settings", "person", "people", "person-add", "star",
    "download", "link", "emoji", "file",
    "folder", "notification", "mute", "copy", "forward",
    "reply", "refresh", "chevron-down", "chevron-right", "arrow-down",
    "warning", "info", "success", "error", "calendar",
    "clock", "eye", "eye-off", "lock", "qr",
    "block", "tag", "announcement", "theme", "language", "devices", "logout",
    "pin", "poll",
    // Message actions
    "recall", "unpin", "merge-forward", "multi-select", "quote",
    "reaction", "translate", "mention", "read", "mark",
    // Composer
    "rich-text", "attachment",
    // Conversation
    "mark-unread", "archive", "unarchive", "clear-history",
    // Calls
    "mic-off", "camera-off", "speaker", "speaker-off", "end-call",
    "switch-camera", "screen-share",
    // Media
    "play", "pause", "expand", "collapse", "zoom-in", "zoom-out", "rotate",
    // Members
    "group", "admin", "remove-member", "transfer-owner", "silence", "report",
    // General
    "chevron-up", "chevron-left", "keyboard", "mini-app",
    "pin-self", "diagnostics", "card", "id", "join-request", "storage",
    "red-packet",
]

/// Maps each semantic icon name to the closest SF Symbol name. Every symbol is in the SF Symbols
/// catalogue at the package's iOS 16 / macOS 13 floor; where the natural symbol is newer or does not
/// exist, the entry names the closest symbol with the same concept.
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
    "comment": "bubble.left",
    "share": "square.and.arrow.up",
    "camera": "camera",
    "image": "photo",
    // A map pin, as the location message and attach tile draw it (`location` is the current-position arrow).
    "location": "mappin.and.ellipse",
    "mic": "mic",
    "phone": "phone",
    "video": "video",
    "settings": "gearshape",
    "person": "person",
    "people": "person.2",
    "person-add": "person.badge.plus",
    "star": "star",
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
    // An exclamation circle: an x-circle reads as cancel.
    "error": "exclamationmark.circle",
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
    // More than one device, not a single laptop.
    "devices": "laptopcomputer.and.iphone",
    "logout": "rectangle.portrait.and.arrow.right",
    "pin": "pin",
    "poll": "chart.bar",
    "recall": "arrow.uturn.backward",
    "unpin": "pin.slash",
    "merge-forward": "arrow.triangle.merge",
    "multi-select": "checklist",
    "quote": "quote.opening",
    // SF Symbols has no face-with-plus; the add-reaction key shares the emoji face.
    "reaction": "face.smiling",
    // `translate` needs iOS 17.4; `character.bubble` is the translation glyph available at iOS 16.
    "translate": "character.bubble",
    "mention": "at",
    // SF Symbols has no double check; an opened envelope reads as "read".
    "read": "envelope.open",
    "mark": "flag",
    "rich-text": "textformat",
    "attachment": "paperclip",
    "mark-unread": "message.badge",
    "archive": "archivebox",
    "unarchive": "tray.and.arrow.up",
    "clear-history": "eraser",
    "mic-off": "mic.slash",
    "camera-off": "video.slash",
    "speaker": "speaker.wave.2",
    "speaker-off": "speaker.slash",
    "end-call": "phone.down",
    "switch-camera": "arrow.triangle.2.circlepath.camera",
    "screen-share": "rectangle.on.rectangle",
    "play": "play",
    "pause": "pause",
    "expand": "arrow.up.left.and.arrow.down.right",
    "collapse": "arrow.down.right.and.arrow.up.left",
    "zoom-in": "plus.magnifyingglass",
    "zoom-out": "minus.magnifyingglass",
    "rotate": "rotate.right",
    "group": "person.3",
    "admin": "checkmark.shield",
    "remove-member": "person.badge.minus",
    "transfer-owner": "key",
    // A member who cannot speak. SF Symbols has no slashed speech bubble; a silenced voice waveform
    // is the same concept and stays apart from `speaker-off` (audio output) and `mic-off`.
    "silence": "waveform.slash",
    "report": "exclamationmark.octagon",
    "chevron-up": "chevron.up",
    "chevron-left": "chevron.left",
    "keyboard": "keyboard",
    "mini-app": "square.grid.2x2",
    // Round 9: concepts every kit drew under a name that meant something else.
    "pin-self": "bookmark",
    "diagnostics": "ladybug",
    "card": "person.crop.rectangle",
    "id": "number",
    "join-request": "tray.and.arrow.down",
    "storage": "internaldrive",
    // SF Symbols has no red packet: the kit draws its own glyph (``FlareIconImage``); the envelope is what a raw
    // `Image(systemName:)` of this name shows.
    "red-packet": "envelope",
]

/// The names the kit draws itself rather than with an SF Symbol: ``FlareIconImage`` draws them, and the symbol in
/// ``flareIconMap`` is only the stand-in for a raw `Image(systemName:)`.
let flareKitGlyphNames: Set<String> = ["red-packet"]

/// A semantic icon at `size`: the registry's SF Symbol, or for a kit-drawn name (``flareKitGlyphNames``) the kit's
/// own line glyph in a `size` square. Either takes the foreground colour, as a symbol does. Controls that draw a
/// host's icon name (``IconView``, buttons, the composer's action panel, menus) draw through this.
struct FlareIconImage: View {
    let name: String
    let size: CGFloat
    var weight: Font.Weight = .regular

    var body: some View {
        if name == "red-packet" {
            FlareRedPacketIcon().frame(width: size, height: size)
        } else {
            Image(systemName: flareIconSymbol(name)).font(.system(size: size, weight: weight))
        }
    }
}

/// `red-packet`: the card's small envelope as a single-colour line glyph on the 24 grid — a 15 x 19.5 body with 2.7
/// corners, a flap curve hanging from the sides (at 0.7 of the flap) to the flap's depth (0.42 of the height) in
/// the middle, and a solid seal of radius 2.6 on its lowest point. Lines follow SF Symbols' regular weight.
struct FlareRedPacketIcon: View {
    var body: some View {
        ZStack {
            FlareRedPacketIconLines().fill()
            FlareRedPacketIconSeal().fill()
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }

    /// The glyph's geometry on the 24 grid.
    enum Grid {
        static let left: CGFloat = 4.5, right: CGFloat = 19.5, top: CGFloat = 2.25, bottom: CGFloat = 21.75
        static let corner: CGFloat = 2.7
        static let flap: CGFloat = (bottom - top) * 0.42
        static let side: CGFloat = flap * 0.7
        static let seal: CGFloat = 2.6
        /// The line, in grid units: SF Symbols' regular weight at this size.
        static let line: CGFloat = 1.8
    }
}

private struct FlareRedPacketIconLines: Shape {
    func path(in rect: CGRect) -> Path {
        typealias G = FlareRedPacketIcon.Grid
        let u = min(rect.width, rect.height) / 24
        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: rect.minX + x * u, y: rect.minY + y * u) }
        var path = Path(roundedRect: CGRect(origin: p(G.left, G.top), size: CGSize(width: (G.right - G.left) * u,
                                                                                    height: (G.bottom - G.top) * u)),
                        cornerRadius: G.corner * u)
        // The flap: a quadratic through (12, top + flap), its control as far below that point as the sides are above.
        path.move(to: p(G.left, G.top + G.side))
        path.addQuadCurve(to: p(G.right, G.top + G.side), control: p(12, G.top + G.flap + (G.flap - G.side)))
        // Stroked here, so the line scales with the glyph as a symbol's does.
        return path.strokedPath(StrokeStyle(lineWidth: G.line * u, lineCap: .round, lineJoin: .round))
    }
}

private struct FlareRedPacketIconSeal: Shape {
    func path(in rect: CGRect) -> Path {
        typealias G = FlareRedPacketIcon.Grid
        let u = min(rect.width, rect.height) / 24
        let centre = CGPoint(x: rect.minX + 12 * u, y: rect.minY + (G.top + G.flap) * u)
        return Path(ellipseIn: CGRect(x: centre.x - G.seal * u, y: centre.y - G.seal * u,
                                      width: G.seal * 2 * u, height: G.seal * 2 * u))
    }
}

/// The SF Symbol drawn for a semantic icon name; an unknown name draws `questionmark`. The one
/// resolution every kit icon name goes through (``IconView``, header actions, ``ActionMenuView`` items,
/// and every `icon:` the kit's models take).
///
/// A name that is not in the registry draws the fallback and says so once in a debug build — an SF
/// Symbol name passed where a kit name belongs (`"person.2"` for `people`) is not a compile error and
/// would otherwise be a silent question mark in the product.
func flareIconSymbol(_ name: String) -> String {
    if let symbol = flareIconMap[name] { return symbol }
    #if DEBUG
    flareWarnUnknownIcon(name)
    #endif
    return "questionmark"
}

#if DEBUG
private let flareUnknownIconLock = NSLock()
private nonisolated(unsafe) var flareWarnedIcons: Set<String> = []

/// Says an icon name is unknown once per name, so a list of 200 rows does not print 200 lines.
private func flareWarnUnknownIcon(_ name: String) {
    flareUnknownIconLock.lock()
    let unseen = flareWarnedIcons.insert(name).inserted
    flareUnknownIconLock.unlock()
    guard unseen else { return }
    print("[FlareIMUI] unknown icon name \"\(name)\" — pass one of flareIconNames; drawing the fallback glyph")
}
#endif

/// Action ids that stand for a kit icon name, so a header action needs no `icon` of its own to draw
/// the right glyph. The same four on every platform.
let flareActionIconAliases: [String: String] = [
    "audioCall": "phone",
    "videoCall": "video",
    "addMember": "person-add",
    "details": "info",
]

/// The SF Symbol for an action's icon name: an alias in ``flareActionIconAliases`` first, then the
/// kit vocabulary; an unknown name draws `questionmark`, never `more`.
func flareActionSymbol(_ name: String) -> String {
    flareIconSymbol(flareActionIconAliases[name] ?? name)
}

/// Whether an action id names an icon by itself: an alias or a kit icon name.
func flareActionIdNamesIcon(_ id: String) -> Bool {
    flareActionIconAliases[id] != nil || flareIconMap[id] != nil
}

/// Renders a Flare semantic icon as an SF Symbol.
///
/// Unknown names fall back to `questionmark`. The default colour is the
/// theme-aware `textSecondary` token.
public struct IconView: View {
    private let name: String
    private let size: CGFloat
    private let color: Color?
    private let accessibilityLabel: String?

    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme

    /// `accessibilityLabel` is the icon's own name. Leave it nil for a decorative
    /// icon inside an already-labelled control: the symbol is hidden from
    /// VoiceOver instead of announcing SF Symbols' own name over that label.
    public init(_ name: String, size: CGFloat = 20, color: Color? = nil, accessibilityLabel: String? = nil) {
        self.name = name
        self.size = size
        self.color = color
        self.accessibilityLabel = accessibilityLabel
    }

    public var body: some View {
        let tint = color ?? FlareColors.of(scheme, brand: flareBrandTheme).textSecondary
        if flareKitGlyphNames.contains(name) {
            FlareIconImage(name: name, size: size)
                .foregroundColor(tint)
                .accessibilityLabel(accessibilityLabel ?? "")
                .accessibilityHidden(accessibilityLabel == nil)
        } else {
            Image(systemName: flareIconSymbol(name))
                .font(.system(size: size))
                .foregroundColor(tint)
                .accessibilityLabel(accessibilityLabel ?? "")
                .accessibilityHidden(accessibilityLabel == nil)
        }
    }
}
