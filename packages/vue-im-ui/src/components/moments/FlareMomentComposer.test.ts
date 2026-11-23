// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { afterEach, describe, expect, it } from "vitest";
import { defineComponent, h, nextTick } from "vue";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import FlareMomentComposer from "./FlareMomentComposer.vue";

const hosts: ReturnType<typeof mount>[] = [];
function open(props: Record<string, unknown> = {}) {
  const host = mount(defineComponent({ setup() {
    useFlareI18nProvider("en-US");
    return () => h(FlareMomentComposer, props);
  } }), { attachTo: document.body });
  hosts.push(host);
  return host.findComponent(FlareMomentComposer);
}
afterEach(() => { hosts.splice(0).forEach(host => host.unmount()); document.body.innerHTML = ""; });

describe("moment editor", () => {
  it("focuses writing on the full page and submits trimmed text only after there is content", async () => {
    const wrapper = open({ layout: "page" });
    await nextTick();
    const input = wrapper.get("textarea");
    expect(document.activeElement).toBe(input.element);
    const post = wrapper.get(".flare-moment-composer__post");
    expect(post.attributes("disabled")).toBeDefined();
    await input.setValue("  A note  ");
    await post.trigger("click");
    expect(wrapper.emitted("submit")).toEqual([["A note"]]);
  });
  it("edits and clears a location in place, with Escape cancelling the local edit", async () => {
    const wrapper = open({ location: "杭州", locationEditable: true });
    await wrapper.get(".flare-moment-composer__row").trigger("click");
    await wrapper.get("input").setValue("  九溪  ");
    await wrapper.get("input").trigger("keydown", { key: "Escape" });
    expect(wrapper.emitted("update:location")).toBeUndefined();
    expect(wrapper.find("input").exists()).toBe(false);
    await wrapper.get(".flare-moment-composer__row").trigger("click");
    expect((wrapper.get("input").element as HTMLInputElement).value).toBe("杭州");
    await wrapper.get("input").setValue("  九溪  ");
    await wrapper.get("input").trigger("keydown", { key: "Enter" });
    expect(wrapper.emitted("update:location")).toEqual([["九溪"]]);
    await wrapper.get(".flare-moment-composer__row").trigger("click");
    await wrapper.get("input").setValue("");
    await wrapper.get("input").trigger("keydown", { key: "Enter" });
    expect(wrapper.emitted("update:location")?.at(-1)).toEqual([""]);
  });
  it("consumes the confirming Enter before returning focus, while leaving IME confirmation alone", async () => {
    const wrapper = open({ locationEditable: true });
    await wrapper.get(".flare-moment-composer__row").trigger("click");
    const input = wrapper.get("input");
    await input.setValue("九溪");
    const composing = new KeyboardEvent("keydown", { key: "Enter", isComposing: true, bubbles: true, cancelable: true });
    input.element.dispatchEvent(composing);
    expect(composing.defaultPrevented).toBe(false);
    expect(wrapper.emitted("update:location")).toBeUndefined();
    const enter = new KeyboardEvent("keydown", { key: "Enter", bubbles: true, cancelable: true });
    input.element.dispatchEvent(enter);
    expect(enter.defaultPrevented).toBe(true);
    await nextTick();
    expect(wrapper.emitted("update:location")).toEqual([["九溪"]]);
    expect(wrapper.find("input").exists()).toBe(false);
  });
  it("preserves native Enter activation on the inline location action buttons", async () => {
    const wrapper = open({ locationEditable: true });
    await wrapper.get(".flare-moment-composer__row").trigger("click");
    for (const button of wrapper.findAll(".flare-moment-composer__location .flare-icon-button")) {
      const enter = new KeyboardEvent("keydown", { key: "Enter", bubbles: true, cancelable: true });
      button.element.dispatchEvent(enter);
      expect(enter.defaultPrevented).toBe(false);
    }
  });
  it("retries the retained text through submit and commits an open location edit first", async () => {
    const wrapper = open({ locationEditable: true, submitError: "Not posted" });
    await wrapper.get("textarea").setValue("  Keep this draft  ");
    await wrapper.get(".flare-moment-composer__row").trigger("click");
    await wrapper.get("input").setValue("  西湖  ");
    await wrapper.get(".flare-status-banner__action").trigger("click");
    expect(wrapper.emitted("update:location")).toEqual([["西湖"]]);
    expect(wrapper.emitted("submit")).toEqual([["Keep this draft"]]);
    expect((wrapper.get("textarea").element as HTMLTextAreaElement).value).toBe("  Keep this draft  ");
  });
  it("locks the draft, cancellation and attachments while a post or upload is busy", async () => {
    const wrapper = open({ busy: true, images: ["fixture.jpg"] });
    expect(wrapper.get("textarea").attributes("disabled")).toBeDefined();
    for (const control of wrapper.findAll("button")) {
      expect(control.attributes("disabled")).toBeDefined();
      await control.trigger("click");
    }
    expect(wrapper.emitted("cancel")).toBeUndefined();
    expect(wrapper.emitted("submit")).toBeUndefined();
    expect(wrapper.emitted("removeImage")).toBeUndefined();
  });
});
