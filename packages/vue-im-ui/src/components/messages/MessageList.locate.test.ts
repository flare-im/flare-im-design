// @vitest-environment happy-dom
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { mount } from "@vue/test-utils";
import { h, type Component } from "vue";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import FlareUiProvider from "../../design-system/provider/FlareUiProvider.vue";
import type { MessageLike } from "../../shared/contracts/messageRow";
import MessageList from "./MessageList.vue";

/**
 * The mark a located row wears. Vue is the reference implementation, so the numbers in its stylesheet
 * are the numbers in `spec/locate-highlight-vectors.json` that the three native kits draw from — this
 * file is what keeps the two in step, because a CSS animation cannot be asserted from a unit test.
 */
const tableFile = resolve(__dirname, "../../../../../spec/locate-highlight-vectors.json");
const css = readFileSync(
  resolve(__dirname, "../../design-system/styles/chat/message-bubble.css"),
  "utf8",
);
const table = JSON.parse(readFileSync(tableFile, "utf8")) as {
  durationMs: number;
  reducedMotionStop: { alpha: number; spread: number };
  stops: { atMs: number; alpha: number; spread: number }[];
};

function message(id: string, senderId: string, minute: number): MessageLike {
  const createdAt = 1_736_922_600_000 + minute * 60_000;
  return {
    serverId: `server-${id}`, clientMsgId: `client-${id}`, senderId, senderDisplayName: senderId,
    conversationSeq: minute, createdAt, clientCreatedAt: createdAt, messageType: 1,
    content: { contentType: "text", text: `message ${id}` }, status: "read",
    isRecalled: false, isRead: true, timelineKey: `server:server-${id}`, timelineSortTs: createdAt, attributes: {},
  };
}

function mountList() {
  const messages = [message("1", "ivy", 0), message("2", "me", 1), message("3", "ivy", 2)];
  const host = mount(FlareUiProvider, {
    // Attached, because moving the reading cursor is only observable on a document: a detached element
    // takes no focus, and `document.activeElement` would stay on the body whatever the list did.
    attachTo: document.body,
    props: { themeMode: "light", locale: "en-US", layoutMode: "pc" },
    slots: { default: () => h(MessageList as Component, { currentUserId: "me", messages }) },
  });
  const list = host.findComponent(MessageList as Component);
  return { host, api: list.vm as unknown as { scrollToMessage(id: string, smooth?: boolean): Promise<boolean> } };
}

const marked = (host: ReturnType<typeof mountList>["host"]) =>
  host.findAll(".message-row--locating").map((row) => row.attributes("data-message-id"));

describe("the mark a located row wears", () => {
  beforeEach(() => vi.useFakeTimers());
  afterEach(() => vi.useRealTimers());

  it("marks the row the list jumped to, and drops the mark when the window is over", async () => {
    const { host, api } = mountList();
    expect(marked(host)).toEqual([]);

    expect(await api.scrollToMessage("server-2", false)).toBe(true);
    expect(marked(host)).toHaveLength(1);

    vi.advanceTimersByTime(table.durationMs - 1);
    expect(marked(host)).toHaveLength(1);
    vi.advanceTimersByTime(1);
    expect(marked(host)).toEqual([]);
    host.unmount();
  });

  it("marks one row at a time: a second jump inside the window clears the first", async () => {
    const { host, api } = mountList();
    await api.scrollToMessage("server-2", false);
    const first = marked(host);
    vi.advanceTimersByTime(400);

    await api.scrollToMessage("server-3", false);
    const second = marked(host);
    // Two marked rows would say the jump landed twice.
    expect(second).toHaveLength(1);
    expect(second).not.toEqual(first);

    // The first row's own timer must not take the second row's mark with it.
    vi.advanceTimersByTime(table.durationMs - 400);
    expect(marked(host)).toEqual(second);
    vi.advanceTimersByTime(400);
    expect(marked(host)).toEqual([]);
    host.unmount();
  });

  it("tells a screen reader which row the jump landed on", async () => {
    const { host, api } = mountList();
    const live = host.get(".message-list__locate-announcement");
    expect(live.attributes("aria-live")).toBe("polite");
    expect(live.text()).toBe("");

    await api.scrollToMessage("server-2", false);
    // The announcement is written on the next tick, so a repeat of the same sentence is not swallowed.
    await vi.advanceTimersByTimeAsync(0);
    await host.vm.$nextTick();
    // The same one line a reply strip would show, named by its sender: the ring says this to everyone
    // who can see it.
    expect(live.text()).toBe("Jumped to me's message: message 2");
    host.unmount();
  });

  it("takes the reading cursor to the row it landed on", async () => {
    const { host, api } = mountList();
    expect(document.activeElement?.className ?? "").not.toContain("message-bubble--focusable");

    await api.scrollToMessage("server-2", false);
    await vi.advanceTimersByTimeAsync(0);
    await host.vm.$nextTick();

    // The row itself now reads under the cursor — the ring says the same thing to everyone who can see it.
    const focused = document.activeElement as HTMLElement | null;
    expect(focused?.classList.contains("message-bubble--focusable")).toBe(true);
    expect(focused?.closest("[data-message-id]")?.getAttribute("data-message-id")).toBe("client-2");
    host.unmount();
  });

  it("draws the window and the three stops the shared table declares", () => {
    const rule = /\.message-row--locating \.message-bubble \{\s*animation: im-message-locate-pulse (\d+)ms (\w+);/.exec(css);
    expect(rule, "the locating rule is gone from the stylesheet").not.toBeNull();
    expect(Number(rule![1])).toBe(table.durationMs);
    // Linear, because an easing curve is not reproducible in three other animation systems.
    expect(rule![2]).toBe("linear");

    const frames = /@keyframes im-message-locate-pulse \{([\s\S]*?)\n\}/.exec(css);
    expect(frames, "the keyframes are gone from the stylesheet").not.toBeNull();
    const stops = [...frames![1].matchAll(
      /([\d.]+)% \{\s*box-shadow:\s*0 0 0 (\d+)px color-mix\(in srgb, var\(--flare-color-primary\) (\d+)%/g,
    )].map(([, at, spread, alpha]) => ({
      atMs: Math.round((Number(at) / 100) * table.durationMs),
      alpha: Number(alpha) / 100,
      spread: Number(spread),
    }));
    expect(stops).toEqual(table.stops);
  });

  it("holds the mark still for a reader who asked for less motion, rather than dropping it", () => {
    // The global rule in accessibility.css collapses every animation to 0.01ms, so an animated-only
    // mark is no mark at all under Reduce Motion.
    const reduced = /@media \(prefers-reduced-motion: reduce\) \{\s*\.message-row--locating \.message-bubble \{([\s\S]*?)\n  \}/.exec(css);
    expect(reduced, "Reduce Motion drops the mark entirely").not.toBeNull();
    expect(reduced![1]).toContain("animation: none");
    const held = /0 0 0 (\d+)px color-mix\(in srgb, var\(--flare-color-primary\) (\d+)%/.exec(reduced![1]);
    expect(held).not.toBeNull();
    expect({ spread: Number(held![1]), alpha: Number(held![2]) / 100 }).toEqual(table.reducedMotionStop);
  });
});
