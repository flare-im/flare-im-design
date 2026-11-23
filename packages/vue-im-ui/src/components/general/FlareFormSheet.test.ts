// @vitest-environment happy-dom
import { afterEach, describe, expect, it } from "vitest";
import { mount } from "@vue/test-utils";
import { defineComponent, h, nextTick, reactive, type Component } from "vue";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import FlareFormSheet from "./FlareFormSheet.vue";

let wrapper: ReturnType<typeof mount> | undefined;
let host: ReturnType<typeof mount> | undefined;
let sheetProps: Record<string, unknown>;
function setup(props: Record<string, unknown>) {
  sheetProps = reactive(props);
  host = mount(defineComponent({ setup() {
    useFlareI18nProvider("zh-CN");
    return () => h(FlareFormSheet as Component, sheetProps, { default: () => h("input", { value: "draft" }) });
  } }), { attachTo: document.body });
  return host.findComponent(FlareFormSheet);
}
async function setProps(props: Record<string, unknown>) { Object.assign(sheetProps, props); await nextTick(); }
afterEach(() => { host?.unmount(); wrapper = undefined; document.body.innerHTML = ""; });
describe.each([false, true])("shared edit sheet (fill: %s)", (fill) => {
  it("keeps a busy draft open for Escape, scrim and submit, then restores cancellation", async () => {
    wrapper = setup({ open: true, title: "Edit", busy: true, fill });
    await nextTick();
    expect(document.querySelector('[role="dialog"]')?.getAttribute("aria-label")).toBe("Edit");
    expect(document.querySelector("fieldset")?.disabled).toBe(true);
    document.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape", bubbles: true }));
    (document.querySelector(".flare-overlay-scrim") as HTMLElement).click();
    document.querySelector("form")!.dispatchEvent(new Event("submit", { bubbles: true, cancelable: true }));
    expect(wrapper.emitted("close")).toBeUndefined();
    expect(wrapper.emitted("confirm")).toBeUndefined();
    await setProps({ busy: false });
    document.dispatchEvent(new KeyboardEvent("keydown", { key: "Escape", bubbles: true }));
    expect(wrapper.emitted("close")).toHaveLength(1);
  });
  it("shows compact reply context once and keeps the native draft on a retry", async () => {
    wrapper = setup({ open: true, title: "回复评论", description: "回复 陈默", density: "compact", error: "发送失败", confirmLabel: "重试", fill });
    await nextTick();
    expect(document.querySelector(".flare-form-sheet__description")?.textContent).toBe("回复 陈默");
    expect(document.querySelector("input")?.value).toBe("draft");
    const retry = Array.from(document.querySelectorAll("button")).find(button => button.textContent === "重试")!;
    retry.click(); await nextTick();
    expect(wrapper.emitted("confirm")).toHaveLength(1);
    expect(wrapper.emitted("close")).toBeUndefined();
  });
  it("retains the field value and exposes a failed save without closing", async () => {
    wrapper = setup({ open: true, title: "Edit", confirmDisabled: true, fill });
    await nextTick();
    document.querySelector("form")!.dispatchEvent(new Event("submit", { bubbles: true, cancelable: true }));
    expect(wrapper.emitted("confirm")).toBeUndefined();
    await setProps({ confirmDisabled: false });
    document.querySelector("form")!.dispatchEvent(new Event("submit", { bubbles: true, cancelable: true }));
    expect(wrapper.emitted("confirm")).toHaveLength(1);
    await setProps({ error: "Save failed" });
    expect(document.querySelector('[role="alert"]')?.textContent).toBe("Save failed");
    expect(document.querySelector("input")?.value).toBe("draft");
    expect(wrapper.emitted("close")).toBeUndefined();
  });
});
