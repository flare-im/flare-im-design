// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { defineComponent, h, reactive } from "vue";
import { describe, expect, it, vi } from "vitest";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import FlareReauthSheet from "./FlareReauthSheet.vue";
import FlareSelect from "./FlareSelect.vue";
function fixture(extra = {}) {
  const props = reactive({ destinations: [{ id: "opaque-a", label: "+86 •••• 1234" }, { id: "opaque-b", label: "a•••@example.test" }], selectedId: "opaque-a", code: "", canSend: true, canSubmit: true, ...extra });
  const view = mount(defineComponent({ setup() { useFlareI18nProvider("en-US"); return () => h(FlareReauthSheet, props); } }), { global: { stubs: { FlareBottomSheet: { template: "<section><slot/></section>" } } } });
  const sheet = view.findComponent(FlareReauthSheet);
  const button = (label: string) => view.findAll("button").find(item => item.text() === label)!;
  return { props, view, sheet, button };
}
describe("host-driven reauthentication sheet", () => {
  it("emits only opaque destination selection, code edits and explicit actions", async () => {
    const { view, sheet, button } = fixture();
    view.findComponent(FlareSelect).vm.$emit("update:modelValue", "opaque-b");
    await view.get("input").setValue("1234567"); await button("Send code").trigger("click"); await button("Confirm").trigger("click");
    expect(sheet.emitted("selectDestination")).toEqual([["opaque-b"]]);
    expect(sheet.emitted("changeCode")).toEqual([["123456"]]);
    expect(sheet.emitted("send")).toEqual([[]]); expect(sheet.emitted("submit")).toEqual([[]]);
    expect(view.get("input").attributes("autocomplete")).toBe("one-time-code");
    view.unmount();
  });
  it("takes the cooldown from the host and permits cancellation during a request", async () => {
    vi.useFakeTimers();
    const { view, sheet, button } = fixture({ resendInSeconds: 20, sending: true });
    await button("Send again (20s)").trigger("click"); await button("Confirm").trigger("click");
    vi.advanceTimersByTime(5000); expect(view.text()).toContain("Send again (20s)");
    expect(sheet.emitted("send")).toBeUndefined(); expect(sheet.emitted("submit")).toBeUndefined();
    await button("Cancel").trigger("click"); expect(sheet.emitted("cancel")).toEqual([[]]);
    view.unmount(); vi.useRealTimers();
  });
  it("cannot send or submit with an unavailable destination", async () => {
    const { view, sheet, button } = fixture({ selectedId: "unknown" });
    await button("Send code").trigger("click"); await button("Confirm").trigger("click");
    expect(sheet.emitted("send")).toBeUndefined(); expect(sheet.emitted("submit")).toBeUndefined(); view.unmount();
  });
});
