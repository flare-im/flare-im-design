import SwiftUI

/// Display group of a ``FlareMessageMenuEntry``; groups render in this order.
public enum FlareMessageMenuGroup: String, CaseIterable, Sendable {
    case primary, organize, destructive
}

/// One action of the message long-press sheet; `id` is the stable action id
/// (reply / forward / recall / multiSelect / mark / pin / copy / edit / delete …).
public struct FlareMessageMenuEntry: Identifiable, Equatable, Sendable {
    public let id: String
    public let label: String
    /// Semantic kit icon name (``flareIconNames``).
    public let icon: String
    public let group: FlareMessageMenuGroup
    public let enabled: Bool
    public init(id: String, label: String, icon: String,
                group: FlareMessageMenuGroup = .organize, enabled: Bool = true) {
        self.id = id; self.label = label; self.icon = icon
        self.group = group; self.enabled = enabled
    }
}

/// Entries grouped in display order (primary, organize, destructive); empty
/// groups are dropped.
public func messageMenuGroups(_ entries: [FlareMessageMenuEntry]) -> [[FlareMessageMenuEntry]] {
    FlareMessageMenuGroup.allCases
        .map { group in entries.filter { $0.group == group } }
        .filter { !$0.isEmpty }
}

/// What can be done with one message right now: the `can*` flags of the core's action
/// availability (`domain::message_actions`), under the core's names. The host asks the core
/// and hands the answer to `MessageActionSheetView`, which turns it into the standard actions.
public struct FlareMessageActionAvailability: Equatable, Sendable {
    public var canReply: Bool
    public var canForward: Bool
    public var canCopy: Bool
    public var canEdit: Bool
    public var canDelete: Bool
    public var canRecall: Bool
    public var canPin: Bool
    public var canUnpin: Bool
    public var canReact: Bool
    public var canMultiSelect: Bool
    public var canSave: Bool
    public var canResend: Bool

    public init(canReply: Bool = false, canForward: Bool = false, canCopy: Bool = false,
                canEdit: Bool = false, canDelete: Bool = false, canRecall: Bool = false,
                canPin: Bool = false, canUnpin: Bool = false, canReact: Bool = false,
                canMultiSelect: Bool = false, canSave: Bool = false, canResend: Bool = false) {
        self.canReply = canReply; self.canForward = canForward; self.canCopy = canCopy
        self.canEdit = canEdit; self.canDelete = canDelete; self.canRecall = canRecall
        self.canPin = canPin; self.canUnpin = canUnpin; self.canReact = canReact
        self.canMultiSelect = canMultiSelect; self.canSave = canSave; self.canResend = canResend
    }

    /// The core's answer as the SDK returns it (camelCase JSON); a flag that is not `true` is off.
    public init(json: [String: Any]) {
        func flag(_ key: String) -> Bool { json[key] as? Bool == true }
        self.init(canReply: flag("canReply"), canForward: flag("canForward"), canCopy: flag("canCopy"),
                  canEdit: flag("canEdit"), canDelete: flag("canDelete"), canRecall: flag("canRecall"),
                  canPin: flag("canPin"), canUnpin: flag("canUnpin"), canReact: flag("canReact"),
                  canMultiSelect: flag("canMultiSelect"), canSave: flag("canSave"), canResend: flag("canResend"))
    }
}

/// Quick reactions the sheet offers when the host passes none; the same set on every platform.
public let flareQuickReactions = ["👍", "❤️", "😂", "😮", "😢", "🎉"]

/// The text a message body can put on the clipboard: a text body's own text, or the core's plain text of a
/// rich-text body; nil when there is none.
///
/// Copy is offered on this, not on the core's `canCopy`: the core reads its preview text
/// (`text_for_storage`), which falls back to a token like `[图片]` for media, so an image, a voice
/// message and a file all claim to be copyable and the action then copies nothing.
public func flareCopyableText(_ content: FlareMessageContent?) -> String? {
    guard let text = (content as? FlareTextContent)?.text ?? (content as? FlareRichTextContent)?.plainText else {
        return nil
    }
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : text
}

/// The standard actions `availability` allows, in the order every platform shows them: reply,
/// forward, recall and resend as quick actions; multi-select, mark, pin, pin for me, unpin, copy,
/// preview, save and edit as the list; delete last. Mark and delete share `canDelete`, pin and
/// pin-for-me share `canPin`, multi-select and preview share `canMultiSelect`. Ids in `hidden`
/// (actions the host does not implement) are left out.
///
/// `content` is the message's body: copy is offered only when it has text to copy
/// (``flareCopyableText(_:)``), so an image or a voice message never offers an action that does
/// nothing. Without a body nothing is copyable.
public func messageMenuActions(_ availability: FlareMessageActionAvailability, strings: FlareStrings,
                               hidden: Set<String> = [],
                               content: FlareMessageContent? = nil) -> [FlareMessageMenuEntry] {
    let a = availability
    let copyable = flareCopyableText(content) != nil
    let candidates: [(Bool, String, String, String, FlareMessageMenuGroup)] = [
        (a.canReply, "reply", strings.messageActionReply, "reply", .primary),
        (a.canForward, "forward", strings.messageActionForward, "forward", .primary),
        (a.canRecall, "recall", strings.messageActionRecall, "recall", .primary),
        (a.canResend, "resend", strings.messageActionResend, "refresh", .primary),
        (a.canMultiSelect, "multiSelect", strings.messageActionMultiSelect, "multi-select", .organize),
        (a.canDelete, "mark", strings.messageActionMark, "mark", .organize),
        (a.canPin, "pin", strings.messageActionPin, "pin", .organize),
        (a.canPin, "pinSelf", strings.messageActionPinSelf, "pin-self", .organize),
        (a.canUnpin, "unpin", strings.messageActionUnpin, "unpin", .organize),
        (a.canCopy && copyable, "copy", strings.messageActionCopy, "copy", .organize),
        (a.canMultiSelect, "preview", strings.messageActionPreview, "eye", .organize),
        (a.canSave, "save", strings.messageActionSave, "download", .organize),
        (a.canEdit, "edit", strings.messageActionEdit, "edit", .organize),
        (a.canDelete, "delete", strings.messageActionDelete, "delete", .destructive),
    ]
    return candidates.compactMap { allowed, id, label, icon, group in
        allowed && !hidden.contains(id)
            ? FlareMessageMenuEntry(id: id, label: label, icon: icon, group: group)
            : nil
    }
}

/// The message long-press action sheet — a reaction strip plus grouped actions
/// (primary / organize / destructive, destructive in red). Spec:
/// Message/MessageActionSheet (`MessageActionSheetView`). The host passes the core's
/// `availability` and the message's `content` and gets the standard actions (see
/// `messageMenuActions`), leaves out the ones it does not implement with `hiddenActions`, and
/// appends its own `actions` to their groups. Copy needs the body: it is offered only for a message
/// with text to copy, so pass `content`. `reactions` defaults to `flareQuickReactions` when the
/// message can take one.
/// Dispatches `onAction` with the action id and `onReact` with the emoji; owns no
/// positioning — present it with ``SwiftUI/View/flareBottomSheet(item:title:onDismiss:content:)``
/// (or in a popover on a pointer device).
public struct MessageActionSheetView: View {
    private let availability: FlareMessageActionAvailability
    private let content: FlareMessageContent?
    private let hiddenActions: Set<String>
    private let actions: [FlareMessageMenuEntry]
    private let reactions: [String]?
    private let label: String?
    private let emptyText: String?
    private let onAction: ((String) -> Void)?
    private let onReact: ((String) -> Void)?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings
    @ScaledMetric(relativeTo: .body) private var textScale: CGFloat = 1

    public init(availability: FlareMessageActionAvailability = .init(),
                content: FlareMessageContent? = nil, hiddenActions: Set<String> = [],
                actions: [FlareMessageMenuEntry] = [], reactions: [String]? = nil,
                label: String? = nil, emptyText: String? = nil,
                onAction: ((String) -> Void)? = nil, onReact: ((String) -> Void)? = nil) {
        self.availability = availability; self.content = content; self.hiddenActions = hiddenActions
        self.actions = actions; self.reactions = reactions
        self.label = label; self.emptyText = emptyText
        self.onAction = onAction; self.onReact = onReact
    }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let groups = messageMenuGroups(
            messageMenuActions(availability, strings: strings, hidden: hiddenActions, content: content) + actions)
        // A host list is gated by canReact too: no reaction strip on a message that cannot take one.
        let strip = availability.canReact ? (reactions ?? flareQuickReactions) : []
        VStack(alignment: .leading, spacing: FlareSizes.spacingSm) {
            if !strip.isEmpty {
                HStack(spacing: 0) {
                    ForEach(strip, id: \.self) { reaction in
                        Button { onReact?(reaction) } label: {
                            Text(reaction).font(.system(size: FlareSizes.iconSizeLg * textScale))
                                .frame(maxWidth: .infinity, minHeight: FlareSizes.touchTarget)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(reaction)
                    }
                }
                .padding(.bottom, FlareSizes.spacingXs)
            }
            if groups.isEmpty && strip.isEmpty {
                Text(emptyText ?? strings.messageActionSheetEmpty)
                    .font(.system(size: FlareSizes.fontSizeLg * textScale))
                    .foregroundColor(colors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(FlareSizes.spacingLg)
            }
            ForEach(Array(groups.enumerated()), id: \.offset) { _, entries in
                VStack(spacing: 0) {
                    ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                        if index > 0 { Divider().overlay(colors.borderSecondary) }
                        let destructive = entry.group == .destructive
                        let foreground = !entry.enabled ? colors.textTertiary : (destructive ? colors.error : colors.textPrimary)
                        Button { onAction?(entry.id) } label: {
                            HStack(spacing: FlareSizes.spacingMd) {
                                Image(systemName: flareIconSymbol(entry.icon)).font(.system(size: FlareSizes.iconSizeMd * textScale))
                                Text(entry.label).font(.system(size: FlareSizes.fontSizeXl * textScale))
                                Spacer(minLength: 0)
                            }
                            .foregroundColor(foreground)
                            .padding(.horizontal, FlareSizes.spacingMd)
                            .padding(.vertical, FlareSizes.spacingSm)
                            .frame(maxWidth: .infinity, minHeight: FlareSizes.touchTarget, alignment: .leading)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .disabled(!entry.enabled)
                        .accessibilityLabel(entry.label)
                    }
                }
                .background(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).fill(colors.bgPrimary))
                .overlay(RoundedRectangle(cornerRadius: FlareSizes.radiusLg).stroke(colors.borderPrimary))
            }
        }
        .padding(.horizontal, FlareSizes.spacingMd)
        .padding(.top, FlareSizes.spacingLg)
        .padding(.bottom, FlareSizes.spacingMd)
        .frame(maxWidth: .infinity, alignment: .leading)
        // In a sheet the ground runs on under the home indicator.
        .background(colors.bgSecondary.ignoresSafeArea(.container, edges: .bottom))
        .accessibilityElement(children: .contain)
        .accessibilityLabel(label ?? strings.messageActionSheetLabel)
    }
}
