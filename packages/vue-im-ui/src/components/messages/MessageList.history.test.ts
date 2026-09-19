// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { h, nextTick, ref, type Component } from "vue";
import { afterEach, describe, expect, it, vi } from "vitest";
import FlareUiProvider from "../../design-system/provider/FlareUiProvider.vue";
import type { MessageLike } from "../../shared/contracts/messageRow";
import MessageList from "./MessageList.vue";

function message(id: string, senderId: string, minute: number): MessageLike {
  const createdAt = 1_736_922_600_000 + minute * 60_000;
  return {
    serverId: `server-${id}`, clientMsgId: `client-${id}`, senderId, senderDisplayName: senderId,
    conversationSeq: minute, createdAt, clientCreatedAt: createdAt, messageType: 1,
    content: { contentType: "text", text: `message ${id}` }, status: "read", isRecalled: false, isRead: true,
    timelineKey: `server:server-${id}`, timelineSortTs: createdAt, attributes: {},
  };
}

const timeline = [message("1", "ivy", 0), message("2", "me", 1), message("3", "ivy", 2)];

/** Mounts a timeline whose scroller either overflows (a long history) or fits on screen, with older pages still to load. */
function mountHistory(overflows: boolean) {
  const hasOlder = ref(true);
  const host = mount(FlareUiProvider, {
    props: { themeMode: "light", locale: "en-US", layoutMode: "pc" },
    slots: { default: () => h(MessageList as Component, { currentUserId: "me", messages: timeline, hasOlder: hasOlder.value }) },
  });
  const scroller = host.get(".message-list").element as HTMLElement;
  Object.defineProperty(scroller, "clientHeight", { configurable: true, value: 400 });
  Object.defineProperty(scroller, "scrollHeight", { configurable: true, value: overflows ? 2000 : 400 });
  return { host, hasOlder };
}

afterEach(() => {
  vi.useRealTimers();
});

describe("MessageList start of history", () => {
  it("tells a reader at the top of a long history that nothing older exists, then clears the first date", async () => {
    vi.useFakeTimers();
    const { host, hasOlder } = mountHistory(true);
    hasOlder.value = false;
    await nextTick();
    await nextTick();
    expect(host.get(".message-list-history-end").text()).toBe("No earlier messages");
    vi.advanceTimersByTime(2400);
    await nextTick();
    expect(host.find(".message-list-history-end").exists()).toBe(false);
    host.unmount();
  });

  it("shows no hint over a timeline that fits on screen, where it would cover the first date", async () => {
    const { host, hasOlder } = mountHistory(false);
    hasOlder.value = false;
    await nextTick();
    await nextTick();
    expect(host.find(".message-list-history-end").exists()).toBe(false);
    host.unmount();
  });
});

describe("MessageList locating a message", () => {
  it("keeps a located message on screen when the conversation was just opened", async () => {
    const { host } = mountHistory(true);
    const list = host.findComponent(MessageList as Component);
    const scroller = host.get(".message-list").element as HTMLElement;
    const api = list.vm as unknown as { scrollToBottom(): Promise<void>; scrollToMessage(id: string, smooth?: boolean): Promise<boolean> };
    void api.scrollToBottom();
    expect(await api.scrollToMessage("client-1", false)).toBe(true);
    // happy-dom has no layout, so stand in for scrollIntoView moving the reader up the history.
    scroller.scrollTop = 120;
    await new Promise((resolve) => setTimeout(resolve, 900));
    expect(scroller.scrollTop).toBe(120);
    host.unmount();
  });
});
