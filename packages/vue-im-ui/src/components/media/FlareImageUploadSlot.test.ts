// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";
import FlareImageUploadSlot from "./FlareImageUploadSlot.vue";

const base = {
  title: "Document front",
  statusText: "Not uploaded",
  pickLabel: "Choose photo",
};
describe("FlareImageUploadSlot", () => {
  it("separates native picker and transfer intents for a local selection", async () => {
    const wrapper = mount(FlareImageUploadSlot, {
      props: { ...base, state: "empty" },
    });
    await wrapper.get("button").trigger("click");
    expect(wrapper.emitted("choose")).toHaveLength(1);
    expect(wrapper.get("button").attributes("aria-label")).toBe(
      "Choose photo: Document front",
    );
    await wrapper.setProps({
      state: "selected",
      previewUrl: "blob:local",
      statusText: "Selected",
      actionLabel: "Upload",
    });
    expect(wrapper.get("img").attributes("src")).toBe("blob:local");
    await wrapper.get(".flare-button").trigger("click");
    expect(wrapper.emitted("action")).toHaveLength(1);
  });
  it("makes completed materials read-only without inventing a remove or preview request", async () => {
    const wrapper = mount(FlareImageUploadSlot, {
      props: {
        ...base,
        state: "uploaded",
        statusText: "Uploaded",
        actionLabel: "Upload",
      },
    });
    expect(wrapper.get("button").attributes("disabled")).toBeDefined();
    expect(wrapper.find("img").exists()).toBe(false);
    expect(wrapper.find(".flare-button").exists()).toBe(false);
    await wrapper.get("button").trigger("click");
    expect(wrapper.emitted("choose")).toBeUndefined();
  });
  it("offers replacement and retry after failure and disables selection during transfer", async () => {
    const wrapper = mount(FlareImageUploadSlot, {
      props: {
        ...base,
        state: "failed",
        statusText: "Retry required",
        actionLabel: "Retry",
      },
    });
    await wrapper.get(".flare-image-upload__picker").trigger("click");
    await wrapper.get(".flare-button").trigger("click");
    expect(wrapper.emitted("choose")).toHaveLength(1);
    expect(wrapper.emitted("action")).toHaveLength(1);
    await wrapper.setProps({ state: "uploading", disabled: true });
    expect(wrapper.attributes("aria-busy")).toBe("true");
    expect(wrapper.get("progress").attributes("value")).toBeUndefined();
    expect(wrapper.get("button").attributes("disabled")).toBeDefined();
    expect(wrapper.find(".flare-button").exists()).toBe(false);
  });
  it("exposes an independent read-only preview after upload even when editing is closed", async () => {
    const wrapper = mount(FlareImageUploadSlot, {
      props: {
        ...base,
        state: "uploaded",
        disabled: true,
        previewLabel: "View document",
        previewUrl: "blob:private",
      },
    });
    expect(wrapper.get("button").attributes("disabled")).toBeUndefined();
    expect(wrapper.get("button").attributes("aria-label")).toBe(
      "View document: Document front",
    );
    await wrapper.get("button").trigger("click");
    expect(wrapper.emitted("preview")).toHaveLength(1);
    expect(wrapper.emitted("choose")).toBeUndefined();
    expect(wrapper.emitted("action")).toBeUndefined();
    await wrapper.setProps({ previewLoading: true });
    expect(wrapper.attributes("aria-busy")).toBe("true");
    expect(wrapper.find("progress").exists()).toBe(true);
    expect(wrapper.get("button").attributes("disabled")).toBeDefined();
    await wrapper.setProps({ previewLoading: false, previewDisabled: true });
    expect(wrapper.get("button").attributes("disabled")).toBeDefined();
  });
});
