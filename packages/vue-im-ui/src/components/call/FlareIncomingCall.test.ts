// @vitest-environment happy-dom
import { flushPromises, mount } from "@vue/test-utils";
import { describe, expect, it, vi } from "vitest";
import { defineComponent, h, type Component } from "vue";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import FlareIncomingCall from "./FlareIncomingCall.vue";

function mountIn(props: Record<string, unknown>) {
  return mount(defineComponent({ setup() {
    useFlareI18nProvider("zh-CN");
    return () => h(FlareIncomingCall as Component, props);
  } }), { attachTo: document.body });
}

describe("incoming call", () => {
  it("full screen: focuses the answer key and announces the caller politely", async () => {
    const view = mountIn({ callerName: "周屿", mode: "audio" });
    await flushPromises();
    expect(document.activeElement).toBe(view.get("[data-incoming-accept]").element);
    expect(view.get('[aria-live="polite"]').text()).toBe("周屿 邀请你语音通话");
    expect(view.find("[data-incoming-audio]").exists()).toBe(false);
    view.unmount();
  });

  it("banner: never takes focus, names its round keys and offers answer with audio on a video invite", async () => {
    const before = document.createElement("input");
    document.body.appendChild(before);
    before.focus();
    const onAcceptAudio = vi.fn(), onAccept = vi.fn(), onReject = vi.fn();
    const view = mountIn({ callerName: "周屿", mode: "video", presentation: "banner", onAcceptAudio, onAccept, onReject });
    await flushPromises();
    expect(view.get("[data-presentation]").attributes("data-presentation")).toBe("banner");
    expect(document.activeElement).toBe(before);
    expect(view.get("[data-incoming-accept]").attributes("aria-label")).toBe("接听");
    expect(view.get("[data-incoming-reject]").attributes("aria-label")).toBe("拒接");
    const audio = view.get("[data-incoming-audio]");
    expect(audio.attributes("aria-label")).toBe("语音接听");
    await audio.trigger("click");
    expect(onAcceptAudio).toHaveBeenCalledOnce();
    expect(onAccept).not.toHaveBeenCalled();
    view.unmount();
    before.remove();
  });
});
