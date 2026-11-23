import SwiftUI

/// One option in a `FilterTabsView`.
/// `badge` is drawn when it is above 0 or `badgeMore` says there are more than it (the server had more than it counted),
/// and reads 99+ above 99 or with `badgeMore` (`spec/count-badge-vectors.json`).
public struct FlareFilterTabOption: Identifiable, Sendable {
    public let value: String
    public let label: String
    public let badge: Int?
    public let badgeMore: Bool
    /// Optional leading SF Symbol name.
    /// Semantic kit icon name (``flareIconNames``) before the label; nil draws none.
    public let icon: String?

    public var id: String { value }

    public init(value: String, label: String, badge: Int? = nil, badgeMore: Bool = false, icon: String? = nil) {
        self.value = value; self.label = label; self.badge = badge; self.badgeMore = badgeMore; self.icon = icon
    }
}

/// Horizontal, scrollable filter tablist. Spec: General/FilterTabs (`FilterTabsView`).
/// A row of pill buttons; the selected pill is surfaced in the brand `primary` tint. Each pill keeps the size it is
/// drawn at and sits centred in a cell at least `FlareSizes.touchTarget` square, which takes the taps.
/// `enabled` false (what the tabs filter is loading) dims the row and disables every tab.
/// `appearance: .quiet` draws the tabs as words with an underline under the selected one instead of pills — the
/// Vue kit's `FlareFilterTabs appearance="quiet"`, for a filter row under a page title (the conversation list's
/// 全部 / 未读 / @我), where a row of pills would read as a second set of buttons.
public struct FilterTabsView: View {
    public enum Appearance: Sendable { case pill, quiet }
    private let options: [FlareFilterTabOption]
    @Binding private var selection: String
    private let enabled: Bool
    private let onChange: ((String) -> Void)?
    private let appearance: Appearance
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme

    public init(options: [FlareFilterTabOption], selection: Binding<String>, enabled: Bool = true,
                appearance: Appearance = .pill, onChange: ((String) -> Void)? = nil) {
        self.options = options; self._selection = selection; self.enabled = enabled; self.onChange = onChange
        self.appearance = appearance
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: appearance == .quiet ? 0 : FlareSizes.spacingXs + 2) {
                ForEach(options) { option in
                    let active = selection == option.value
                    Button {
                        selection = option.value
                        onChange?(option.value)
                    } label: {
                        HStack(spacing: FlareSizes.spacingXs + 2) {
                            if let icon = option.icon {
                                Image(systemName: flareIconSymbol(icon)).font(.system(size: FlareSizes.fontSizeMd))
                            }
                            Text(option.label)
                                .font(.system(size: FlareSizes.fontSizeMd, weight: active ? .semibold : .medium))
                            if flareCountBadgeDrawn(count: option.badge, more: option.badgeMore) {
                                if appearance == .quiet {
                                    // Quiet: the count is a note, not an alarm — plain text in the tab's own colour.
                                    Text(flareCountBadgeText(count: option.badge, more: option.badgeMore))
                                        .font(.system(size: FlareSizes.fontSizeMd))
                                        .opacity(0.7)
                                } else {
                                    Text(flareCountBadgeText(count: option.badge, more: option.badgeMore))
                                        .font(.system(size: FlareSizes.fontSizeXs, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 5)
                                        .frame(minWidth: 16, minHeight: 16)
                                        .background(Capsule().fill(colors.primary))
                                }
                            }
                        }
                        .foregroundColor(active ? colors.primaryText : colors.textSecondary)
                        .padding(.horizontal, appearance == .quiet ? FlareSizes.spacingSm : FlareSizes.spacingMd + 2)
                        .padding(.vertical, appearance == .quiet ? FlareSizes.spacingSm : FlareSizes.spacingXs + 2)
                        .background(
                            Capsule().fill(appearance == .quiet ? Color.clear
                                           : active ? colors.primary.opacity(0.12) : colors.bgSecondary)
                        )
                        .overlay(
                            Capsule().stroke(appearance == .pill && active ? colors.primary.opacity(0.26) : Color.clear,
                                             lineWidth: 1)
                        )
                        .overlay(alignment: .bottom) {
                            if appearance == .quiet && active {
                                Capsule().fill(colors.primary).frame(height: 2).padding(.horizontal, FlareSizes.spacingSm)
                            }
                        }
                        .frame(minWidth: FlareSizes.touchTarget, minHeight: FlareSizes.touchTarget)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(!enabled)
                    .accessibilityAddTraits(active ? .isSelected : [])
                }
            }
            .padding(appearance == .quiet ? 0 : 2)
        }
        // Quiet: one hairline under the whole row (Vue `border-block-end`).
        .overlay(alignment: .bottom) {
            if appearance == .quiet { Rectangle().fill(colors.borderSecondary).frame(height: 1) }
        }
        .opacity(enabled ? 1 : FlareOpacity.disabled)
        .animation(.easeOut(duration: 0.15), value: selection)
    }
}
