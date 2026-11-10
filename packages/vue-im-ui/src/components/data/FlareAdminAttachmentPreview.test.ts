// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { nextTick } from "vue";
import { afterEach, describe, expect, it } from "vitest";
import Preview from "./FlareAdminAttachmentPreview.vue";
const props = {
  open: true,
  title: "Private media",
  url: "https://objects.test/file",
  closeText: "Close",
  downloadText: "Download",
  failedText: "Media unavailable",
};
afterEach(() => {
  document.body.innerHTML = "";
});
describe("private attachment preview presentation", () => {
  it("unmounts media when closed rather than leaving a playing element during modal leave", async () => {
    const host = mount(Preview, {
      attachTo: document.body,
      props: { ...props, kind: "video" },
    });
    expect(document.querySelector("video")).not.toBeNull();
    await host.setProps({ open: false });
    await nextTick();
    expect(document.querySelector("video")).toBeNull();
    host.unmount();
  });
  it("shows an explicit native playback failure without exposing the URL in text", async () => {
    const host = mount(Preview, {
      attachTo: document.body,
      props: { ...props, kind: "audio" },
    });
    document.querySelector("audio")?.dispatchEvent(new Event("error"));
    await nextTick();
    expect(document.body.textContent).toContain("Media unavailable");
    expect(document.body.textContent).not.toContain(props.url);
    host.unmount();
  });
  it("uses neutral failure content for message-owning hosts and keeps the close action available", async () => {
    const host = mount(Preview, {
      attachTo: document.body,
      props: { ...props, error: "Preview unavailable", errorPresentation: "neutral" },
    });
    expect(document.querySelector(".n-alert")).toBeNull();
    expect(document.querySelector('[role="status"]')?.textContent).toContain("Preview unavailable");
    const close = Array.from(document.querySelectorAll("button")).find((button) => button.textContent === "Close");
    close?.click();
    await nextTick();
    expect(host.emitted("close")).toHaveLength(1);
    host.unmount();
  });
  it("keeps native playback failure neutral without exposing private URLs", async () => {
    const host = mount(Preview, {
      attachTo: document.body,
      props: { ...props, kind: "audio", errorPresentation: "neutral" },
    });
    document.querySelector("audio")?.dispatchEvent(new Event("error"));
    await nextTick();
    expect(document.querySelector(".n-alert")).toBeNull();
    expect(document.querySelector('[role="status"]')?.textContent).toContain("Media unavailable");
    expect(document.body.textContent).not.toContain(props.url);
    host.unmount();
  });
});
