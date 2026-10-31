// @vitest-environment happy-dom
import { flushPromises, mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";
import { defineComponent, h, type Component } from "vue";
import { useFlareI18nProvider } from "../../../../shared/i18n/useFlareI18n";
import type { ContentElem } from "../../../../utils/contentElem";
import AudioView from "./AudioView.vue";
import ImageView from "./ImageView.vue";
import VideoView from "./VideoView.vue";

/**
 * A picture, a video or a voice message whose address resolves to nothing is still that kind of message: it says
 * it is not available right now, in the reader's language, and offers no dead control. The native kits draw the
 * same body for the content a host hands them without an address.
 */
function mountView(view: Component, content: ContentElem, locale = "zh-CN") {
  return mount(defineComponent({
    setup() {
      useFlareI18nProvider(locale);
      return () => h(view, { content, isSelf: false, messageId: "m1" });
    },
  }));
}

describe("media with nothing to load", () => {
  const cases: Array<[string, Component, ContentElem, string, string]> = [
    ["an image", ImageView, { contentType: "image", image: { source: {} } }, "图片暂时无法加载", "Image isn't available right now"],
    ["a video", VideoView, { contentType: "video", video: { source: {}, durationMs: 4000 } }, "视频暂时无法加载", "Video isn't available right now"],
    ["a voice message", AudioView, { contentType: "audio", audio: { durationMs: 4000 } }, "语音暂时无法加载", "Voice message isn't available right now"],
  ];
  for (const [name, view, content, zh, en] of cases) {
    const kind = (content as { contentType: string }).contentType;
    it(`${name} says it is not available, in both languages`, async () => {
      for (const [locale, words] of [["zh-CN", zh], ["en-US", en]] as const) {
        const wrapper = mountView(view, content, locale);
        await flushPromises();
        const unavailable = wrapper.get(".im-media-unavailable");
        expect(unavailable.attributes("data-kind")).toBe(kind);
        expect(unavailable.attributes("aria-label")).toBe(words);
        expect(unavailable.text()).toBe(words);
        expect(wrapper.text()).not.toContain("不支持");
        expect(wrapper.find("button").exists()).toBe(false);
        wrapper.unmount();
      }
    });
  }

  it("a message with an address draws its own body, not the unavailable line", async () => {
    const image = mountView(ImageView, { contentType: "image", image: { source: { url: "https://cdn.example.com/p.png" } } });
    const video = mountView(VideoView, { contentType: "video", video: { source: { url: "https://cdn.example.com/v.mp4" } } });
    const audio = mountView(AudioView, { contentType: "audio", audio: { url: "https://cdn.example.com/a.webm" } });
    await flushPromises();
    for (const wrapper of [image, video, audio]) {
      expect(wrapper.find(".im-media-unavailable").exists()).toBe(false);
      expect(wrapper.find("button").exists()).toBe(true);
    }
  });
});
