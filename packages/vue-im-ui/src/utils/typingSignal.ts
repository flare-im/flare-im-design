/**
 * What this client tells a conversation about its own typing.
 *
 * The rule is shared with the Flutter, SwiftUI and Compose kits and tested against the `signal` half of
 * `spec/typing-vectors.json`. It lives here rather than in each app because all five were writing it, and
 * writing it differently: the pause that ends typing was 3000, 2800, 1500, 1500 and — on iOS — never, two
 * apps re-reported `true` on every keystroke, and the two that deduplicated the report never refreshed it,
 * so a message that took longer than the peer's belief to write stopped showing as typing while it was
 * still being typed.
 *
 * The engine is a state machine with the clock passed in, not read: the same script must produce the same
 * reports on four platforms, and a rule that reads `Date.now()` cannot be tested at all.
 */

/** A pause this long after the last edit ends typing. */
export const flareTypingIdleStopMs = 4000;
/** `typing: true` is reported at most this often while the user keeps typing. */
export const flareTypingRefreshMs = 2500;
/** How long a peer stays "typing" on this belief without a fresh signal (the receiving half of the rule). */
export const flareTypingPeerTtlMs = 6000;

export interface FlareTypingReport {
  conversationId: string;
  typing: boolean;
  /**
   * The instant the report is for. Usually the `nowMs` handed in, but an idle stop is timestamped at its
   * deadline, so a host whose timer fired late still reports the moment typing actually ended — and the
   * shared table can assert *when*, not only *what*.
   */
  atMs: number;
}

/**
 * One conversation types at a time: the composer is one control, so an edit somewhere else ends the
 * previous conversation before it starts the new one. Every method answers with the reports to send, in
 * order — the caller does the sending, and a send that fails is not this rule's business.
 */
export class FlareTypingSignal {
  private activeId = "";
  private lastTrueAtMs = 0;
  private idleDeadlineMs = 0;

  /** The conversation currently reported as typing, or "" when none is. */
  get typingConversationId(): string {
    return this.activeId;
  }

  /** When the idle stop is due, or null when nothing is typing. Hosts arm a timer on it. */
  get idleDeadline(): number | null {
    return this.activeId ? this.idleDeadlineMs : null;
  }

  /** The composer's text changed. Text that trims to nothing is not typing. */
  edit(conversationId: string, text: string, nowMs: number): FlareTypingReport[] {
    const out = this.tick(nowMs);
    if (!text.trim() || !conversationId) return [...out, ...this.stop(nowMs)];
    if (this.activeId !== conversationId) {
      out.push(...this.stop(nowMs));
      this.activeId = conversationId;
      this.lastTrueAtMs = nowMs;
      out.push({ conversationId, typing: true, atMs: nowMs });
    } else if (nowMs - this.lastTrueAtMs >= flareTypingRefreshMs) {
      this.lastTrueAtMs = nowMs;
      out.push({ conversationId, typing: true, atMs: nowMs });
    }
    this.idleDeadlineMs = nowMs + flareTypingIdleStopMs;
    return out;
  }

  /** The message went out. It says more than the signal does, so typing ends with it. */
  send(_conversationId: string, nowMs: number): FlareTypingReport[] {
    return [...this.tick(nowMs), ...this.stop(nowMs)];
  }

  /** The reader left the conversation, the screen or the app. */
  close(nowMs: number): FlareTypingReport[] {
    return [...this.tick(nowMs), ...this.stop(nowMs)];
  }

  /** Time passed. Fires the idle stop at its deadline, not at `nowMs`, so a late tick still reports on time. */
  tick(nowMs: number): FlareTypingReport[] {
    if (!this.activeId || nowMs < this.idleDeadlineMs) return [];
    return this.stop(this.idleDeadlineMs);
  }

  private stop(atMs: number): FlareTypingReport[] {
    if (!this.activeId) return [];
    const conversationId = this.activeId;
    this.activeId = "";
    this.idleDeadlineMs = 0;
    return [{ conversationId, typing: false, atMs }];
  }
}

/**
 * What this client believes about its peers — the receiving half of the same rule.
 *
 * Facts in (someone started, someone stopped, the server listed everyone typing, a message arrived from a
 * typer), the people typing in a conversation out, in the order they started. Nothing here knows a wire
 * shape: the app parses its own events and calls these, which is the boundary the kit is not allowed to
 * cross. A belief expires `flareTypingPeerTtlMs` after the signal that made it, so a client that dies
 * mid-sentence does not leave a peer typing forever.
 *
 * Two of five apps had this, with two different expiries and two different sets of facts — one of them
 * only ever heard "someone started", so a server listing of who is typing did nothing — and three apps had
 * no idea a peer could be typing at all. Tested against the `roster` half of `spec/typing-vectors.json`.
 */
export class FlareTypingRoster {
  /** conversationId → (userId → the instant this belief expires), insertion-ordered by when they started. */
  private readonly state = new Map<string, Map<string, number>>();

  /** `selfId` never appears among the typers: this client's own signal is not news to itself. */
  constructor(private readonly selfId = "") {}

  /** Someone began typing in a conversation. */
  started(conversationId: string, userId: string, nowMs: number): void {
    if (!conversationId || !userId || userId === this.selfId) return;
    const users = this.state.get(conversationId) ?? new Map<string, number>();
    users.set(userId, nowMs + flareTypingPeerTtlMs);
    this.state.set(conversationId, users);
  }

  /** Someone stopped — an explicit signal, believed at once. */
  stopped(conversationId: string, userId: string): void {
    const users = this.state.get(conversationId);
    if (!users?.delete(userId)) return;
    if (!users.size) this.state.delete(conversationId);
  }

  /** The server listed everyone typing in a conversation: that listing is the whole truth for it. */
  replaced(conversationId: string, userIds: readonly string[], nowMs: number): void {
    if (!conversationId) return;
    const kept = userIds.filter((id) => id && id !== this.selfId);
    if (!kept.length) {
      this.state.delete(conversationId);
      return;
    }
    const users = new Map<string, number>();
    for (const id of kept) users.set(id, nowMs + flareTypingPeerTtlMs);
    this.state.set(conversationId, users);
  }

  /** A message arrived. It says more than the signal did, so its sender is no longer typing. */
  sent(conversationId: string, senderId: string): void {
    this.stopped(conversationId, senderId);
  }

  /** Drops every belief whose time has run out. Hosts call it on a timer armed from `nextExpiry`. */
  prune(nowMs: number): void {
    for (const [conversationId, users] of [...this.state]) {
      for (const [userId, expiresAt] of [...users]) if (expiresAt <= nowMs) users.delete(userId);
      if (!users.size) this.state.delete(conversationId);
    }
  }

  /** Who is typing in a conversation, in the order they started. */
  typers(conversationId: string): string[] {
    return [...(this.state.get(conversationId)?.keys() ?? [])];
  }

  /** When the soonest belief runs out, or null when nothing is typing. */
  get nextExpiry(): number | null {
    let next: number | null = null;
    for (const users of this.state.values()) {
      for (const expiresAt of users.values()) next = next === null ? expiresAt : Math.min(next, expiresAt);
    }
    return next;
  }

  /** Forgets everything — signing out, or switching account. */
  clear(): void {
    this.state.clear();
  }
}

/**
 * The names a typing indicator shows. A typer the roster has but the directory has not introduced yet
 * falls back to `fallback` — the conversation's own name in a 1:1, a generic "member" word in a group —
 * because a raw id is never shown to a reader. An empty fallback drops the unnamed typer instead.
 */
export function flareTypingNames(
  userIds: readonly string[],
  nameOf: (userId: string) => string,
  fallback: string,
): string[] {
  return userIds.map((userId) => nameOf(userId) || fallback).filter((name) => name.length > 0);
}
