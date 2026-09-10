// @vitest-environment happy-dom
import { afterEach, describe, expect, it } from "vitest";
import { mount } from "@vue/test-utils";
import { defineComponent, h, type Component } from "vue";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import MessageActionSheet from "./MessageActionSheet.vue";
import { FLARE_COMPOSER_ACTION_IDS, type FlareComposerAction } from "../../shared/contracts/composer";

let host: ReturnType<typeof mount>;
afterEach(() => { host?.unmount(); });

function mountSheet(props: Record<string, unknown> = {}, locale: "zh-CN" | "en-US" = "en-US") {
  host = mount(defineComponent({ setup() {
    useFlareI18nProvider(locale);
    return () => h(MessageActionSheet as Component, props);
  } }));
  return host.findComponent(MessageActionSheet);
}

describe("FlareMessageActionSheet", () => {
  it("defaults to the unified id table (no create_ prefix, no thread) with t() labels", () => {
    const sheet = mountSheet();
    const ids = sheet.findAll("button").map((b) => b.attributes("data-action-id"));
    expect(ids).toEqual([...FLARE_COMPOSER_ACTION_IDS]);
    expect(sheet.find('[data-action-id="file"]').text()).toBe("File");
    expect(sheet.find('[data-action-id="vote"]').text()).toBe("Vote");
    expect(sheet.attributes("aria-label")).toBe("Message features");
  });

  it("localizes default labels through the strings provider", () => {
    const sheet = mountSheet({}, "zh-CN");
    expect(sheet.find('[data-action-id="file"]').text()).toBe("文件");
    expect(sheet.find('[data-action-id="camera"]').text()).toBe("拍摄");
  });

  it("emits action(action) and the deprecated build(op) with the legacy op name", async () => {
    const sheet = mountSheet();
    await sheet.find('[data-action-id="link"]').trigger("click");
    const action = sheet.emitted("action")?.[0]?.[0] as FlareComposerAction;
    expect(action.id).toBe("link");
    expect(sheet.emitted("build")?.[0]).toEqual(["create_link_card"]);
    await sheet.find('[data-action-id="file"]').trigger("click");
    expect(sheet.emitted("build")?.[1]).toEqual(["create_file"]);
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
    expect(sheet.emitted("build")?.[0]).toEqual(["tenant_form"]);
  });
});
