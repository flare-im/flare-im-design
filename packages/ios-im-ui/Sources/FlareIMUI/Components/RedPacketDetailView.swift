import SwiftUI

/// One claim in a red packet's details. Every field is host-formatted: the kit does no money or time maths.
/// Spec: RedPacketDetail `claims`.
public struct FlareRedPacketClaim: Identifiable, Hashable, Sendable {
    public let id: String
    public let name: String
    public let avatar: String?
    public let time: String
    public let amount: String
    /// The best-luck share of a finished lucky packet.
    public let best: Bool

    public init(id: String, name: String, avatar: String? = nil, time: String, amount: String, best: Bool = false) {
        self.id = id; self.name = name; self.avatar = avatar; self.time = time; self.amount = amount; self.best = best
    }
}

/// A red packet's details page body: the red arc header, the sender ("X's red packet" with the kind tag), the
/// blessing, the viewer's own amount in large type with its note, the summary band and the claim list.
/// Spec: RedPacketDetail (`RedPacketDetailView`).
///
/// It is a page, not a layer: the host pushes it and wraps it in ``FlareScreen`` (which scrolls). The list
/// marks the best-luck claim, says so when no one has claimed yet, and ends with the host's `note` (a refund
/// notice, for instance).
///
/// With `onBack` the page draws its own red title bar — a light back key and `title` (the kit's
/// ``FlareStrings/packetDetailTitle`` by default) — in one piece with the arc below and reaching up into the top
/// safe area; the host hides its own navigation bar then. Inside a scroll view (which turns the safe area into a
/// content inset) the host lets the scroll view ignore the top safe area and pads the page by it: the red runs up
/// past the page's top to fill it. Without `onBack` the page starts at the arc, as before.
public struct RedPacketDetailView: View {
    private let senderName: String
    private let senderAvatar: String?
    private let blessing: String
    private let kindLabel: String?
    private let amount: String?
    private let amountNote: String?
    private let summary: String
    private let claims: [FlareRedPacketClaim]
    private let note: String?
    private let title: String?
    private let onBack: (() -> Void)?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    public init(senderName: String, senderAvatar: String? = nil, blessing: String, kindLabel: String? = nil,
                amount: String? = nil, amountNote: String? = nil, summary: String,
                claims: [FlareRedPacketClaim] = [], note: String? = nil, title: String? = nil,
                onBack: (() -> Void)? = nil) {
        self.senderName = senderName; self.senderAvatar = senderAvatar; self.blessing = blessing
        self.kindLabel = kindLabel; self.amount = amount; self.amountNote = amountNote; self.summary = summary
        self.claims = claims; self.note = note; self.title = title; self.onBack = onBack
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        VStack(spacing: 0) {
            top(colors)
            header(colors)
                .padding(.top, FlareSizes.spacing2xl)
                .padding(.horizontal, FlareSizes.spacingLg)
            Text(summary)
                .font(.system(size: FlareSizes.fontSizeMd))
                .foregroundColor(colors.textTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, FlareSizes.spacingLg)
                .padding(.vertical, FlareSizes.spacingSm)
                .background(colors.bgSecondary)
                .padding(.top, FlareSizes.spacing2xl)
            if claims.isEmpty {
                Text(strings.packetNoClaims)
                    .font(.system(size: FlareSizes.fontSizeLg))
                    .foregroundColor(colors.textTertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, FlareSizes.spacing2xl)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(Array(claims.enumerated()), id: \.element.id) { index, claim in
                        row(claim, colors)
                        if index < claims.count - 1 {
                            Rectangle().fill(colors.borderSecondary).frame(height: RedPacketMetrics.hairline)
                                .padding(.leading, FlareSizes.spacingLg + FlareSizes.componentMessageAvatarSize
                                         + FlareSizes.spacingMd)
                                .accessibilityHidden(true)
                        }
                    }
                }
                .accessibilityElement(children: .contain)
                .accessibilityLabel(strings.packetClaims)
            }
            if let note, !note.isEmpty {
                Text(note)
                    .font(.system(size: FlareSizes.fontSizeSm))
                    .foregroundColor(colors.textTertiary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, FlareSizes.spacingLg)
                    .padding(.vertical, FlareSizes.spacingXl)
            }
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .background(colors.bgPrimary)
    }

    /// The red arc, under the red title bar when the page has a way back. Bar and arc are one shape and one
    /// gradient, so there is no seam between them.
    private func top(_ colors: FlareColors) -> some View {
        VStack(spacing: 0) {
            if let onBack { titleBar(colors, onBack: onBack) }
            Color.clear.frame(height: FlareSizes.componentRedPacketDetailHeaderHeight)
        }
        .frame(maxWidth: .infinity)
        .background(
            RedPacketFlapShape(depth: FlareSizes.componentRedPacketDetailHeaderHeight * 0.4)
                .fill(RedPacketPalette.cover(colors))
                // With its own title bar the page is the top of the screen. A scroll view turns the safe area into
                // a content inset nothing inside can reach past, so the host pads the page by it instead and the
                // red reaches up past the page's top: under the status bar, and into a short pull past the top.
                .padding(.top, onBack == nil ? 0 : -Self.topBleed)
                .ignoresSafeArea(edges: .top)
                .accessibilityHidden(true)
        )
    }

    /// How far the red runs up past the page's top when the page has its own title bar: more than any phone's
    /// status bar.
    static let topBleed: CGFloat = 160

    private func titleBar(_ colors: FlareColors, onBack: @escaping () -> Void) -> some View {
        ZStack {
            Text(title ?? strings.packetDetailTitle)
                .font(.system(size: FlareSizes.fontSize2xl, weight: .semibold))
                .foregroundColor(colors.redPacketOnSurface)
                .lineLimit(1)
                .padding(.horizontal, FlareSizes.touchTarget)
                .accessibilityAddTraits(.isHeader)
            HStack(spacing: 0) {
                Button(action: onBack) {
                    Image(systemName: flareIconSymbol("back"))
                        .font(.system(size: FlareSizes.iconSizeMd, weight: .semibold))
                        .foregroundColor(colors.redPacketOnSurface)
                        .flareTouchTarget()
                }
                .buttonStyle(.plain)
                .flipsForRightToLeftLayoutDirection(true)
                .accessibilityLabel(strings.back)
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, FlareSizes.spacingXs)
        .frame(maxWidth: .infinity, minHeight: FlareSizes.headerHeight)
    }

    private func header(_ colors: FlareColors) -> some View {
        VStack(spacing: FlareSizes.spacingSm) {
            HStack(spacing: FlareSizes.spacingSm) {
                AvatarView(userId: senderName, displayName: senderName, avatarURL: senderAvatar,
                           size: FlareSizes.iconSizeXl)
                Text(strings.packetFromSender(senderName))
                    .font(.system(size: FlareSizes.fontSize3xl, weight: .semibold))
                    .foregroundColor(colors.textPrimary)
                    .lineLimit(1)
                if let kindLabel, !kindLabel.isEmpty {
                    Text(kindLabel)
                        .font(.system(size: FlareSizes.fontSizeXs, weight: .semibold))
                        .foregroundColor(colors.redPacketGold)
                        .padding(.horizontal, FlareSizes.spacingXs)
                        .padding(.vertical, FlareSizes.spacing3xs)
                        .background(RoundedRectangle(cornerRadius: FlareSizes.radiusXs).fill(colors.redPacketEnd))
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            Text(blessing)
                .font(.system(size: FlareSizes.fontSizeLg))
                .foregroundColor(colors.textSecondary)
                .multilineTextAlignment(.center)
            if let amount {
                Text(amount)
                    .font(.system(size: FlareSizes.componentRedPacketAmountFontSize, weight: .semibold))
                    .foregroundColor(colors.textPrimary)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .padding(.top, FlareSizes.spacingMd)
                if let amountNote, !amountNote.isEmpty {
                    Text(amountNote)
                        .font(.system(size: FlareSizes.fontSizeMd))
                        .foregroundColor(colors.textTertiary)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func row(_ claim: FlareRedPacketClaim, _ colors: FlareColors) -> some View {
        HStack(spacing: FlareSizes.spacingMd) {
            AvatarView(userId: claim.id, displayName: claim.name, avatarURL: claim.avatar,
                       size: FlareSizes.componentMessageAvatarSize)
            VStack(alignment: .leading, spacing: FlareSizes.spacing3xs) {
                Text(claim.name)
                    .font(.system(size: FlareSizes.fontSizeXl))
                    .foregroundColor(colors.textPrimary)
                    .lineLimit(1)
                Text(claim.time)
                    .font(.system(size: FlareSizes.fontSizeSm))
                    .foregroundColor(colors.textTertiary)
                    .lineLimit(1)
            }
            Spacer(minLength: FlareSizes.spacingSm)
            VStack(alignment: .trailing, spacing: FlareSizes.spacing3xs) {
                Text(claim.amount)
                    .font(.system(size: FlareSizes.fontSizeXl, weight: .medium))
                    .foregroundColor(colors.textPrimary)
                    .lineLimit(1)
                if claim.best {
                    HStack(spacing: FlareSizes.spacing3xs) {
                        IconView("star", size: FlareSizes.iconSizeSm, color: colors.warningText)
                            .accessibilityHidden(true)
                        Text(strings.packetBestLuck)
                            .font(.system(size: FlareSizes.fontSizeSm))
                            .foregroundColor(colors.warningText)
                    }
                }
            }
        }
        .padding(.horizontal, FlareSizes.spacingLg)
        .padding(.vertical, FlareSizes.spacingMd)
        .frame(minHeight: FlareSizes.touchTarget)
        .accessibilityElement(children: .combine)
    }
}
