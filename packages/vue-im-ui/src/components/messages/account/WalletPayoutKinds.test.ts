// @vitest-environment happy-dom
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { enableAutoUnmount, mount } from "@vue/test-utils";
import { defineComponent, h } from "vue";
import { afterEach, describe, expect, it } from "vitest";
import { useFlareI18nProvider } from "../../../shared/i18n/useFlareI18n";
import type { FlarePluginPageViewModel } from "../../../shared/contracts/plugin-ui";
import FlarePluginForm from "../../form/FlarePluginForm.vue";
import FlarePluginPage from "../FlarePluginPage.vue";

type Fixture = {
  variant: "all4" | "alipay_only" | "empty";
  locale: "zh-CN" | "en-US";
  page: string;
  sourceData: Record<string, unknown>;
  view: FlarePluginPageViewModel;
};
const fixtures = JSON.parse(readFileSync(resolve(__dirname,
  "../../../../../../spec/wallet-payout-kind-vectors.json"), "utf8")) as {
    contractVersion: string;
    cases: Fixture[];
  };
enableAutoUnmount(afterEach);
afterEach(() => { document.body.innerHTML = ""; });

describe("0.3.2 resolved payout-kind choices", () => {
  it.each(fixtures.cases)("renders $variant in $locale without a static fallback", fixture => {
    expect(fixtures.contractVersion).toBe("0.3.2");
    const view = structuredClone({ ...fixture.view, data: fixture.sourceData });
    const actions: unknown[] = [];
    const wrapper = mount(defineComponent({ setup() {
      useFlareI18nProvider(fixture.locale);
      return () => h(FlarePluginPage, {
        page: { pluginId: "flare.wallet", page: fixture.page }, view,
        onAction: (...args) => actions.push(args),
      });
    } }), { attachTo: document.body });
    const kind = view.inputs!.find(input => input.id === "kind")!;
    expect(kind.default).toBeUndefined();
    expect((kind.choices ?? []).map(choice => choice.value)).toEqual(
      fixture.variant === "all4" ? ["bankCard", "alipay", "wechat", "address"]
        : fixture.variant === "alipay_only" ? ["alipay"] : [],
    );
    expect((kind.choices ?? []).map(choice => choice.label)).toEqual(
      fixture.variant === "empty" ? [] : fixture.variant === "alipay_only" ? [fixture.locale === "en-US" ? "Alipay" : "支付宝"]
        : fixture.locale === "en-US" ? ["Bank card", "Alipay", "WeChat", "Payout address"] : ["银行卡", "支付宝", "微信", "收款地址"],
    );
    expect(wrapper.text()).toContain("Example owner");
    expect(wrapper.text()).toContain("****1234");
    const rows = view.blocks!.find(block => block.kind === "rows")!;
    if (rows.kind !== "rows") throw new Error("Expected the original profile rows");
    expect(rows.rows[0].actions.map(action => action.id)).toEqual(["default", "remove"]);
    if (fixture.variant === "empty") {
      expect(wrapper.findComponent(FlarePluginForm).exists()).toBe(false);
      expect(wrapper.find("[data-form-submit]").exists()).toBe(false);
      expect(wrapper.find("[data-flow-form-unavailable]").exists()).toBe(false);
      expect(wrapper.text()).toContain(fixture.locale === "en-US"
        ? "No payout method types are currently enabled. Existing payout methods can still be viewed and managed."
        : "当前未开放可用的收款类型，已有收款方式仍可查看和管理。");
    } else {
      const form = wrapper.getComponent(FlarePluginForm);
      expect(form.props("inputs").find(input => input.id === "kind")).toEqual(kind);
      expect(wrapper.findAll("[data-form-submit]")).toHaveLength(1);
    }
    expect(actions).toEqual([]);
  });
});
