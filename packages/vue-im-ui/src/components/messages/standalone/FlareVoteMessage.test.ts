// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";
import { h } from "vue";
import FlareUiProvider from "../../../design-system/provider/FlareUiProvider.vue";
import FlareVoteMessage from "./FlareVoteMessage.vue";
import VoteView from "../business/FlareVoteMessageView.vue";

describe("canonical poll body", () => {
  it("does not invent results and keeps read-only options non-interactive", async () => {
    const wrapper = mount(FlareVoteMessage, { props: { title: "Select", options: [{ text: "First" }], readOnly: true } });
    expect(wrapper.text()).not.toContain("%");
    expect(wrapper.find("button").exists()).toBe(false);
    await wrapper.find(".opt").trigger("click");
    expect(wrapper.emitted("select")).toBeUndefined();
  });
  it("clamps known results and emits the actual option and index", async () => {
    const option = { text: "First", pct: 200 };
    const wrapper = mount(FlareVoteMessage, { props: { options: [option] } });
    expect(wrapper.text()).toContain("100%");
    await wrapper.find("button").trigger("click");
    expect(wrapper.emitted("select")?.[0]).toEqual([option, 0]);
  });
  it("uses the public body for runtime votes without result data", () => {
    const wrapper = mount(FlareUiProvider, { slots: { default: () => h(VoteView, {
      isSelf: true, content: { contentType: "vote", vote: { title: "Lunch", options: ["A", "B"] } },
    }) } });
    expect(wrapper.findComponent(FlareVoteMessage).exists()).toBe(true);
    expect(wrapper.text()).not.toContain("0 votes");
    expect(wrapper.text()).not.toContain("0%");
  });
});
