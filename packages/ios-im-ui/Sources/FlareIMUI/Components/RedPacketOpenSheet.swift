import SwiftUI

/// What the open-packet layer shows. Spec: RedPacketOpenSheet `state`.
///
/// `ready` offers the gold open button; `opening` flips it while the claim runs and takes no second tap;
/// `finished`, `expired` and `notEligible` say why there is nothing to open — the first two offer the details when
/// the viewer may look (`canViewDetails`), `notEligible` never does; `error` keeps the button for another try.
public enum FlareRedPacketOpenState: String, Sendable, CaseIterable {
    case ready, opening, finished, expired, notEligible, error
}

/// The open-packet layer: a red envelope centred over the scrim, with the sender, the blessing and the gold
/// open button on the flap's edge, and the close button under the envelope. Spec: RedPacketOpenSheet.
///
/// Present it with ``SwiftUI/View/flareRedPacketOpenSheet(isPresented:onDismiss:sheet:)`` (a clear full-screen
/// cover on iOS 16.4+, a system sheet elsewhere) or draw it over the page yourself. The scrim, Escape, the
/// VoiceOver escape gesture and the close button call `onClose`; the host clears the presentation there.
///
/// - Copy: `finished` says the packet ran out, `expired` that it is past its lifetime, `notEligible` that this
///   viewer cannot open it; the host's `message` (for instance "only they can open it") replaces each. Under
///   `error` the message, or the kit's retry copy, shows under the blessing.
/// - Motion: while `opening` the button turns about its vertical axis. With Reduce Motion it does not turn and
///   says the claim is in progress instead.
/// - The host formats names and passes the avatar URL; the layer requests nothing.
/// - Keys per state (`spec/red-packet-vectors.json` openSheet): 開 while ready, opening or error; the details key only
///   for finished / expired with `canViewDetails` (from the personal layer); never for notEligible — the server
///   returns no amount or records to a viewer the packet is not for.
public struct RedPacketOpenSheet: View {
    private let senderName: String
    private let senderAvatar: String?
    private let blessing: String
    private let kindLabel: String?
    private let state: FlareRedPacketOpenState
    private let message: String?
    private let canViewDetails: Bool
    private let onOpen: (() -> Void)?
    private let onViewDetails: (() -> Void)?
    private let onClose: () -> Void
    @Environment(\.flareLayerVisible) private var visible
    @Environment(\.flareLayerChromeless) private var chromeless
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    public init(senderName: String, senderAvatar: String? = nil, blessing: String, kindLabel: String? = nil,
                state: FlareRedPacketOpenState = .ready, message: String? = nil, canViewDetails: Bool = true,
                onOpen: (() -> Void)? = nil, onViewDetails: (() -> Void)? = nil,
                onClose: @escaping () -> Void) {
        self.senderName = senderName; self.senderAvatar = senderAvatar; self.blessing = blessing
        self.kindLabel = kindLabel; self.state = state; self.message = message; self.canViewDetails = canViewDetails
        self.onOpen = onOpen; self.onViewDetails = onViewDetails; self.onClose = onClose
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        GeometryReader { proxy in
            ZStack {
                if !chromeless {
                    FlareOverlayScrim(color: colors.scrim, visible: visible, onTap: onClose)
                }
                if visible {
                    layer(width: Self.envelopeWidth(window: proxy.size.width))
                        .transition(reduceMotion ? .opacity : .scale(scale: 0.9).combined(with: .opacity))
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
        }
    }

    /// The envelope's width: the token, never closer than an extra-large gutter to the window's sides.
    static func envelopeWidth(window: CGFloat) -> CGFloat {
        max(0, min(FlareSizes.componentRedPacketEnvelopeWidth, window - 2 * FlareSizes.spacingXl))
    }

    /// The large line on the flap: the blessing while there is something to open, otherwise why not (the host's
    /// non-empty `message` replaces the kit's copy).
    static func headline(state: FlareRedPacketOpenState, blessing: String, message: String?,
                         strings: FlareStrings) -> String {
        let custom = message.flatMap { $0.isEmpty ? nil : $0 }
        switch state {
        case .ready, .opening, .error: return blessing
        case .finished: return custom ?? strings.packetMissed
        case .expired: return custom ?? strings.packetExpiredNotice
        case .notEligible: return custom ?? strings.packetNotEligible
        }
    }

    /// The small line under it: only a failed claim has one, the host's `message` or the kit's retry copy.
    static func hint(state: FlareRedPacketOpenState, message: String?, strings: FlareStrings) -> String? {
        guard state == .error else { return nil }
        return message.flatMap { $0.isEmpty ? nil : $0 } ?? strings.packetOpenFailed
    }

    /// The space SwiftUI adds between lines for `FlareSizes.lineHeightNormal` (1.5): its own line box is about
    /// `lineHeightTight` (1.2) of the size, so the rest of the token's height goes between the lines.
    static func lineGap(_ size: CGFloat) -> CGFloat {
        size * (FlareSizes.lineHeightNormal - FlareSizes.lineHeightTight)
    }

    /// The open button is there while there is something to open.
    static func showsOpenButton(_ state: FlareRedPacketOpenState) -> Bool { FlareRedPacketOpenRules.showsCoin(state) }

    /// A finished or expired packet leads to the details when the viewer may look; notEligible never does.
    static func showsDetails(_ state: FlareRedPacketOpenState, canViewDetails: Bool = true) -> Bool {
        FlareRedPacketOpenRules.showsDetails(state, canViewDetails: canViewDetails)
    }

    private func layer(width: CGFloat) -> some View {
        VStack(spacing: FlareSizes.spacingXl) {
            envelope(width: width)
            closeButton
        }
        .background(FlareOverlayEscapeKey(escape: .close, perform: onClose))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(strings.packetFromSender(senderName))
        .accessibilityAddTraits(.isModal)
        .accessibilityAction(.escape) { onClose() }
    }

    private func envelope(width: CGFloat) -> some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let minHeight = FlareSizes.componentRedPacketEnvelopeMinHeight
        let flapHeight = minHeight * RedPacketMetrics.flapShare
        let coin = FlareSizes.componentRedPacketOpenButtonSize
        let curve = width * RedPacketMetrics.flapCurve
        let showsCoin = Self.showsOpenButton(state)
        return VStack(spacing: 0) {
            VStack(spacing: FlareSizes.spacingMd) {
                HStack(spacing: FlareSizes.spacingSm) {
                    AvatarView(userId: senderName, displayName: senderName, avatarURL: senderAvatar,
                               size: FlareSizes.iconSizeXl)
                    Text(strings.packetFromSender(senderName))
                        .font(.system(size: FlareSizes.fontSize2xl, weight: .medium))
                        .foregroundColor(colors.redPacketGold)
                        .lineLimit(1)
                }
                if let kindLabel, !kindLabel.isEmpty {
                    Text(kindLabel)
                        .font(.system(size: FlareSizes.fontSizeXs, weight: .medium))
                        .foregroundColor(colors.redPacketEnd)
                        .padding(.horizontal, FlareSizes.spacingSm)
                        .padding(.vertical, FlareSizes.spacing3xs)
                        .background(Capsule().fill(colors.redPacketGold))
                }
                // A long notice (a host's message, a failure) wraps at the kit's body line height, three lines at most.
                Text(Self.headline(state: state, blessing: blessing, message: message, strings: strings))
                    .font(.system(size: FlareSizes.fontSize5xl, weight: .semibold))
                    .foregroundColor(colors.redPacketGold)
                    .multilineTextAlignment(.center)
                    .lineSpacing(Self.lineGap(FlareSizes.fontSize5xl))
                    .lineLimit(3)
                    .truncationMode(.tail)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, FlareSizes.spacingSm)
                if let hint = Self.hint(state: state, message: message, strings: strings) {
                    Text(hint)
                        .font(.system(size: FlareSizes.fontSizeMd))
                        .foregroundColor(colors.redPacketOnSurface.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .lineSpacing(Self.lineGap(FlareSizes.fontSizeMd))
                        .lineLimit(3)
                        .truncationMode(.tail)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(.top, FlareSizes.spacing2xl * 2)
            .padding(.horizontal, FlareSizes.spacingXl)
            .padding(.bottom, (showsCoin ? coin / 2 : curve) + FlareSizes.spacingLg)
            .frame(maxWidth: .infinity, minHeight: flapHeight, alignment: .top)
            .background(
                RedPacketFlapShape(depth: curve)
                    .fill(RedPacketPalette.flap(colors))
                    .shadow(color: Color.black.opacity(0.18), radius: FlareSizes.spacingSm, y: FlareSizes.spacingXs)
            )
            .alignmentGuide(.redPacketFlapEdge) { $0[.bottom] }
            ZStack {
                if Self.showsDetails(state, canViewDetails: canViewDetails), onViewDetails != nil { detailsLink }
            }
            .padding(.top, showsCoin ? coin / 2 : 0)
            .padding(.bottom, FlareSizes.spacingLg)
            .frame(maxWidth: .infinity, minHeight: minHeight - flapHeight, alignment: .bottom)
        }
        // The button straddles both halves, so it is laid over the whole envelope (drawn and hit above both),
        // centred on the flap's edge however tall the flap grows.
        .overlay(alignment: Alignment(horizontal: .center, vertical: .redPacketFlapEdge)) {
            if showsCoin {
                openButton.alignmentGuide(.redPacketFlapEdge) { $0[VerticalAlignment.center] }
            }
        }
        .frame(width: width)
        // Its own height, whatever the window offers.
        .fixedSize(horizontal: false, vertical: true)
        .background(RoundedRectangle(cornerRadius: FlareSizes.radiusXl).fill(RedPacketPalette.body(colors)))
        .clipShape(RoundedRectangle(cornerRadius: FlareSizes.radiusXl))
        // One shadow under the envelope's outline, not one under each line of text.
        .compositingGroup()
        .flareShadow(FlareShadows.of(scheme).xl)
    }

    private var openButton: some View {
        let coin = FlareSizes.componentRedPacketOpenButtonSize
        let opening = state == .opening
        return Button { if !opening { onOpen?() } } label: {
            coinFace(spinning: opening && !reduceMotion, progress: opening && reduceMotion)
                .frame(width: coin, height: coin)
                .contentShape(Circle())
        }
        .buttonStyle(.plain)
        .disabled(opening || onOpen == nil)
        .accessibilityLabel(strings.packetOpenAction)
        .accessibilityValue(opening ? strings.packetBusy : "")
    }

    @ViewBuilder
    private func coinFace(spinning: Bool, progress: Bool) -> some View {
        if spinning {
            // Driven by the clock rather than a repeating animation, so leaving `opening` stops it on its face.
            TimelineView(.animation) { context in
                let period = RedPacketMetrics.flipPeriod
                let turn = context.date.timeIntervalSinceReferenceDate.truncatingRemainder(dividingBy: period) / period
                coinDisc(progress: false)
                    .rotation3DEffect(.degrees(turn * 360), axis: (x: 0, y: 1, z: 0))
            }
        } else {
            coinDisc(progress: progress)
        }
    }

    private func coinDisc(progress: Bool) -> some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let coin = FlareSizes.componentRedPacketOpenButtonSize
        return ZStack {
            Circle().fill(RedPacketPalette.coin(colors))
                .shadow(color: Color.black.opacity(0.22), radius: FlareSizes.spacingXs, y: FlareSizes.spacing3xs)
            Circle().stroke(colors.redPacketGoldDeep, lineWidth: FlareSizes.spacing3xs)
            if progress {
                // Reduce Motion: the claim's progress in words instead of the turning coin.
                Text(strings.packetBusy)
                    .font(.system(size: FlareSizes.fontSizeMd, weight: .semibold))
                    .foregroundColor(colors.redPacketEnd)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .padding(FlareSizes.spacingSm)
            } else {
                Text(strings.packetOpenAction)
                    .font(.system(size: coin * RedPacketMetrics.openGlyphShare, weight: .semibold, design: .serif))
                    .foregroundColor(colors.redPacketEnd)
            }
        }
    }

    private var detailsLink: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        return Button { onViewDetails?() } label: {
            HStack(spacing: FlareSizes.spacingXs) {
                Text(strings.packetViewDetails)
                Image(systemName: flareIconSymbol("chevron-right"))
                    .font(.system(size: FlareSizes.fontSizeSm, weight: .semibold))
                    .accessibilityHidden(true)
            }
            .font(.system(size: FlareSizes.fontSizeLg))
            .foregroundColor(colors.redPacketGold)
            .padding(.horizontal, FlareSizes.spacingMd)
            .flareTouchTarget()
        }
        .buttonStyle(.plain)
    }

    private var closeButton: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        return Button(action: onClose) {
            Image(systemName: flareIconSymbol("close"))
                .font(.system(size: FlareSizes.iconSizeSm, weight: .medium))
                .foregroundColor(colors.redPacketOnSurface)
                .frame(width: FlareSizes.iconSizeXl, height: FlareSizes.iconSizeXl)
                .overlay(Circle().stroke(colors.redPacketOnSurface.opacity(0.85), lineWidth: RedPacketMetrics.ringWidth))
                .flareTouchTarget()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(strings.close)
    }
}

extension VerticalAlignment {
    private enum RedPacketFlapEdge: AlignmentID {
        static func defaultValue(in dimensions: ViewDimensions) -> CGFloat { dimensions[.top] }
    }

    /// The envelope flap's lower edge, where the open button sits.
    static let redPacketFlapEdge = VerticalAlignment(RedPacketFlapEdge.self)
}

public extension View {
    /// Presents a ``RedPacketOpenSheet`` while `isPresented`: over a clear full-screen cover on iOS 16.4+ (the
    /// sheet draws its own scrim and animates the envelope; Reduce Motion shows it at once), a system sheet on
    /// earlier iOS and on macOS. The sheet's `onClose` should set `isPresented` to false; `onDismiss` runs once
    /// it is gone. ``FlareFeedback`` toasts show above it.
    func flareRedPacketOpenSheet(isPresented: Binding<Bool>, onDismiss: (() -> Void)? = nil,
                                 sheet: @escaping () -> RedPacketOpenSheet) -> some View {
        modifier(FlareRedPacketOpenPresenter(isPresented: isPresented, onDismiss: onDismiss, sheet: sheet))
    }
}

struct FlareRedPacketOpenPresenter: ViewModifier {
    @Binding var isPresented: Bool
    let onDismiss: (() -> Void)?
    let sheet: () -> RedPacketOpenSheet
    @State private var presence = UUID()

    func body(content: Content) -> some View {
        content.modifier(FlareLayerPresenter(
            isPresented: $isPresented, presence: presence, coverKind: .modal, registers: true,
            dismissible: true, compact: nil, allowsPush: false,
            resolve: { _ in .cover }, onDismiss: onDismiss,
            sheetLayer: { EmptyView() },
            coverLayer: { sheet() },
            pushLayer: { EmptyView() }
        ))
    }
}
