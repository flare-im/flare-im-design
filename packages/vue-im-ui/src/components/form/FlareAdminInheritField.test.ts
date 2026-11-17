// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { afterEach, describe, expect, it } from "vitest";
import { defineComponent, h, type Component } from "vue";
import { NSwitch } from "naive-ui";
import { useFlareI18nProvider, type FlareLocale } from "../../shared/i18n/useFlareI18n";
import FlareAdminInheritField from "./FlareAdminInheritField.vue";

const hosts: ReturnType<typeof mount>[] = [];
afterEach(() => hosts.splice(0).forEach((host) => host.unmount()));

function mountField(
  props: Record<string, unknown>,
  slots: Record<string, () => unknown> = {},
  locale: FlareLocale = "zh-CN",
) {
  const host = mount(defineComponent({
    setup() {
      useFlareI18nProvider(locale);
      return () => h(FlareAdminInheritField as Component, props, slots);
    },
  }));
  hosts.push(host);
  return host;
}

const custom = () => h("input", { class: "custom-control" });

describe("FlareAdminInheritField", () => {
  it("shows the default read-only while inherited", () => {
    const host = mountField(
      { label: "应用名称", inherited: true, inheritedValue: "IM 控制台" },
      { default: custom },
    );
    expect(host.get(".flare-admin-inherit-field__default").text()).toContain("默认：IM 控制台");
    expect(host.find(".custom-control").exists()).toBe(false);
  });

  it("switching the default off shows the custom control", async () => {
    const host = mountField(
      { label: "应用名称", inherited: true, inheritedValue: "IM 控制台" },
      { default: custom },
    );
    await host.getComponent(NSwitch).trigger("click");
    const field = host.getComponent(FlareAdminInheritField);
    expect(field.emitted("update:inherited")).toEqual([[false]]);

    const own = mountField(
      { label: "应用名称", inherited: false, inheritedValue: "IM 控制台" },
      { default: custom },
    );
    expect(own.find(".custom-control").exists()).toBe(true);
    expect(own.find(".flare-admin-inherit-field__default").exists()).toBe(false);
  });

  it("disabled disables the switch", () => {
    const host = mountField({ label: "应用名称", inherited: true, inheritedValue: "x", disabled: true });
    expect(host.getComponent(NSwitch).props("disabled")).toBe(true);
  });

  it("extra slot sits beside the switch", () => {
    const host = mountField(
      { label: "应用名称", inherited: true, inheritedValue: "x" },
      { extra: () => h("button", { class: "translations" }, "多语言") },
    );
    const side = host.get(".flare-admin-inherit-field__switch");
    expect(side.find(".n-switch").exists()).toBe(true);
    expect(side.get(".translations").text()).toBe("多语言");
  });

  it("english labels", () => {
    const host = mountField({ label: "App name", inherited: true, inheritedValue: "Console" }, {}, "en-US");
    expect(host.get(".flare-admin-inherit-field__switch-text").text()).toBe("Use default");
    expect(host.get(".flare-admin-inherit-field__default").text()).toContain("Default: Console");
    expect(host.getComponent(NSwitch).attributes("aria-label")).toBe("App name · Use default");
  });
});
