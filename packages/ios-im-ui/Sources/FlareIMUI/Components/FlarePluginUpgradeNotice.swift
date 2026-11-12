import SwiftUI

/// Where an upgrade notice sits: a message card's line, the mark of a "+" or "Me" entry, or a whole page (also the
/// sheet an entry opens).
public enum FlarePluginUpgradeVariant: String, Sendable, CaseIterable { case card, entry, page }

/// Plugin upgrade notice — what a plugin contribution this build cannot draw shows instead (`unavailableReason`
/// `upgrade_required`). Spec: Message/PluginUpgradeNotice (`FlarePluginUpgradeNotice`), `spec/plugin-view-vectors.json`
/// → upgradeNotice; docs/plugin-components.md "Upgrade notice".
///
/// The kit asks nothing: the host reads the engine's `update.plugin_upgrade_status` for the view's `minBuild` and
/// passes the answer as `status`. The update key shows only when that build is offered to this device and the host
/// passes `onUpdate` (which calls `update.open_flow` or opens the platform update UI); with no build for this device
/// yet only the copy shows ("当前版本暂不支持，新版本发布后可用"), so a rollout elsewhere is never revealed.
/// - ``FlarePluginUpgradeVariant/card``: one line ("更新应用后查看") and the update key, under the card's title.
/// - ``FlarePluginUpgradeVariant/entry``: the "需更新" mark after an entry's label; the entry stays listed and opens
///   the page form in a sheet.
/// - ``FlarePluginUpgradeVariant/page``: the kit empty state with `title` (what the page was), the description and the
///   update key.
public struct FlarePluginUpgradeNotice: View {
    private let variant: FlarePluginUpgradeVariant
    private let title: String?
    private let status: PluginUpgradeStatus?
    private let busy: Bool
    private let onUpdate: (() -> Void)?
    @ScaledMetric(relativeTo: .body) private var textScale: CGFloat = 1
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    /// - Parameters:
    ///   - title: What the page was (the placeholder's title); page only.
    ///   - status: `update.plugin_upgrade_status` for the view's `minBuild`; nil while the host has not asked.
    ///   - busy: The update flow is opening: the key spins.
    ///   - onUpdate: Opens the update flow. Without it no key is drawn.
    public init(variant: FlarePluginUpgradeVariant = .card, title: String? = nil, status: PluginUpgradeStatus? = nil,
                busy: Bool = false, onUpdate: (() -> Void)? = nil) {
        self.variant = variant; self.title = title; self.status = status; self.busy = busy; self.onUpdate = onUpdate
    }

    var mode: PluginUpgradeMode { PluginUpgradeMode.of(status, canUpdate: onUpdate != nil) }

    /// The card line: why it cannot be shown, or that no build can show it yet.
    static func cardText(_ mode: PluginUpgradeMode, _ strings: FlareStrings) -> String {
        mode == .notAvailable ? strings.pluginUpgradeNotAvailable : strings.pluginViewUnavailableUpgradeRequired
    }

    /// The page description.
    static func pageText(_ mode: PluginUpgradeMode, _ strings: FlareStrings) -> String {
        mode == .notAvailable ? strings.pluginUpgradeNotAvailable : strings.pluginUpgradeDescription
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        switch variant {
        case .entry:
            PluginBadgeView(badge: PluginBadge(text: strings.pluginUpgradeBadge, tone: .warning))
                .accessibilityIdentifier("plugin.upgrade.entry")
        case .page:
            EmptyStateView(title: title.flatMap { $0.isEmpty ? nil : $0 } ?? strings.pluginUpgradeTitle,
                           description: Self.pageText(mode, strings), icon: "info",
                           actions: mode == .update ? AnyView(updateKey(primary: true)) : nil)
                .accessibilityIdentifier("plugin.upgrade.page")
        case .card:
            FlareFlowLayout(spacing: FlareSizes.spacingSm, lineSpacing: FlareSizes.spacing2xs, trailingLast: mode == .update) {
                Text(Self.cardText(mode, strings))
                    .font(.system(size: FlareSizes.fontSizeSm * textScale))
                    .foregroundColor(colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                if mode == .update { updateKey(primary: false) }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("plugin.upgrade.card")
        }
    }

    private func updateKey(primary: Bool) -> some View {
        ButtonView(label: strings.pluginUpgradeAction, variant: .primary, size: primary ? .md : .sm, loading: busy,
                   disabled: busy, appearance: primary ? .standard : .text, maintainTouchTarget: true) {
            guard !busy, mode == .update else { return }
            onUpdate?()
        }
        .accessibilityIdentifier("plugin.upgrade.action")
    }
}
