// Your own "backend" — a plain reactive in-memory store. No Flare core, no SDK:
// the UI components only take props and emit events, so any data source works.
import { reactive } from "vue";

export type Msg = { id: string; self: boolean; type: "text" | "image"; text?: string; src?: string };
export type Conv = {
  id: string;
  displayName: string;
  avatarUrl?: string;
  lastMessagePreview?: string;
  unreadCount?: number;
  updatedAt?: number;
};

let seq = 100;
const now = Date.now();

export const backend = reactive({
  me: "me",
  activeId: "c1",
  conversations: [
    { id: "c1", displayName: "Henry Ford", lastMessagePreview: "Taking a look now 👍", updatedAt: now - 3e5 },
    { id: "c2", displayName: "Design Team", lastMessagePreview: "Ivy: shipped the new build", unreadCount: 2, updatedAt: now - 9e5 },
    { id: "c3", displayName: "Kai Wang", lastMessagePreview: "Let's sync tomorrow", updatedAt: now - 864e5 },
  ] as Conv[],
  threads: {
    c1: [
      { id: "m1", self: false, type: "text", text: "Hey — did the new build go out?" },
      { id: "m2", self: true, type: "text", text: "Yep, just shipped. Notes are on flare.im" },
      { id: "m3", self: false, type: "text", text: "Nice, taking a look now 👍" },
    ],
    c2: [{ id: "m4", self: false, type: "text", text: "shipped the new build" }],
    c3: [{ id: "m5", self: true, type: "text", text: "Let's sync tomorrow" }],
  } as Record<string, Msg[]>,

  get active(): Conv | undefined {
    return this.conversations.find((c) => c.id === this.activeId);
  },
  get messages(): Msg[] {
    return this.threads[this.activeId] ?? [];
  },
  select(id: string): void {
    this.activeId = id;
    const c = this.conversations.find((x) => x.id === id);
    if (c) c.unreadCount = 0;
  },
  send(text: string): void {
    (this.threads[this.activeId] ??= []).push({ id: `m${++seq}`, self: true, type: "text", text });
    const c = this.active;
    if (c) {
      c.lastMessagePreview = text;
      c.updatedAt = Date.now();
    }
    // Simulate a reply coming back from your backend.
    const target = this.activeId;
    setTimeout(() => {
      (this.threads[target] ??= []).push({ id: `m${++seq}`, self: false, type: "text", text: "Got it — thanks!" });
      const conv = this.conversations.find((x) => x.id === target);
      if (conv) conv.lastMessagePreview = "Got it — thanks!";
    }, 900);
  },
});
