// @vitest-environment happy-dom
// The red packet pages the plugin page draws for renderers redPacket.compose / redPacket.detail (§11): the pure plans,
// the composition (moved from the web app's RedPacketPageContent) and the page's routing by renderer, never plugin id.
import { afterEach, describe, expect, it, vi } from "vitest";
import { enableAutoUnmount, flushPromises, mount } from "@vue/test-utils";
import { defineComponent, h } from "vue";
import FlarePluginPage from "./FlarePluginPage.vue";
import FlareRedPacketComposer from "./FlareRedPacketComposer.vue";
import FlareRedPacketDetail from "./FlareRedPacketDetail.vue";
import FlareRedPacketOpenSheet from "./FlareRedPacketOpenSheet.vue";
import FlareRedPacketPage from "./FlareRedPacketPage.vue";
import FlareRedPacketReview from "./FlareRedPacketReview.vue";
import { flareRedPacketComposePlan, flareRedPacketDetailPlan, flareRedPacketPagePlan, flareRedPacketReviewPlan } from "../../shared/contracts/red-packet";
import type { FlarePluginViewModel } from "../../shared/contracts/plugin-ui";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";

enableAutoUnmount(afterEach);
const compose = (props: Record<string, unknown> = {}): FlarePluginViewModel => ({
  available: true, title: "红包", fields: [],
  presentation: { renderer: "redPacket.compose", props, actions: { submit: "prepare" } },
  actions: [{ id: "prepare", label: "塞钱进红包", form: ["kind", "amount", "shareCount", "greeting", "designatedUserIds"] }],
  inputs: [
    { id: "kind", kind: "select", label: "类型", required: true, default: "normal", choices: [{ value: "normal", label: "普通" }, { value: "lucky", label: "拼手气" }, { value: "exclusive", label: "专属" }] },
    { id: "amount", kind: "money", label: "金额", required: true, money: { currency: "CNY", scale: 2, min: "0.01", max: "10.00" } },
    { id: "shareCount", kind: "number", label: "份数", required: true, min: 1, max: 100, default: 1 },
    { id: "greeting", kind: "text", label: "祝福语", required: true, maxLength: 128, default: "恭喜发财，大吉大利" },
    { id: "designatedUserIds", kind: "members", label: "收件人", required: true, min: 1, max: 1, showWhen: { field: "kind", anyOf: ["exclusive"] } },
  ],
});
const details = (extra: Record<string, unknown> = {}) => ({ viewerRole: "eligible", status: "open", kind: "normal", greeting: "祝福", currency: "CNY",
  currencyExponent: 2, claimedCount: 0, shareCount: 1, createdAtMs: 1000, expiresAtMs: 100000, claimsListed: false, ...extra });
const packet = (detail: Record<string, unknown> = details(), props: Record<string, unknown> = {}, actions: FlarePluginViewModel["actions"] = [{ id: "claim", label: "领取红包" }],
  bound: Record<string, string> = { claim: "claim" }): FlarePluginViewModel => ({
  available: true, title: "详情", fields: [], actions,
  presentation: { renderer: "redPacket.detail", props: { senderId: "sender", details: detail, claims: [], ...props }, actions: bound },
});
const confirm = (props: Record<string, unknown> = {}): FlarePluginViewModel => ({
  available: true, title: "发送已授权红包", fields: [{ label: "状态", value: "待付款" }],
  blocks: [{ kind: "note", text: "发送结果未知时请处理原操作，勿新建红包重复扣款。", tone: "warning" }],
  actions: [{ id: "commit", label: "发送红包" }, { id: "recovery", label: "查看待确认操作" }],
  presentation: { renderer: "redPacket.review", props: { amount: "8.88", currency: "CNY", kind: "lucky", shareCount: 3, blessing: "恭喜发财", ...props }, actions: { submit: "commit" } },
} as FlarePluginViewModel);
function render(view: FlarePluginViewModel = compose(), extra: Record<string, unknown> = {}) {
  const action = vi.fn();
  const wrapper = mount(defineComponent({ setup() { useFlareI18nProvider("zh-CN"); return () => h(FlareRedPacketPage, { view, onAction: action, ...extra }); } }));
  return { wrapper, action };
}

describe("red packet page plans", () => {
  it("maps the compose renderer onto its bound submit action and falls back to the plain document otherwise", () => {
    expect(flareRedPacketComposePlan(compose())).toMatchObject({ kind: "compose", kinds: ["normal", "lucky", "exclusive"], scale: 2, currency: "CNY", ownedActionIds: ["prepare"] });
    expect(flareRedPacketComposePlan(compose({ maxRecipients: 4 }))?.maxRecipients).toBe(4);
    const direct = compose();
    direct.presentation!.actions = { submitDirect: "prepareDirect" };
    direct.actions = [{ id: "prepareDirect", label: "塞钱进红包", form: ["amount", "greeting"] }];
    expect(flareRedPacketComposePlan(direct)?.kinds).toEqual(["normal"]);
    expect(flareRedPacketComposePlan(compose({ journal: { commandId: "original", known: false } }))).toBeUndefined();
    const unbound = compose(); unbound.presentation!.actions = {};
    expect(flareRedPacketComposePlan(unbound)).toBeUndefined();
    const confirmed = compose(); confirmed.actions[0]!.confirm = "Confirm";
    expect(flareRedPacketComposePlan(confirmed)).toBeUndefined();
    const other = compose(); other.presentation!.renderer = "redPacket.card";
    expect(flareRedPacketPagePlan(other)).toBeUndefined();
    expect(flareRedPacketComposePlan({ ...compose(), unavailableReason: "unbound_copy" })).toBeUndefined();
    const plain = compose(); delete plain.presentation;
    expect(flareRedPacketPagePlan(plain)).toBeUndefined();
  });

  it("maps the detail renderer only for details this viewer may see, with the claim and wallet actions", () => {
    const plan = flareRedPacketDetailPlan(packet(details({ completedInMs: 500 }), { claims: [{ id: "bob", amountMinor: "100", claimedAtMs: 2, best: true }, { id: 3 }] }));
    expect(plan).toMatchObject({ kind: "detail", senderId: "sender", ownedActionIds: ["claim"], paidClaimPending: false });
    expect(plan?.details.completedAtMs).toBe(1500);
    expect(plan?.claims).toEqual([{ id: "bob", amountMinor: "100", claimedAtMs: 2, best: true }]);
    expect(flareRedPacketDetailPlan(packet(details({ myAmountMinor: "not-money" })))).toBeUndefined();
    expect(flareRedPacketDetailPlan(packet(details({ viewerRole: "nobody" })))).toBeUndefined();
    const wallet = flareRedPacketDetailPlan(packet(details({ viewerRole: "claimer", myAmountMinor: "1" }), {},
      [{ id: "wallet", label: "查看钱包", target: { kind: "page", page: "flare.wallet.page.home", pluginId: "flare.wallet" } }], { wallet: "wallet" }));
    expect(wallet?.claimAction).toBeUndefined();
    expect(wallet?.walletAction?.id).toBe("wallet");
  });
});

describe("red packet review (confirm page, 4.3)", () => {
  it("maps the review renderer onto its bound send key, and falls back on an unconfirmed original command", () => {
    expect(flareRedPacketReviewPlan(confirm())).toMatchObject({ kind: "review", amount: "8.88", currency: "CNY", packetKind: "lucky", shareCount: 3, ownedActionIds: ["commit"] });
    expect(flareRedPacketReviewPlan(confirm({ journal: { commandId: "original", known: false } }))).toBeUndefined();
    const unsent = confirm(); unsent.presentation!.actions = {};
    expect(flareRedPacketReviewPlan(unsent)).toBeUndefined();
  });

  it("draws the kit review with the symbol and the kind line, and sends through the host", async () => {
    const { wrapper, action } = render(confirm());
    const review = wrapper.getComponent(FlareRedPacketReview);
    expect(review.props()).toMatchObject({ amount: "¥8.88", kindLabel: "拼手气红包 · 3 个", blessing: "恭喜发财", submitLabel: "发送红包" });
    expect(wrapper.text()).toContain("勿新建红包重复扣款");
    review.vm.$emit("submit");
    expect(action).toHaveBeenCalledExactlyOnceWith("commit");
  });

  it("keeps the plain document, warning and recovery on the page when the review does not map", () => {
    const page = { pluginId: "any.plugin", page: "any.plugin.page.confirm" };
    const wrapper = mount(FlarePluginPage, { props: { page, view: confirm({ journal: { commandId: "original", known: false } }), onAction: vi.fn() } });
    expect(wrapper.findComponent(FlareRedPacketReview).exists()).toBe(false);
    expect(wrapper.find('[data-action-id="recovery"]').exists()).toBe(true);
    expect(wrapper.text()).toContain("勿新建红包重复扣款");
  });
});

describe("FlareRedPacketPage", () => {
  it("says how many are in the group under the count, never in a direct conversation", () => {
    // The host's group size (viewer included), not the member search's rows (which leave the viewer out).
    const members = [{ userId: "a", name: "A" }, { userId: "b", name: "B" }];
    expect(render(compose(), { members, memberCount: 12 }).wrapper.getComponent(FlareRedPacketComposer).props("memberCount")).toBe(12);
    expect(render(compose(), { members }).wrapper.getComponent(FlareRedPacketComposer).props("memberCount")).toBeUndefined();
    const direct = compose();
    direct.presentation!.actions = { submitDirect: "prepareDirect" };
    direct.actions = [{ id: "prepareDirect", label: "塞钱进红包", form: ["amount", "greeting"] }];
    expect(render(direct, { members, memberCount: 2 }).wrapper.getComponent(FlareRedPacketComposer).props("memberCount")).toBeUndefined();
    const page = { pluginId: "any.plugin", page: "any.plugin.page.compose" };
    const hosted = mount(FlarePluginPage, { props: { page, view: compose(), memberCount: 7, onAction: vi.fn() } });
    expect(hosted.getComponent(FlareRedPacketComposer).props("memberCount")).toBe(7);
  });

  it("distinguishes an already paid claim from its still-unconfirmed original command", () => {
    const view = packet(details({ viewerRole: "claimer", status: "completed", claimsListed: true, myAmountMinor: "1" }),
      { journal: { known: false, commandId: "original", capabilityId: "flare.redpacket.ui.claim" } }, [], {});
    const { wrapper } = render(view, { error: "结果暂未确认，请稍后查看" });
    expect(wrapper.text()).toContain("红包已存入钱包");
    expect(wrapper.text()).toContain("原操作仍待确认");
  });

  it("rejects a quantity over the live product limit before preparing a packet", async () => {
    const { wrapper, action } = render(compose({ maxRecipients: 4 }));
    const composer = wrapper.getComponent(FlareRedPacketComposer);
    composer.vm.$emit("update:amount", "0.08"); composer.vm.$emit("update:count", 8); await flushPromises();
    composer.vm.$emit("submit"); await flushPromises();
    expect(action).not.toHaveBeenCalled();
    expect(composer.props("errorField")).toBe("count");
    expect(composer.props("error")).toContain("4");
  });

  it("checks a failed claim by refreshing the existing detail without submitting another claim", async () => {
    const refresh = vi.fn();
    const { wrapper, action } = render(packet(), { error: "结果暂未确认", onRefresh: refresh });
    const sheet = wrapper.getComponent(FlareRedPacketOpenSheet);
    expect(sheet.props("reviewOnError")).toBe(true);
    sheet.vm.$emit("viewDetails"); await flushPromises();
    expect(refresh).toHaveBeenCalledOnce();
    expect(action).not.toHaveBeenCalled();
    expect(sheet.props("open")).toBe(false);
  });

  it("claims through the host from 開 and opens the wallet from the deposited row", async () => {
    const { wrapper, action } = render(packet());
    wrapper.getComponent(FlareRedPacketOpenSheet).vm.$emit("open");
    expect(action).toHaveBeenCalledExactlyOnceWith("claim");
    const claimed = render(packet(details({ viewerRole: "claimer", myAmountMinor: "1" }), {},
      [{ id: "wallet", label: "查看钱包", target: { kind: "page", page: "flare.wallet.page.home", pluginId: "flare.wallet" } }], { wallet: "wallet" }));
    expect(claimed.wrapper.findComponent(FlareRedPacketOpenSheet).props("open")).toBe(false);
    // The page is a fragment led by its (absent) error banner, so the row is looked up in the detail it draws.
    await claimed.wrapper.getComponent(FlareRedPacketDetail).get("[data-detail-deposited]").trigger("click");
    expect(claimed.action).toHaveBeenCalledExactlyOnceWith("wallet");
  });

  it("restores only the active flow draft after remount without preparing another payment", async () => {
    const contentState: Record<string, unknown> = {};
    const first = render(compose(), { contentState });
    let composer = first.wrapper.getComponent(FlareRedPacketComposer);
    composer.vm.$emit("update:amount", "0.01"); composer.vm.$emit("update:count", 3); composer.vm.$emit("update:greeting", "Keep this greeting"); await flushPromises();
    first.wrapper.unmount();
    const second = render(compose(), { contentState });
    composer = second.wrapper.getComponent(FlareRedPacketComposer);
    expect(composer.props()).toMatchObject({ amount: "0.01", count: 3, greeting: "Keep this greeting" });
    expect(first.action).not.toHaveBeenCalled();
    expect(second.action).not.toHaveBeenCalled();
    expect(render().wrapper.getComponent(FlareRedPacketComposer).props("amount")).toBe("");
  });

  it("does not restore a recipient absent from the currently authorized member choices", async () => {
    const contentState = { redPacketDraft: { kind: "exclusive", amount: "0.01", count: 1, greeting: "Hi", recipientId: "no-longer-selectable" } };
    const { wrapper, action } = render(compose(), { contentState, members: [{ userId: "other", name: "Current member" }] });
    const composer = wrapper.getComponent(FlareRedPacketComposer);
    composer.vm.$emit("submit"); await flushPromises();
    expect(composer.props("errorField")).toBe("recipient");
    expect(action).not.toHaveBeenCalled();
  });

  it("uses the Kit composer and exact currency values, and rejects an over-limit group total", async () => {
    const { wrapper, action } = render();
    const composer = wrapper.getComponent(FlareRedPacketComposer);
    composer.vm.$emit("update:amount", "6.00"); composer.vm.$emit("update:count", 2); await flushPromises();
    expect(composer.props("total")).toBe("¥12.00");
    composer.vm.$emit("submit");
    expect(action).not.toHaveBeenCalled();
    composer.vm.$emit("update:amount", "0.01"); await flushPromises();
    composer.vm.$emit("submit");
    expect(action).toHaveBeenCalledExactlyOnceWith("prepare", { formValues: { kind: "normal", amount: { amount: "0.01", currency: "CNY" }, shareCount: 2, greeting: "恭喜发财，大吉大利" } });
  });

  it("does not open the sheet while busy and preserves absent private amounts in the Kit detail", () => {
    const { wrapper } = render(packet(), { busyActionId: "claim" });
    const detail = wrapper.getComponent(FlareRedPacketDetail);
    expect(detail.props("details").totalMinor).toBeUndefined();
    expect(detail.props("details").myAmountMinor).toBeUndefined();
    expect(wrapper.getComponent(FlareRedPacketOpenSheet).props("state")).toBe("opening");
  });

  it("a direct conversation offers a single ordinary packet and submits no hidden kind/count fields", async () => {
    const view = compose();
    view.presentation!.actions = { submitDirect: "prepareDirect" };
    view.actions = [{ id: "prepareDirect", label: "塞钱进红包", form: ["amount", "greeting"] }];
    const { wrapper, action } = render(view);
    const composer = wrapper.getComponent(FlareRedPacketComposer);
    expect(composer.props("kinds")).toEqual(["normal"]);
    composer.vm.$emit("update:amount", "0.01"); await flushPromises();
    composer.vm.$emit("submit");
    expect(action).toHaveBeenCalledExactlyOnceWith("prepareDirect", { formValues: { amount: { amount: "0.01", currency: "CNY" }, greeting: "恭喜发财，大吉大利" } });
  });

  it("identifies the invalid quantity and returns focus to it without preparing a payment", async () => {
    const { wrapper, action } = render();
    const composer = wrapper.getComponent(FlareRedPacketComposer);
    composer.vm.$emit("update:amount", "1.00"); composer.vm.$emit("update:count", 0); await flushPromises();
    composer.vm.$emit("submit"); await flushPromises();
    expect(action).not.toHaveBeenCalled();
    expect(composer.props("errorField")).toBe("count");
    expect(composer.get('input[inputmode="numeric"]').attributes("aria-invalid")).toBe("true");
    expect(composer.get('input[inputmode="decimal"]').attributes("aria-invalid")).toBeUndefined();
  });

  it("marks recipient validation separately from amount and keeps host-wide errors global", async () => {
    const { wrapper, action } = render();
    const composer = wrapper.getComponent(FlareRedPacketComposer);
    composer.vm.$emit("update:kind", "exclusive"); composer.vm.$emit("update:amount", "1.00"); await flushPromises();
    composer.vm.$emit("submit"); await flushPromises();
    expect(action).not.toHaveBeenCalled();
    expect(composer.props("errorField")).toBe("recipient");
    expect(composer.props("error")).toBe("请选择发给谁");
    const failed = render(compose(), { error: "网络暂不可用" }).wrapper.getComponent(FlareRedPacketComposer);
    expect(failed.props("errorField")).toBe("form");
    expect(failed.get('input[inputmode="decimal"]').attributes("aria-invalid")).toBeUndefined();
  });

  it("keeps an over-limit quantity on the form without preparing a command", async () => {
    const { wrapper, action } = render();
    const composer = wrapper.getComponent(FlareRedPacketComposer);
    composer.vm.$emit("update:amount", "0.01"); composer.vm.$emit("update:count", 101); await flushPromises();
    composer.vm.$emit("submit"); await flushPromises();
    expect(action).not.toHaveBeenCalled();
    expect(composer.props("errorField")).toBe("count");
  });
});

describe("FlarePluginPage routes the red packet renderers", () => {
  const page = { pluginId: "any.plugin", page: "any.plugin.page.compose" };
  it("draws the kit composer for redPacket.compose whatever the plugin id, and sends the page's form", async () => {
    const action = vi.fn();
    const wrapper = mount(FlarePluginPage, { props: { page, view: compose(), onAction: action } });
    const composer = wrapper.getComponent(FlareRedPacketComposer);
    composer.vm.$emit("update:amount", "0.01"); await flushPromises();
    composer.vm.$emit("submit"); await flushPromises();
    expect(action).toHaveBeenCalledExactlyOnceWith("prepare", expect.objectContaining({ page, formValues: expect.objectContaining({ shareCount: 1 }) }));
  });

  it("draws the plain document when the view does not map, and keeps the detail's other actions", () => {
    const unbound = compose(); unbound.presentation!.actions = {};
    expect(mount(FlarePluginPage, { props: { page, view: unbound, onAction: vi.fn() } }).findComponent(FlareRedPacketComposer).exists()).toBe(false);
    const view = packet(details(), {}, [{ id: "claim", label: "领取红包" }, { id: "cancel", label: "取消并退回未领取资金", style: "danger" }]);
    const wrapper = mount(FlarePluginPage, { props: { page, view, onAction: vi.fn() } });
    expect(wrapper.findComponent(FlareRedPacketDetail).exists()).toBe(true);
    expect(wrapper.find('[data-action-id="cancel"]').exists()).toBe(true);
    expect(wrapper.find('[data-action-id="claim"]').exists()).toBe(false);
  });
});
