// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { defineComponent, h } from "vue";
import { describe, expect, it } from "vitest";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import FlareQuickPhrases from "./FlareQuickPhrases.vue";

const groups = [
  { key: "greet", title: "问候", phrases: [{ id: "g1", text: "在的，请讲" }, { id: "g2", text: "稍等一下" }] },
  { key: "close", title: "收尾", phrases: [{ id: "c1", text: "感谢反馈" }] },
];

function render(props: Record<string, unknown>) {
  return mount(defineComponent({
    setup() {
      useFlareI18nProvider("zh-CN");
      return () => h(FlareQuickPhrases, props);
    },
  }));
}

/**
 * Canned replies: one group at a time, a phrase reports its text and nothing else, and the manage
 * control only exists when the host can act on it. Release criterion §1 (component tests).
 */
describe("FlareQuickPhrases", () => {
  it("opens on the first group and lists its phrases", () => {
    const wrapper = render({ groups });
    expect(wrapper.findAll(".flare-quick-phrases__item").map((b) => b.text())).toEqual([
      "在的，请讲", "稍等一下",
    ]);
  });

  it("switches groups, and says which one is showing", async () => {
    const wrapper = render({ groups });
    const tabs = wrapper.findAll('[role="tab"]');
    expect(tabs.map((t) => t.attributes("aria-selected"))).toEqual(["true", "false"]);

    await tabs[1].trigger("click");
    expect(wrapper.findAll(".flare-quick-phrases__item").map((b) => b.text())).toEqual(["感谢反馈"]);
    expect(wrapper.findAll('[role="tab"]').map((t) => t.attributes("aria-selected"))).toEqual(["false", "true"]);
  });

  it("offers no tab strip for a single group", () => {
    const wrapper = render({ groups: [groups[0]] });
    expect(wrapper.find('[role="tablist"]').exists()).toBe(false);
    expect(wrapper.findAll(".flare-quick-phrases__item")).toHaveLength(2);
  });

  it("reports the phrase's text, so a host inserts words and not an id", async () => {
    const wrapper = render({ groups });
    await wrapper.findAll(".flare-quick-phrases__item")[1].trigger("click");
    expect(wrapper.findComponent(FlareQuickPhrases).emitted("select")?.[0]).toEqual(["稍等一下"]);
  });

  it("shows the manage control only when the host asked for it", async () => {
    expect(render({ groups }).find(".flare-quick-phrases__manage").exists()).toBe(false);
    const wrapper = render({ groups, manageable: true });
    await wrapper.find(".flare-quick-phrases__manage").trigger("click");
    expect(wrapper.findComponent(FlareQuickPhrases).emitted("manage")).toHaveLength(1);
  });

  it("draws an empty list rather than breaking when there are no groups", () => {
    const wrapper = render({ groups: [] });
    expect(wrapper.findAll(".flare-quick-phrases__item")).toHaveLength(0);
  });
});
