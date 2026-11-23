// @vitest-environment happy-dom
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";
import FlareUnreadBadge from "./FlareUnreadBadge.vue";

type Case = { id: string; count?: number; more?: boolean; text: string; drawn: boolean };
const vectors = JSON.parse(readFileSync(resolve(__dirname, "../../../../../spec/count-badge-vectors.json"), "utf8")) as { cases: Case[] };

/** The unread pill, the same contract as the Flutter kit's FlareUnreadBadge, reading the shared count text (99+). */
describe("FlareUnreadBadge", () => {
  it.each(vectors.cases.map((v) => [v.id, v] as const))("draws %s as the shared count badge does", (_, v) => {
    const badge = mount(FlareUnreadBadge, { props: { count: v.count as number, more: v.more } });
    const pill = badge.find("[data-shape='number']");
    expect(pill.exists()).toBe(v.drawn);
    if (v.drawn) expect(pill.text()).toBe(v.text);
  });

  it("draws nothing for 0 unless dot or more, and a dot only when there is no count", () => {
    expect(mount(FlareUnreadBadge, { props: { count: 0 } }).html()).not.toContain("flare-unread-badge");
    expect(mount(FlareUnreadBadge, { props: { count: -4 } }).html()).not.toContain("flare-unread-badge");
    const dot = mount(FlareUnreadBadge, { props: { count: 0, dot: true } });
    expect(dot.find("[data-shape='dot']").attributes("aria-hidden")).toBe("true");
    expect(dot.text()).toBe("");
    expect(mount(FlareUnreadBadge, { props: { count: 3, dot: true } }).get("[data-shape='number']").text()).toBe("3");
    expect(mount(FlareUnreadBadge, { props: { count: 0, dot: true, more: true } }).get("[data-shape='number']").text()).toBe("99+");
  });

  it("caps at 99 and reads more as 99+", () => {
    expect(mount(FlareUnreadBadge, { props: { count: 99 } }).text()).toBe("99");
    expect(mount(FlareUnreadBadge, { props: { count: 100 } }).text()).toBe("99+");
    expect(mount(FlareUnreadBadge, { props: { count: 5, more: true } }).text()).toBe("99+");
  });

  it("takes Flutter's maxCount for a smaller cap", () => {
    expect(mount(FlareUnreadBadge, { props: { count: 12, maxCount: 9 } }).text()).toBe("9+");
    expect(mount(FlareUnreadBadge, { props: { count: 9, maxCount: 9 } }).text()).toBe("9");
  });

  it("has a quiet look for a silenced conversation", () => {
    expect(mount(FlareUnreadBadge, { props: { count: 2, quiet: true } }).classes()).toContain("flare-unread-badge--quiet");
    expect(mount(FlareUnreadBadge, { props: { count: 2 } }).classes()).not.toContain("flare-unread-badge--quiet");
  });
});
