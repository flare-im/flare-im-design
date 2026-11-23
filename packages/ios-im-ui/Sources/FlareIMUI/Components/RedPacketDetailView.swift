import SwiftUI

/// A red packet's details page body: the red arch (``RedPacketArchView``), the sender ("X的红包" with the kind badge), the greeting,
/// and what this viewer may see. Spec: RedPacketDetail (`RedPacketDetailView`).
///
/// Red packet v5 §2: the server trims the details by `viewerRole`, and the page draws exactly what came back
/// (`spec/red-packet-vectors.json` detail, ``FlareRedPacketDetailRules``): the viewer's own amount in large type with
/// "已存入钱包" (a way to the wallet with `onDeposited`) when `myAmountMinor` is there; a headline for an eligible member who came too late ("手慢了，红包派完了"
/// / "红包已过期") and for a member the packet is not for ("仅 某某 可领取"); the summary band (totals only when the
/// server returned them — to the sender); the claim list only when `claimsListed`; the sender's refund line.
/// Amounts are formatted from minor units with `currencyExponent` by integer arithmetic; best luck is the server's.
///
/// It is a page, not a layer: the host pushes it and wraps it in ``FlareScreen`` (which scrolls).
///
/// With `onBack` the page draws the kit's neutral page header — back and `title` (the kit's
/// ``FlareStrings/packetDetailTitle`` by default) — above the arch; the host hides its own navigation bar then.
/// Without `onBack` the page starts at the arch. On a wide window (iPad, Mac) the content is a centred column
/// ``FlareSizes/detailPaneMaxWidth`` wide, the arch included.
public struct RedPacketDetailView: View {
    private let senderName: String
    private let senderAvatar: String?
    private let details: FlareRedPacketDetailsView
    private let designatedName: String?
    private let claims: [FlareRedPacketClaim]
    private let title: String?
    private let onBack: (() -> Void)?
    private let onDeposited: (() -> Void)?
    private let clock: PluginViewClock
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    /// - Parameters:
    ///   - details: The plugin's details result for this viewer.
    ///   - designatedName: An exclusive packet's designated member, for "仅 某某 可领取".
    ///   - claims: The claim rows (names and avatars from the host's directory); drawn only when
    ///     `details.claimsListed`.
    ///   - onDeposited: Makes the "saved to your wallet" line a way to the wallet.
    ///   - nowMs: The moment times are written against ("today" shows the time alone); the server clock when nil.
    public init(senderName: String, senderAvatar: String? = nil, details: FlareRedPacketDetailsView,
                designatedName: String? = nil, claims: [FlareRedPacketClaim] = [], title: String? = nil,
                onBack: (() -> Void)? = nil, onDeposited: (() -> Void)? = nil, nowMs: Int64? = nil) {
        self.init(senderName: senderName, senderAvatar: senderAvatar, details: details, designatedName: designatedName,
                  claims: claims, title: title, onBack: onBack, onDeposited: onDeposited,
                  clock: PluginViewClock(nowMs: nowMs, utcOffsetMinutes: nil))
    }

    /// The page at a fixed clock — how the tests pin now and the zone.
    init(senderName: String, senderAvatar: String?, details: FlareRedPacketDetailsView, designatedName: String?,
         claims: [FlareRedPacketClaim], title: String?, onBack: (() -> Void)?, onDeposited: (() -> Void)? = nil,
         clock: PluginViewClock) {
        self.senderName = senderName; self.senderAvatar = senderAvatar; self.details = details
        self.designatedName = designatedName; self.claims = claims; self.title = title; self.onBack = onBack
        self.onDeposited = onDeposited; self.clock = clock
    }

    private var presentation: FlareRedPacketDetailPresentation {
        FlareRedPacketDetailRules.presentation(details, designatedName: designatedName, nowMs: clock.now(),
                                               strings: strings, utcOffsetMinutes: clock.utcOffsetMinutes)
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let shown = presentation
        VStack(spacing: 0) {
            if let onBack {
                ScreenHeaderView(title: title ?? strings.packetDetailTitle, leading: {
                    IconButtonView(icon: "back", accessibilityLabel: strings.back, action: onBack)
                })
            }
            column(colors, shown)
                .frame(maxWidth: FlareSizes.detailPaneMaxWidth)
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .background(colors.bgPrimary)
    }

    /// The arch and everything under it: one column, as wide as the details pane at most.
    private func column(_ colors: FlareColors, _ shown: FlareRedPacketDetailPresentation) -> some View {
        VStack(spacing: 0) {
            RedPacketArchView()
            header(colors, shown)
                .padding(.top, FlareSizes.spacing2xl)
                .padding(.horizontal, FlareSizes.spacingLg)
            if let summary = shown.summary {
                Text(summary)
                    .font(.system(size: FlareSizes.fontSizeMd))
                    .foregroundColor(colors.textSecondary)
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
    }

    private func header(_ colors: FlareColors, _ shown: FlareRedPacketDetailPresentation) -> some View {
        let badge = FlareRedPacketCardRules.badge(details.kind, strings: strings)
        return VStack(spacing: FlareSizes.spacingSm) {
            AvatarView(userId: senderName, displayName: senderName, avatarURL: senderAvatar,
                       size: FlareSizes.componentRedPacketDetailAvatarSize)
                .accessibilityHidden(true)
            HStack(spacing: FlareSizes.spacingSm) {
                Text(strings.packetFromSender(senderName))
                    .font(.system(size: FlareSizes.fontSize3xl, weight: .semibold))
                    .foregroundColor(colors.textPrimary)
                    .lineLimit(1)
                if let badge {
                    // The kind reads as a quiet tag beside the title (Vue `__kind`, Compose): the red is the arch's.
                    Text(badge)
                        .font(.system(size: FlareSizes.fontSizeXs, weight: .semibold))
                        .foregroundColor(colors.textSecondary)
                        .padding(.horizontal, FlareSizes.spacingXs)
                        .frame(minWidth: FlareSizes.iconSizeMd, minHeight: FlareSizes.iconSizeMd)
                        .background(RoundedRectangle(cornerRadius: FlareSizes.radiusXs).fill(colors.bgSecondary))
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
                    .font(.system(size: FlareSizes.componentRedPacketDetailAmountFontSize, weight: .semibold)
                        .monospacedDigit())
                    .foregroundColor(colors.textPrimary)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .padding(.top, FlareSizes.spacingMd)
                if shown.deposited { deposited(colors) }
            }
        }
        .frame(maxWidth: .infinity)
    }

    /// "已存入钱包" after the success mark; with `onDeposited` a way to the wallet ("›").
    @ViewBuilder private func deposited(_ colors: FlareColors) -> some View {
        let line = HStack(spacing: FlareSizes.spacingXs) {
            IconView("success", size: FlareSizes.iconSizeSm, color: colors.successText)
            Text(strings.packetDeposited)
                .font(.system(size: FlareSizes.fontSizeMd))
                .foregroundColor(colors.textSecondary)
            if onDeposited != nil {
                IconView("chevron-right", size: FlareSizes.fontSizeSm, color: colors.textTertiary)
            }
        }
        if let onDeposited {
            Button(action: onDeposited) { line.flareTouchTarget() }
                .buttonStyle(FlareButtonFeedbackStyle())
        } else {
            line
        }
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
                    .font(.system(size: FlareSizes.fontSize2xl, weight: .semibold).monospacedDigit())
                    .foregroundColor(colors.textPrimary)
                    .lineLimit(1)
                if claim.best {
                    HStack(spacing: FlareSizes.spacing3xs) {
                        // §4.6: the star 12, as tall as its label.
                        IconView("star", size: FlareSizes.fontSizeSm, color: colors.warningText)
                            .accessibilityHidden(true)
                        Text(strings.packetBestLuck)
                            .font(.system(size: FlareSizes.fontSizeSm))
                            .foregroundColor(colors.warningText)
                    }
                }
            }
        }
        .padding(.horizontal, FlareSizes.spacingLg)
        .frame(minHeight: FlareSizes.componentRedPacketClaimRowHeight)
        .accessibilityElement(children: .combine)
    }
}
