package com.flare.im.ui

/**
 * What a client owes the server when the connection comes back.
 *
 * The rule is shared with the Vue, Flutter and SwiftUI kits and tested against
 * `spec/reconnect-refresh-vectors.json`. It lives here rather than in each app because a gap is not just a
 * pause and all five apps were treating it as one: they subscribe and read when the conversation list
 * loads and when a chat opens, and a reconnect is neither — so a peer who went offline during the gap
 * stayed "online" on screen until something else happened to reload the list.
 *
 * Three different things go wrong across a gap, and they need three different answers:
 * - a belief formed before it may be stale (the peer who stopped typing never got to say so);
 * - a server-side watch dies with the stream that carried it (presence is a gRPC stream);
 * - a change that happened during the gap was never delivered, and a subscription only promises the next.
 *
 * The case that must *not* refresh is a session that ended. Being kicked or having the token expire is
 * terminal — the core does not reconnect by design — so asking the server to watch things again is work
 * for a session that no longer exists.
 */

/**
 * The work one connection transition creates: [dropStaleBeliefs] forgets what could have gone stale
 * unobserved, [resubscribe] asks the server again for what it was watching, [reread] reads the current
 * value of what is on screen.
 */
data class FlareReconnectWork(
    val dropStaleBeliefs: Boolean,
    val resubscribe: Boolean,
    val reread: Boolean,
) {
    /** Whether this transition asks for anything at all. */
    val isEmpty: Boolean get() = !dropStaleBeliefs && !resubscribe && !reread

    companion object {
        val None = FlareReconnectWork(dropStaleBeliefs = false, resubscribe = false, reread = false)
    }
}

class FlareConnectionRefresh {
    private var previous: FlareConnectionPhase? = null
    private var hasBeenConnected = false
    private var interrupted = false

    /** The connection phase changed. Answers the work this transition creates. */
    fun observe(phase: FlareConnectionPhase): FlareReconnectWork {
        if (phase == previous) return FlareReconnectWork.None
        previous = phase

        if (phase == FlareConnectionPhase.Kicked || phase == FlareConnectionPhase.Expired) {
            // A session that ended is not an interruption to recover from: it is over. Forgetting that
            // this client was ever connected is what makes the next `Connected` a fresh start — the app's
            // own open path does the work then, exactly as on a cold start, and nothing re-subscribes on
            // the way out.
            interrupted = false
            hasBeenConnected = false
            return FlareReconnectWork(dropStaleBeliefs = true, resubscribe = false, reread = false)
        }

        if (phase == FlareConnectionPhase.Connected) {
            if (hasBeenConnected && interrupted) {
                interrupted = false
                return FlareReconnectWork(dropStaleBeliefs = false, resubscribe = true, reread = true)
            }
            hasBeenConnected = true
            return FlareReconnectWork.None
        }

        // Connecting / Reconnecting / Offline / Disconnected
        if (!hasBeenConnected || interrupted) return FlareReconnectWork.None
        interrupted = true
        return FlareReconnectWork(dropStaleBeliefs = true, resubscribe = false, reread = false)
    }
}
