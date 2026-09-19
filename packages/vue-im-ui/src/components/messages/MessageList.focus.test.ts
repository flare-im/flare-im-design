// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { h, nextTick, type Component } from "vue";
import { describe, expect, it } from "vitest";
import FlareUiProvider from "../../design-system/provider/FlareUiProvider.vue";
import type { MessageLike } from "../../shared/contracts/messageRow";
import MessageBubble from "./MessageBubble.vue";
import MessageList from "./MessageList.vue";

function message(id: string, senderId: string, minute: number, extra: Partial<MessageLike> = {}): MessageLike {
  const createdAt = 1_736_922_600_000 + minute * 60_000;
  return {
    serverId: `server-${id}`, clientMsgId: `client-${id}`, senderId, senderDisplayName: senderId,
    conversationSeq: minute, createdAt, clientCreatedAt: createdAt, messageType: 1,
    content: { contentType: "text", text: `message ${id}` }, status: "read", isRecalled: false, isRead: true,
    timelineKey: `server:server-${id}`, timelineSortTs: createdAt, attributes: {}, ...extra,
  };
}

const listeners = { onReply: () => {}, onReact: () => {}, onForward: () => {} };

function mountList(messages: MessageLike[]) {
  return mount(FlareUiProvider, {
    props: { themeMode: "light", locale: "en-US", layoutMode: "pc" },
    slots: { default: () => h(MessageList as Component, { messages, currentUserId: "me", hasOlder: false, ...listeners }) },
    attachTo: document.body,
  });
}

function tabStops(host: ReturnType<typeof mountList>): string[] {
  return host.findAll(".message-bubble--focusable")
    .filter((bubble) => bubble.attributes("tabindex") === "0")
    .map((bubble) => bubble.text());
}

describe("MessageList keyboard focus", () => {
  it("puts only the newest message that opens a menu in the Tab sequence", () => {
    const host = mountList([
      message("1", "ivy", 0),
      message("2", "me", 1),
      message("3", "ivy", 2, { isRecalled: true }),
    ]);
    expect(host.findAll(".message-bubble--focusable")).toHaveLength(2);
    expect(tabStops(host)).toEqual([expect.stringContaining("message 2")]);
    host.unmount();
  });

  it("moves between messages with the arrow keys, Home and End, and keeps the last one focused as the Tab stop", async () => {
    const host = mountList([message("1", "ivy", 0), message("2", "me", 1), message("3", "ivy", 2)]);
    const bubbles = () => host.findAll(".message-bubble--focusable");
    const newest = bubbles()[2].element as HTMLElement;
    newest.focus();
    await nextTick();

    await bubbles()[2].trigger("keydown", { key: "ArrowUp" });
    expect(document.activeElement).toBe(bubbles()[1].element);
    await nextTick();
    expect(tabStops(host)).toEqual([expect.stringContaining("message 2")]);

    await bubbles()[1].trigger("keydown", { key: "Home" });
    expect(document.activeElement).toBe(bubbles()[0].element);
    await bubbles()[0].trigger("keydown", { key: "ArrowUp" });
    expect(document.activeElement).toBe(bubbles()[0].element);
    await bubbles()[0].trigger("keydown", { key: "End" });
    expect(document.activeElement).toBe(newest);

    // Keys typed inside the message content, or with a modifier, are left alone.
    await bubbles()[2].trigger("keydown", { key: "ArrowUp", shiftKey: true });
    expect(document.activeElement).toBe(newest);
    host.unmount();
  });

  it("keeps a message's hover controls out of the Tab sequence until focus is inside that message", async () => {
    const host = mountList([message("1", "ivy", 0), message("2", "ivy", 1)]);
    const rows = host.findAllComponents(MessageBubble);
    const toolbarTabindexes = (index: number) => rows[index].findAll(".im-bar-btn").map((button) => button.attributes("tabindex"));
    expect(toolbarTabindexes(1).length).toBeGreaterThan(0);
    expect(toolbarTabindexes(1).every((value) => value === "-1")).toBe(true);

    (rows[1].get(".message-bubble--focusable").element as HTMLElement).focus();
    await nextTick();
    expect(toolbarTabindexes(1).every((value) => value === "0")).toBe(true);
    expect(toolbarTabindexes(0).every((value) => value === "-1")).toBe(true);

    (rows[1].get(".message-bubble--focusable").element as HTMLElement).blur();
    await nextTick();
    expect(toolbarTabindexes(1).every((value) => value === "-1")).toBe(true);
    host.unmount();
  });

  it("names a focused message by sender and time and describes it by its content", () => {
    const host = mountList([message("1", "ivy", 0)]);
    const bubble = host.get(".message-bubble--focusable");
    expect(bubble.attributes("role")).toBe("group");
    expect(bubble.attributes("aria-label")).toContain("ivy");
    const body = host.get(`#${bubble.attributes("aria-describedby")}`);
    expect(body.text()).toContain("message 1");
    host.unmount();
  });

  it("keeps a bubble outside a list in the Tab sequence", () => {
    const host = mount(FlareUiProvider, {
      props: { themeMode: "light", locale: "en-US", layoutMode: "pc" },
      slots: { default: () => h(MessageBubble as Component, { message: message("1", "ivy", 0), currentUserId: "me" }) },
    });
    expect(host.get(".message-bubble--focusable").attributes("tabindex")).toBe("0");
    host.unmount();
  });
});
