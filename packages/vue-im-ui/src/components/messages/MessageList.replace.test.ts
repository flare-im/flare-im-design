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
 * A window the host replaces as a whole and a locate that lands in it (`spec/message-list-paging-vectors.json`
 * `locateAfterReplace`), on the component, in a scroller that behaves like a browser's: the offset is clamped to the
 * content, a write to it stops a smooth scroll that is running, every change fires one `scroll` event a frame later,
 * and a scroller whose height changes tells its resize observers. Each case runs twice, once with the offset the swap
 * leaves at 0 (Chromium does that when the tapped quote leaves with the old rows: focus fixup recalculates style, and
 * inside the size container that lays the timeline out while it is empty) and once with it left at the new end.
 */
type Window = { from: number; to: number; hasNewer: boolean; windowId?: string };
type Case = {
  id: string;
  before: Window;
  after: Window;
  locate: number;
  readerAskedOlder: boolean;
  pageLands: boolean;
  readerMovesTo: "top" | "bottom" | null;
  expected: { requests: string[]; locatedInView: boolean; marked: boolean };
};
const table = JSON.parse(
  readFileSync(resolve(__dirname, "../../../../../spec/message-list-paging-vectors.json"), "utf8"),
) as { locateAfterReplace: { rowHeight: number; viewportHeight: number; pageRows: number; cases: Case[] } };
const { rowHeight, viewportHeight, pageRows, cases } = table.locateAfterReplace;
/** The newer end's band below the timeline takes this much of the list's height while it is drawn. */
const BAND_PX = 48;
const FRAME_MS = 16;

function message(n: number): MessageLike {
  // A second apart from the start of one day: no date pill sits between the rows.
  const createdAt = Date.UTC(2025, 0, 15) + n * 1000;
  return {
    serverId: `srv-${n}`, clientMsgId: `m${n}`, senderId: n % 2 ? "ivy" : "lee", senderDisplayName: "Ivy",
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

/** A browser's scroller for the list's `.message-list`: rows `rowHeight` high, a viewport `viewportHeight` high. */
type Observer = { callback: ResizeObserverCallback; targets: Set<Element> };

function browserScroller(root: HTMLElement, observers: Set<Observer>) {
  const scroller = root.querySelector<HTMLElement>(".message-list")!;
  let offset = 0;
  let smooth: ReturnType<typeof setTimeout> | null = null;
  let scrollQueued = false;
  let notifiedHeight = -1;
  const drawn = () => Array.from(scroller.querySelectorAll<HTMLElement>("[data-message-id]"));
  const height = () => viewportHeight - (root.querySelector(".message-list-pagination--newer, .message-list-load-newer") ? BAND_PX : 0);
  const max = () => Math.max(0, drawn().length * rowHeight - height());
  const queueScroll = () => {
    scrollQueued = true;
  };
  const write = (value: number, bySmoothScroll = false) => {
    if (!bySmoothScroll && smooth) {
      clearTimeout(smooth);
      smooth = null;
    }
    const next = Math.min(max(), Math.max(0, value));
    if (next !== offset) {
      offset = next;
      queueScroll();
    }
  };
  const read = () => (offset = Math.min(offset, max()));
  Object.defineProperty(scroller, "scrollTop", { configurable: true, get: read, set: (value: number) => write(value) });
  Object.defineProperty(scroller, "scrollHeight", { configurable: true, get: () => drawn().length * rowHeight });
  Object.defineProperty(scroller, "clientHeight", { configurable: true, get: height });
  const rectOf = (top: number, size: number) => ({ top, bottom: top + size, height: size, left: 0, right: 320, width: 320, x: 0, y: top, toJSON: () => ({}) }) as DOMRect;
  const originalRect = HTMLElement.prototype.getBoundingClientRect;
  patch(HTMLElement.prototype, "getBoundingClientRect", function (this: HTMLElement) {
    if (this === scroller) return rectOf(0, height());
    const index = this.dataset.messageId ? drawn().indexOf(this) : -1;
    return index >= 0 ? rectOf(index * rowHeight - read(), rowHeight) : originalRect.call(this);
  });
  patch(HTMLElement.prototype, "scrollIntoView", function (this: HTMLElement, options?: ScrollIntoViewOptions | boolean) {
    const index = drawn().indexOf(this);
    if (index < 0) return;
    const target = index * rowHeight - (height() - rowHeight) / 2;
    if (typeof options !== "object" || options.behavior !== "smooth") return write(target);
    write(read());
    const from = read();
    let step = 0;
    const tick = () => {
      step += 1;
      write(from + ((target - from) * step) / 8, true);
      smooth = step < 8 ? setTimeout(tick, FRAME_MS) : null;
    };
    smooth = setTimeout(tick, FRAME_MS);
  });
  // One frame, in the order a browser runs it: the scroll event for an offset that changed, then the resize step,
  // where a list whose height changed tells whoever observes it.
  const frames = setInterval(() => {
    if (scrollQueued) {
      scrollQueued = false;
      scroller.dispatchEvent(new Event("scroll"));
    }
    const now = height();
    if (now === notifiedHeight) return;
    notifiedHeight = now;
    for (const observer of observers) {
      if (observer.targets.has(scroller)) observer.callback([], observer as unknown as ResizeObserver);
    }
  }, FRAME_MS);
  restorers.push(() => {
    clearInterval(frames);
    if (smooth) clearTimeout(smooth);
  });
  return {
    scroller,
    /** What the forced layout does in the middle of the swap: the empty timeline clamps the offset to 0. */
    clampToTop: () => write(0),
    /** The reader's own move: an input first, then the offset it scrolls to. */
    readerScrollsTo(edge: "top" | "bottom") {
      scroller.dispatchEvent(new Event("wheel"));
      write(edge === "top" ? 0 : max());
    },
    inView(n: number) {
      const row = scroller.querySelector<HTMLElement>(`[data-message-id="m${n}"]`);
      if (!row) return false;
      const box = row.getBoundingClientRect();
      return box.top >= 0 && box.bottom <= height();
    },
  };
}

/** Every resize observer the list makes is one the scroller above can call. */
function fakeResizeObservers(registry: Set<Observer>) {
  class FakeResizeObserver {
    private readonly entry: Observer;
    constructor(callback: ResizeObserverCallback) {
      this.entry = { callback, targets: new Set() };
    }
    observe(target: Element) {
      this.entry.targets.add(target);
      registry.add(this.entry);
    }
    unobserve(target: Element) {
      this.entry.targets.delete(target);
    }
    disconnect() {
      this.entry.targets.clear();
      registry.delete(this.entry);
    }
  }
  patch(globalThis as { ResizeObserver: unknown }, "ResizeObserver", FakeResizeObserver);
}

const wait = (ms: number) => new Promise((done) => setTimeout(done, ms));

async function run(vector: Case, swapLeaves: "top" | "end") {
  const asked: string[] = [];
  const messages = ref(rows(vector.before.from, vector.before.to));
  const hasNewer = ref(vector.before.hasNewer);
  const windowId = ref(vector.before.windowId);
  const loadingOlder = ref(false);
  const loadingNewer = ref(false);
  const observers = new Set<Observer>();
  fakeResizeObservers(observers);
  const host = mount(FlareUiProvider, {
    attachTo: document.body,
    props: { themeMode: "light", locale: "en-US", layoutMode: "pc" },
    slots: {
      default: () => h(MessageList as Component, {
        conversationId: "c1", currentUserId: "me", messages: messages.value, hasOlder: true, hasNewer: hasNewer.value,
        windowId: windowId.value, loadingOlder: loadingOlder.value, loadingNewer: loadingNewer.value,
        onLoadOlder: () => { asked.push("older"); loadingOlder.value = true; },
        onLoadNewer: () => { asked.push("newer"); loadingNewer.value = true; },
        onJumpToLatest: () => {},
      }),
    },
  });
  const scroller = browserScroller(host.element as HTMLElement, observers);
  const list = host.findComponent(MessageList as Component).vm as unknown as {
    scrollToMessage(id: string, smooth?: boolean): Promise<boolean>;
  };
  await flushPromises();
  await wait(900);
  // (1) The reader is at the bottom of `before`.
  scroller.scroller.scrollTop = 1e9;
  await wait(4 * FRAME_MS);
  // (2) The reader scrolls to the top and the list asks for older history, which the host keeps for later.
  if (vector.readerAskedOlder) {
    scroller.readerScrollsTo("top");
    await wait(4 * FRAME_MS);
  }
  // (3) The host hands the list `after`, and the browser lays the swap out.
  messages.value = rows(vector.after.from, vector.after.to);
  hasNewer.value = vector.after.hasNewer;
  windowId.value = vector.after.windowId;
  await nextTick();
  if (swapLeaves === "top") scroller.clampToTop();
  // (4) The locate trip asks the list once `openAround` answered and the list has drawn a pass.
  await nextTick();
  await wait(FRAME_MS);
  expect(await list.scrollToMessage(`m${vector.locate}`)).toBe(true);
  const marked = host.find(`[data-message-id="m${vector.locate}"]`).classes().includes("message-row--locating");
  // (5) A page of older rows lands while the locate is still moving.
  if (vector.pageLands) {
    await wait(2 * FRAME_MS);
    const first = messages.value[0]!.conversationSeq as number;
    messages.value = [...rows(first - pageRows, first - 1), ...messages.value];
    loadingOlder.value = false;
  }
  await wait(900);
  // (6) The reader moves the list themselves.
  if (vector.readerMovesTo) {
    scroller.readerScrollsTo(vector.readerMovesTo);
    await wait(6 * FRAME_MS);
  }
  const result = { requests: asked, locatedInView: scroller.inView(vector.locate), marked };
  host.unmount();
  return result;
}

describe("a window replaced as a whole, and a locate that lands in it", () => {
  it("reads the shared table", () => {
    expect(cases.length).toBeGreaterThanOrEqual(8);
  });
  for (const vector of cases) {
    for (const swapLeaves of ["top", "end"] as const) {
      it(`${vector.id} (the swap leaves the offset at the ${swapLeaves})`, async () => {
        expect(await run(vector, swapLeaves)).toEqual(vector.expected);
      }, 10_000);
    }
  }
});
