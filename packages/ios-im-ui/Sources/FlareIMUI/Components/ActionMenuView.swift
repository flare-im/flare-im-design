import SwiftUI

/// One entry of an ``ActionMenuView``, in the kit's action vocabulary — the fields
/// ``ConversationHeaderAction`` uses — so a header action and a menu entry are described the same way.
public struct FlareActionItem: Identifiable, Hashable, Sendable {
    /// Reported through the menu's `onSelect` when the item is chosen.
    public let id: String
    public let label: String
    /// Semantic kit icon name (one of ``flareIconNames``, or an action alias: `audioCall`, `videoCall`,
    /// `addMember`, `details`), drawn as its SF Symbol.
    public let icon: String?
    /// Items of one group sit in one section of the menu (see ``ActionMenuView`` for the rule).
    public let group: String?
    /// False leaves the item out of the menu entirely.
    public let visible: Bool
    /// False keeps the item visible but dimmed: announced as disabled, it never reports.
    public let enabled: Bool
    /// Compact text after the label (a count, a shortcut).
    public let badge: String?
    /// The item's name for assistive technology, in place of its label.
    public let accessibilityLabel: String?
    /// Why the item is disabled: its second line while `enabled` is false.
    public let disabledReason: String?
    /// Non-nil makes the item checkable: a check while true, exposed as the selected state.
    public let pressed: Bool?
    /// A destructive item: label and icon in the error colour.
    public let danger: Bool

    public init(
        id: String,
        label: String,
        icon: String? = nil,
        group: String? = nil,
        visible: Bool = true,
        enabled: Bool = true,
        badge: String? = nil,
        accessibilityLabel: String? = nil,
        disabledReason: String? = nil,
        pressed: Bool? = nil,
        danger: Bool = false
    ) {
        self.id = id; self.label = label; self.icon = icon; self.group = group
        self.visible = visible; self.enabled = enabled; self.badge = badge
        self.accessibilityLabel = accessibilityLabel; self.disabledReason = disabledReason
        self.pressed = pressed; self.danger = danger
    }
}

/// A menu of host actions opened from `label`. Spec: ActionMenu (`ActionMenuView`).
///
/// Drawn by the kit rather than on the system pull-down `Menu`: UIKit gives its menu a ~250pt
/// minimum width, so three two-character actions filled well over half a phone screen, and no
/// amount of styling on this side could narrow it. The other three kits draw their own and size
/// it to the content, so this one was the odd one out on every screen that has a "+".
/// Width is the content's, clamped to [``ActionMenuRules/minWidth``, ``ActionMenuRules/maxWidth``]
/// — the same numbers the Android/Flutter/Vue menus use.
///
/// The rules every platform shares:
/// - Host order is kept, also when the menu opens upward.
/// - A new section starts before an item whose `group` is set and differs from the last group
///   seen; an item without a group stays in the current section. Put destructive items in their
///   own group.
/// - Choosing an enabled item closes the menu, then reports its id through `onSelect`. A disabled
///   item stays visible with its `disabledReason` as the second line, is announced as disabled and
///   never reports.
/// - A `pressed` item is checkable: a check while true, which VoiceOver reads as selected.
/// - A `danger` item is destructive (label and icon in the error colour).
/// - `accessibilityLabel` names the menu. Invisible items are left out, and a menu with no visible
///   item never opens: only `label` is drawn.
public struct ActionMenuView<Label: View>: View {
    private let items: [FlareActionItem]
    private let accessibilityLabel: String
    private let onSelect: (String) -> Void
    private let label: Label

    public init(items: [FlareActionItem], accessibilityLabel: String, onSelect: @escaping (String) -> Void,
                @ViewBuilder label: () -> Label) {
        self.items = items; self.accessibilityLabel = accessibilityLabel
        self.onSelect = onSelect; self.label = label()
    }

    @State private var open = false
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme

    public var body: some View {
        let sections = ActionMenuRules.sections(items)
        if sections.isEmpty {
            label.accessibilityLabel(accessibilityLabel)
        } else {
            Button { open = true } label: { label }
                .buttonStyle(.plain)
                .accessibilityLabel(accessibilityLabel)
                .accessibilityAddTraits(.isButton)
                .flareActionMenuPopover(isPresented: $open) { sheet(sections) }
        }
    }

    /// The drawn menu surface. Internal so the tests can inspect the rows without presenting it.
    func sheet(_ sections: [[FlareActionItem]]) -> some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        return VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(sections.enumerated()), id: \.offset) { index, section in
                if index > 0 {
                    Rectangle().fill(colors.borderSecondary).frame(height: 1)
                }
                ForEach(section) { item in row(item, colors) }
            }
        }
        // Content width, clamped — the host's labels decide, within the kit's bounds.
        .frame(minWidth: ActionMenuRules.minWidth, maxWidth: ActionMenuRules.maxWidth, alignment: .leading)
        .fixedSize(horizontal: true, vertical: false)
        .background(
            RoundedRectangle(cornerRadius: FlareSizes.radiusLg)
                .fill(colors.bgElevated)
                .overlay(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).stroke(colors.borderSecondary, lineWidth: 1))
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityLabel)
    }

    @ViewBuilder
    func row(_ item: FlareActionItem, _ colors: FlareColors) -> some View {
        let tint = item.danger ? colors.error : (item.enabled ? colors.textPrimary : colors.textDisabled)
        let button = Button {
            // Close first, then report: a host that pushes a screen on select should not race the
            // dismissal, and a disabled item never reports at all.
            open = false
            onSelect(item.id)
        } label: {
            HStack(spacing: FlareSizes.spacingSm) {
                if let symbol = ActionMenuRules.symbol(item) {
                    // 装饰性:紧挨着的就是同义文字,读屏再念一遍图标名是噪音。
                    Image(systemName: symbol).font(.system(size: FlareSizes.fontSize4xl)).foregroundColor(tint)
                        .accessibilityHidden(true)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(ActionMenuRules.title(item))
                        .font(.system(size: FlareSizes.fontSize2xl))
                        .foregroundColor(tint)
                        .lineLimit(1)
                    if let secondLine = ActionMenuRules.secondLine(item) {
                        Text(secondLine)
                            .font(.system(size: FlareSizes.fontSizeSm))
                            .foregroundColor(colors.textTertiary)
                            .lineLimit(2)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, FlareSizes.spacingMd)
            .frame(minHeight: FlareSizes.touchTarget)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!item.enabled)
        .accessibilityAddTraits(ActionMenuRules.traits(item))
        if let name = item.accessibilityLabel {
            button.accessibilityLabel(name)
        } else {
            button
        }
    }
}

private extension View {
    /// The menu anchored to its trigger. `.popover` gives the anchoring, the outside-tap dismissal
    /// and the focus handling; the kit draws the surface inside it, so the card matches the other
    /// three platforms instead of being the system's. Below iOS 16.4 the popover adapts to a sheet
    /// — still the right actions, just presented the way that OS presents them.
    @ViewBuilder
    func flareActionMenuPopover<C: View>(isPresented: Binding<Bool>,
                                        @ViewBuilder content: @escaping () -> C) -> some View {
        if #available(iOS 16.4, macOS 13.3, *) {
            popover(isPresented: isPresented, attachmentAnchor: .rect(.bounds), arrowEdge: .top) {
                content()
                    .presentationCompactAdaptation(.popover)
                    .presentationBackground(.clear)
            }
        } else {
            popover(isPresented: isPresented, attachmentAnchor: .rect(.bounds), arrowEdge: .top) {
                content()
            }
        }
    }
}

/// ``ActionMenuView``'s pure rules, shared by the view and its tests.
enum ActionMenuRules {
    /// The visible items in host order, split into sections: a new section starts before an item
    /// whose group is set and differs from the last group seen. Empty when nothing is visible.
    static func sections(_ items: [FlareActionItem]) -> [[FlareActionItem]] {
        var sections: [[FlareActionItem]] = []
        var lastGroup: String?
        for item in items where item.visible {
            if sections.isEmpty || (item.group != nil && item.group != lastGroup) {
                sections.append([item])
            } else {
                sections[sections.count - 1].append(item)
            }
            if let group = item.group { lastGroup = group }
        }
        return sections
    }

    /// The row's title: the label, then the badge as compact trailing text.
    static func title(_ item: FlareActionItem) -> String {
        guard let badge = item.badge, !badge.isEmpty else { return item.label }
        return "\(item.label)  \(badge)"
    }

    /// The row's second line: why a disabled item is disabled.
    static func secondLine(_ item: FlareActionItem) -> String? {
        guard !item.enabled, let reason = item.disabledReason, !reason.isEmpty else { return nil }
        return reason
    }

    /// The symbol beside the title: the check while pressed, otherwise the item's icon (an action
    /// alias such as `videoCall` resolves as the header's buttons resolve it).
    static func symbol(_ item: FlareActionItem) -> String? {
        if item.pressed == true { return flareIconSymbol("check") }
        return item.icon.map(flareActionSymbol)
    }

    /// A pressed item is selected for assistive technology; any other item adds nothing.
    static func traits(_ item: FlareActionItem) -> AccessibilityTraits {
        item.pressed == true ? .isSelected : []
    }

    /// The menu's width bounds. The same numbers on all four kits: the content decides the width,
    /// these only stop it being a sliver or a page.
    static let minWidth: CGFloat = 112
    static let maxWidth: CGFloat = 280
}
