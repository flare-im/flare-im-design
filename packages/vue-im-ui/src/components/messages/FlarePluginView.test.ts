// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";
import FlarePluginView from "./FlarePluginView.vue";
const view = { available: true, title: "<script>unsafe()</script>", fields: [{ label: "Amount", value: "100" }], actions: [{ id: "claim", label: "Claim" }] };
describe("plugin view", () => {
  it("renders inert text and emits only an action ID", async () => {
    const wrapper = mount(FlarePluginView, { props: { view } });
    expect(wrapper.find("script").exists()).toBe(false);
    await wrapper.get("button").trigger("click");
    expect(wrapper.emitted("action")).toEqual([["claim"]]);
  });
  it("removes actions and private fields from unavailable history", () => {
    const wrapper = mount(FlarePluginView, { props: { view: { ...view, available: false } } });
    expect(wrapper.find("button").exists()).toBe(false);
    expect(wrapper.find("dl").exists()).toBe(false);
  });
  it("blocks repeated actions while a command is unresolved", () => {
    const wrapper = mount(FlarePluginView, { props: { view, busy: true } });
    expect(wrapper.get("button").attributes("disabled")).toBeDefined();
  });
});
