// @vitest-environment happy-dom
import { afterEach, describe, expect, it } from "vitest";
import { mount } from "@vue/test-utils";
import { defineComponent, h, type Component } from "vue";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import FlareComposerActionPanel from "./FlareComposerActionPanel.vue";
import { FLARE_DEFAULT_COMPOSER_ACTION_IDS, type FlareComposerAction } from "../../shared/contracts/composer";

let host: ReturnType<typeof mount>;
afterEach(() => { host?.unmount(); });

function mountSheet(props: Record<string, unknown> = {}, locale: "zh-CN" | "en-US" = "en-US") {
  host = mount(defineComponent({ setup() {
    useFlareI18nProvider(locale);
    return () => h(FlareComposerActionPanel as Component, props);
  } }));
  return host.findComponent(FlareComposerActionPanel);
}

describe("FlareComposerActionPanel", () => {
  it("defaults to the restrained unified action set with t() labels", () => {
    const sheet = mountSheet();
    const ids = sheet.findAll("button").map((b) => b.attributes("data-action-id"));
    expect(ids).toEqual([...FLARE_DEFAULT_COMPOSER_ACTION_IDS]);
    expect(sheet.find('[data-action-id="file"]').text()).toBe("File");
    expect(sheet.find('[data-action-id="contact"]').text()).toBe("Contact card");
    expect(sheet.attributes("aria-label")).toBe("Message features");
  });

  it("localizes default labels through the strings provider", () => {
    const sheet = mountSheet({}, "zh-CN");
    expect(sheet.find('[data-action-id="file"]').text()).toBe("文件");
    expect(sheet.find('[data-action-id="voice"]').text()).toBe("语音");
  });

  it("emits the selected action object", async () => {
    const sheet = mountSheet();
    await sheet.find('[data-action-id="image"]').trigger("click");
    const action = sheet.emitted("action")?.[0]?.[0] as FlareComposerAction;
    expect(action.id).toBe("image");
  });

  it("renders host-supplied actions verbatim and passes their ids through", async () => {
    const actions: FlareComposerAction[] = [
      { id: "tenant_form", label: "Form", hint: "Survey", icon: "edit" },
      { id: "vote", label: "Poll" },
    ];
    const sheet = mountSheet({ actions });
    expect(sheet.findAll("button")).toHaveLength(2);
    expect(sheet.find('[data-action-id="tenant_form"] small').text()).toBe("Survey");
    await sheet.find('[data-action-id="tenant_form"]').trigger("click");
    expect((sheet.emitted("action")?.[0]?.[0] as FlareComposerAction).id).toBe("tenant_form");
  });

  it("filters hidden and unavailable actions while preserving disabled actions", async () => {
    const actions: FlareComposerAction[] = [
      { id: "image", label: "Image", enabled: false },
      { id: "voice", label: "Voice", visible: false },
      { id: "order", label: "Order", intent: "open-order" },
    ];
    const sheet = mountSheet({ actions, capabilities: { availableActionIds: ["image", "order"] } });
    expect(sheet.findAll("button").map((button) => button.attributes("data-action-id"))).toEqual(["image", "order"]);
    expect(sheet.find('[data-action-id="image"]').attributes("disabled")).toBeDefined();
    await sheet.find('[data-action-id="image"]').trigger("click");
    expect(sheet.emitted("action")).toBeUndefined();
  });

  it("renders Vue icon components as well as semantic glyph names", () => {
    const Glyph = defineComponent({ render: () => h("svg", { "data-custom-icon": "true" }) });
    const wrapper = mountSheet({ actions: [
      { id: "image", label: "Image", icon: "image" },
      { id: "custom", label: "Approval", icon: Glyph, tone: "amber" },
    ] });
    expect(wrapper.findAll("[data-custom-icon]")).toHaveLength(1);
    expect(wrapper.get('[data-action-id="custom"]').attributes("data-tone")).toBe("amber");
  });
});
