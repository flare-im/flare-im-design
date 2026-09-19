/// What a client owes the server when the connection comes back.
///
/// The rule is shared with the Vue, SwiftUI and Compose kits and tested against
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
library;

import 'connection_notice.dart';

/// The work one connection transition creates.
class FlareReconnectWork {
  const FlareReconnectWork({
    required this.dropStaleBeliefs,
    required this.resubscribe,
    required this.reread,
  });

  /// Forget what could have gone stale unobserved — the typing roster above all.
  final bool dropStaleBeliefs;

  /// Ask the server again for what it was watching for us.
  final bool resubscribe;

  /// Read the current value of what is on screen: a subscription says nothing about the change you missed.
  final bool reread;

  /// Whether this transition asks for anything at all.
  bool get isEmpty => !dropStaleBeliefs && !resubscribe && !reread;

  static const none = FlareReconnectWork(dropStaleBeliefs: false, resubscribe: false, reread: false);

  @override
  bool operator ==(Object other) =>
      other is FlareReconnectWork &&
      other.dropStaleBeliefs == dropStaleBeliefs &&
      other.resubscribe == resubscribe &&
      other.reread == reread;

  @override
  int get hashCode => Object.hash(dropStaleBeliefs, resubscribe, reread);

  @override
  String toString() => 'FlareReconnectWork(drop: $dropStaleBeliefs, resubscribe: $resubscribe, reread: $reread)';
}

class FlareConnectionRefresh {
  FlareConnectionPhase? _previous;
  bool _hasBeenConnected = false;
  bool _interrupted = false;

  /// The connection phase changed. Answers the work this transition creates.
  FlareReconnectWork observe(FlareConnectionPhase phase) {
    if (phase == _previous) return FlareReconnectWork.none;
    _previous = phase;

    if (phase == FlareConnectionPhase.kicked || phase == FlareConnectionPhase.expired) {
      // A session that ended is not an interruption to recover from: it is over. Forgetting that this
      // client was ever connected is what makes the next `connected` a fresh start — the app's own open
      // path does the work then, exactly as on a cold start, and nothing re-subscribes on the way out.
      _interrupted = false;
      _hasBeenConnected = false;
      return const FlareReconnectWork(dropStaleBeliefs: true, resubscribe: false, reread: false);
    }

    if (phase == FlareConnectionPhase.connected) {
      if (_hasBeenConnected && _interrupted) {
        _interrupted = false;
        return const FlareReconnectWork(dropStaleBeliefs: false, resubscribe: true, reread: true);
      }
      _hasBeenConnected = true;
      return FlareReconnectWork.none;
    }

    // connecting / reconnecting / offline / disconnected
    if (!_hasBeenConnected || _interrupted) return FlareReconnectWork.none;
    _interrupted = true;
    return const FlareReconnectWork(dropStaleBeliefs: true, resubscribe: false, reread: false);
  }
}
