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

/// A menu of host actions opened from `label`, on the system pull-down `Menu` (the native idiom
/// on iPhone and iPad). Spec: ActionMenu (`ActionMenuView`).
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

    public var body: some View {
        let sections = ActionMenuRules.sections(items)
        if sections.isEmpty {
            label.accessibilityLabel(accessibilityLabel)
        } else {
            Menu {
                ForEach(Array(sections.enumerated()), id: \.offset) { _, section in
                    Section {
                        ForEach(section) { item in row(item) }
                    }
                }
            } label: {
                label
            }
            // The system reverses a menu that opens upward; the host's order is the order.
            .menuOrder(.fixed)
            .help(accessibilityLabel)
            .accessibilityLabel(accessibilityLabel)
        }
    }

    @ViewBuilder
    private func row(_ item: FlareActionItem) -> some View {
        let button = Button(role: item.danger ? .destructive : nil) {
            onSelect(item.id)
        } label: {
            rowLabel(item)
        }
        .disabled(!item.enabled)
        .accessibilityAddTraits(ActionMenuRules.traits(item))
        if let name = item.accessibilityLabel {
            button.accessibilityLabel(name)
        } else {
            button
        }
    }

    /// The title (with the badge) and symbol, then the second line — the parts a system menu row
    /// shows. The second line must follow the title as a sibling `Text`: inside the `Label`'s title
    /// the system menu drops it.
    @ViewBuilder
    private func rowLabel(_ item: FlareActionItem) -> some View {
        let title = ActionMenuRules.title(item)
        if let symbol = ActionMenuRules.symbol(item) {
            SwiftUI.Label(title, systemImage: symbol)
        } else {
            Text(title)
        }
        if let secondLine = ActionMenuRules.secondLine(item) {
            Text(secondLine)
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
}
