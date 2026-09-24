// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { defineComponent, h, nextTick, ref } from "vue";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import { setFlareRuntimeLocale } from "../../shared/i18n/messages";
import FlareMyInvitePanel from "./FlareMyInvitePanel.vue";

type Props = Partial<InstanceType<typeof FlareMyInvitePanel>["$props"]>;
const NOW = 1_767_000_000_000;
const invitees = [
  { userId: "u1", displayName: "Ann", joinedAt: Date.UTC(2026, 8, 24, 12) },
  { userId: "u2", displayName: "Bob", avatarUrl: "https://example.test/bob.png", joinedAt: Date.UTC(2026, 0, 5, 12) },
];

function mountPanel(initial: Props = {}) {
  const state = ref<Props>({ code: "AB12CD", invitees, ...initial });
  const events: string[] = [];
  const host = mount(defineComponent({
    setup() {
      useFlareI18nProvider("en-US");
      return () =>
        h(FlareMyInvitePanel, {
          code: "AB12CD",
          invitees,
          ...state.value,
          onCopy: (code: string) => events.push(`copy:${code}`),
          onShare: (url: string) => events.push(`share:${url}`),
          onRegenerate: () => events.push("regenerate"),
          onLoadMore: () => events.push("loadMore"),
          onSelect: (id: string) => events.push(`select:${id}`),
        });
    },
  }));
  const button = (label: string) => host.findAll("button").find((b) => b.text().includes(label));
  return { host, state, events, button };
}

describe("FlareMyInvitePanel", () => {
  beforeEach(() => { vi.useFakeTimers(); vi.setSystemTime(NOW); });
  afterEach(() => { vi.useRealTimers(); });

  it("shows the code, the share link, and dispatches copy / share / select without touching the clipboard", async () => {
    const { host, events, button } = mountPanel({ shareUrl: "https://flare.example/r/t1/AB12CD" });
    expect(host.get("section").attributes("aria-label")).toBe("My invite");
    expect(host.get(".flare-my-invite__code").text()).toBe("AB12CD");
    expect(host.get(".flare-my-invite__link").text()).toBe("https://flare.example/r/t1/AB12CD");
    await button("Copy")!.trigger("click");
    await button("Share")!.trigger("click");
    await host.findAll(".flare-my-invite__person")[1].trigger("click");
    expect(events).toEqual(["copy:AB12CD", "share:https://flare.example/r/t1/AB12CD", "select:u2"]);
    expect(host.findAll(".flare-my-invite__joined").map((n) => n.text())).toEqual(["Joined 2026-09-24", "Joined 2026-01-05"]);
  });

  it("shares the code itself when the host built no link", async () => {
    const { events, button } = mountPanel();
    await button("Share")!.trigger("click");
    expect(events).toEqual(["share:AB12CD"]);
  });

  it("lists depth rows per maxDepthShown and always ends with the total", async () => {
    const stats = { direct: 5, l2: 12, l3: 40, total: 57 };
    const { host, state } = mountPanel({ stats });
    const labels = () => host.findAll("dt").map((n) => n.text());
    expect(labels()).toEqual(["Direct", "Level 2", "Level 3", "Team total"]);
    expect(host.findAll("dd").map((n) => n.text())).toEqual(["5", "12", "40", "57"]);
    state.value = { stats, maxDepthShown: 1 };
    await nextTick();
    expect(labels()).toEqual(["Direct", "Team total"]);
    state.value = { stats: null };
    await nextTick();
    expect(host.find("dl").exists()).toBe(false);
  });

  it("count-only mode replaces the list with the direct count", () => {
    const { host } = mountPanel({ showProfiles: false, stats: { direct: 9, l2: 0, l3: 0, total: 9 } });
    expect(host.find(".flare-my-invite__person").exists()).toBe(false);
    expect(host.get(".flare-my-invite__count-only").text()).toBe("9 people");
  });

  it("empty and loading are different states: the skeleton never pretends to be an empty list", async () => {
    const { host, state } = mountPanel({ code: "", invitees: [], loading: true });
    expect(host.find(".flare-my-invite__ghost--code").exists()).toBe(true);
    expect(host.find(".flare-my-invite__empty").exists()).toBe(false);
    expect(host.get("section").attributes("aria-busy")).toBe("true");
    state.value = { code: "AB12CD", invitees: [], loading: false };
    await nextTick();
    expect(host.find(".flare-my-invite__ghost--code").exists()).toBe(false);
    expect(host.get(".flare-my-invite__empty").text()).toBe("No one has joined with your code yet");
  });

  it("offers regenerate only when allowed, disables it while cooling down and says how long", async () => {
    const { host, state, events, button } = mountPanel();
    expect(button("Regenerate")).toBeUndefined();
    state.value = { canRegenerate: true, regenerateAvailableAt: NOW + 15 * 60_000 };
    await nextTick();
    expect(button("Regenerate")!.attributes("disabled")).toBeDefined();
    expect(host.get(".flare-my-invite__cooldown").text()).toBe("You can regenerate in 15 min");
    // The clock moves on; the control frees itself without a new prop.
    vi.setSystemTime(NOW + 16 * 60_000);
    vi.advanceTimersByTime(30_000);
    await nextTick();
    expect(host.find(".flare-my-invite__cooldown").exists()).toBe(false);
    await button("Regenerate")!.trigger("click");
    expect(events).toEqual(["regenerate"]);
    state.value = { canRegenerate: true, regenerating: true };
    await nextTick();
    expect(button("Regenerating")!.attributes("disabled")).toBeDefined();
  });

  it("shows load more only while another page exists and marks it busy", async () => {
    const { host, state, events, button } = mountPanel();
    expect(button("Load more")).toBeUndefined();
    state.value = { hasMore: true };
    await nextTick();
    await button("Load more")!.trigger("click");
    expect(events).toEqual(["loadMore"]);
    state.value = { hasMore: true, loadingMore: true };
    await nextTick();
    expect(button("Load more")!.attributes("disabled")).toBeDefined();
    expect(host.find(".flare-my-invite__more").exists()).toBe(true);
  });

  it("renders from the runtime locale in a host without a provider", () => {
    setFlareRuntimeLocale("zh-CN");
    const wrapper = mount(FlareMyInvitePanel, { props: { code: "AB12CD", invitees: [] } });
    expect(wrapper.get("section").attributes("aria-label")).toBe("我的邀请");
    expect(wrapper.get(".flare-my-invite__empty").text()).toBe("还没有人通过你的邀请码加入");
  });
});
