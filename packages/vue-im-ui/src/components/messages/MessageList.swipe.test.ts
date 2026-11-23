// @vitest-environment happy-dom
import { flushPromises, mount } from "@vue/test-utils";
import { h, type Component } from "vue";
import { afterEach, describe, expect, it } from "vitest";
import FlareUiProvider from "../../design-system/provider/FlareUiProvider.vue";
import type { MessageLike } from "../../shared/contracts/messageRow";
import MessageBubble from "./MessageBubble.vue";
import MessageList from "./MessageList.vue";

// Swipe to reply (spec/swipe-reply-vectors.json), as Flutter's onSwipeReply: a touch drag of a row towards the
// trailing edge follows the finger, and letting go past 56 raises `swipeReply` with the row's id. Only while the host
// listens, never for a notice, and never while selecting.
function message(id: string, minute: number, extra: Partial<MessageLike> = {}): MessageLike {
  const createdAt = 1_736_922_600_000 + minute * 60_000;
  return {
    serverId: `server-${id}`, clientMsgId: `client-${id}`, senderId: "ivy", senderDisplayName: "Ivy",
    conversationSeq: minute, createdAt, clientCreatedAt: createdAt, messageType: 1,
    content: { contentType: "text", text: `Message ${id}` }, status: "read", isRecalled: false, isRead: true,
    timelineKey: `server:server-${id}`, timelineSortTs: createdAt, attributes: {}, ...extra,
  };
}

const rows = [message("1", 0), message("2", 1, { isRecalled: true })];
const mounted: Array<{ unmount(): void }> = [];
afterEach(() => { mounted.splice(0).forEach((wrapper) => wrapper.unmount()); document.body.innerHTML = ""; });

function mountList(props: Record<string, unknown>) {
  const host = mount(FlareUiProvider, {
    props: { themeMode: "light", locale: "en-US", layoutMode: "h5" },
    slots: { default: () => h(MessageList as Component, { currentUserId: "me", hasOlder: false, messages: rows, ...props }) },
    attachTo: document.body,
  });
  mounted.push(host);
  return host;
}

function touch(target: Element, type: string, x: number, y: number): void {
  const point = { identifier: 1, target, clientX: x, clientY: y, pageX: x, pageY: y, screenX: x, screenY: y };
  const event = new Event(type, { bubbles: true, cancelable: true }) as Event & Record<string, unknown>;
  const list = type === "touchend" || type === "touchcancel" ? [] : [point];
  Object.defineProperty(event, "touches", { value: list });
  Object.defineProperty(event, "changedTouches", { value: [point] });
  target.dispatchEvent(event);
}

function swipe(target: Element, dx: number, dy = 0, end = "touchend"): void {
  touch(target, "touchstart", 100, 300);
  touch(target, "touchmove", 100 + dx / 2, 300 + dy / 2);
  touch(target, "touchmove", 100 + dx, 300 + dy);
  touch(target, end, 100 + dx, 300 + dy);
}

const row = (host: ReturnType<typeof mountList>, id: string) => host.get(`.message-row[data-message-id="${id}"]`);

describe("MessageList swipe to reply", () => {
  it("replies to a row dragged past the arming distance", async () => {
    const replies: string[] = [];
    const host = mountList({ onSwipeReply: (id: string) => replies.push(id) });
    await flushPromises();
    const bubble = row(host, "server-1").get(".message-bubble").element;
    touch(bubble, "touchstart", 100, 300);
    touch(bubble, "touchmove", 196, 300);
    await flushPromises();
    // The row follows the finger with resistance past 56 (96 → 70), and the glyph is drawn in full.
    expect((row(host, "server-1").element as HTMLElement).style.transform).toBe("translateX(70px)");
    expect(host.get("[data-swipe-reply-affordance]").attributes("style")).toContain("opacity: 1");
    touch(bubble, "touchend", 196, 300);
    await flushPromises();
    expect(replies).toEqual(["server-1"]);
    expect((row(host, "server-1").element as HTMLElement).style.transform).toBe("");
    expect(host.find("[data-swipe-reply-affordance]").exists()).toBe(false);
  });

  it("does nothing for a short drag, a trailing drag, a mostly vertical drag or a cancelled touch", async () => {
    const replies: string[] = [];
    const host = mountList({ onSwipeReply: (id: string) => replies.push(id) });
    await flushPromises();
    const bubble = row(host, "server-1").get(".message-bubble").element;
    swipe(bubble, 40);
    swipe(bubble, -90);
    swipe(bubble, 60, 50);
    swipe(bubble, 90, 0, "touchcancel");
    await flushPromises();
    expect(replies).toEqual([]);
  });

  it("leaves notices, selection and hosts without the listener alone", async () => {
    const replies: string[] = [];
    const host = mountList({ onSwipeReply: (id: string) => replies.push(id) });
    await flushPromises();
    swipe(row(host, "server-2").element, 90);
    const selecting = mountList({ multiSelectMode: true, onSwipeReply: (id: string) => replies.push(`selecting ${id}`) });
    await flushPromises();
    swipe(row(selecting, "server-1").element, 90);
    await flushPromises();
    expect(replies).toEqual([]);

    const plain = mountList({});
    await flushPromises();
    swipe(row(plain, "server-1").get(".message-bubble").element, 90);
    expect((row(plain, "server-1").element as HTMLElement).style.transform).toBe("");
    expect(plain.find(".message-list--swipe-reply").exists()).toBe(false);
    expect(host.find(".message-list--swipe-reply").exists()).toBe(true);
  });

  it("offers Reply in the menu through the swipe intent when only the swipe is taken", async () => {
    const replies: string[] = [];
    const host = mountList({ onSwipeReply: (id: string) => replies.push(id) });
    await flushPromises();
    const bubble = host.findComponent(MessageBubble);
    expect(bubble.props("menuConfig")?.actions).toMatchObject({ reply: true });
    bubble.vm.$emit("reply", "server-1");
    expect(replies).toEqual(["server-1"]);

    const both: string[] = [];
    const withReply = mountList({ onSwipeReply: () => both.push("swipe"), onReply: () => both.push("reply") });
    await flushPromises();
    withReply.findComponent(MessageBubble).vm.$emit("reply", "server-1");
    expect(both).toEqual(["reply"]);
  });
});
