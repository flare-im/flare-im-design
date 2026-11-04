// @vitest-environment happy-dom
import { flushPromises, mount } from "@vue/test-utils";
import { defineComponent, h, nextTick, ref } from "vue";
import { NQrCode } from "naive-ui";
import { describe, expect, it, vi } from "vitest";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import { setFlareRuntimeLocale } from "../../shared/i18n/messages";
import FlareMyInvitePanel from "./FlareMyInvitePanel.vue";

type Props = Partial<InstanceType<typeof FlareMyInvitePanel>["$props"]>;
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
          onLoadMore: () => events.push("loadMore"),
          onSelect: (id: string) => events.push(`select:${id}`),
        });
    },
  }));
  const button = (label: string) => host.findAll("button").find((b) => b.text().includes(label));
  return { host, state, events, button };
}

describe("FlareMyInvitePanel", () => {
  it("uses the registration link only in the QR and offers one copy action for the full code", async () => {
    const code = "ABCD2345WXYZ";
    const link = `https://flare.example/r/t1/${code}`;
    const { host, events, button } = mountPanel({ code, shareUrl: link });
    expect(host.get("section").attributes("aria-label")).toBe("My invite");
    expect(host.get(".flare-my-invite__code").text()).toBe(code);
    expect(host.get(".flare-my-invite__hero").text()).not.toContain(link);
    expect(host.get("[role=img]").attributes("aria-label")).toBe("Scan to sign up");
    expect(host.getComponent(NQrCode).props("value")).toBe(link);
    expect(host.get(".flare-my-invite__hero").findAll("button").map((button) => button.text())).toEqual(["Copy"]);
    await button("Copy")!.trigger("click");
    await host.findAll(".flare-my-invite__person")[1].trigger("click");
    expect(events).toEqual([`copy:${code}`, "select:u2"]);
    expect(host.findAll(".flare-my-invite__joined").map((n) => n.text())).toEqual(["Joined 2026-09-24", "Joined 2026-01-05"]);
  });

  it("starts with the first level without extra labels or a duplicate host title", () => {
    const { host } = mountPanel({ showTitle: false });
    expect(host.find(".flare-my-invite__head").exists()).toBe(false);
    expect(host.get(".flare-my-invite__team").text()).toContain("Invitation relationships");
    expect(host.get(".flare-my-invite__team").text()).not.toContain("People you invited");
    expect(host.get(".flare-my-invite__team").text()).not.toContain("Invited you");
    expect(host.get(".flare-my-invite__team").text()).not.toContain("You");
    expect(host.findAll(".flare-my-invite__name").map((row) => row.text())).toEqual(["Ann", "Bob"]);
  });

  it("loads individual branches, retries a failed page and stops at the visible depth", async () => {
    const child = { userId: "u3", displayName: "Casey", joinedAt: 0, hasChildren: true };
    const leaf = { userId: "u4", displayName: "Dana", joinedAt: 0, hasChildren: true };
    const secondChild = { userId: "u5", displayName: "Evan", joinedAt: 0 };
    const loadChildren = vi.fn()
      .mockResolvedValueOnce({ invitees: [child], nextCursor: "u1-next" })
      .mockRejectedValueOnce(new Error("network"))
      .mockResolvedValueOnce({ invitees: [child, secondChild] })
      .mockResolvedValueOnce({ invitees: [leaf] });
    const { host, state, events, button } = mountPanel({
      invitees: [{ ...invitees[0], hasChildren: true }, invitees[1]],
      maxDepthShown: 3,
      onLoadChildren: loadChildren,
    });
    const expand = (label: string) => host.get(`button[aria-label="${label}"]`);
    expect(loadChildren).not.toHaveBeenCalled();
    expect(expand("Expand Ann").attributes("aria-expanded")).toBe("false");
    await expand("Expand Ann").trigger("click");
    await flushPromises();
    expect(loadChildren).toHaveBeenNthCalledWith(1, "u1", undefined);
    expect(expand("Collapse Ann").attributes("aria-expanded")).toBe("true");
    await button("Load more")!.trigger("click");
    await flushPromises();
    expect(host.text()).toContain("Could not load further invitations");
    await button("Retry")!.trigger("click");
    await flushPromises();
    expect(loadChildren).toHaveBeenNthCalledWith(2, "u1", "u1-next");
    expect(loadChildren).toHaveBeenNthCalledWith(3, "u1", "u1-next");
    expect(host.findAll(".flare-my-invite__name").map((row) => row.text())).toEqual(["Ann", "Casey", "Evan", "Bob"]);
    await expand("Expand Casey").trigger("click");
    await flushPromises();
    expect(loadChildren).toHaveBeenNthCalledWith(4, "u3", undefined);
    expect(host.find('button[aria-label="Expand Dana"]').exists()).toBe(false);
    await button("Dana")!.trigger("click");
    expect(events).toEqual(["select:u4"]);
    await expand("Collapse Ann").trigger("click");
    const branchId = expand("Expand Ann").attributes("aria-controls");
    expect(host.get(`[id="${branchId}"]`).attributes("style")).toContain("display: none");
    await expand("Expand Ann").trigger("click");
    expect(host.get(`[id="${branchId}"]`).attributes("style") ?? "").not.toContain("display: none");
    expect(loadChildren).toHaveBeenCalledTimes(4);
    state.value = { ...state.value, showProfiles: false };
    await nextTick();
    expect(host.find(".flare-my-invite__team").exists()).toBe(false);
  });

  it.each(["", `https://flare.example/${"a".repeat(2331)}/r/t1/AB12CD`])(
    "keeps the code copyable when there is no renderable QR",
    async (shareUrl) => {
      const { host, events, button } = mountPanel({ shareUrl });
      expect(host.findComponent(NQrCode).exists()).toBe(false);
      expect(host.find(".flare-my-invite__qr-hint").exists()).toBe(false);
      await button("Copy")!.trigger("click");
      expect(events).toEqual(["copy:AB12CD"]);
    },
  );

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

  it("count-only mode shows statistics without the relationship section", () => {
    const { host } = mountPanel({
      showProfiles: false,
      stats: { direct: 9, l2: 0, l3: 0, total: 9 },
      invitees: [{ userId: "invitee", displayName: "Invitee", joinedAt: 0 }],
      hasMore: true,
    });
    expect(host.find(".flare-my-invite__team").exists()).toBe(false);
    expect(host.get("h4").text()).toBe("My team");
    expect(host.findAll("dd").map((n) => n.text())).toEqual(["9", "0", "0", "9"]);
  });

  it("does not render a stale invitation QR or any invite actions without a code", () => {
    const { host, button } = mountPanel({
      code: "",
      shareUrl: "https://flare.example/r/t1/AB12CD",
      showProfiles: false,
      stats: { direct: 9, l2: 0, l3: 0, total: 9 },
    });
    expect(host.get(".flare-my-invite__unavailable").text()).toBe("Invite code unavailable");
    expect(host.findComponent(NQrCode).exists()).toBe(false);
    expect(button("Copy")).toBeUndefined();
    expect(host.get("h4").text()).toBe("My team");
  });

  it("empty and loading are different states: the skeleton never pretends to be an empty list", async () => {
    const { host, state, button } = mountPanel({ invitees: [], loading: true, shareUrl: "https://flare.example/r/t1/AB12CD" });
    expect(host.find(".flare-my-invite__ghost--code").exists()).toBe(true);
    expect(host.find(".flare-my-invite__empty").exists()).toBe(false);
    expect(host.findComponent(NQrCode).exists()).toBe(false);
    expect(button("Copy")).toBeUndefined();
    expect(host.get("section").attributes("aria-busy")).toBe("true");
    state.value = { code: "AB12CD", invitees: [], loading: false };
    await nextTick();
    expect(host.find(".flare-my-invite__ghost--code").exists()).toBe(false);
    expect(host.get(".flare-my-invite__empty").text()).toBe("No one has joined with your code yet");
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
