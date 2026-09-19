/**
 * When what someone typed and did not send is written down, and what it is written as.
 *
 * The rule is shared with the Flutter, SwiftUI and Compose kits and tested against
 * `spec/draft-vectors.json`. It lives here rather than in each app because all five were writing it, and
 * writing it to five different places with five different lifetimes: the web app saved to the core after
 * 1200 ms, so a draft roamed to another device; the Tauri app to `localStorage` after 450 ms, so it
 * survived a restart on that machine and nowhere else; the Android app to a map in memory, so it survived
 * switching conversations and nothing else; the Flutter and iOS apps did not save at all — leave the chat
 * and what you typed was gone. "Draft" meant four different things.
 *
 * The engine is a state machine with the clock passed in, not read, for the same reason the typing signal
 * is: the same script must produce the same writes on four platforms.
 */

/** A pause this long after the last edit writes the draft down. */
export const flareDraftSaveDelayMs = 1200;

/** One write this client owes the core. `text` of "" clears the conversation's draft. */
export interface FlareDraftSave {
  conversationId: string;
  text: string;
  /** The instant the write is for — the deadline when a pause triggered it, otherwise the moment it happened. */
  atMs: number;
}

/**
 * The text a send that reached nothing leaves behind: above whatever was typed while it was in flight,
 * and never twice. A failed send of nothing changes nothing.
 */
export function flareRestoredDraft(current: string, failed: string): string {
  const back = failed.trim();
  if (!back) return current;
  if (!current.trim()) return failed;
  if (current.includes(back)) return current;
  return `${failed}\n${current}`;
}

/** A draft that trims to nothing is stored as "", which is what clears it. */
function stored(text: string): string {
  return text.trim() ? text : "";
}

export class FlareDraftAutosave {
  private readonly saved = new Map<string, string>();
  private pending: { conversationId: string; text: string } | null = null;
  private deadlineMs = 0;

  /** What the core already holds for a conversation, so an unchanged draft is never written back. */
  seed(conversationId: string, text: string): void {
    if (!conversationId) return;
    this.saved.set(conversationId, stored(text));
  }

  /** The draft this client believes the core holds. */
  storedText(conversationId: string): string {
    return this.saved.get(conversationId) ?? "";
  }

  /** When the pending write is due, or null when none is. Hosts arm a timer on it. */
  get pendingDeadline(): number | null {
    return this.pending ? this.deadlineMs : null;
  }

  /** The composer's text changed. Editing a sent message is not this: the host does not report it here. */
  edit(conversationId: string, text: string, nowMs: number): FlareDraftSave[] {
    const out = this.tick(nowMs);
    if (!conversationId) return out;
    // Moving to another conversation writes the one being left before starting the new one.
    if (this.pending && this.pending.conversationId !== conversationId) out.push(...this.flush(nowMs));
    this.pending = { conversationId, text: stored(text) };
    this.deadlineMs = nowMs + flareDraftSaveDelayMs;
    return out;
  }

  /** The message went out: the draft it came from is gone, and any pending write with it. */
  send(conversationId: string, nowMs: number): FlareDraftSave[] {
    const out = this.tick(nowMs);
    if (this.pending?.conversationId === conversationId) this.pending = null;
    return [...out, ...this.write(conversationId, "", nowMs)];
  }

  /** The reader left the conversation, the screen or the app: write the pending draft now. */
  leave(nowMs: number): FlareDraftSave[] {
    return [...this.tick(nowMs), ...this.flush(nowMs)];
  }

  /**
   * A send that reached nothing. Its text goes back immediately, never on the timer: a draft lost to a
   * pending write is the one case where losing it is unforgivable.
   */
  restore(conversationId: string, failedText: string, nowMs: number): FlareDraftSave[] {
    const out = this.tick(nowMs);
    if (!conversationId) return out;
    if (this.pending?.conversationId === conversationId) this.pending = null;
    return [...out, ...this.write(conversationId, flareRestoredDraft(this.storedText(conversationId), failedText), nowMs)];
  }

  /** Time passed. Fires the pending write at its deadline, not at `nowMs`. */
  tick(nowMs: number): FlareDraftSave[] {
    if (!this.pending || nowMs < this.deadlineMs) return [];
    return this.flush(this.deadlineMs);
  }

  private flush(atMs: number): FlareDraftSave[] {
    const pending = this.pending;
    if (!pending) return [];
    this.pending = null;
    this.deadlineMs = 0;
    return this.write(pending.conversationId, pending.text, atMs);
  }

  private write(conversationId: string, text: string, atMs: number): FlareDraftSave[] {
    if (!conversationId) return [];
    const next = stored(text);
    if (this.storedText(conversationId) === next) return [];
    this.saved.set(conversationId, next);
    return [{ conversationId, text: next, atMs }];
  }
}
