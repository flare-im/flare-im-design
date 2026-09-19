import Foundation

/// What a client owes the server when the connection comes back.
///
/// The rule is shared with the Vue, Flutter and Compose kits and tested against
/// `spec/reconnect-refresh-vectors.json`. It lives here rather than in each app because a gap is not just
/// a pause and all five apps were treating it as one: they subscribe and read when the conversation list
/// loads and when a chat opens, and a reconnect is neither — so a peer who went offline during the gap
/// stayed "online" on screen until something else happened to reload the list.
///
/// Three different things go wrong across a gap, and they need three different answers:
/// - a belief formed before it may be stale (the peer who stopped typing never got to say so);
/// - a server-side watch dies with the stream that carried it (presence is a gRPC stream);
/// - a change that happened during the gap was never delivered, and a subscription only promises the next.
///
/// The case that must *not* refresh is a session that ended. Being kicked or having the token expire is
/// terminal — the core does not reconnect by design — so asking the server to watch things again is work
/// for a session that no longer exists.
public struct FlareReconnectWork: Equatable, Sendable {
    /// Forget what could have gone stale unobserved — the typing roster above all.
    public let dropStaleBeliefs: Bool
    /// Ask the server again for what it was watching for us.
    public let resubscribe: Bool
    /// Read the current value of what is on screen: a subscription says nothing about the change you missed.
    public let reread: Bool

    public init(dropStaleBeliefs: Bool, resubscribe: Bool, reread: Bool) {
        self.dropStaleBeliefs = dropStaleBeliefs
        self.resubscribe = resubscribe
        self.reread = reread
    }

    /// Whether this transition asks for anything at all.
    public var isEmpty: Bool { !dropStaleBeliefs && !resubscribe && !reread }

    public static let none = FlareReconnectWork(dropStaleBeliefs: false, resubscribe: false, reread: false)
}

public final class FlareConnectionRefresh {
    private var previous: FlareConnectionPhase?
    private var hasBeenConnected = false
    private var interrupted = false

    public init() {}

    /// The connection phase changed. Answers the work this transition creates.
    public func observe(_ phase: FlareConnectionPhase) -> FlareReconnectWork {
        guard phase != previous else { return .none }
        previous = phase

        if phase == .kicked || phase == .expired {
            // A session that ended is not an interruption to recover from: it is over. Forgetting that
            // this client was ever connected is what makes the next `connected` a fresh start — the app's
            // own open path does the work then, exactly as on a cold start, and nothing re-subscribes on
            // the way out.
            interrupted = false
            hasBeenConnected = false
            return FlareReconnectWork(dropStaleBeliefs: true, resubscribe: false, reread: false)
        }

        if phase == .connected {
            if hasBeenConnected, interrupted {
                interrupted = false
                return FlareReconnectWork(dropStaleBeliefs: false, resubscribe: true, reread: true)
            }
            hasBeenConnected = true
            return .none
        }

        // connecting / reconnecting / offline / disconnected
        guard hasBeenConnected, !interrupted else { return .none }
        interrupted = true
        return FlareReconnectWork(dropStaleBeliefs: true, resubscribe: false, reread: false)
    }
}
