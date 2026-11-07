// @vitest-environment happy-dom
import { afterEach, describe, expect, it, vi } from "vitest";
import { mount } from "@vue/test-utils";
import { defineComponent, h, nextTick, reactive, type Slot } from "vue";
import { NButton, NFormItem, NInput, NPopover } from "naive-ui";
import FlareAdminSettings from "./FlareAdminSettings.vue";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";

function setup(options: {
  props: { label: string; title?: string; density?: "comfortable" | "compact" };
  slots?: Record<string, Slot>;
}) {
  return mount(
    defineComponent({
      setup() {
        useFlareI18nProvider("zh-CN");
        return () => h(FlareAdminSettings, options.props, options.slots);
      },
    }),
  );
}

const hosts: ReturnType<typeof mount>[] = [];
afterEach(() => {
  hosts.splice(0).forEach((host) => host.unmount());
  vi.restoreAllMocks();
  vi.unstubAllGlobals();
  document.body.innerHTML = "";
});
describe("FlareAdminSettings", () => {
  it("composes a compact heading with the existing scope, preserves its draft and disabled tools", async () => {
    const props = reactive({ label: "插件工作区", title: "审核中心", density: "compact" as "comfortable" | "compact" });
    const host = setup({ props, slots: {
      scope: () => [h(NInput, { defaultValue: "Application A", inputProps: { "aria-label": "应用" } })],
      tools: () => [h(NButton, { disabled: true }, () => "管理与配置")],
      default: () => [h("p", "Business records")],
    } });
    hosts.push(host);
    expect(host.get("header h3").text()).toBe("审核中心");
    const input = host.get('input[aria-label="应用"]');
    props.title = "配置发布";
    props.density = "comfortable";
    await nextTick();
    expect(host.get("header h3").text()).toBe("配置发布");
    expect(host.get("input").element).toBe(input.element);
    expect((input.element as HTMLInputElement).value).toBe("Application A");
    expect(host.get("header button").attributes("disabled")).toBeDefined();
    expect(host.text()).toContain("Business records");
  });
  it("adapts navigation to a compact selector while preserving the content and its draft", async () => {
    let width = 1000;
    let resize = () => {};
    vi.stubGlobal("ResizeObserver", class {
      constructor(callback: () => void) { resize = callback; }
      observe() {}
      disconnect() {}
    });
    vi.spyOn(HTMLElement.prototype, "getBoundingClientRect").mockImplementation(() => new DOMRect(0, 0, width, 800));
    const host = setup({ props: { label: "Plugin data" }, slots: {
      navigation: () => [h("nav", { "aria-label": "Plugins" }, "Poll / Task")],
      "compact-navigation": () => [h("select", { "aria-label": "Plugins" }, [h("option", "Poll")])],
      default: () => [h(NInput, { defaultValue: "Keep draft" })],
    } });
    hosts.push(host);
    await nextTick();
    const input = host.get("input").element;
    expect(host.find("aside nav").exists()).toBe(true);
    expect(host.find("select").exists()).toBe(false);
    width = 700;
    resize();
    await nextTick();
    expect(host.find("aside").exists()).toBe(false);
    expect(host.find('select[aria-label="Plugins"]').exists()).toBe(true);
    expect(host.get("input").element).toBe(input);
    expect(host.get("input").element.value).toBe("Keep draft");
    width = 1000;
    resize();
    await nextTick();
    expect(host.find("aside nav").exists()).toBe(true);
    expect(host.get("input").element).toBe(input);
  });

  it("composes native controls, a labelled workspace and separate protected notices", async () => {
    const host = setup({
      props: { label: "Settings" },
      slots: {
        scope: () => [h(NFormItem, { label: "Scope" }, () => h(NInput))],
        tools: () => [h(NButton, { disabled: true }, () => "Refresh")],
        help: () => [h("p", "Ordinary documentation")],
        notice: () => [h("div", { role: "alert" }, "Unknown write: reconcile")],
        default: () => [h("p", "Content")],
        footer: () => [h(NButton, { disabled: true }, () => "Save")],
      },
    });
    hosts.push(host);
    expect(host.attributes("aria-label")).toBe("Settings");
    expect(host.find("h1").exists()).toBe(false);
    expect(host.get('[role="alert"]').text()).toContain("Unknown write");
    expect(host.findComponent(NPopover).props("show")).toBe(false);
    const help = host.get("button[aria-expanded]");
    const trigger = help.element;
    await help.trigger("click");
    expect(host.findComponent(NPopover).props("show")).toBe(true);
    expect(host.get("button[aria-expanded]").element).toBe(trigger);
    await help.trigger("click");
    expect(host.findComponent(NPopover).props("show")).toBe(false);
    expect(
      host.get(".flare-admin-settings__footer button").attributes("disabled"),
    ).toBeDefined();
    expect(host.findComponent(NInput).exists()).toBe(true);
  });
  it("adapts by the workspace width without remounting or losing an input draft", async () => {
    let width = 1000;
    let resize = () => {};
    const disconnect = vi.fn();
    vi.stubGlobal(
      "ResizeObserver",
      class {
        constructor(callback: () => void) {
          resize = callback;
        }
        observe() {}
        disconnect = disconnect;
      },
    );
    vi.spyOn(HTMLElement.prototype, "getBoundingClientRect").mockImplementation(
      () => new DOMRect(0, 0, width, 800),
    );
    const host = setup({
      props: { label: "Settings" },
      slots: {
        default: ({ narrow }: { narrow: boolean }) => [
          h("output", String(narrow)),
          h(NInput, { defaultValue: "Draft" }),
        ],
      },
    });
    hosts.push(host);
    await nextTick();
    const input = host.get("input").element;
    expect(host.get("output").text()).toBe("false");
    width = 390;
    resize();
    await nextTick();
    expect(host.get("output").text()).toBe("true");
    expect(host.get("input").element).toBe(input);
    expect(host.get("input").element.value).toBe("Draft");
    host.unmount();
    hosts.pop();
    expect(disconnect).toHaveBeenCalledOnce();
  });
  it("does not add a save action, footer or business behavior without host slots", () => {
    const host = setup({ props: { label: "Read only" } });
    hosts.push(host);
    expect(host.find("footer").exists()).toBe(false);
    expect(host.findComponent(NButton).exists()).toBe(false);
    expect(host.emitted()).toEqual({});
  });
});
