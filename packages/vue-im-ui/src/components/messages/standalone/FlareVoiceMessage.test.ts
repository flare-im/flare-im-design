// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";
import { defineComponent, h } from "vue";
import { useFlareI18nProvider } from "../../../shared/i18n/useFlareI18n";
import FlareVoiceMessage from "./FlareVoiceMessage.vue";

function mountVoice(props: Record<string, unknown> = {}) {
  const host = mount(defineComponent({
    setup() {
      useFlareI18nProvider("zh-CN");
      return () => h(FlareVoiceMessage, props);
    },
  }));
  return host.findComponent(FlareVoiceMessage);
}

describe("FlareVoiceMessage", () => {
  it("uses one compact row for play, waveform, and duration", async () => {
    const wrapper = mountVoice({ seconds: 7 });

    expect(wrapper.find(".fm-voice__play").exists()).toBe(true);
    expect(wrapper.find(".fm-voice__wave").exists()).toBe(true);
    expect(wrapper.findAll(".fm-voice__wave i")).toHaveLength(18);
    expect(wrapper.find(".fm-voice__duration").text()).toBe('7"');

    await wrapper.find(".fm-voice__play").trigger("click");
    expect(wrapper.emitted("play")).toHaveLength(1);
  });

  it("localizes the disabled playback state", () => {
    const wrapper = mountVoice({ seconds: 0, disabled: true });

    expect(wrapper.attributes("aria-label")).toContain("语音不可播放");
    expect(wrapper.find(".fm-voice__play").attributes("aria-label")).toBe("语音不可播放");
    expect(wrapper.findAll("button").every((button) => button.attributes("disabled") !== undefined)).toBe(true);
  });
});
