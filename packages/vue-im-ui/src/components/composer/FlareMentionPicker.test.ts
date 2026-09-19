// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";
import { defineComponent, h, nextTick, type Component } from "vue";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import FlareMentionPicker from "./FlareMentionPicker.vue";

const candidates = [
  { id: "u_xu", name: "徐知远" },
  { id: "u_chen", name: "陈默" },
  { id: "u_chenxi", name: "陈曦" },
];

function mountPicker() {
  const host = mount(defineComponent({ setup() {
    useFlareI18nProvider("zh-CN");
    return () => h(FlareMentionPicker as Component, { candidates, allowEveryone: true });
  } }), { attachTo: document.body });
  return { host, picker: host.findComponent(FlareMentionPicker as Component) };
}

describe("FlareMentionPicker", () => {
  it("picks the first match with Enter while focus stays in the search field", async () => {
    const { host, picker } = mountPicker();
    const search = host.get("input.flare-mention__search");
    expect(search.attributes("role")).toBe("combobox");
    await search.setValue("陈");
    const options = host.findAll('[role="option"]');
    expect(options.map((option) => option.get("strong").text())).toEqual(["陈默", "陈曦"]);
    expect(search.attributes("aria-activedescendant")).toBe(options[0].attributes("id"));
    await search.trigger("keydown", { key: "Enter" });
    expect(picker.emitted("select")).toEqual([[candidates[1]]]);
    host.unmount();
  });

  it("moves the highlight with the arrow keys and wraps", async () => {
    const { host, picker } = mountPicker();
    const search = host.get("input.flare-mention__search");
    await search.setValue("陈");
    await search.trigger("keydown", { key: "ArrowDown" });
    await nextTick();
    expect(host.findAll('[role="option"]')[1].attributes("aria-selected")).toBe("true");
    await search.trigger("keydown", { key: "ArrowDown" });
    await nextTick();
    expect(host.findAll('[role="option"]')[0].attributes("aria-selected")).toBe("true");
    await search.trigger("keydown", { key: "ArrowUp" });
    await search.trigger("keydown", { key: "Enter" });
    expect(picker.emitted("select")).toEqual([[candidates[2]]]);
    host.unmount();
  });

  it("ignores the Enter that commits an IME composition, and closes on Escape", async () => {
    const { host, picker } = mountPicker();
    const search = host.get("input.flare-mention__search");
    await search.trigger("keydown", { key: "Enter", isComposing: true });
    await search.trigger("keydown", { key: "Enter", keyCode: 229 });
    expect(picker.emitted("select")).toBeUndefined();
    await search.trigger("keydown", { key: "Escape" });
    expect(picker.emitted("close")).toHaveLength(1);
    host.unmount();
  });
});
