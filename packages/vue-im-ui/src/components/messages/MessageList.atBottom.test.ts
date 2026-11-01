// @vitest-environment happy-dom
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { flushPromises, mount } from "@vue/test-utils";
import { h, nextTick, ref, type Component } from "vue";
import { afterEach, describe, expect, it } from "vitest";
import FlareUiProvider from "../../design-system/provider/FlareUiProvider.vue";
import type { MessageLike } from "../../shared/contracts/messageRow";
import MessageList from "./MessageList.vue";

/**
 * Whether the reader is at the bottom (`spec/message-list-paging-vectors.json` `atBottom`), as the component tells the
 * host through `atBottomChange`, in a scroller that behaves like a browser's: rows 100 px high in a 400 px viewport, the
 * offset clamped to the content, and every change of it firing one `scroll` event a frame later.
 */
const table = JSON.parse(
  readFileSync(resolve(__dirname, "../../../../../spec/message-list-paging-vectors.json"), "utf8"),
) as { atBottom: { within: number } };
const ROW_PX = 100;
const VIEWPORT_PX = 400;
const FRAME_MS = 16;

function message(n: number, senderId = "ivy"): MessageLike {
  const createdAt = Date.UTC(2025, 0, 15) + n * 1000;
  return {
    serverId: `srv-${n}`, clientMsgId: `m${n}`, senderId, senderDisplayName: senderId,
    conversationSeq: n, createdAt, clientCreatedAt: createdAt, messageType: 1,
    content: { contentType: "text", text: `message ${n}` }, status: "read", isRecalled: false, isRead: true,
    timelineKey: `server:srv-${n}`, timelineSortTs: createdAt, attributes: {},
  };
}
const rows = (from: number, to: number) => Array.from({ length: to - from + 1 }, (_, index) => message(from + index));

const restorers: Array<() => void> = [];
afterEach(() => {
  while (restorers.length) restorers.pop()!();
});

function patch<T extends object, K extends keyof T>(target: T, key: K, value: T[K]): void {
  const original = Object.getOwnPropertyDescriptor(target, key);
  Object.defineProperty(target, key, { configurable: true, writable: true, value });
  restorers.push(() => (original ? Object.defineProperty(target, key, original) : delete target[key]));
}

function browserScroller(root: HTMLElement) {
  const scroller = root.querySelector<HTMLElement>(".message-list")!;
  let offset = 0;
  let scrollQueued = false;
  const drawn = () => Array.from(scroller.querySelectorAll<HTMLElement>("[data-message-id]"));
  const max = () => Math.max(0, drawn().length * ROW_PX - VIEWPORT_PX);
  const write = (value: number) => {
    const next = Math.min(max(), Math.max(0, value));
    if (next !== offset) {
      offset = next;
      scrollQueued = true;
    }
  };
  const read = () => (offset = Math.min(offset, max()));
  Object.defineProperty(scroller, "scrollTop", { configurable: true, get: read, set: (value: number) => write(value) });
  Object.defineProperty(scroller, "scrollHeight", { configurable: true, get: () => drawn().length * ROW_PX });
  Object.defineProperty(scroller, "clientHeight", { configurable: true, get: () => VIEWPORT_PX });
  const rectOf = (top: number, size: number) => ({ top, bottom: top + size, height: size, left: 0, right: 320, width: 320, x: 0, y: top, toJSON: () => ({}) }) as DOMRect;
  const originalRect = HTMLElement.prototype.getBoundingClientRect;
  patch(HTMLElement.prototype, "getBoundingClientRect", function (this: HTMLElement) {
    if (this === scroller) return rectOf(0, VIEWPORT_PX);
    const index = this.dataset.messageId ? drawn().indexOf(this) : -1;
    return index >= 0 ? rectOf(index * ROW_PX - read(), ROW_PX) : originalRect.call(this);
  });
  patch(HTMLElement.prototype, "scrollIntoView", function (this: HTMLElement) {
    const index = drawn().indexOf(this);
    if (index >= 0) write(index * ROW_PX - (VIEWPORT_PX - ROW_PX) / 2);
  });
  const frames = setInterval(() => {
    if (!scrollQueued) return;
    scrollQueued = false;
    scroller.dispatchEvent(new Event("scroll"));
  }, FRAME_MS);
  restorers.push(() => clearInterval(frames));
  return {
    /** What the forced layout in the middle of a swap can do: the empty timeline clamps the offset to 0. */
    clampToTop: () => write(0),
    /** The reader's own move: an input first, then the offset it scrolls to, `fromBottom` above the end. */
    readerScrollsTo(fromBottom: number) {
      scroller.dispatchEvent(new Event("wheel"));
      write(max() - fromBottom);
    },
  };
}

const wait = (ms: number) => new Promise((done) => setTimeout(done, ms));
/** Long enough for the list's own placing (two frames, then re-scrolls up to 760 ms) to finish. */
const settle = () => wait(900);

function mountList(initial: MessageLike[], options: { hasNewer?: boolean; windowId?: string } = {}) {
  const told: boolean[] = [];
  const messages = ref(initial);
  const hasNewer = ref(Boolean(options.hasNewer));
  const windowId = ref(options.windowId);
  const conversationId = ref("c1");
  patch(globalThis as { ResizeObserver: unknown }, "ResizeObserver", class {
    observe() {}
    unobserve() {}
    disconnect() {}
  });
  const host = mount(FlareUiProvider, {
    attachTo: document.body,
    props: { themeMode: "light", locale: "en-US", layoutMode: "pc" },
    slots: {
      default: () => h(MessageList as Component, {
        conversationId: conversationId.value, currentUserId: "me", messages: messages.value, hasOlder: false,
        hasNewer: hasNewer.value, windowId: windowId.value,
        onLoadNewer: () => {}, onJumpToLatest: () => {},
        onAtBottomChange: (atBottom: boolean) => told.push(atBottom),
      }),
    },
  });
  restorers.push(() => host.unmount());
  const scroller = browserScroller(host.element as HTMLElement);
  const list = host.findComponent(MessageList as Component).vm as unknown as {
    scrollToMessage(id: string, smooth?: boolean): Promise<boolean>;
  };
  return { host, told, messages, hasNewer, windowId, conversationId, scroller, list };
}

describe("whether the reader is at the bottom (atBottomChange)", () => {
  it("counts the bottom within the distance the table names", () => {
    expect(table.atBottom.within).toBe(80);
  });

  it("tells the host once after the first layout, at the newest row", async () => {
    const { told } = mountList(rows(1, 40));
    await flushPromises();
    await settle();
    expect(told).toEqual([true]);
  });

  it("tells it once for an empty list too", async () => {
    const { told } = mountList([]);
    await flushPromises();
    await settle();
    expect(told).toEqual([true]);
  });

  it("tells false when the reader scrolls up and true when they come back, and nothing within the distance", async () => {
    const { told, scroller } = mountList(rows(1, 40));
    await flushPromises();
    await settle();
    scroller.readerScrollsTo(table.atBottom.within);
    await wait(4 * FRAME_MS);
    expect(told).toEqual([true]);
    scroller.readerScrollsTo(table.atBottom.within + 20);
    await wait(4 * FRAME_MS);
    expect(told).toEqual([true, false]);
    scroller.readerScrollsTo(1200);
    await wait(4 * FRAME_MS);
    expect(told).toEqual([true, false]);
    scroller.readerScrollsTo(0);
    await wait(4 * FRAME_MS);
    expect(told).toEqual([true, false, true]);
  });

  it("stays at the bottom while messages arrive under a reader there, and stays away from it for one who scrolled up", async () => {
    const { told, messages, scroller } = mountList(rows(1, 40));
    await flushPromises();
    await settle();
    messages.value = [...messages.value, message(41)];
    await settle();
    messages.value = [...messages.value, message(42), message(43)];
    await settle();
    expect(told).toEqual([true]);
    scroller.readerScrollsTo(900);
    await wait(4 * FRAME_MS);
    messages.value = [...messages.value, message(44)];
    await settle();
    expect(told).toEqual([true, false]);
  });

  it("goes back to the bottom with the new-messages key", async () => {
    const { host, told, messages, scroller } = mountList(rows(1, 40));
    await flushPromises();
    await settle();
    scroller.readerScrollsTo(900);
    await wait(4 * FRAME_MS);
    messages.value = [...messages.value, message(41)];
    await settle();
    await host.find(".message-list-scroll-latest button").trigger("click");
    await settle();
    expect(told).toEqual([true, false, true]);
  });

  it("is at the bottom again when a message of the reader's own arrives during a locate", async () => {
    const { told, messages, list } = mountList(rows(1, 40));
    await flushPromises();
    await settle();
    expect(await list.scrollToMessage("m20", false)).toBe(true);
    await settle();
    messages.value = [...messages.value, message(41, "me")];
    await settle();
    expect(told).toEqual([true, false, true]);
  });

  for (const swapLeaves of ["top", "end"] as const) {
    it(`is not at the bottom of a window replaced without the reader asking until they move it (the swap leaves the offset at the ${swapLeaves})`, async () => {
      const { told, messages, windowId, scroller } = mountList(rows(961, 1000), { windowId: "timeline:1" });
      await flushPromises();
      await settle();
      messages.value = rows(921, 960);
      windowId.value = "timeline:2";
      await nextTick();
      if (swapLeaves === "top") scroller.clampToTop();
      await settle();
      // The list opened the new window at its newest row; that is not the reader arriving there.
      expect(told).toEqual([true, false]);
      scroller.readerScrollsTo(30);
      await wait(4 * FRAME_MS);
      expect(told).toEqual([true, false, true]);
    }, 10_000);

    it(`is at the bottom of the latest window the reader asked for (the swap leaves the offset at the ${swapLeaves})`, async () => {
      const { host, told, messages, hasNewer, windowId, scroller } = mountList(rows(921, 960), { hasNewer: true, windowId: "timeline:1" });
      await flushPromises();
      await settle();
      scroller.readerScrollsTo(900);
      await wait(4 * FRAME_MS);
      await host.find(".message-list-scroll-latest button").trigger("click");
      messages.value = rows(961, 1000);
      hasNewer.value = false;
      windowId.value = "timeline:2";
      await nextTick();
      if (swapLeaves === "top") scroller.clampToTop();
      await settle();
      expect(told).toEqual([true, false, true]);
    }, 10_000);
  }

  it("is not at the bottom while a locate holds the reading position, even when the located row is the last", async () => {
    const { told, list, scroller } = mountList(rows(1, 40));
    await flushPromises();
    await settle();
    expect(await list.scrollToMessage("m40", false)).toBe(true);
    await settle();
    expect(told).toEqual([true, false]);
    scroller.readerScrollsTo(0);
    await wait(4 * FRAME_MS);
    expect(told).toEqual([true, false, true]);
  });

  it("tells another conversation's first layout once more", async () => {
    const { told, messages, conversationId } = mountList(rows(1, 40));
    await flushPromises();
    await settle();
    conversationId.value = "c2";
    messages.value = rows(101, 140);
    await settle();
    expect(told).toEqual([true, true]);
  });
});
