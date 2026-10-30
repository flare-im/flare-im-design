// @vitest-environment happy-dom
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { enableAutoUnmount, flushPromises, mount } from "@vue/test-utils";
import { defineComponent, h } from "vue";
import { afterEach, describe, expect, it } from "vitest";
import { useFlareI18nProvider } from "../../../shared/i18n/useFlareI18n";
import type { FlarePluginActionPayload, FlarePluginPageActionPayload, FlarePluginPageViewModel } from "../../../shared/contracts/plugin-ui";
import FlareAccountView from "./FlareAccountView.vue";
import FlarePluginPage from "../FlarePluginPage.vue";
import { flareAccountDayKey, flareAccountEntries } from "./account";
const fixture = JSON.parse(readFileSync(resolve(__dirname, "../../../../../../spec/account-view-vectors.json"), "utf8"));
const model = (): FlarePluginPageViewModel => structuredClone(fixture.view);
enableAutoUnmount(afterEach);
afterEach(() => { document.body.innerHTML = ""; });
function render(view = model(), page = false) {
  const actions: Array<[string, FlarePluginActionPayload | FlarePluginPageActionPayload]> = [];
  const wrapper = mount(defineComponent({ setup() {
    useFlareI18nProvider("zh-CN");
    return () => page ? h(FlarePluginPage, { page: { pluginId: "example", page: "wallet" }, view, appearance: "account", onAction: (id, payload) => actions.push([id, payload]) }) : h(FlareAccountView, { view, onAction: (id, payload) => actions.push([id, payload]) });
  } }), { attachTo: document.body });
  return { wrapper, actions };
}
function button(label: string): HTMLButtonElement { return [...document.body.querySelectorAll("button")].find(button => button.textContent?.trim() === label)!; }
describe("account presentation", () => {
  it("keeps server display amounts and bound row identities intact", () => {
    const entries = flareAccountEntries(model());
    expect(entries.map(entry => entry.amount)).toEqual(fixture.expect.amounts);
    expect(entries.map(entry => entry.key)).toEqual(fixture.expect.entryKeys);
    const view = model(); const block = view.blocks!.find(block => block.kind === "rows")!;
    if (block.kind === "rows") block.rows = [...block.rows, block.rows[0]];
    expect(flareAccountEntries(view)).toHaveLength(fixture.expect.amounts.length);
    expect(flareAccountDayKey(Number.NaN)).toBe("unknown");
    expect(flareAccountDayKey()).toBe("unknown");
  });
  it("separates a hidden balance from visible transaction amounts", async () => {
    const { wrapper } = render();
    expect(wrapper.get("[data-account-balance]").text()).toBe("¥1,288.66");
    await wrapper.get('button[aria-label="隐藏余额"]').trigger("click");
    expect(wrapper.get("[data-account-balance]").text()).toBe("••••");
    expect(wrapper.get(".flare-account-view__balance").text()).not.toContain("¥1,288.66");
    expect(wrapper.text()).toContain("+¥88.88");
    expect(wrapper.get("details").attributes("open")).toBeUndefined();
  });
  it("opens record details even without a packet action, and never invents funding controls", async () => {
    const { wrapper, actions } = render();
    await wrapper.get('[data-account-entry="tx-04"]').trigger("click");
    await flushPromises();
    expect(document.body.textContent).toContain("交易详情");
    expect(document.body.textContent).toContain("tx-04");
    expect(actions).toHaveLength(0);
    expect([...document.body.querySelectorAll('[role="dialog"] button')].some(node => node.textContent?.includes("查看红包"))).toBe(false);
    expect(wrapper.text()).not.toContain("提现");
    expect(wrapper.text()).not.toContain("充值");
  });
  it("forwards the original row input and page data when opening its packet", async () => {
    const view = { ...model(), data: { opaque: "kept" } };
    const { wrapper, actions } = render(view, true);
    await wrapper.get('[data-account-entry="tx-01"]').trigger("click");
    await flushPromises();
    button("查看红包").click();
    await flushPromises();
    expect(actions).toEqual([["open", { page: { pluginId: "example", page: "wallet" }, data: { opaque: "kept" }, row: { key: "tx-01", input: { packetId: "packet-01" } } }]]);
  });
  it("shows an honest empty ledger without changing the balance", () => {
    const view = model(); view.blocks = [];
    const { wrapper } = render(view);
    expect(wrapper.text()).toContain("暂无交易记录");
    expect(wrapper.get("[data-account-balance]").text()).toBe("¥1,288.66");
  });
  it("uses the declared account section in wallet details instead of calling a wallet a transaction", async () => {
    const view = model();
    view.presentation = {renderer: "account", props: {sectionTitle: "我的钱包", groupByDate: false}, actions: {}};
    const { wrapper } = render(view);
    await wrapper.get('[data-account-entry="tx-04"]').trigger("click");
    await flushPromises();
    const dialog = document.body.querySelector('[role="dialog"]')!;
    expect(dialog.textContent).toContain("我的钱包");
    expect(dialog.textContent).toContain("记录编号");
    expect(dialog.textContent).not.toContain("交易单号");
  });
  it("does not render account contents for an unavailable page", () => {
    const { wrapper } = render({ ...model(), available: false, unavailableReason: "no_permission" }, true);
    expect(wrapper.find(".flare-account-view").exists()).toBe(false);
    expect(wrapper.text()).not.toContain("¥1,288.66");
  });
});
