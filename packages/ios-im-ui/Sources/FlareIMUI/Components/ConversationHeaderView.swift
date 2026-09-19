import SwiftUI

public enum ConversationHeaderKind: String, Sendable { case direct, group, channel, bot, system }
public enum ConversationHeaderActionPlacement: String, Sendable { case primary, add, overflow }

public struct ConversationIdentity: Sendable {
    public let id: String
    public let title: String
    public let kind: ConversationHeaderKind
    public let subtitle: String?
    public let avatarURL: String?
    public let presence: FlarePresence?
    public let memberCount: Int?
    public let typingText: String?
    public let accessibilityLabel: String?
    /// Makes the whole identity block (avatar, title, subtitle or typing text) one button that
    /// dispatches this action through `onAction` — e.g. open the conversation's details.
    public let action: ConversationHeaderAction?

    public init(
        id: String,
        title: String,
        kind: ConversationHeaderKind = .direct,
        subtitle: String? = nil,
        avatarURL: String? = nil,
        presence: FlarePresence? = nil,
        memberCount: Int? = nil,
        typingText: String? = nil,
        accessibilityLabel: String? = nil,
        action: ConversationHeaderAction? = nil
    ) {
        self.id = id; self.title = title; self.kind = kind; self.subtitle = subtitle
        self.avatarURL = avatarURL; self.presence = presence; self.memberCount = memberCount
        self.typingText = typingText; self.accessibilityLabel = accessibilityLabel
        self.action = action
    }
}

public struct ConversationHeaderAction: Identifiable, Sendable {
    public let id: String
    public let label: String
    /// Semantic kit icon name (one of ``flareIconNames``), drawn as its SF Symbol. Without one the
    /// action draws its id: `audioCall` → `phone`, `videoCall` → `video`, `addMember` → `person-add`,
    /// `details` → `info`, or a kit icon name used as the id.
    public let icon: String?
    public let placement: ConversationHeaderActionPlacement
    public let group: String?
    public let order: Int?
    public let visible: Bool
    public let enabled: Bool
    public let badge: String?
    public let intent: String?
    public let capability: String?
    public let accessibilityLabel: String?
    public let disabledReason: String?
    /// Non-nil makes the action a toggle in this state: selected look and the selected trait
    /// when true. Nil is a plain action.
    public let pressed: Bool?

    public init(
        id: String,
        label: String,
        icon: String? = nil,
        placement: ConversationHeaderActionPlacement = .primary,
        group: String? = nil,
        order: Int? = nil,
        visible: Bool = true,
        enabled: Bool = true,
        badge: String? = nil,
        intent: String? = nil,
        capability: String? = nil,
        accessibilityLabel: String? = nil,
        disabledReason: String? = nil,
        pressed: Bool? = nil
    ) {
        self.id = id; self.label = label; self.icon = icon; self.placement = placement
        self.group = group; self.order = order; self.visible = visible; self.enabled = enabled
        self.badge = badge; self.intent = intent; self.capability = capability
        self.accessibilityLabel = accessibilityLabel; self.disabledReason = disabledReason
        self.pressed = pressed
    }
}

public struct ConversationHeaderCapabilities: Sendable {
    public let availableActionIds: Set<String>?
    public init(availableActionIds: Set<String>? = nil) { self.availableActionIds = availableActionIds }
}

public struct ConversationHeaderConfiguration: Sendable {
    public let replaceDefaults: Bool
    public let removeActionIds: Set<String>
    public let actionOverrides: [ConversationHeaderAction]
    public let maxPrimaryActions: Int
    public let compactMaxPrimaryActions: Int

    public init(
        replaceDefaults: Bool = false,
        removeActionIds: Set<String> = [],
        actionOverrides: [ConversationHeaderAction] = [],
        maxPrimaryActions: Int = 3,
        compactMaxPrimaryActions: Int = 1
    ) {
        self.replaceDefaults = replaceDefaults; self.removeActionIds = removeActionIds
        self.actionOverrides = actionOverrides; self.maxPrimaryActions = maxPrimaryActions
        self.compactMaxPrimaryActions = compactMaxPrimaryActions
    }
}

public let DefaultDirectConversationHeaderConfig = ConversationHeaderConfiguration()
public let DefaultGroupConversationHeaderConfig = ConversationHeaderConfiguration()

private let directConversationHeaderActions = [
    ConversationHeaderAction(id: "search", label: "Search messages", icon: "search", order: 10),
    ConversationHeaderAction(id: "audioCall", label: "Start audio call", icon: "phone", order: 20, capability: "audioCall"),
    ConversationHeaderAction(id: "videoCall", label: "Start video call", icon: "video", order: 30, capability: "videoCall"),
    ConversationHeaderAction(id: "share", label: "Share contact", icon: "share", placement: .add, order: 40),
    ConversationHeaderAction(id: "details", label: "Conversation details", icon: "info", placement: .overflow, order: 90),
]

private let groupConversationHeaderActions = [
    ConversationHeaderAction(id: "search", label: "Search messages", icon: "search", order: 10),
    ConversationHeaderAction(id: "audioCall", label: "Start audio call", icon: "phone", order: 20, capability: "audioCall"),
    ConversationHeaderAction(id: "videoCall", label: "Start video call", icon: "video", order: 30, capability: "videoCall"),
    ConversationHeaderAction(id: "addMember", label: "Add member", icon: "person-add", placement: .add, order: 40),
    ConversationHeaderAction(id: "share", label: "Share conversation", icon: "share", placement: .add, order: 50),
    ConversationHeaderAction(id: "details", label: "Conversation details", icon: "info", placement: .overflow, order: 90),
]

public func resolveConversationHeaderActions(
    identity: ConversationIdentity,
    capabilities: ConversationHeaderCapabilities? = nil,
    configuration: ConversationHeaderConfiguration = ConversationHeaderConfiguration(),
    actions: [ConversationHeaderAction] = []
) -> [ConversationHeaderAction] {
    let defaults = identity.kind == .group || identity.kind == .channel
        ? groupConversationHeaderActions : directConversationHeaderActions
    var byId: [String: ConversationHeaderAction] = [:]
    var order: [String] = []
    if !configuration.replaceDefaults {
        for action in defaults { byId[action.id] = action; order.append(action.id) }
    }
    for action in configuration.actionOverrides + actions {
        if byId[action.id] == nil { order.append(action.id) }
        byId[action.id] = action
    }
    let available = capabilities?.availableActionIds
    return order.compactMap { byId[$0] }.filter { action in
        action.visible && !configuration.removeActionIds.contains(action.id)
            && (available == nil || available!.contains(action.capability ?? action.id))
    }.enumerated().sorted { left, right in
        (left.element.order ?? left.offset) < (right.element.order ?? right.offset)
    }.map(\.element)
}

/// Opinionated conversation identity plus capability-aware host actions.
public struct ConversationHeaderView: View {
    private let identity: ConversationIdentity
    private let capabilities: ConversationHeaderCapabilities?
    private let configuration: ConversationHeaderConfiguration
    private let actions: [ConversationHeaderAction]
    private let showBack: Bool
    private let onBack: (() -> Void)?
    private let onAction: ((ConversationHeaderAction) -> Void)?
    private let identityContent: ((ConversationIdentity) -> AnyView)?
    private let actionIcon: ((ConversationHeaderAction) -> AnyView)?
    private let trailing: AnyView?

    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    public init(
        identity: ConversationIdentity,
        capabilities: ConversationHeaderCapabilities? = nil,
        configuration: ConversationHeaderConfiguration = ConversationHeaderConfiguration(),
        actions: [ConversationHeaderAction] = [],
        showBack: Bool = false,
        onBack: (() -> Void)? = nil,
        onAction: ((ConversationHeaderAction) -> Void)? = nil,
        identityContent: ((ConversationIdentity) -> AnyView)? = nil,
        actionIcon: ((ConversationHeaderAction) -> AnyView)? = nil,
        trailing: AnyView? = nil
    ) {
        self.identity = identity; self.capabilities = capabilities; self.configuration = configuration
        self.actions = actions; self.showBack = showBack; self.onBack = onBack; self.onAction = onAction
        self.identityContent = identityContent; self.actionIcon = actionIcon; self.trailing = trailing
    }

    /// The identity's action when it survives the header's filtering (visible, not removed,
    /// capability available), is enabled and something handles it; nil leaves the identity plain,
    /// not a dead control.
    static func identityAction(_ identity: ConversationIdentity, capabilities: ConversationHeaderCapabilities?,
                               configuration: ConversationHeaderConfiguration, hasOnAction: Bool) -> ConversationHeaderAction? {
        guard hasOnAction, let action = identity.action, action.visible, action.enabled,
              !configuration.removeActionIds.contains(action.id) else { return nil }
        let available = capabilities?.availableActionIds
        return available == nil || available!.contains(action.capability ?? action.id) ? action : nil
    }

    /// The identity button's label: the action's accessibility label, else title and action label.
    static func identityLabel(_ identity: ConversationIdentity, action: ConversationHeaderAction,
                              strings: FlareStrings) -> String {
        action.accessibilityLabel ?? strings.conversationHeaderIdentityLabel(
            identity.title, localizedLabel(action, kind: identity.kind, strings: strings))
    }

    /// The label a header action shows. The kit's default actions carry English labels; one whose
    /// label is still its default (same id, same text, in the defaults for `kind`) shows the strings
    /// table's words instead, and any other label shows as the host gave it (Vue `localizedLabel`).
    static func localizedLabel(_ action: ConversationHeaderAction, kind: ConversationHeaderKind,
                               strings: FlareStrings) -> String {
        let defaults = kind == .group || kind == .channel ? groupConversationHeaderActions : directConversationHeaderActions
        guard defaults.contains(where: { $0.id == action.id && $0.label == action.label }) else { return action.label }
        switch action.id {
        case "search": return strings.conversationHeaderSearch
        case "audioCall": return strings.conversationHeaderAudioCall
        case "videoCall": return strings.conversationHeaderVideoCall
        case "addMember": return strings.conversationHeaderAddMember
        case "share": return strings.conversationHeaderShare
        case "details": return strings.conversationHeaderDetails
        default: return action.label
        }
    }

    /// The subtitle under the title: the typing text, else the subtitle, else a group's or channel's
    /// member count, else the presence in words; empty when there is none.
    static func subtitle(_ identity: ConversationIdentity, strings: FlareStrings) -> String {
        if let typing = identity.typingText?.nilIfBlank { return typing }
        if let subtitle = identity.subtitle?.nilIfBlank { return subtitle }
        if identity.kind == .group || identity.kind == .channel, let count = identity.memberCount {
            return strings.memberCount(count)
        }
        switch identity.presence {
        case .online?: return strings.presenceOnline
        case .offline?: return strings.presenceOffline
        case .busy?: return strings.presenceBusy
        case .away?: return strings.presenceAway
        case nil: return ""
        }
    }

    /// A More menu that would hold one action is a detour: that action takes the More button itself
    /// (Vue `soleOverflowAction`). Two or more keep the menu.
    static func soleOverflowAction(_ overflow: [ConversationHeaderAction]) -> ConversationHeaderAction? {
        overflow.count == 1 ? overflow[0] : nil
    }

    /// A toggle action that is on (`pressed == true`) is selected; a plain action adds nothing.
    static func toggleTraits(_ action: ConversationHeaderAction) -> AccessibilityTraits {
        action.pressed == true ? .isSelected : []
    }

    /// Where the resolved actions go: the first `maxPrimary` primary actions are buttons, the add
    /// menu holds the `.add` actions, and the overflow menu holds the primary actions past the limit
    /// followed by the `.overflow` actions — each in resolved order.
    static func regions(_ resolved: [ConversationHeaderAction], maxPrimary: Int)
        -> (primary: [ConversationHeaderAction], add: [ConversationHeaderAction], overflow: [ConversationHeaderAction]) {
        let candidates = resolved.filter { $0.placement == .primary }
        return (primary: Array(candidates.prefix(maxPrimary)),
                add: resolved.filter { $0.placement == .add },
                overflow: Array(candidates.dropFirst(maxPrimary)) + resolved.filter { $0.placement == .overflow })
    }

    /// The icon name a header action draws: its own `icon`, else its id, through the action aliases
    /// (`audioCall` → `phone`, `videoCall` → `video`, `addMember` → `person-add`, `details` → `info`).
    /// An id that names no icon draws the kit's unknown glyph, never `more`.
    static func symbol(_ action: ConversationHeaderAction) -> String {
        flareActionSymbol(action.icon ?? action.id)
    }

    /// A header action as a menu item, field by field (a header action is never destructive). Without
    /// an `icon`, the item takes its id when the id names an icon (an alias or a kit name), as the
    /// header's buttons resolve it; any other id leaves the row text-only.
    static func menuItem(_ action: ConversationHeaderAction, kind: ConversationHeaderKind,
                         strings: FlareStrings) -> FlareActionItem {
        FlareActionItem(id: action.id, label: localizedLabel(action, kind: kind, strings: strings),
                        icon: action.icon ?? (flareActionIdNamesIcon(action.id) ? action.id : nil),
                        group: action.group,
                        visible: action.visible, enabled: action.enabled, badge: action.badge,
                        accessibilityLabel: action.accessibilityLabel, disabledReason: action.disabledReason,
                        pressed: action.pressed)
    }

    public var body: some View {
        GeometryReader { proxy in
            content(compact: proxy.size.width < 560)
        }
        .frame(height: FlareSizes.headerHeight)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(identity.accessibilityLabel ?? identity.title)
    }

    private func content(compact: Bool) -> some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let resolved = resolveConversationHeaderActions(
            identity: identity, capabilities: capabilities, configuration: configuration, actions: actions)
        let (primary, add, overflow) = Self.regions(
            resolved, maxPrimary: compact ? configuration.compactMaxPrimaryActions : configuration.maxPrimaryActions)
        let identityAction = Self.identityAction(identity, capabilities: capabilities, configuration: configuration,
                                                 hasOnAction: onAction != nil)
        return HStack(spacing: 2) {
            if showBack {
                // The 44pt frame belongs to the label: a borderless button is hit by its label only.
                Button(action: { onBack?() }) { Image(systemName: flareIconSymbol("back")).flareTouchTarget() }
                    .disabled(onBack == nil)
                    .accessibilityLabel(strings.back)
            }
            identityBlock(compact: compact, action: identityAction, colors: colors)
                .frame(maxWidth: .infinity, alignment: .leading)
            ForEach(primary) { action in actionButton(action, colors: colors) }
            if !add.isEmpty { actionMenu(add, icon: "add", label: strings.conversationHeaderAddActions, colors: colors) }
            if let sole = Self.soleOverflowAction(overflow) {
                actionButton(sole, glyph: "more", colors: colors)
            } else if !overflow.isEmpty {
                actionMenu(overflow, icon: "more", label: strings.conversationHeaderMoreActions, colors: colors)
            }
            if let trailing { trailing }
        }
        .padding(.horizontal, compact ? FlareSizes.spacingSm : FlareSizes.spacingLg)
        .frame(height: FlareSizes.headerHeight)
        .background(colors.bgSecondary)
        .overlay(alignment: .bottom) { Rectangle().fill(colors.borderPrimary).frame(height: 1) }
    }

    /// The identity (default or host content); with an identity action, all of it is one button.
    @ViewBuilder
    private func identityBlock(compact: Bool, action: ConversationHeaderAction?, colors: FlareColors) -> some View {
        let block = Group {
            if let identityContent { identityContent(identity) }
            else { defaultIdentity(compact: compact, colors: colors) }
        }
        if let action {
            Button(action: { onAction?(action) }) {
                block.frame(minHeight: FlareSizes.touchTargetMin).contentShape(Rectangle())
            }
            .buttonStyle(IdentityButtonStyle(colors: colors))
            .help(Self.localizedLabel(action, kind: identity.kind, strings: strings))
            .accessibilityLabel(Self.identityLabel(identity, action: action, strings: strings))
            .accessibilityAddTraits(Self.toggleTraits(action))
        } else {
            block
        }
    }

    private func defaultIdentity(compact: Bool, colors: FlareColors) -> some View {
        let subtitle = Self.subtitle(identity, strings: strings)
        return HStack(spacing: FlareSizes.spacingSm) {
            AvatarView(userId: identity.id, displayName: identity.title, avatarURL: identity.avatarURL,
                       size: compact ? 36 : 40, presence: identity.presence)
            VStack(alignment: .leading, spacing: 1) {
                Text(identity.title).font(.system(size: FlareSizes.fontSize2xl, weight: .semibold))
                    .foregroundColor(colors.textPrimary).lineLimit(1)
                if !subtitle.isEmpty {
                    Text(subtitle).font(.system(size: FlareSizes.fontSizeSm))
                        .foregroundColor(identity.presence == .online ? colors.successText : colors.textTertiary).lineLimit(1)
                }
            }
        }
    }

    /// A header action as its own button. `glyph` draws that kit icon instead of the action's own:
    /// the sole overflow action keeps the More glyph and takes its own name.
    private func actionButton(_ action: ConversationHeaderAction, glyph: String? = nil, colors: FlareColors) -> some View {
        let on = action.pressed == true
        let label = Self.localizedLabel(action, kind: identity.kind, strings: strings)
        return Button(action: { onAction?(action) }) {
            Group {
                if let glyph { Image(systemName: flareIconSymbol(glyph)) }
                else if let actionIcon { actionIcon(action) }
                else { Image(systemName: Self.symbol(action)) }
            }
            // The 44pt frame belongs to the label: a borderless button is hit by its label only.
            .flareTouchTarget()
        }
        .foregroundColor(on ? colors.primaryText : colors.textSecondary)
        // A toggle that is on sits on the selected ground.
        .background(RoundedRectangle(cornerRadius: FlareSizes.radiusMd).fill(on ? colors.bgSelected : Color.clear))
        .disabled(!action.enabled || onAction == nil)
        .help(action.disabledReason ?? label)
        .accessibilityLabel(action.accessibilityLabel ?? label)
        .accessibilityAddTraits(Self.toggleTraits(action))
    }

    /// The add / overflow menu: the kit ``ActionMenuView`` over the actions as items; a pressed
    /// action shows its check, groups are sections, and choosing an item dispatches its action.
    private func actionMenu(_ actions: [ConversationHeaderAction], icon: String, label: String, colors: FlareColors) -> some View {
        ActionMenuView(items: actions.map { Self.menuItem($0, kind: identity.kind, strings: strings) },
                       accessibilityLabel: label, onSelect: { id in
            if let action = actions.first(where: { $0.id == id }) { onAction?(action) }
        }) {
            Image(systemName: flareIconSymbol(icon))
                .frame(minWidth: FlareSizes.touchTargetMin, minHeight: FlareSizes.touchTargetMin)
                .foregroundColor(colors.textSecondary)
        }
        .disabled(onAction == nil)
    }
}

/// The identity button: its content as is, on the hover ground while pressed and ringed while focused.
private struct IdentityButtonStyle: ButtonStyle {
    let colors: FlareColors

    func makeBody(configuration: Configuration) -> some View {
        IdentityButtonBody(configuration: configuration, colors: colors)
    }

    private struct IdentityButtonBody: View {
        let configuration: ButtonStyleConfiguration
        let colors: FlareColors
        @Environment(\.isFocused) private var focused

        var body: some View {
            configuration.label
                .padding(.horizontal, FlareSizes.spacingXs)
                .background(RoundedRectangle(cornerRadius: FlareSizes.radiusMd)
                    .fill(configuration.isPressed ? colors.bgHover : Color.clear))
                .overlay(RoundedRectangle(cornerRadius: FlareSizes.radiusMd)
                    .stroke(focused ? colors.borderSelected : Color.clear, lineWidth: 2))
        }
    }
}

private extension String {
    var nilIfBlank: String? { trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : self }
}
