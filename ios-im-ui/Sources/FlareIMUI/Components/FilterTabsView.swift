import SwiftUI

/// One option in a `FilterTabsView`.
public struct FlareFilterTabOption: Identifiable, Sendable {
    public let value: String
    public let label: String
    public let badge: Int?
    /// Optional leading SF Symbol name.
    public let systemImage: String?

    public var id: String { value }

    public init(value: String, label: String, badge: Int? = nil, systemImage: String? = nil) {
        self.value = value; self.label = label; self.badge = badge; self.systemImage = systemImage
    }
}

/// Horizontal, scrollable filter tablist. Spec: General/FilterTabs (`FilterTabsView`).
/// A row of pill buttons; the selected pill is surfaced in the brand `primary` tint.
public struct FilterTabsView: View {
    private let options: [FlareFilterTabOption]
    @Binding private var selection: String
    private let onChange: ((String) -> Void)?
    @Environment(\.colorScheme) private var scheme

    public init(options: [FlareFilterTabOption], selection: Binding<String>,
                onChange: ((String) -> Void)? = nil) {
        self.options = options; self._selection = selection; self.onChange = onChange
    }

    public var body: some View {
        let colors = FlareColors.of(scheme)
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: FlareSizes.spacingXs + 2) {
                ForEach(options) { option in
                    let active = selection == option.value
                    Button {
                        selection = option.value
                        onChange?(option.value)
                    } label: {
                        HStack(spacing: FlareSizes.spacingXs + 2) {
                            if let systemImage = option.systemImage {
                                Image(systemName: systemImage).font(.system(size: FlareSizes.fontSizeMd))
                            }
                            Text(option.label)
                                .font(.system(size: FlareSizes.fontSizeMd, weight: active ? .semibold : .medium))
                            if let badge = option.badge, badge > 0 {
                                Text("\(badge)")
                                    .font(.system(size: FlareSizes.fontSizeXs, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 5)
                                    .frame(minWidth: 16, minHeight: 16)
                                    .background(Capsule().fill(colors.primary))
                            }
                        }
                        .foregroundColor(active ? colors.primary : colors.textSecondary)
                        .padding(.horizontal, FlareSizes.spacingMd + 2)
                        .padding(.vertical, FlareSizes.spacingXs + 2)
                        .background(
                            Capsule().fill(active ? colors.primary.opacity(0.12) : colors.bgSecondary)
                        )
                        .overlay(
                            Capsule().stroke(active ? colors.primary.opacity(0.26) : Color.clear, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(2)
        }
        .animation(.easeOut(duration: 0.15), value: selection)
    }
}
