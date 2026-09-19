import Foundation

/// When what someone typed and did not send is written down, and what it is written as.
///
/// The rule is shared with the Vue, Flutter and Compose kits and tested against `spec/draft-vectors.json`.
/// It lives here rather than in each app because all five were writing it, and writing it to five
/// different places with five different lifetimes: the web app saved to the core after 1200 ms, so a
/// draft roamed to another device; the Tauri app to `localStorage` after 450 ms, so it survived a restart
/// on that machine and nowhere else; the Android app to a map in memory, so it survived switching
/// conversations and nothing else; the Flutter and iOS apps did not save at all — leave the chat and what
/// you typed was gone. "Draft" meant four different things.
public enum FlareDraft {
    /// A pause this long after the last edit writes the draft down.
    public static let saveDelayMs = 1200
}

/// One write this client owes the core. `text` of "" clears the conversation's draft.
public struct FlareDraftSave: Equatable, Sendable {
    public let conversationId: String
    public let text: String
    /// The instant the write is for — the deadline when a pause triggered it, else the moment it happened.
    public let atMs: Int

    public init(conversationId: String, text: String, atMs: Int) {
        self.conversationId = conversationId
        self.text = text
        self.atMs = atMs
    }
}

/// The text a send that reached nothing leaves behind: above whatever was typed while it was in flight,
/// and never twice. A failed send of nothing changes nothing.
public func flareRestoredDraft(_ current: String, failed: String) -> String {
    let back = failed.trimmingCharacters(in: .whitespacesAndNewlines)
    if back.isEmpty { return current }
    if current.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return failed }
    if current.contains(back) { return current }
    return "\(failed)\n\(current)"
}

public final class FlareDraftAutosave {
    private var saved: [String: String] = [:]
    private var pending: (conversationId: String, text: String)?
    private var deadlineMs = 0

    public init() {}

    private static func stored(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "" : text
    }

    /// What the core already holds for a conversation, so an unchanged draft is never written back.
    public func seed(_ conversationId: String, text: String) {
        guard !conversationId.isEmpty else { return }
        saved[conversationId] = Self.stored(text)
    }

    /// The draft this client believes the core holds.
    public func storedText(_ conversationId: String) -> String { saved[conversationId] ?? "" }

    /// When the pending write is due, or nil when none is. Hosts arm a timer on it.
    public var pendingDeadline: Int? { pending == nil ? nil : deadlineMs }

    /// The composer's text changed. Editing a sent message is not this: the host does not report it here.
    public func edit(_ conversationId: String, text: String, nowMs: Int) -> [FlareDraftSave] {
        var out = tick(nowMs)
        guard !conversationId.isEmpty else { return out }
        // Moving to another conversation writes the one being left before starting the new one.
        if let pending, pending.conversationId != conversationId { out.append(contentsOf: flush(at: nowMs)) }
        pending = (conversationId: conversationId, text: Self.stored(text))
        deadlineMs = nowMs + FlareDraft.saveDelayMs
        return out
    }

    /// The message went out: the draft it came from is gone, and any pending write with it.
    public func send(_ conversationId: String, nowMs: Int) -> [FlareDraftSave] {
        var out = tick(nowMs)
        if pending?.conversationId == conversationId { pending = nil }
        out.append(contentsOf: write(conversationId, text: "", atMs: nowMs))
        return out
    }

    /// The reader left the conversation, the screen or the app: write the pending draft now.
    public func leave(nowMs: Int) -> [FlareDraftSave] { tick(nowMs) + flush(at: nowMs) }

    /// A send that reached nothing. Its text goes back immediately, never on the timer: a draft lost to a
    /// pending write is the one case where losing it is unforgivable.
    public func restore(_ conversationId: String, failedText: String, nowMs: Int) -> [FlareDraftSave] {
        var out = tick(nowMs)
        guard !conversationId.isEmpty else { return out }
        if pending?.conversationId == conversationId { pending = nil }
        out.append(contentsOf: write(conversationId, text: flareRestoredDraft(storedText(conversationId), failed: failedText), atMs: nowMs))
        return out
    }

    /// Time passed. Fires the pending write at its deadline, not at `nowMs`.
    public func tick(_ nowMs: Int) -> [FlareDraftSave] {
        guard pending != nil, nowMs >= deadlineMs else { return [] }
        return flush(at: deadlineMs)
    }

    private func flush(at atMs: Int) -> [FlareDraftSave] {
        guard let pending else { return [] }
        self.pending = nil
        deadlineMs = 0
        return write(pending.conversationId, text: pending.text, atMs: atMs)
    }

    private func write(_ conversationId: String, text: String, atMs: Int) -> [FlareDraftSave] {
        guard !conversationId.isEmpty else { return [] }
        let next = Self.stored(text)
        guard storedText(conversationId) != next else { return [] }
        saved[conversationId] = next
        return [FlareDraftSave(conversationId: conversationId, text: next, atMs: atMs)]
    }
}
