// @vitest-environment happy-dom
import { afterEach, describe, expect, it } from "vitest";
import { mount } from "@vue/test-utils";
import { defineComponent, h } from "vue";
import { NButton, NPopover } from "naive-ui";
import FlareAdminIconPicker from "./FlareAdminIconPicker.vue";
const icon = defineComponent(() => () => h("svg"));
const options = [
  { value: "wallet", label: "钱包图标", component: icon },
  { value: "gift", label: "红包图标", component: icon },
];
const hosts: ReturnType<typeof mount>[] = [];
afterEach(() => hosts.splice(0).forEach((h) => h.unmount()));
describe("admin icon picker", () => {
  it("selects a catalog key through a named preview button and offers a default", async () => {
    const host = mount(FlareAdminIconPicker, { props: { options } });
    hosts.push(host);
    host.findComponent(NPopover).vm.$emit("update:show", true);
    await host.vm.$nextTick();
    const select = host
      .findAllComponents(NButton)
      .find((b) => b.attributes("aria-label") === "钱包图标");
    expect(select).toBeDefined();
    await select!.trigger("click");
    expect(host.emitted("update:modelValue")).toEqual([["wallet"]]);
    expect(host.findComponent(NPopover).props("show")).toBe(false);
  });
  it("does not open or change a disabled configuration", async () => {
    const host = mount(FlareAdminIconPicker, {
      props: { options, disabled: true, modelValue: "gift" },
    });
    hosts.push(host);
    host.findComponent(NPopover).vm.$emit("update:show", true);
    await host.vm.$nextTick();
    expect(host.findComponent(NPopover).props("show")).toBe(false);
    expect(host.findComponent(NButton).props("disabled")).toBe(true);
    expect(host.emitted("update:modelValue")).toBeUndefined();
  });
});
