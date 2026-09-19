// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";
import { defineComponent, h, type Component } from "vue";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import FlareCallControls from "./FlareCallControls.vue";
import FlareCallDock from "./FlareCallDock.vue";

function mountIn(component: Component, props: Record<string, unknown>) {
  return mount(defineComponent({ setup() {
    useFlareI18nProvider("zh-CN");
    return () => h(component, props);
  } }), { attachTo: document.body });
}

const switches = (host: ReturnType<typeof mountIn>) =>
  host.findAll('[role="switch"]').map((control) => [control.text() || control.attributes("aria-label"), control.attributes("aria-checked")]);

describe("call device toggles", () => {
  it("name each device and report whether it is on", () => {
    const video = mountIn(FlareCallControls as Component, { mode: "video", muted: true, cameraOn: true });
    expect(switches(video)).toEqual([["麦克风", "false"], ["摄像头", "true"]]);
    video.unmount();
    const voice = mountIn(FlareCallControls as Component, { mode: "audio", muted: false, speakerOn: false });
    expect(switches(voice)).toEqual([["麦克风", "true"], ["扬声器", "false"]]);
    voice.unmount();
  });

  it("names the dock's main button after what it does", () => {
    const dock = mountIn(FlareCallDock as Component, { title: "周屿", mode: "audio", muted: true });
    expect(dock.get(".flare-call-dock__main").attributes("aria-label")).toBe("返回通话");
    expect(switches(dock)).toEqual([["麦克风", "false"]]);
    dock.unmount();
  });
});
