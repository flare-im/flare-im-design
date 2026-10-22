// @vitest-environment happy-dom
import { afterEach, describe, expect, it } from "vitest";
import { mount } from "@vue/test-utils";
import { defineComponent, h, type Component } from "vue";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import FlareComposerActionPanel from "./FlareComposerActionPanel.vue";
import FlareGlyph from "../general/FlareGlyph.vue";
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
  it("defaults to the built-in features in panel order, each with its glyph and t() label", () => {
    const sheet = mountSheet();
    const ids = sheet.findAll("button").map((b) => b.attributes("data-action-id"));
    expect(ids).toEqual([...FLARE_DEFAULT_COMPOSER_ACTION_IDS]);
    expect(ids).toEqual(["image", "camera", "video", "file", "voice", "location", "card"]);
    expect(sheet.findAllComponents(FlareGlyph).map((glyph) => glyph.props("icon"))).toEqual(["image", "camera", "video", "file", "mic", "location", "card"]);
    expect(sheet.findAll(".flare-action-panel__label").map((label) => label.text()))
      .toEqual(["Image", "Camera", "Video", "File", "Voice", "Location", "Contact card"]);
    // Polls come from the poll plugin now.
    expect(sheet.find('[data-action-id="poll"]').exists()).toBe(false);
    expect(sheet.find('[data-action-id="contact"]').exists()).toBe(false);
    expect(sheet.attributes("aria-label")).toBe("Message features");
  });

  it("localizes default labels through the strings provider", () => {
    const sheet = mountSheet({}, "zh-CN");
    expect(sheet.findAll(".flare-action-panel__label").map((label) => label.text()))
      .toEqual(["图片", "拍摄", "视频", "文件", "语音", "位置", "名片"]);
  });

  it("labels built-in items a host passes without a label, and draws plugin items after them", () => {
    const actions: FlareComposerAction[] = [
      { id: "image", kind: "feature", icon: "image", order: 10 },
      { id: "poll", kind: "feature", icon: "poll", order: 60 },
      { id: "plugin:flare.redpacket.send", kind: "plugin", label: "红包", icon: "red-packet", order: 100 },
      { id: "plugin:acme.form", kind: "plugin", label: "表单", icon: "clipboard-form", order: 110 },
      { id: "plugin:acme.vote", kind: "plugin", label: "投票插件", order: 120 },
    ];
    const sheet = mountSheet({ actions }, "zh-CN");
    expect(sheet.findAll(".flare-action-panel__label").map((label) => label.text())).toEqual(["图片", "投票", "红包", "表单", "投票插件"]);
    // 注册表里没有的插件图标名回退到通用插件图标；认识的（red-packet）照用。
    expect(sheet.findAllComponents(FlareGlyph).map((glyph) => glyph.props("icon"))).toEqual(["image", "poll", "red-packet", "plugin", "plugin"]);
    expect(sheet.find('[data-action-id="plugin:acme.form"] [data-flare-glyph="Puzzle"]').exists()).toBe(true);
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
