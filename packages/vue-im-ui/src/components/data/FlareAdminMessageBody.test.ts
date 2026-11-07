// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { describe, it, expect } from "vitest";
import Body from "./FlareAdminMessageBody.vue";
const labels = {
  empty: "Empty",
  recalled: "Recalled",
  unavailable: "Unavailable",
  preview: "Preview",
  download: "Download",
  more: "Full text",
  kinds: { image: "Image" },
};
const attachments = [
  { id: "a", kind: "image", name: "", size: 10 },
  { id: "b", kind: "file", name: "<report>.txt", size: 20 },
];
describe("admin readable message body", () => {
  it("escapes sender text and file names, and emits only attachment intents", async () => {
    const host = mount(Body, {
      props: {
        state: "available",
        text: "<script>alert(1)</script>\nhello",
        attachments,
        labels,
      },
    });
    expect(host.find("script").exists()).toBe(false);
    expect(host.text()).toContain("<script>alert(1)</script>");
    const buttons = host.findAll("button");
    await buttons[0].trigger("click");
    await buttons[1].trigger("click");
    expect(host.emitted("preview")).toEqual([["a"]]);
    expect(host.emitted("download")).toEqual([["b"]]);
    host.unmount();
  });
  it.each(["recalled", "unavailable"])(
    "never renders hidden %s content or media actions",
    (state) => {
      const host = mount(Body, {
        props: { state, text: "private", attachments, labels },
      });
      expect(host.text()).not.toContain("private");
      expect(host.find("button").exists()).toBe(false);
      host.unmount();
    },
  );
  it("provides compact bounded content and a full-text intent", async () => {
    const host = mount(Body, {
      props: {
        state: "available",
        text: "Long text",
        labels,
        compact: true,
        truncated: true,
      },
    });
    expect(host.classes()).toContain("is-compact");
    await host.get("button").trigger("click");
    expect(host.emitted("more")).toEqual([[]]);
    host.unmount();
  });
});
