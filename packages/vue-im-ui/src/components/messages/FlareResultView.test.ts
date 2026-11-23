// @vitest-environment happy-dom
// R7 (docs/plugin-experience.md): the done key is pinned to the bottom on phones and centred on PC; more keys go in the
// contract slot `actions`.
import { enableAutoUnmount, mount } from "@vue/test-utils";
import { defineComponent, h } from "vue";
import { afterEach, describe, expect, it } from "vitest";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import { useFlarePlatformProvider } from "../../shared/platform/useFlarePlatform";
import FlareResultView from "./FlareResultView.vue";

enableAutoUnmount(afterEach);

function render(phone: boolean) {
  const events: string[] = [];
  const wrapper = mount(defineComponent({
    setup() {
      useFlareI18nProvider("zh-CN");
      useFlarePlatformProvider({ capabilities: { bottomSheet: phone } });
      return () => h(FlareResultView, { title: "转账成功", tone: "success", onDone: () => events.push("done") }, {
        actions: () => h("button", { "data-extra": "true" }, "查看原单"),
      });
    },
  }));
  return { wrapper, events };
}

describe("FlareResultView keys", () => {
  it("pins the done key to the bottom on phones and draws the actions slot after it", async () => {
    const { wrapper, events } = render(true);
    const keys = wrapper.get("[data-result-keys]");
    expect(keys.classes()).toContain("is-pinned");
    expect(keys.find("[data-extra]").exists()).toBe(true);
    await wrapper.get("[data-result-done]").trigger("click");
    expect(events).toEqual(["done"]);
    expect(wrapper.get("[data-result-done]").text()).toBe("完成");
  });

  it("keeps the keys in flow on PC", () => {
    const { wrapper } = render(false);
    expect(wrapper.get("[data-result-keys]").classes()).not.toContain("is-pinned");
  });

  it("folds reference fields into the References group instead of the details (R3)", () => {
    const wrapper = mount(defineComponent({
      setup() {
        useFlareI18nProvider("zh-CN");
        return () => h(FlareResultView, { title: "转账成功", tone: "success", details: [
          { label: "金额", value: "¥99.00" },
          { label: "资金单", value: "fund-7731", format: { kind: "reference", id: "fund-7731", labelled: false } },
        ] });
      },
    }));
    expect(wrapper.get(".flare-result__details").text()).toContain("¥99.00");
    expect(wrapper.get(".flare-result__details").text()).not.toContain("fund-7731");
    expect(wrapper.get("[data-references]").text()).toContain("fund-7731");
  });
});
