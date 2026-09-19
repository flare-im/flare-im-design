import SwiftUI

/// Relation between the viewer and the contact, as decided by the host.
/// Names match the cross-platform contract (Vue / Flutter / Compose enums).
public enum FlareRelationState: String, CaseIterable, Sendable {
    case none, pendingOut, pendingIn, friends, blocked
}

/// Commands the bar may ask the host to run.
public enum FlareRelationAction: String, CaseIterable, Sendable {
    case add, accept, reject, remove, block, unblock, message
}

/// Capabilities the host can honour. `false` → the action is not rendered.
public struct FlareRelationCapabilities: Sendable {
    public let add, accept, reject, remove, block, unblock, message: Bool
    public init(add: Bool = false, accept: Bool = false, reject: Bool = false,
                remove: Bool = false, block: Bool = false, unblock: Bool = false,
                message: Bool = false) {
        self.add = add; self.accept = accept; self.reject = reject
        self.remove = remove; self.block = block; self.unblock = unblock
        self.message = message
    }

    public func allows(_ action: FlareRelationAction) -> Bool {
        switch action {
        case .add: return add
        case .accept: return accept
        case .reject: return reject
        case .remove: return remove
        case .block: return block
        case .unblock: return unblock
        case .message: return message
        }
    }
}

/// One displayable entry; `destructive` entries render in the trailing group.
public struct FlareRelationActionEntry: Equatable, Sendable {
    public let action: FlareRelationAction
    public let primary: Bool
    public let destructive: Bool
    public init(_ action: FlareRelationAction, primary: Bool = false, destructive: Bool = false) {
        self.action = action; self.primary = primary; self.destructive = destructive
    }
}

/// The full, ordered rule table. Capabilities filter it; they never reorder it,
/// so a button keeps its slot whichever switches the host flips.
private func relationRules(_ relation: FlareRelationState) -> [FlareRelationActionEntry] {
    switch relation {
    case .none:
        return [.init(.add, primary: true), .init(.block)]
    // pendingOut deliberately omits `add`: the request is already out, so the bar
    // shows a disabled "waiting" notice instead of a button that would re-send.
    case .pendingOut:
        return [.init(.block)]
    case .pendingIn:
        return [.init(.accept, primary: true), .init(.reject), .init(.block)]
    case .friends:
        return [.init(.message, primary: true), .init(.remove, destructive: true), .init(.block, destructive: true)]
    // While blocked nothing else is offered — no message, no friend request.
    case .blocked:
        return [.init(.unblock, primary: true)]
    }
}

/// Ordered, displayable actions for `relation` under `capabilities`.
/// The host owns the relation; the component owns nothing but this table.
public func relationActions(_ relation: FlareRelationState?,
                            capabilities: FlareRelationCapabilities?) -> [FlareRelationActionEntry] {
    let caps = capabilities ?? .init()
    return relationRules(relation ?? FlareRelationState.none).filter { caps.allows($0.action) }
}

/// True while an outgoing request is waiting: the bar shows a disabled primary
/// notice in place of the add button, regardless of capabilities, because it
/// reports state rather than offering a command.
public func relationShowsPending(_ relation: FlareRelationState?) -> Bool {
    relation == .pendingOut
}

/// Relation action bar for the bottom of a contact detail page. The host owns
/// the relation state and every command; the bar only decides which buttons
/// exist and emits intent. It never mutates the relation, never retries, and
/// keeps the previous failure reason on screen until it is dismissed.
/// Spec: Contacts/RelationActionBar.
public struct RelationActionBarView: View {
    let relation: FlareRelationState
    let capabilities: FlareRelationCapabilities
    /// Host sets this synchronously before dispatching; disables every button.
    let busy: Bool
    /// Reason the previous command failed; kept until dismissed, never auto-cleared.
    let error: String?
    let onAction: ((FlareRelationAction) -> Void)?
    let onDismissError: (() -> Void)?
    let addText, acceptText, rejectText, removeText, blockText, unblockText, messageText: String?
    let pendingText, busyText, dismissErrorText, emptyText: String?

    @State private var pending: FlareRelationAction?
    @Environment(\.colorScheme) private var scheme
    @Environment(\.flareBrandTheme) private var flareBrandTheme
    @Environment(\.flareStrings) private var strings

    public init(relation: FlareRelationState,
                capabilities: FlareRelationCapabilities = .init(),
                busy: Bool = false,
                error: String? = nil,
                onAction: ((FlareRelationAction) -> Void)? = nil,
                onDismissError: (() -> Void)? = nil,
                addText: String? = nil,
                acceptText: String? = nil,
                rejectText: String? = nil,
                removeText: String? = nil,
                blockText: String? = nil,
                unblockText: String? = nil,
                messageText: String? = nil,
                pendingText: String? = nil,
                busyText: String? = nil,
                dismissErrorText: String? = nil,
                emptyText: String? = nil) {
        self.relation = relation; self.capabilities = capabilities; self.busy = busy
        self.error = error; self.onAction = onAction; self.onDismissError = onDismissError
        self.addText = addText; self.acceptText = acceptText; self.rejectText = rejectText
        self.removeText = removeText; self.blockText = blockText; self.unblockText = unblockText
        self.messageText = messageText; self.pendingText = pendingText; self.busyText = busyText
        self.dismissErrorText = dismissErrorText; self.emptyText = emptyText
    }

    public func label(for action: FlareRelationAction) -> String {
        switch action {
        case .add: return copy.addText
        case .accept: return copy.acceptText
        case .reject: return copy.rejectText
        case .remove: return copy.removeText
        case .block: return copy.blockText
        case .unblock: return copy.unblockText
        case .message: return copy.messageText
        }
    }

    static func symbol(for action: FlareRelationAction) -> String {
        switch action {
        case .add: return "person.badge.plus"
        case .accept: return "checkmark"
        case .reject: return "xmark"
        case .remove: return "trash"
        case .block: return "nosign"
        case .unblock: return "checkmark.circle"
        case .message: return "bubble.left"
        }
    }

    /// Copy in effect: an explicit parameter wins, otherwise the `flareStrings` provider.
    struct Copy {
        let addText, acceptText, rejectText, removeText: String
        let blockText, unblockText, messageText, pendingText: String
        let busyText, dismissErrorText, emptyText: String
    }
    func resolveCopy(_ strings: FlareStrings) -> Copy {
        Copy(
            addText: addText ?? strings.relationActionBarAdd,
            acceptText: acceptText ?? strings.relationActionBarAccept,
            rejectText: rejectText ?? strings.reject,
            removeText: removeText ?? strings.relationActionBarRemove,
            blockText: blockText ?? strings.relationActionBarBlock,
            unblockText: unblockText ?? strings.relationActionBarUnblock,
            messageText: messageText ?? strings.sendMessage,
            pendingText: pendingText ?? strings.relationActionBarPending,
            busyText: busyText ?? strings.relationActionBarBusy,
            dismissErrorText: dismissErrorText ?? strings.relationActionBarDismissError,
            emptyText: emptyText ?? strings.relationActionBarEmpty
        )
    }
    private var copy: Copy { resolveCopy(strings) }

    public var body: some View {
        let colors = FlareColors.of(scheme, brand: flareBrandTheme)
        let entries = relationActions(relation, capabilities: capabilities)
        let safe = entries.filter { !$0.destructive }
        let danger = entries.filter { $0.destructive }
        let pendingNotice = relationShowsPending(relation)
        let isEmpty = entries.isEmpty && !pendingNotice
        let reason = (error ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

        VStack(spacing: 0) {
            if !reason.isEmpty { errorStrip(colors, reason) }
            FlareFlowLayout(spacing: FlareSizes.spacingSm, lineSpacing: FlareSizes.spacingSm) {
                if pendingNotice {
                    HStack(spacing: 6) {
                        Image(systemName: "clock").font(.system(size: 14))
                        Text(copy.pendingText).font(.system(size: FlareSizes.fontSizeMd, weight: .semibold))
                    }
                    .foregroundColor(colors.textDisabled)
                    .padding(.horizontal, FlareSizes.spacingMd)
                    .frame(minHeight: FlareSizes.touchTarget)
                    .background(RoundedRectangle(cornerRadius: FlareSizes.radiusMd).fill(colors.bgDisabled))
                    .accessibilityElement(children: .combine)
                }
                if isEmpty {
                    Text(copy.emptyText)
                        .font(.system(size: FlareSizes.fontSizeMd))
                        .foregroundColor(colors.textTertiary)
                        .frame(minHeight: FlareSizes.touchTarget)
                }
                ForEach(safe, id: \.action) { entry in button(colors, entry) }
                if !danger.isEmpty {
                    HStack(spacing: FlareSizes.spacingSm) {
                        Rectangle().fill(colors.borderSecondary).frame(width: 1, height: 24)
                        ForEach(danger, id: \.action) { entry in button(colors, entry) }
                    }
                }
            }
            .padding(.horizontal, FlareSizes.spacingLg)
            .padding(.vertical, FlareSizes.spacingSm)
        }
        .frame(maxWidth: .infinity)
        .background(colors.bgPrimary)
        .overlay(alignment: .top) { Rectangle().fill(colors.borderSecondary).frame(height: 1) }
        .onChange(of: busy) { newValue in if !newValue { pending = nil } }
    }

    @ViewBuilder
    private func errorStrip(_ colors: FlareColors, _ reason: String) -> some View {
        HStack(spacing: FlareSizes.spacingSm) {
            Image(systemName: "exclamationmark.circle")
                .font(.system(size: 14))
                .foregroundColor(colors.errorText)
            Text(reason)
                .font(.system(size: FlareSizes.fontSizeMd))
                .foregroundColor(colors.errorText)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let onDismissError {
                Button(action: onDismissError) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14))
                        .foregroundColor(colors.textSecondary)
                        .frame(width: FlareSizes.touchTarget, height: FlareSizes.touchTarget)
                }
                .buttonStyle(.plain)
                .disabled(busy)
                .opacity(busy ? 0.45 : 1)
                .accessibilityLabel(copy.dismissErrorText)
            }
        }
        .padding(.horizontal, FlareSizes.spacingLg)
        .padding(.vertical, FlareSizes.spacingSm)
        .frame(maxWidth: .infinity)
        .background(colors.error.opacity(0.10))
        .overlay(alignment: .bottom) { Rectangle().fill(colors.borderSecondary).frame(height: 1) }
    }

    private func button(_ colors: FlareColors, _ entry: FlareRelationActionEntry) -> some View {
        let enabled = !busy && onAction != nil
        let inProgress = busy && pending == entry.action
        let text = label(for: entry.action)
        let fg: Color = entry.primary ? .white : (entry.destructive ? colors.error : colors.textPrimary)
        let bg: Color = entry.primary
            ? colors.primary
            : (entry.destructive ? colors.error.opacity(0.10) : colors.bgSecondary)
        return Button {
            pending = entry.action
            onAction?(entry.action)
        } label: {
            HStack(spacing: 6) {
                if inProgress {
                    ProgressView().controlSize(.small).tint(fg)
                } else {
                    Image(systemName: Self.symbol(for: entry.action)).font(.system(size: 14))
                }
                Text(text).font(.system(size: FlareSizes.fontSizeMd, weight: .medium)).lineLimit(1)
            }
            .foregroundColor(fg)
            .padding(.horizontal, FlareSizes.spacingMd)
            .frame(minWidth: FlareSizes.touchTarget, minHeight: FlareSizes.touchTarget)
            .background(RoundedRectangle(cornerRadius: FlareSizes.radiusMd).fill(bg))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : (inProgress ? 0.85 : 0.45))
        .accessibilityLabel(inProgress ? "\(text) · \(copy.busyText)" : text)
    }
}
