import type { FlareConnectionPhase } from "./connectionNotice";

/**
 * What a client owes the server when the connection comes back.
 *
 * The rule is shared with the Flutter, SwiftUI and Compose kits and tested against
 * `spec/reconnect-refresh-vectors.json`. It lives here rather than in each app because a gap is not just
 * a pause and all five apps were treating it as one: they subscribe and read when the conversation list
 * loads and when a chat opens, and a reconnect is neither — so a peer who went offline during the gap
 * stayed "online" on screen until something else happened to reload the list.
 *
 * Three different things go wrong across a gap, and they need three different answers:
 * - a belief formed before it may be stale (the peer who stopped typing never got to say so);
 * - a server-side watch dies with the stream that carried it (presence is a gRPC stream);
 * - a change that happened during the gap was never delivered, and a subscription only promises the next one.
 *
 * The case that must *not* refresh is a session that ended. Being kicked or having the token expire is
 * terminal — the core does not reconnect by design — so asking the server to watch things again is work
 * for a session that no longer exists.
 */
export interface FlareReconnectWork {
  /** Forget what could have gone stale unobserved — the typing roster above all. */
  dropStaleBeliefs: boolean;
  /** Ask the server again for what it was watching for us. */
  resubscribe: boolean;
  /** Read the current value of what is on screen: a subscription says nothing about the change you missed. */
  reread: boolean;
}

const NOTHING: FlareReconnectWork = { dropStaleBeliefs: false, resubscribe: false, reread: false };

/** True for a phase the core will not come back from on its own. */
function isTerminal(phase: FlareConnectionPhase): boolean {
  return phase === "kicked" || phase === "expired";
}

export class FlareConnectionRefresh {
  private previous: FlareConnectionPhase | null = null;
  private hasBeenConnected = false;
  private interrupted = false;

  /** The connection phase changed. Answers the work this transition creates. */
  observe(phase: FlareConnectionPhase): FlareReconnectWork {
    if (phase === this.previous) return NOTHING;
    this.previous = phase;

    if (isTerminal(phase)) {
      // A session that ended is not an interruption to recover from: it is over. Forgetting that this
      // client was ever connected is what makes the next `connected` a fresh start — the app's own open
      // path does the work then, exactly as on a cold start, and nothing re-subscribes on the way out.
      this.interrupted = false;
      this.hasBeenConnected = false;
      return { dropStaleBeliefs: true, resubscribe: false, reread: false };
    }

    if (phase === "connected") {
      if (this.hasBeenConnected && this.interrupted) {
        this.interrupted = false;
        return { dropStaleBeliefs: false, resubscribe: true, reread: true };
      }
      this.hasBeenConnected = true;
      return NOTHING;
    }

    // connecting / reconnecting / offline / disconnected
    if (!this.hasBeenConnected || this.interrupted) return NOTHING;
    this.interrupted = true;
    return { dropStaleBeliefs: true, resubscribe: false, reread: false };
  }
}
