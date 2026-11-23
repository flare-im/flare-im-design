// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";
import FlareTextMessage from "./FlareTextMessage.vue";
import TextView from "../MessagesView/views/TextView.vue";
import FlareEmojiMessage from "./FlareEmojiMessage.vue";
import FrozenStickerThumb from "../../composer/FrozenStickerThumb/index.vue";

describe("canonical text body", () => {
  it("escapes quotes and HTML instead of injecting link attributes", () => {
    const text = 'https://example.com/"onclick="alert(1) <img src=x onerror=alert(2)> [bad](javascript:alert(3))';
    const wrapper = mount(FlareTextMessage, { props: { text } });
    expect(wrapper.find("[onclick], [onerror], img, script").exists()).toBe(false);
    expect(wrapper.findAll("a").every(a => /^(https?:|mailto:)/.test(a.attributes("href") ?? ""))).toBe(true);
    expect(wrapper.text()).toContain("<img src=x onerror=alert(2)>");
  });

  it("dispatches runtime text through the public body", () => {
    const wrapper = mount(TextView, { props: { content: { contentType: "text", text: { text: "Hello" } }, isSelf: true } });
    expect(wrapper.findComponent(FlareTextMessage).props()).toMatchObject({ self: true, selectable: true });
    expect(wrapper.find(".fm-text").exists()).toBe(true);
    expect(wrapper.text()).toBe("Hello");
  });

  it("keeps formatting and link events without message metadata", async () => {
    const wrapper = mount(FlareTextMessage, { props: { text: "**Review** https://example.com", selectable: true } });
    expect(wrapper.find("strong").text()).toBe("Review");
    await wrapper.find("a").trigger("click");
    expect(wrapper.emitted("linkClick")?.[0]).toEqual(["https://example.com/"]);
    expect(wrapper.find("time, .flare-message-meta").exists()).toBe(false);
  });

  it("animates only a sent standalone emoji and freezes mixed inline emoji", async () => {
    const standalone = mount(FlareTextMessage, { props: { text: "[alien]" } });
    expect(standalone.findComponent(FlareEmojiMessage).exists()).toBe(true);
    expect(standalone.findComponent(FlareEmojiMessage).props("animated")).toBe(true);

    const inline = mount(FlareTextMessage, { props: { text: "hello [alien]" } });
    expect(inline.findComponent(FlareEmojiMessage).exists()).toBe(false);
    expect(inline.findComponent(FrozenStickerThumb).exists()).toBe(true);
  });

  it("highlights the mention span alongside emoji without highlighting literal text", () => {
    const wrapper = mount(FlareTextMessage, { props: {
      text: "@林夏 [alien] 提到 @我",
      mentions: [{ start: 0, length: 3, self: true, all: false }],
    } });
    expect(wrapper.findAll(".fm-text__mention")).toHaveLength(1);
    expect(wrapper.get(".fm-text__mention.is-me").text()).toBe("@林夏");
    expect(wrapper.findComponent(FrozenStickerThumb).exists()).toBe(true);
    expect(wrapper.text()).toContain("提到 @我");
  });
});
