// @vitest-environment happy-dom
import { flushPromises, mount } from "@vue/test-utils";
import { h, nextTick, ref, type Component } from "vue";
import { describe, expect, it } from "vitest";
import FlareUiProvider from "../../design-system/provider/FlareUiProvider.vue";
import type { MessageLike } from "../../shared/contracts/messageRow";
import MessageList from "./MessageList.vue";

// The two ends of the window and the back-to-latest key (spec/message-list-paging-vectors.json), on the component:
// a detached window draws its newer end below the timeline, asks for newer pages near the bottom, offers the way back
// to the latest, keeps the reader in place when a newer page arrives, and opens the latest window at its bottom.
function message(id: number, senderId = "ivy"): MessageLike {
  const createdAt = 1_736_922_600_000 + id * 60_000;
  return {
    serverId: `server-${id}`, clientMsgId: `client-${id}`, senderId, senderDisplayName: senderId,
    conversationSeq: id, createdAt, clientCreatedAt: createdAt, messageType: 1,
    content: { contentType: "text", text: `message ${id}` }, status: "read", isRecalled: false, isRead: true,
    timelineKey: `server:server-${id}`, timelineSortTs: createdAt, attributes: {},
  };
}

const range = (from: number, to: number, senderId?: string) =>
  Array.from({ length: to - from + 1 }, (_, index) => message(from + index, senderId));

const ROW_PX = 100;
const VIEWPORT_PX = 400;

/** Mounts a list whose scroller is ROW_PX per message tall and VIEWPORT_PX high. */
function mountList(initial: { messages: MessageLike[]; hasNewer?: boolean; hasOlder?: boolean }, listeners: Record<string, unknown> = {}) {
  const messages = ref(initial.messages);
  const hasNewer = ref(initial.hasNewer ?? false);
  const hasOlder = ref(initial.hasOlder ?? false);
  const loadingNewer = ref(false);
  const newerError = ref<string | undefined>(undefined);
  const host = mount(FlareUiProvider, {
    props: { themeMode: "light", locale: "en-US", layoutMode: "pc" },
    slots: {
      default: () => h(MessageList as Component, {
        currentUserId: "me", messages: messages.value, hasOlder: hasOlder.value, hasNewer: hasNewer.value,
        loadingNewer: loadingNewer.value, newerError: newerError.value, ...listeners,
      }),
    },
  });
  const scroller = host.get(".message-list").element as HTMLElement;
  Object.defineProperty(scroller, "clientHeight", { configurable: true, value: VIEWPORT_PX });
  Object.defineProperty(scroller, "scrollHeight", { configurable: true, get: () => messages.value.length * ROW_PX });
  return { host, scroller, messages, hasNewer, hasOlder, loadingNewer, newerError };
}

async function settle(): Promise<void> {
  await flushPromises();
  await nextTick();
  await new Promise((resolve) => setTimeout(resolve, 900));
}

async function scrollTo(scroller: HTMLElement, top: number): Promise<void> {
  scroller.scrollTop = top;
  scroller.dispatchEvent(new Event("scroll"));
  await nextTick();
}

describe("MessageList newer end", () => {
  it("draws nothing new and never asks for newer when left at its defaults", async () => {
    const asked: string[] = [];
    const { host, scroller } = mountList({ messages: range(1, 20) }, { onLoadNewer: () => asked.push("newer") });
    await settle();
    expect(host.find(".message-list-pagination--newer").exists()).toBe(false);
    expect(host.find(".message-list-load-newer").exists()).toBe(false);
    expect(host.find(".message-list-scroll-latest").exists()).toBe(false);
    await scrollTo(scroller, 20 * ROW_PX - VIEWPORT_PX);
    expect(asked).toEqual([]);
    host.unmount();
  });

  it("offers newer pages and the latest below a detached window, and raises both intents", async () => {
    const asked: string[] = [];
    const { host } = mountList(
      { messages: range(1, 20), hasNewer: true },
      { onLoadNewer: () => asked.push("newer"), onJumpToLatest: () => asked.push("latest") },
    );
    await settle();
    const button = host.get(".message-list-pagination--newer button");
    expect(button.text()).toBe("Load newer messages");
    const key = host.get(".message-list-scroll-latest button");
    expect(key.attributes("aria-label")).toBe("Back to latest");
    expect(host.get(".message-list-scroll-latest").classes()).toContain("message-list-scroll-latest--above-newer");
    await button.trigger("click");
    await key.trigger("click");
    expect(asked).toEqual(["newer", "latest"]);
    host.unmount();
  });

  it("has no back-to-latest key for a detached window when nobody takes the jump", async () => {
    const { host } = mountList({ messages: range(1, 20), hasNewer: true }, { onLoadNewer: () => {} });
    await settle();
    expect(host.find(".message-list-scroll-latest").exists()).toBe(false);
    host.unmount();
  });

  it("shows a spinner while a newer page loads, and the error with a retry after it fails", async () => {
    const asked: string[] = [];
    const { host, loadingNewer, newerError } = mountList({ messages: range(1, 20), hasNewer: true }, { onLoadNewer: () => asked.push("newer") });
    await settle();
    loadingNewer.value = true;
    await nextTick();
    expect(host.get(".message-list-load-newer").text()).toBe("Loading newer messages…");
    expect(host.find(".message-list-pagination--newer").exists()).toBe(false);
    loadingNewer.value = false;
    newerError.value = "Could not load";
    await nextTick();
    expect(host.get(".message-list-pagination--newer [role=status]").text()).toBe("Could not load");
    await host.get(".message-list-pagination--newer button").trigger("click");
    expect(asked).toEqual(["newer"]);
    host.unmount();
  });

  it("asks for a newer page within the shared distance of the bottom, once until it loads", async () => {
    const asked: string[] = [];
    const { host, scroller } = mountList({ messages: range(1, 20), hasNewer: true }, { onLoadNewer: () => asked.push("newer") });
    await settle();
    const bottom = 20 * ROW_PX - VIEWPORT_PX;
    await scrollTo(scroller, bottom - 400);
    expect(asked).toEqual([]);
    await scrollTo(scroller, bottom - 150);
    await scrollTo(scroller, bottom - 100);
    expect(asked).toEqual(["newer"]);
    host.unmount();
  });

  it("asks for an older page within the shared distance of the top", async () => {
    const asked: string[] = [];
    const { host, scroller } = mountList({ messages: range(1, 20), hasOlder: true }, { onLoadOlder: () => asked.push("older") });
    await settle();
    await scrollTo(scroller, 400);
    expect(asked).toEqual([]);
    await scrollTo(scroller, 140);
    expect(asked).toEqual(["older"]);
    host.unmount();
  });

  it("keeps a reader at the bottom of a detached window where they are when a newer page arrives", async () => {
    const { host, scroller, messages, hasNewer } = mountList(
      { messages: range(1, 20), hasNewer: true },
      { onLoadNewer: () => {}, onJumpToLatest: () => {} },
    );
    await settle();
    const bottom = 20 * ROW_PX - VIEWPORT_PX;
    await scrollTo(scroller, bottom);
    // The page ends in one of the reader's own messages and attaches the window: still a page, not news.
    messages.value = [...range(1, 20), ...range(21, 30, "me")];
    hasNewer.value = false;
    await settle();
    expect(scroller.scrollTop).toBe(bottom);
    host.unmount();
  });

  it("opens the latest window at its bottom after the reader asked for it", async () => {
    const { host, scroller, messages, hasNewer } = mountList(
      { messages: range(1, 20), hasNewer: true },
      { onLoadNewer: () => {}, onJumpToLatest: () => {} },
    );
    await settle();
    await scrollTo(scroller, 300);
    await host.get(".message-list-scroll-latest button").trigger("click");
    messages.value = range(500, 540);
    hasNewer.value = false;
    await settle();
    expect(scroller.scrollTop).toBe(41 * ROW_PX - VIEWPORT_PX);
    expect(host.find(".message-list-scroll-latest").exists()).toBe(false);
    host.unmount();
  });
});
