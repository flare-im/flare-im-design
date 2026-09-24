// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { defineComponent, h } from "vue";
import { describe, expect, it } from "vitest";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import FlareTranslationView from "./FlareTranslationView.vue";

/** The kit's strings come from a provider, the way a host mounts the kit. */
function render(props: InstanceType<typeof FlareTranslationView>["$props"]) {
  return mount(defineComponent({
    setup() {
      useFlareI18nProvider("zh-CN");
      return () => h(FlareTranslationView, props);
    },
  }));
}

/**
 * A translation says three things: the result, who translated it, and — on request — what was
 * translated. The source is hidden until asked for, so a reader is not shown the same message
 * twice. Release criterion §1 (component tests).
 */
describe("FlareTranslationView", () => {
  it("shows the result and says a translation is what it is", () => {
    const wrapper = render({ translated: "See you tomorrow" });
    expect(wrapper.find(".flare-translation__text").text()).toBe("See you tomorrow");
    expect(wrapper.find(".flare-translation__by").text()).toContain("翻译");
  });

  it("names the provider when the host knows it", () => {
    const wrapper = render({ translated: "hi", provider: "DeepL" });
    expect(wrapper.find(".flare-translation__by").text()).toContain("DeepL");
  });

  it("keeps the source hidden until it is asked for, and hides it again", async () => {
    const wrapper = render({ translated: "See you tomorrow", original: "明天见" });
    expect(wrapper.find(".flare-translation__original").exists()).toBe(false);

    const toggle = wrapper.find(".flare-translation__toggle");
    await toggle.trigger("click");
    expect(wrapper.find(".flare-translation__original").text()).toBe("明天见");

    await wrapper.find(".flare-translation__toggle").trigger("click");
    expect(wrapper.find(".flare-translation__original").exists()).toBe(false);
  });

  it("offers no toggle when there is no source to show", () => {
    const wrapper = render({ translated: "hi" });
    expect(wrapper.find(".flare-translation__toggle").exists()).toBe(false);
  });

  it("while it is translating, says so instead of showing an empty result", () => {
    const wrapper = render({ translated: "", original: "明天见", pending: true });
    expect(wrapper.find(".flare-translation__pending").exists()).toBe(true);
    expect(wrapper.find(".flare-translation__text").exists()).toBe(false);
    expect(wrapper.find(".flare-translation__toggle").exists()).toBe(false);
    expect(wrapper.find(".flare-translation").classes()).toContain("is-pending");
  });
});
