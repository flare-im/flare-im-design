import Foundation

public enum FlareComposerInteractionMode: String, Sendable {
    case idle, typing, mentioning, replying, editing, uploading, recording, sending
    case sendBlocked, offline, readOnly, slowMode, permissionDenied
}

public enum FlareComposerInteractionAction: String, Sendable, Hashable {
    case type, send, newline, attach, mention, reply, edit, record, cancel, retry
}

public struct FlareComposerInteractionInput: Sendable {
    public var hasText = false, mentioning = false, replying = false, editing = false
    public var uploading = false, recording = false, sending = false, sendBlocked = false
    public var online = true, readOnly = false, slowMode = false, permissionGranted = true

    public init(hasText: Bool = false, mentioning: Bool = false, replying: Bool = false,
                editing: Bool = false, uploading: Bool = false, recording: Bool = false,
                sending: Bool = false, sendBlocked: Bool = false, online: Bool = true,
                readOnly: Bool = false, slowMode: Bool = false, permissionGranted: Bool = true) {
        self.hasText = hasText; self.mentioning = mentioning; self.replying = replying
        self.editing = editing; self.uploading = uploading; self.recording = recording
        self.sending = sending; self.sendBlocked = sendBlocked; self.online = online
        self.readOnly = readOnly; self.slowMode = slowMode; self.permissionGranted = permissionGranted
    }
}

public func resolveComposerMode(_ input: FlareComposerInteractionInput) -> FlareComposerInteractionMode {
    if input.readOnly { return .readOnly }
    if !input.permissionGranted { return .permissionDenied }
    if !input.online { return .offline }
    if input.slowMode { return .slowMode }
    if input.sendBlocked { return .sendBlocked }
    if input.sending { return .sending }
    if input.recording { return .recording }
    if input.uploading { return .uploading }
    if input.editing { return .editing }
    if input.mentioning { return .mentioning }
    if input.replying { return .replying }
    return input.hasText ? .typing : .idle
}

public func composerAllowedActions(_ mode: FlareComposerInteractionMode) -> Set<FlareComposerInteractionAction> {
    switch mode {
    case .readOnly: return []
    case .permissionDenied: return [.cancel]
    case .offline: return [.type, .newline, .attach, .cancel, .retry]
    case .slowMode, .sendBlocked: return [.type, .newline, .attach, .mention, .cancel]
    case .sending: return [.cancel]
    case .recording: return [.send, .cancel]
    case .uploading: return [.type, .newline, .attach, .cancel]
    case .editing, .mentioning, .replying: return [.type, .newline, .send, .attach, .mention, .cancel]
    default: return [.type, .send, .newline, .attach, .mention, .reply, .edit, .record]
    }
}

public enum FlareMessageInteractionMode: String, Sendable {
    case normal, hover, selected, multiSelected, sending, sent, delivered, read
    case failed, retrying, edited, recalled, deleted, ephemeral, expired
}

public func resolveMessageMode(_ lifecycle: FlareMessageLifecycle, hovered: Bool = false,
                               selected: Bool = false, multiSelect: Bool = false,
                               retrying: Bool = false) -> FlareMessageInteractionMode {
    if lifecycle.mutation == .deleted { return .deleted }
    if lifecycle.ephemeral == .expired { return .expired }
    if lifecycle.mutation == .recalled { return .recalled }
    if retrying { return .retrying }
    if lifecycle.send == .failed || lifecycle.transfer == .failed { return .failed }
    if lifecycle.ephemeral != .none { return .ephemeral }
    if lifecycle.mutation == .edited { return .edited }
    if multiSelect && selected { return .multiSelected }
    if selected { return .selected }
    if hovered { return .hover }
    if lifecycle.send == .sending || lifecycle.send == .draft { return .sending }
    if lifecycle.read == .read { return .read }
    if lifecycle.delivery != .serverAccepted { return .delivered }
    return lifecycle.send == .sent ? .sent : .normal
}

public enum FlareMessageCapability: String, Sendable, Hashable {
    case reply, reaction, copy, forward, mergeForward, multiSelect, edit, delete, recall
    case pin, unpin, save, translate, report, retry, openThread, jumpToQuote
}

public struct FlareMessageCapabilityInput: Sendable {
    public let lifecycle: FlareMessageLifecycle
    public let own: Bool
    public let canModerate: Bool
    public let supportsCopy: Bool
    public let supportsSave: Bool
    public let supportsTranslate: Bool
    public let supportsMergeForward: Bool
    public let reportable: Bool
    public let pinned: Bool
    public let hasThread: Bool
    public let hasQuote: Bool
    public init(lifecycle: FlareMessageLifecycle, own: Bool, canModerate: Bool = false,
                supportsCopy: Bool = true, supportsSave: Bool = false,
                supportsTranslate: Bool = false, supportsMergeForward: Bool = false,
                reportable: Bool = true, pinned: Bool = false,
                hasThread: Bool = false, hasQuote: Bool = false) {
        self.lifecycle = lifecycle; self.own = own; self.canModerate = canModerate
        self.supportsCopy = supportsCopy; self.supportsSave = supportsSave
        self.supportsTranslate = supportsTranslate; self.supportsMergeForward = supportsMergeForward
        self.reportable = reportable; self.pinned = pinned
        self.hasThread = hasThread; self.hasQuote = hasQuote
    }
}

public func resolveMessageCapabilities(_ input: FlareMessageCapabilityInput) -> Set<FlareMessageCapability> {
    let lifecycle = input.lifecycle
    let terminal = lifecycle.mutation == .deleted || lifecycle.mutation == .recalled || lifecycle.ephemeral == .expired
    let failed = lifecycle.send == .failed || lifecycle.transfer == .failed
    if terminal { return input.canModerate ? [.delete] : [] }
    var result: Set<FlareMessageCapability> = [.multiSelect]
    if input.own || input.canModerate { result.insert(.delete) }
    if failed {
        if input.own { result.insert(.retry) }
    } else {
        result.formUnion([.reply, .reaction, .forward])
        result.insert(input.pinned ? .unpin : .pin)
        if input.supportsMergeForward { result.insert(.mergeForward) }
        if input.hasThread { result.insert(.openThread) }
        if input.hasQuote { result.insert(.jumpToQuote) }
        if input.supportsCopy { result.insert(.copy) }
        if input.supportsSave { result.insert(.save) }
        if input.supportsTranslate { result.insert(.translate) }
        if input.own && lifecycle.send == .sent { result.formUnion([.edit, .recall]) }
        if !input.own && input.reportable { result.insert(.report) }
    }
    return result
}

public enum FlareMessageActionGroup: String, Sendable { case primary, organize, message, destructive }
public enum FlareMessageActionPresentation: String, Sendable { case contextMenu, hoverToolbar, commandPalette, actionSheet, bottomSheet }
public struct FlareMessageAction: Sendable {
    public let id: FlareMessageCapability
    public let group: FlareMessageActionGroup
    public let destructive: Bool
    public let promoted: Bool
}

public func resolveMessageActions(_ input: FlareMessageCapabilityInput, presentation: FlareMessageActionPresentation) -> [FlareMessageAction] {
    let primary: Set<FlareMessageCapability> = [.reply, .reaction, .copy, .forward, .openThread]
    let organize: Set<FlareMessageCapability> = [.pin, .unpin, .save, .translate, .multiSelect, .mergeForward]
    let destructive: Set<FlareMessageCapability> = [.recall, .delete, .report]
    return resolveMessageCapabilities(input).map { id in
        FlareMessageAction(
            id: id,
            group: destructive.contains(id) ? .destructive : organize.contains(id) ? .organize : primary.contains(id) ? .primary : .message,
            destructive: destructive.contains(id),
            promoted: presentation == .hoverToolbar && primary.contains(id)
        )
    }
}

public struct FlareSelectionState: Sendable {
    public let selectedIds: Set<String>
    public let anchorId: String?
    public init(selectedIds: Set<String> = [], anchorId: String? = nil) {
        self.selectedIds = selectedIds; self.anchorId = anchorId
    }
}

public enum FlareSelectionEvent: Sendable {
    case toggle(String), replace(String), extend(String, orderedIds: [String]), clear
}

public func reduceSelection(_ state: FlareSelectionState, _ event: FlareSelectionEvent) -> FlareSelectionState {
    switch event {
    case .clear: return FlareSelectionState()
    case .replace(let id): return FlareSelectionState(selectedIds: [id], anchorId: id)
    case .toggle(let id):
        var next = state.selectedIds
        if next.contains(id) { next.remove(id) } else { next.insert(id) }
        return FlareSelectionState(selectedIds: next, anchorId: id)
    case .extend(let id, let orderedIds):
        guard let anchorId = state.anchorId, let anchor = orderedIds.firstIndex(of: anchorId),
              let target = orderedIds.firstIndex(of: id) else {
            return FlareSelectionState(selectedIds: [id], anchorId: id)
        }
        let bounds = min(anchor, target)...max(anchor, target)
        return FlareSelectionState(selectedIds: Set(orderedIds[bounds]), anchorId: anchorId)
    }
}

public enum FlareDesktopShortcutAction: String, Sendable {
    case search, commandPalette, newConversation, focusComposer, send, newline, closeOverlay
    case previousConversation, nextConversation, toggleDetails, reply, edit, delete, copy, forward, openThread
}
public enum FlareDesktopShortcutScope: String, Sendable { case global, composer, conversation }

public func resolveDesktopShortcut(_ key: String, primary: Bool = false, alt: Bool = false,
                                   shift: Bool = false, scope: FlareDesktopShortcutScope = .global) -> FlareDesktopShortcutAction? {
    let key = key.lowercased()
    if key == "escape" { return .closeOverlay }
    if primary && key == "k" { return .commandPalette }
    if primary && key == "f" { return .search }
    if primary && key == "n" { return .newConversation }
    if primary && shift && key == "d" { return .toggleDetails }
    if alt && key == "arrowup" { return .previousConversation }
    if alt && key == "arrowdown" { return .nextConversation }
    if scope == .composer && key == "enter" { return primary ? .send : .newline }
    if scope == .conversation && primary && key == "c" { return .copy }
    if scope == .conversation && !primary && !alt && key == "r" { return .reply }
    if scope == .conversation && !primary && !alt && key == "e" { return .edit }
    if scope == .conversation && !primary && !alt && key == "f" { return .forward }
    if scope == .conversation && !primary && !alt && key == "t" { return .openThread }
    if scope == .conversation && ["delete", "backspace"].contains(key) { return .delete }
    return nil
}

public enum FlareSwipeIntent: String, Sendable { case none, reply, conversationLeading, conversationTrailing }

public func resolveSwipeIntent(deltaX: Double, deltaY: Double, message: Bool, rtl: Bool = false,
                               multiSelect: Bool = false, threshold: Double = 56) -> FlareSwipeIntent {
    if multiSelect || abs(deltaX) < threshold || abs(deltaX) < abs(deltaY) * 1.25 { return .none }
    let leading = rtl ? deltaX < 0 : deltaX > 0
    if message { return leading ? .reply : .none }
    return leading ? .conversationLeading : .conversationTrailing
}
