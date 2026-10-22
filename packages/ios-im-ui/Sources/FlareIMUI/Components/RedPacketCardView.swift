import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

// MARK: - RedPacketCard

/// Red packet card — the festive envelope in the timeline. Spec: Message/RedPacketCard (`RedPacketCardView`).
///
/// Red packet v5 (docs/design/red-packet-v5-roles-and-wallet.md §1): the greeting, the kind badge on the brand line
/// (拼手气 / 专属; normal has none), "给 某某" on an exclusive packet and one status line — never an amount, not even
/// the viewer's own.
///
/// - `state` comes from the plugin's public layer and the viewer's personal layer
///   (``flareRedPacketCardState(status:claimedByMe:tapAction:)``); the status line follows
///   ``FlareRedPacketCardRules/status(state:statusLabel:busy:disabled:)``: busy, the host's `statusLabel`, then the
///   state (领取红包, 查看红包, 已领取, 已被领完, 已过期, 已退回); an unopened card that is `disabled` says 暂不可用.
/// - Every state but busy / disabled calls `onOpen`; the host routes by the personal layer's `tapAction` (the open
///   sheet, the details, or the not-eligible notice).
/// - A spent card (claimed, finished, expired, refunded) keeps its hue and recedes: each colour is mixed toward
///   `redPacketFadedMixTarget` by ``FlareSizes/componentRedPacketFadedMix``, the text takes `redPacketFadedInk` and
///   the card lies flat. Busy and disabled keep their state's face and say why on the status line.
/// - The card is the message's card surface: the timeline draws no bubble around it. At most
///   ``FlareSizes/componentRedPacketCardWidth`` wide inside its parent, never under the touch target tall.
public struct RedPacketCardView: View {
    private let blessing: String
    private let kind: FlareRedPacketKind?
    private let recipientName: String?
    private let state: FlareRedPacketCardState
    private let disabled: Bool
    private let busy: Bool
    private let statusLabel: String?
    private let onOpen: (() -> Void)?
    @Environment(\.flareStrings) private var strings
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme

    /// - Parameters:
    ///   - kind: Lucky and exclusive draw their badge on the brand line; normal (and nil) draws none.
    ///   - recipientName: An exclusive packet's designated member, from the host's directory ("给 某某").
    public init(blessing: String, kind: FlareRedPacketKind? = nil, recipientName: String? = nil,
                state: FlareRedPacketCardState = .unopened, disabled: Bool = false, busy: Bool = false,
                statusLabel: String? = nil, onOpen: (() -> Void)? = nil) {
        self.blessing = blessing; self.kind = kind; self.recipientName = recipientName; self.state = state
        self.disabled = disabled; self.busy = busy; self.statusLabel = statusLabel; self.onOpen = onOpen
    }

    public var body: some View {
        Button { if canOpen { onOpen?() } } label: { card }
            // Not `.plain`: the system dims a disabled plain button, and a busy or unavailable packet keeps its
            // colours — only its status line says why it does not open.
            .buttonStyle(RedPacketCardPressStyle())
            .disabled(!canOpen)
            .accessibilityLabel(accessibilityName)
            .accessibilityValue(statusText)
    }

    var canOpen: Bool { FlareRedPacketCardRules.tappable(busy: busy, disabled: disabled) && onOpen != nil }

    var statusText: String {
        FlareRedPacketCardRules.status(state: state, statusLabel: statusLabel, busy: busy, disabled: disabled)
            .text(strings)
    }

    private var badge: String? { FlareRedPacketCardRules.badge(kind, strings: strings) }
    private var recipient: String? { FlareRedPacketCardRules.recipient(kind, name: recipientName, strings: strings) }

    /// The greeting, then the badge and the recipient.
    private var accessibilityName: String {
        ([blessing] + [badge, recipient].compactMap { $0 }).joined(separator: ", ")
    }

    private var card: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let faded = FlareRedPacketCardRules.faded(state)
        let ink = faded ? colors.redPacketFadedInk : colors.redPacketOnSurface
        return VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: FlareSizes.spacingMd) {
                RedPacketGlyph(width: RedPacketMetrics.cardGlyphWidth, faded: faded)
                VStack(alignment: .leading, spacing: FlareSizes.spacing3xs) {
                    Text(blessing)
                        .font(.system(size: FlareSizes.fontSizeXl, weight: .semibold))
                        .foregroundColor(ink)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Text(statusText)
                        .font(.system(size: FlareSizes.fontSizeSm))
                        .foregroundColor(faded ? ink : colors.redPacketOnSurface.opacity(0.85))
                        .lineLimit(1)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, FlareSizes.spacing2md)
            .padding(.vertical, FlareSizes.spacingMd)
            Rectangle().fill(ink.opacity(faded ? 0.18 : 0.24)).frame(height: RedPacketMetrics.hairline)
                .padding(.horizontal, FlareSizes.spacing2md)
            HStack(spacing: FlareSizes.spacingSm) {
                if let badge {
                    Text(badge).fontWeight(.semibold).lineLimit(1)
                }
                if let recipient { Text(recipient).lineLimit(1).truncationMode(.tail) }
                Spacer(minLength: 0)
                Text(strings.packetBrand).lineLimit(1)
            }
            .font(.system(size: FlareSizes.fontSize2xs))
            .foregroundColor(ink.opacity(faded ? 0.72 : 0.75))
            .padding(.horizontal, FlareSizes.spacing2md)
            .padding(.vertical, FlareSizes.spacingXs)
        }
        .frame(maxWidth: FlareSizes.componentRedPacketCardWidth, minHeight: FlareSizes.touchTarget, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: FlareSizes.radiusXl).fill(RedPacketPalette.cover(colors, faded: faded)))
        .contentShape(RoundedRectangle(cornerRadius: FlareSizes.radiusXl))
        // One shadow under the card's outline, not one under each line of text; a spent card lies flat.
        .compositingGroup()
        .shadow(color: colors.redPacketEnd.opacity(faded ? 0 : 0.3), radius: FlareSizes.spacingSm, y: FlareSizes.spacingXs)
        // Never squeezed below its content by a crowded parent.
        .fixedSize(horizontal: false, vertical: true)
    }
}

/// The card's press feedback, and nothing else: no dimming while disabled.
private struct RedPacketCardPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.opacity(configuration.isPressed ? 0.85 : 1)
    }
}

// MARK: - Shared red packet drawing

/// Geometry the red packet family shares that has no token of its own: proportions and hairlines.
enum RedPacketMetrics {
    static let hairline: CGFloat = 0.5
    /// The close button's ring.
    static let ringWidth: CGFloat = 1.5
    static let cardGlyphWidth: CGFloat = 30
    /// The glyph is an envelope: taller than wide.
    static let glyphAspect: CGFloat = 1.3
    /// The envelope's flap covers this share of its minimum height; the open button sits on its edge.
    static let flapShare: CGFloat = 0.62
    /// How far the flap's curved edge dips below its straight sides, as a share of the envelope width.
    static let flapCurve: CGFloat = 0.1
    /// The open button's glyph against the button's diameter.
    static let openGlyphShare: CGFloat = 0.42
    /// One turn of the opening flip.
    static let flipPeriod: Double = 0.9
}

/// The festive colour ramps, all from the `colors.redPacket*` tokens.
enum RedPacketPalette {
    static func cover(_ colors: FlareColors, faded: Bool = false) -> LinearGradient {
        LinearGradient(colors: coverStops(colors, faded: faded), startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    /// The card's gradient stops; a spent card's are mixed toward the fade target.
    static func coverStops(_ colors: FlareColors, faded: Bool) -> [Color] {
        let stops = [colors.redPacketStart, colors.redPacketMiddle, colors.redPacketEnd]
        return faded ? stops.map { fade($0, colors) } : stops
    }

    /// `color` moved ``FlareSizes/componentRedPacketFadedMix`` of the way to `redPacketFadedMixTarget`: white in
    /// light mode (the same hue, paler), a red-tinted dark ground in dark mode (the same hue, receding).
    static func fade(_ color: Color, _ colors: FlareColors) -> Color {
        mix(color, colors.redPacketFadedMixTarget, Double(FlareSizes.componentRedPacketFadedMix))
    }

    /// `a` moved `share` of the way towards `b`, per sRGB channel (CSS `color-mix(in srgb …)`).
    static func mix(_ a: Color, _ b: Color, _ share: Double) -> Color {
        let x = rgb(a), y = rgb(b)
        return Color(.sRGB, red: x.r + (y.r - x.r) * share, green: x.g + (y.g - x.g) * share,
                     blue: x.b + (y.b - x.b) * share, opacity: 1)
    }

    /// WCAG relative luminance.
    static func luminance(_ color: Color) -> Double {
        func linear(_ c: Double) -> Double { c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4) }
        let c = rgb(color)
        return 0.2126 * linear(c.r) + 0.7152 * linear(c.g) + 0.0722 * linear(c.b)
    }

    /// WCAG contrast ratio between two colours.
    static func contrast(_ a: Color, _ b: Color) -> Double {
        let (x, y) = (luminance(a), luminance(b))
        return (max(x, y) + 0.05) / (min(x, y) + 0.05)
    }

    /// A colour's sRGB components.
    static func rgb(_ color: Color) -> (r: Double, g: Double, b: Double) {
        #if canImport(UIKit)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)
        return (Double(r), Double(g), Double(b))
        #else
        let c = NSColor(color).usingColorSpace(.sRGB) ?? NSColor.black
        return (Double(c.redComponent), Double(c.greenComponent), Double(c.blueComponent))
        #endif
    }

    static func flap(_ colors: FlareColors) -> LinearGradient {
        LinearGradient(colors: [colors.redPacketStart, colors.redPacketMiddle], startPoint: .top, endPoint: .bottom)
    }

    static func body(_ colors: FlareColors) -> LinearGradient {
        LinearGradient(colors: [colors.redPacketMiddle, colors.redPacketEnd], startPoint: .top, endPoint: .bottom)
    }

    static func coin(_ colors: FlareColors) -> RadialGradient {
        RadialGradient(colors: [colors.redPacketGold, colors.redPacketGoldDeep], center: .center,
                       startRadius: 0, endRadius: FlareSizes.componentRedPacketOpenButtonSize / 2)
    }
}

/// A rectangle whose bottom edge bows downwards: the envelope's flap. The lowest point of the curve is the
/// bottom of the frame, at the middle; the straight sides end `depth` above it.
struct RedPacketFlapShape: Shape {
    let depth: CGFloat

    func path(in rect: CGRect) -> Path {
        let side = rect.maxY - min(depth, rect.height)
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: side))
        // A quadratic curve through (midX, maxY): its control point sits as far below as the sides are above.
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: side),
                          control: CGPoint(x: rect.midX, y: rect.maxY + (rect.maxY - side)))
        path.closeSubpath()
        return path
    }
}

/// The red action of the family ("put money in", "pay"): the large kit button's metrics on the deep red, with
/// white text (above 4.5:1 on it), progress while `loading`, and the whole 48pt box as the target. SwiftUI's kit
/// button has no colour override, so the family draws this one rather than re-tinting ``ButtonView``.
struct RedPacketActionButton: View {
    let label: String
    let loading: Bool
    let disabled: Bool
    let action: (() -> Void)?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        Button { action?() } label: {
            HStack(spacing: FlareSizes.spacingSm) {
                if loading { ProgressView().controlSize(.small).tint(Color.white) }
                Text(label).font(.system(size: FlareSizes.fontSizeXl, weight: .semibold))
            }
            .foregroundColor(Color.white)
            .frame(maxWidth: .infinity, minHeight: FlareSizes.controlHeightLg)
            .padding(.horizontal, FlareSizes.controlPadXLg)
            .background(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).fill(colors.redPacketEnd))
            .contentShape(RoundedRectangle(cornerRadius: FlareSizes.radiusLg))
        }
        .buttonStyle(.plain)
        .disabled(disabled || loading || action == nil)
        .opacity(disabled || action == nil ? FlareOpacity.disabled : 1)
        .accessibilityValue(loading ? strings.packetBusy : "")
    }
}

/// The small gold envelope on a card: body, flap and a red seal, paler on a spent card. Decoration only.
struct RedPacketGlyph: View {
    let width: CGFloat
    var faded = false
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme

    var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let tone: (Color) -> Color = { faded ? RedPacketPalette.fade($0, colors) : $0 }
        let height = width * RedPacketMetrics.glyphAspect
        let corner = width * 0.18
        let flap = height * 0.42
        let seal = width * 0.36
        ZStack(alignment: .top) {
            LinearGradient(colors: [tone(colors.redPacketGold), tone(colors.redPacketGoldDeep)],
                           startPoint: .top, endPoint: .bottom)
            RedPacketFlapShape(depth: flap * 0.3)
                .fill(tone(colors.redPacketGoldDeep))
                .frame(height: flap)
                .shadow(color: colors.redPacketEnd.opacity(faded ? 0.12 : 0.25), radius: 1, y: 1)
            Circle().fill(tone(colors.redPacketEnd))
                .frame(width: seal, height: seal)
                .offset(y: flap - seal / 2)
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: corner))
        .accessibilityHidden(true)
    }
}
