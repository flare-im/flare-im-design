// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";
import FlareFileUpload from "./FlareFileUpload.vue";

const labels = {
  title: "Avatar",
  state: "empty" as const,
  statusText: "Choose an image",
  pickLabel: "Choose",
};
function pick(input: HTMLInputElement, files: File[]) {
  Object.defineProperty(input, "files", { configurable: true, value: files });
  input.dispatchEvent(new Event("change", { bubbles: true }));
}
describe("FlareFileUpload", () => {
  it("emits a file with the supplied policy hint and lets the same file be chosen again", () => {
    const wrapper = mount(FlareFileUpload, {
      props: { ...labels, image: true, accept: "image/png,image/jpeg" },
    });
    const input = wrapper.get('input[type="file"]').element as HTMLInputElement;
    expect(wrapper.get('[role="group"]').attributes("aria-label")).toBe(
      "Avatar",
    );
    expect(input.accept).toBe("image/png,image/jpeg");
    const file = new File(["image"], "portrait.png", { type: "image/png" });
    pick(input, [file]);
    pick(input, [file]);
    expect(wrapper.emitted("select")).toEqual([[file], [file]]);
    expect(input.value).toBe("");
    pick(input, []);
    expect(wrapper.emitted("select")).toHaveLength(2);
    wrapper.unmount();
  });
  it("offers replacement and local removal after completion without doing either itself", async () => {
    const wrapper = mount(FlareFileUpload, {
      props: {
        ...labels,
        state: "uploaded",
        image: true,
        previewUrl: "blob:owned",
        replaceLabel: "Replace",
        removeLabel: "Remove",
        fileName: "portrait.png",
      },
    });
    expect(wrapper.get("img").attributes("src")).toBe("blob:owned");
    expect(wrapper.text()).toContain("portrait.png");
    await wrapper
      .findAll("button")
      .find((button) => button.text() === "Remove")!
      .trigger("click");
    expect(wrapper.emitted("remove")).toHaveLength(1);
    expect(wrapper.get("img").attributes("src")).toBe("blob:owned");
    expect(
      wrapper.get(".flare-image-upload__picker").attributes("disabled"),
    ).toBeUndefined();
    wrapper.unmount();
  });
  it("keeps progress and cancellation controlled by the host", async () => {
    const wrapper = mount(FlareFileUpload, {
      props: {
        ...labels,
        state: "uploading",
        progress: 35,
        cancelLabel: "Cancel",
      },
    });
    expect(wrapper.get("progress").attributes("value")).toBe("35");
    expect(wrapper.get("progress").attributes("max")).toBe("100");
    expect(
      wrapper.get('input[type="file"]').attributes("disabled"),
    ).toBeDefined();
    await wrapper
      .findAll("button")
      .find((button) => button.text() === "Cancel")!
      .trigger("click");
    expect(wrapper.emitted("cancel")).toHaveLength(1);
    expect(wrapper.find("progress").exists()).toBe(true);
    await wrapper.setProps({ progress: undefined });
    expect(wrapper.get("progress").attributes("value")).toBeUndefined();
    wrapper.unmount();
  });
  it("does not choose or retry when disabled and does not invent an image policy", async () => {
    const wrapper = mount(FlareFileUpload, {
      props: {
        ...labels,
        state: "failed",
        disabled: true,
        retryLabel: "Retry",
      },
    });
    const input = wrapper.get('input[type="file"]').element as HTMLInputElement;
    expect(input.getAttribute("accept")).toBeNull();
    pick(input, [new File(["data"], "data.bin")]);
    await wrapper
      .findAll("button")
      .find((button) => button.text() === "Retry")!
      .trigger("click");
    expect(wrapper.emitted("select")).toBeUndefined();
    expect(wrapper.emitted("retry")).toBeUndefined();
    wrapper.unmount();
  });
});
