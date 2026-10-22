import SwiftUI

/// A red packet's details page body: the red arc header, the sender ("X的红包" with the kind badge), the greeting,
/// and what this viewer may see. Spec: RedPacketDetail (`RedPacketDetailView`).
///
/// Red packet v5 §2: the server trims the details by `viewerRole`, and the page draws exactly what came back
/// (`spec/red-packet-vectors.json` detail, ``FlareRedPacketDetailRules``): the viewer's own amount in large type with
/// "已存入钱包" when `myAmountMinor` is there; a headline for an eligible member who came too late ("手慢了，红包派完了"
/// / "红包已过期") and for a member the packet is not for ("仅 某某 可领取"); the summary band (totals only when the
/// server returned them — to the sender); the claim list only when `claimsListed`; the sender's refund line.
/// Amounts are formatted from minor units with `currencyExponent` by integer arithmetic; best luck is the server's.
///
/// It is a page, not a layer: the host pushes it and wraps it in ``FlareScreen`` (which scrolls).
///
/// With `onBack` the page draws its own red title bar — a light back key and `title` (the kit's
/// ``FlareStrings/packetDetailTitle`` by default) — in one piece with the arc below and reaching up into the top
/// safe area; the host hides its own navigation bar then. Inside a scroll view (which turns the safe area into a
/// content inset) the host lets the scroll view ignore the top safe area and pads the page by it: the red runs up
/// past the page's top to fill it. Without `onBack` the page starts at the arc.
public struct RedPacketDetailView: View {
    private let senderName: String
    private let senderAvatar: String?
    private let details: FlareRedPacketDetailsView
    private let designatedName: String?
    private let claims: [FlareRedPacketClaim]
    private let title: String?
    private let onBack: (() -> Void)?
    private let clock: PluginViewClock
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    /// - Parameters:
    ///   - details: The plugin's details result for this viewer.
    ///   - designatedName: An exclusive packet's designated member, for "仅 某某 可领取".
    ///   - claims: The claim rows (names and avatars from the host's directory); drawn only when
    ///     `details.claimsListed`.
    public init(senderName: String, senderAvatar: String? = nil, details: FlareRedPacketDetailsView,
                designatedName: String? = nil, claims: [FlareRedPacketClaim] = [], title: String? = nil,
                onBack: (() -> Void)? = nil) {
        self.init(senderName: senderName, senderAvatar: senderAvatar, details: details, designatedName: designatedName,
                  claims: claims, title: title, onBack: onBack, clock: .system)
    }

    /// The page at a fixed clock — how the tests pin now and the zone.
    init(senderName: String, senderAvatar: String?, details: FlareRedPacketDetailsView, designatedName: String?,
         claims: [FlareRedPacketClaim], title: String?, onBack: (() -> Void)?, clock: PluginViewClock) {
        self.senderName = senderName; self.senderAvatar = senderAvatar; self.details = details
        self.designatedName = designatedName; self.claims = claims; self.title = title; self.onBack = onBack
        self.clock = clock
    }

    private var presentation: FlareRedPacketDetailPresentation {
        FlareRedPacketDetailRules.presentation(details, designatedName: designatedName, nowMs: clock.now(),
                                               strings: strings, utcOffsetMinutes: clock.utcOffsetMinutes)
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let shown = presentation
        VStack(spacing: 0) {
            top(colors)
            header(colors, shown)
                .padding(.top, FlareSizes.spacing2xl)
                .padding(.horizontal, FlareSizes.spacingLg)
            if let summary = shown.summary {
                Text(summary)
                    .font(.system(size: FlareSizes.fontSizeMd))
                    .foregroundColor(colors.textTertiary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, FlareSizes.spacingLg)
                    .padding(.vertical, FlareSizes.spacingSm)
                    .background(colors.bgSecondary)
                    .padding(.top, FlareSizes.spacing2xl)
            }
            if shown.claims {
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
            }
            if let note = shown.note, !note.isEmpty {
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

    private func header(_ colors: FlareColors, _ shown: FlareRedPacketDetailPresentation) -> some View {
        let badge = FlareRedPacketCardRules.badge(details.kind, strings: strings)
        return VStack(spacing: FlareSizes.spacingSm) {
            HStack(spacing: FlareSizes.spacingSm) {
                AvatarView(userId: senderName, displayName: senderName, avatarURL: senderAvatar,
                           size: FlareSizes.iconSizeXl)
                Text(strings.packetFromSender(senderName))
                    .font(.system(size: FlareSizes.fontSize3xl, weight: .semibold))
                    .foregroundColor(colors.textPrimary)
                    .lineLimit(1)
                if let badge {
                    Text(badge)
                        .font(.system(size: FlareSizes.fontSizeXs, weight: .semibold))
                        .foregroundColor(colors.redPacketGold)
                        .padding(.horizontal, FlareSizes.spacingXs)
                        .padding(.vertical, FlareSizes.spacing3xs)
                        .background(RoundedRectangle(cornerRadius: FlareSizes.radiusXs).fill(colors.redPacketEnd))
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            Text(details.greeting)
                .font(.system(size: FlareSizes.fontSizeLg))
                .foregroundColor(colors.textSecondary)
                .multilineTextAlignment(.center)
            if let headline = shown.headline {
                Text(headline)
                    .font(.system(size: FlareSizes.fontSize2xl, weight: .semibold))
                    .foregroundColor(colors.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.top, FlareSizes.spacingMd)
            }
            if let amount = shown.amount {
                Text(amount)
                    .font(.system(size: FlareSizes.componentRedPacketAmountFontSize, weight: .semibold))
                    .foregroundColor(colors.textPrimary)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .padding(.top, FlareSizes.spacingMd)
                if shown.deposited {
                    Text(strings.packetDeposited)
                        .font(.system(size: FlareSizes.fontSizeMd))
                        .foregroundColor(colors.textTertiary)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func row(_ claim: FlareRedPacketClaim, _ colors: FlareColors) -> some View {
        let shown = FlareRedPacketDetailRules.claimRow(claim, currency: details.currency, exponent: details.currencyExponent,
                                                       nowMs: clock.now(), strings: strings,
                                                       utcOffsetMinutes: clock.utcOffsetMinutes)
        return HStack(spacing: FlareSizes.spacingMd) {
            AvatarView(userId: claim.id, displayName: claim.name, avatarURL: claim.avatar,
                       size: FlareSizes.componentMessageAvatarSize)
            VStack(alignment: .leading, spacing: FlareSizes.spacing3xs) {
                Text(claim.name)
                    .font(.system(size: FlareSizes.fontSizeXl))
                    .foregroundColor(colors.textPrimary)
                    .lineLimit(1)
                Text(shown.time)
                    .font(.system(size: FlareSizes.fontSizeSm))
                    .foregroundColor(colors.textTertiary)
                    .lineLimit(1)
            }
            Spacer(minLength: FlareSizes.spacingSm)
            VStack(alignment: .trailing, spacing: FlareSizes.spacing3xs) {
                Text(shown.amount ?? "")
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
