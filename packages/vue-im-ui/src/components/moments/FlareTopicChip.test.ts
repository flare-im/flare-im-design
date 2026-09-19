// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";
import FlareTopicChip from "./FlareTopicChip.vue";

/**
 * A topic reads as `#topic` and is a real button, so a keyboard reaches it and a screen reader
 * announces it as one. Release criterion §1 (component tests).
 */
describe("FlareTopicChip", () => {
  it("writes the hash itself, so a host passes the topic and not the punctuation", () => {
    const wrapper = mount(FlareTopicChip, { props: { topic: "设计评审" } });
    expect(wrapper.text()).toBe("#设计评审");
  });

  it("is a button a keyboard can reach", () => {
    const wrapper = mount(FlareTopicChip, { props: { topic: "release" } });
    expect(wrapper.element.tagName).toBe("BUTTON");
    expect(wrapper.attributes("type")).toBe("button");
  });

  it("reports the tap and decides nothing itself", async () => {
    const wrapper = mount(FlareTopicChip, { props: { topic: "release" } });
    await wrapper.trigger("click");
    expect(wrapper.emitted("click")).toHaveLength(1);
  });
});
