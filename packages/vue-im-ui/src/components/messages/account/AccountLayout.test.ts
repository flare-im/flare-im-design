// @vitest-environment happy-dom
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { enableAutoUnmount, flushPromises, mount } from "@vue/test-utils";
import { defineComponent, h, type Component } from "vue";
import { afterEach, describe, expect, it } from "vitest";
import { useFlareI18nProvider } from "../../../shared/i18n/useFlareI18n";
import type { FlarePluginPageViewModel } from "../../../shared/contracts/plugin-ui";
import FlareScreen from "../../layout/FlareScreen.vue";
import FlarePluginPage from "../FlarePluginPage.vue";
import FlareAccountView from "./FlareAccountView.vue";

type LayoutCase = { id: string; locale: "zh-CN" | "en-US"; layout: string; page: string; view: FlarePluginPageViewModel; expected: { urgentTexts: string[]; informationTexts: string[] } };
const vectors = JSON.parse(readFileSync(resolve(__dirname, "../../../../../../spec/account-layout-vectors.json"), "utf8")) as { cases: LayoutCase[] };
enableAutoUnmount(afterEach);

function render(component: Component, props: Record<string, unknown>, locale: "zh-CN" | "en-US" = "zh-CN") {
  return mount(defineComponent({ setup() {
    useFlareI18nProvider(locale);
    return () => h(component, props);
  } }));
}
function leafText(root: Element, text: string) {
  return [...root.querySelectorAll("*")].filter(node => node.textContent === text && ![...node.children].some(child => child.textContent === text));
}

describe("shared account layout", () => {
  for (const item of vectors.cases.filter(item => item.layout !== "flow")) {
    it(`${item.id}: keeps actionable warnings visible once while ordinary information waits behind its row`, async () => {
      const wrapper = render(FlareAccountView, { view: item.view }, item.locale);
      for (const text of item.expected.urgentTexts) expect(leafText(wrapper.element, text), text).toHaveLength(1);
      // W-06: the information is a list row opening a panel, not a fold on the page.
      for (const text of item.expected.informationTexts) expect(leafText(wrapper.element, text), text).toHaveLength(0);
      await wrapper.get("[data-account-information]").trigger("click");
      await flushPromises();
      const panel = [...document.body.querySelectorAll("[data-account-information-panel]")].at(-1)!;
      for (const text of item.expected.informationTexts) expect(leafText(panel, text), text).toHaveLength(1);
      for (const text of item.expected.urgentTexts) {
        expect(leafText(wrapper.element, text)).toHaveLength(1);
        expect(leafText(panel, text)).toHaveLength(0);
      }
    });
  }

  it("groups ledger context before description and keeps their original strings", () => {
    const item = vectors.cases.find(item => item.id === "ledger-en-US")!;
    const wrapper = render(FlareAccountView, { view: item.view }, item.locale);
    const intro = wrapper.get(".flare-account-view__ledger-intro");
    expect(intro.element.children[0].textContent).toBe(item.view.presentation!.props.contextLabel);
    expect(intro.element.children[1].textContent).toBe(item.view.presentation!.props.description);
  });

  it("preserves the legacy no-layout note placement and information panel", async () => {
    const item = vectors.cases[0];
    const view = structuredClone(item.view);
    delete view.presentation!.props.layout;
    const wrapper = render(FlareAccountView, { view });
    for (const text of item.expected.urgentTexts.slice(0, 2)) expect(leafText(wrapper.element, text)).toHaveLength(0);
    const note = leafText(wrapper.element, item.expected.urgentTexts[2])[0];
    expect(Boolean(wrapper.get(".flare-account-view__balance").element.compareDocumentPosition(note) & Node.DOCUMENT_POSITION_FOLLOWING)).toBe(true);
    await wrapper.get("[data-account-information]").trigger("click");
    await flushPromises();
    const panel = [...document.body.querySelectorAll("[data-account-information-panel]")].at(-1)!;
    for (const text of item.expected.urgentTexts.slice(0, 2)) expect(leafText(panel, text)).toHaveLength(1);
  });

  for (const state of ["loading", "error", "unavailable", "document", "account"] as const) {
    it(`keeps the page frame at its default width during ${state}`, () => {
      const item = vectors.cases[0];
      const props = { page: { pluginId: "fixture", page: item.page }, title: "Wallet", ...(state === "loading" ? { loading: true } : state === "error" ? { error: "Try again" } : { view: { ...item.view, available: state !== "unavailable", ...(state === "document" ? { presentation: undefined } : {}) } }) };
      const wrapper = render(FlarePluginPage, props);
      expect(wrapper.getComponent(FlareScreen).props("contentMaxWidth")).toBe(880);
      expect(wrapper.get<HTMLElement>(".flare-screen").element.style.getPropertyValue("--flare-screen-content-max-width")).toBe("880px");
    });
  }

  it("supports an explicit page frame and explicit unconstrained width", async () => {
    const props = { page: { pluginId: "fixture", page: "page" }, title: "Wallet", contentMaxWidth: 640 };
    const wrapper = mount(FlarePluginPage, { props });
    expect(wrapper.get<HTMLElement>(".flare-screen").element.style.getPropertyValue("--flare-screen-content-max-width")).toBe("640px");
    await wrapper.setProps({ contentMaxWidth: null });
    expect(wrapper.get<HTMLElement>(".flare-screen").element.style.getPropertyValue("--flare-screen-content-max-width")).toBe("");
  });

  for (const width of [undefined, null, 0, -1, NaN, Infinity]) {
    it(`leaves an ordinary Screen unconstrained at ${width}`, () => {
      const wrapper = render(FlareScreen, { title: "Settings", contentMaxWidth: width });
      expect(wrapper.get<HTMLElement>(".flare-screen").element.style.getPropertyValue("--flare-screen-content-max-width")).toBe("");
    });
  }
});

// R10: the wallet head and its wallet rows keep their money formats through the account derivation.
describe("account amounts with a currency", () => {
  it("writes the balance head and a wallet row through the payment formatter", async () => {
    const { flareAccountDocument, flareAccountEntries } = await import("./account");
    const money = (minor: string, scale: number, currency: string) => ({ kind: "money" as const, minor, scale, currency });
    const view = flareAccountDocument({ available: true, title: "钱包", fields: [], actions: [], blocks: [
      { kind: "section", label: "", blocks: [{ kind: "hero", label: "可用余额", value: "1234.56", amount: true, maskable: true, tone: "neutral", format: money("123456", 2, "CNY") }] },
      { kind: "rows", source: "wallets", columns: [{ label: "余额", format: "text" }, { label: "钱包", format: "text" }],
        rows: [{ key: "w1", cells: [{ text: "1234", format: money("1234", 0, "LABPOINT") }, { text: "积分钱包" }], actions: [] }], actions: [] },
    ] } as unknown as FlarePluginPageViewModel);
    expect(view.fields[0].value).toBe("¥1,234.56");
    expect(flareAccountEntries(view)[0].amount).toBe("1,234 LABPOINT");
  });
});
