// @vitest-environment happy-dom
import { flushPromises, mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";
import { defineComponent, h } from "vue";
import { useFlareI18nProvider } from "../../../../shared/i18n/useFlareI18n";
import type { ContentElem } from "../../../../utils/contentElem";
import FlareVoiceMessage from "../../standalone/FlareVoiceMessage.vue";
import AudioView from "./AudioView.vue";

function mountAudio(content: ContentElem, isSelf = false) {
  const host = mount(defineComponent({
    setup() {
      useFlareI18nProvider("zh-CN");
      return () => h(AudioView, { content, isSelf, messageId: "message-1" });
    },
  }));
  return host.findComponent(AudioView);
}

describe("AudioView", () => {
  it("delegates timeline audio presentation to the public FlareVoiceMessage", async () => {
    const wrapper = mountAudio({
      contentType: "audio",
      audio: {
        url: "https://example.com/voice.webm",
        durationMs: 7000,
      },
    }, true);
    await flushPromises();

    const voice = wrapper.findComponent(FlareVoiceMessage);
    expect(voice.exists()).toBe(true);
    expect(voice.props("embedded")).toBe(true);
    expect(voice.props("outbound")).toBe(true);
    expect(voice.props("seconds")).toBe(7);
    expect(voice.props("disabled")).toBe(false);
    expect(wrapper.find(".im-audio__meta").exists()).toBe(false);
    expect(wrapper.text()).not.toContain("Voice message");
  });

  it("a voice message with nothing to load says so instead of a dead player", async () => {
    const wrapper = mountAudio({
      contentType: "audio",
      audio: { durationMs: 4000 },
    });
    await flushPromises();

    expect(wrapper.findComponent(FlareVoiceMessage).exists()).toBe(false);
    const unavailable = wrapper.get(".im-media-unavailable");
    expect(unavailable.attributes("aria-label")).toBe("语音暂时无法加载");
    expect(unavailable.text()).toBe("语音暂时无法加载");
    expect(wrapper.find("button").exists()).toBe(false);
  });
});
