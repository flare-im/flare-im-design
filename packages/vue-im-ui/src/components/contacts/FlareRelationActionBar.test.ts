// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { defineComponent, h, type Component } from "vue";
import { describe, expect, it } from "vitest";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import FlareRelationActionBar from "./FlareRelationActionBar.vue";

function mountBar(props: Record<string, unknown>) {
  return mount(defineComponent({
    setup() {
      useFlareI18nProvider("zh-CN");
      return () => h(FlareRelationActionBar as Component, { relation: "none", capabilities: { add: true }, ...props });
    },
  }));
}
const labels = (wrapper: ReturnType<typeof mountBar>) =>
  wrapper.findAll(".flare-relation-bar__row > button").map((button) => button.text());

describe("FlareRelationActionBar add label", () => {
  it("words the add key from addText, for where the person goes", async () => {
    const wrapper = mountBar({ addText: "添加到通讯录" });
    expect(labels(wrapper)).toEqual(["添加到通讯录"]);
    await wrapper.get(".flare-relation-bar__row > button").trigger("click");
    expect(wrapper.findComponent(FlareRelationActionBar).emitted("action")).toEqual([[{ action: "add" }]]);
  });

  it("keeps the kit's add label without addText", () => {
    expect(labels(mountBar({}))).toEqual(["添加好友"]);
  });
});
