import Foundation

/// What this client tells a conversation about its own typing.
///
/// The rule is shared with the Vue, Flutter and Compose kits and tested against the `signal` half of
/// `spec/typing-vectors.json`. It lives here rather than in each app because all five were writing it, and
/// writing it differently: the pause that ends typing was 3000, 2800, 1500, 1500 and — on iOS — never, two
/// apps re-reported `true` on every keystroke, and the two that deduplicated the report never refreshed it,
/// so a message that took longer than the peer's belief to write stopped showing as typing while it was
/// still being typed.
///
/// The engine is a state machine with the clock passed in, not read: the same script must produce the same
/// reports on four platforms, and a rule that reads the wall clock cannot be tested at all.
public enum FlareTyping {
    /// A pause this long after the last edit ends typing.
    public static let idleStopMs = 4000
    /// `typing: true` is reported at most this often while the user keeps typing.
    public static let refreshMs = 2500
    /// How long a peer stays "typing" on this belief without a fresh signal (the receiving half of the rule).
    public static let peerTtlMs = 6000
}

/// One report this client owes a conversation.
public struct FlareTypingReport: Equatable, Sendable {
    public let conversationId: String
    public let typing: Bool
    /// The instant the report is for. Usually the `nowMs` handed in, but an idle stop is timestamped at its
    /// deadline, so a host whose timer fired late still reports the moment typing actually ended — and the
    /// shared table can assert *when*, not only *what*.
    public let atMs: Int

    public init(conversationId: String, typing: Bool, atMs: Int) {
        self.conversationId = conversationId
        self.typing = typing
        self.atMs = atMs
    }
}

/// One conversation types at a time: the composer is one control, so an edit somewhere else ends the
/// previous conversation before it starts the new one. Every method answers with the reports to send, in
/// order — the caller does the sending, and a send that fails is not this rule's business.
public final class FlareTypingSignal {
    private var activeId = ""
    private var lastTrueAtMs = 0
    private var idleDeadlineMs = 0

    public init() {}

    /// The conversation currently reported as typing, or "" when none is.
    public var typingConversationId: String { activeId }

    /// When the idle stop is due, or nil when nothing is typing. Hosts arm a timer on it.
    public var idleDeadline: Int? { activeId.isEmpty ? nil : idleDeadlineMs }

    /// The composer's text changed. Text that trims to nothing is not typing.
    public func edit(_ conversationId: String, text: String, nowMs: Int) -> [FlareTypingReport] {
        var out = tick(nowMs)
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || conversationId.isEmpty {
            out.append(contentsOf: stop(at: nowMs))
            return out
        }
        if activeId != conversationId {
            out.append(contentsOf: stop(at: nowMs))
            activeId = conversationId
            lastTrueAtMs = nowMs
            out.append(FlareTypingReport(conversationId: conversationId, typing: true, atMs: nowMs))
        } else if nowMs - lastTrueAtMs >= FlareTyping.refreshMs {
            lastTrueAtMs = nowMs
            out.append(FlareTypingReport(conversationId: conversationId, typing: true, atMs: nowMs))
        }
        idleDeadlineMs = nowMs + FlareTyping.idleStopMs
        return out
    }

    /// The message went out. It says more than the signal does, so typing ends with it.
    public func send(_ conversationId: String, nowMs: Int) -> [FlareTypingReport] {
        tick(nowMs) + stop(at: nowMs)
    }

    /// The reader left the conversation, the screen or the app.
    public func close(nowMs: Int) -> [FlareTypingReport] {
        tick(nowMs) + stop(at: nowMs)
    }

    /// Time passed. Fires the idle stop at its deadline, not at `nowMs`, so a late tick still reports on time.
    public func tick(_ nowMs: Int) -> [FlareTypingReport] {
        guard !activeId.isEmpty, nowMs >= idleDeadlineMs else { return [] }
        return stop(at: idleDeadlineMs)
    }

    private func stop(at atMs: Int) -> [FlareTypingReport] {
        guard !activeId.isEmpty else { return [] }
        let conversationId = activeId
        activeId = ""
        idleDeadlineMs = 0
        return [FlareTypingReport(conversationId: conversationId, typing: false, atMs: atMs)]
    }
}

/// What this client believes about its peers — the receiving half of the same rule.
///
/// Facts in (someone started, someone stopped, the server listed everyone typing, a message arrived from a
/// typer), the people typing in a conversation out, in the order they started. Nothing here knows a wire
/// shape: the app parses its own events and calls these, which is the boundary the kit is not allowed to
/// cross. A belief expires `FlareTyping.peerTtlMs` after the signal that made it, so a client that dies
/// mid-sentence does not leave a peer typing forever.
///
/// Two of five apps had this, with two different expiries and two different sets of facts — one of them
/// only ever heard "someone started", so a server listing of who is typing did nothing — and three apps had
/// no idea a peer could be typing at all. Tested against the `roster` half of `spec/typing-vectors.json`.
public final class FlareTypingRoster {
    /// conversationId → the people typing there, in the order they started, each with its expiry.
    private var state: [String: [(userId: String, expiresAt: Int)]] = [:]
    private let selfId: String

    /// `selfId` never appears among the typers: this client's own signal is not news to itself.
    public init(selfId: String = "") { self.selfId = selfId }

    /// Someone began typing in a conversation.
    public func started(_ conversationId: String, userId: String, nowMs: Int) {
        guard !conversationId.isEmpty, !userId.isEmpty, userId != selfId else { return }
        var users = state[conversationId] ?? []
        let expiresAt = nowMs + FlareTyping.peerTtlMs
        if let index = users.firstIndex(where: { $0.userId == userId }) {
            users[index].expiresAt = expiresAt
        } else {
            users.append((userId: userId, expiresAt: expiresAt))
        }
        state[conversationId] = users
    }

    /// Someone stopped — an explicit signal, believed at once.
    public func stopped(_ conversationId: String, userId: String) {
        guard var users = state[conversationId], let index = users.firstIndex(where: { $0.userId == userId }) else { return }
        users.remove(at: index)
        if users.isEmpty { state.removeValue(forKey: conversationId) } else { state[conversationId] = users }
    }

    /// The server listed everyone typing in a conversation: that listing is the whole truth for it.
    public func replaced(_ conversationId: String, userIds: [String], nowMs: Int) {
        guard !conversationId.isEmpty else { return }
        let kept = userIds.filter { !$0.isEmpty && $0 != selfId }
        guard !kept.isEmpty else {
            state.removeValue(forKey: conversationId)
            return
        }
        state[conversationId] = kept.map { (userId: $0, expiresAt: nowMs + FlareTyping.peerTtlMs) }
    }

    /// A message arrived. It says more than the signal did, so its sender is no longer typing.
    public func sent(_ conversationId: String, senderId: String) { stopped(conversationId, userId: senderId) }

    /// Drops every belief whose time has run out. Hosts call it on a timer armed from `nextExpiry`.
    public func prune(_ nowMs: Int) {
        for (conversationId, users) in state {
            let kept = users.filter { $0.expiresAt > nowMs }
            if kept.isEmpty { state.removeValue(forKey: conversationId) } else { state[conversationId] = kept }
        }
    }

    /// Who is typing in a conversation, in the order they started.
    public func typers(_ conversationId: String) -> [String] { (state[conversationId] ?? []).map(\.userId) }

    /// When the soonest belief runs out, or nil when nothing is typing.
    public var nextExpiry: Int? { state.values.flatMap { $0 }.map(\.expiresAt).min() }

    /// Forgets everything — signing out, or switching account.
    public func clear() { state.removeAll() }
}

/// The names a typing indicator shows. A typer the roster has but the directory has not introduced yet
/// falls back to `fallback` — the conversation's own name in a 1:1, a generic "member" word in a group —
/// because a raw id is never shown to a reader. An empty fallback drops the unnamed typer instead.
public func flareTypingNames(
    _ userIds: [String],
    nameOf: (String) -> String,
    fallback: String
) -> [String] {
    userIds.map { nameOf($0).isEmpty ? fallback : nameOf($0) }.filter { !$0.isEmpty }
}
