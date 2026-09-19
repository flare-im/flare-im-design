// @vitest-environment happy-dom
import { afterEach, describe, expect, it } from "vitest";
import { mount } from "@vue/test-utils";
import { defineComponent, h, type Component } from "vue";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import FlareScreen from "./FlareScreen.vue";

let host: ReturnType<typeof mount> | undefined;
afterEach(() => { host?.unmount(); host = undefined; });

function mountScreen(props: Record<string, unknown>) {
  host = mount(defineComponent({
    setup() {
      useFlareI18nProvider("zh-CN");
      return () => h(FlareScreen as Component, props, { default: () => h("p", "内容") });
    },
  }));
  return host;
}

describe("FlareScreen", () => {
  it("names its back button in the interface language", async () => {
    let backs = 0;
    const screen = mountScreen({ title: "设置", back: true, onBack: () => { backs += 1; } });
    const back = screen.get(".flare-screen__back");
    expect(back.attributes("aria-label")).toBe("返回");
    await back.trigger("click");
    expect(backs).toBe(1);
  });

  it("puts a readable page in the reading column only when asked", () => {
    expect(mountScreen({ title: "我" }).classes()).not.toContain("flare-screen--readable");
    host?.unmount();
    expect(mountScreen({ title: "我", readable: true }).get(".flare-screen").classes()).toContain("flare-screen--readable");
  });
});
