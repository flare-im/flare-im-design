// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";
import { defineComponent, h, type Component } from "vue";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import FlareCallControls from "./FlareCallControls.vue";
import FlareCallDock from "./FlareCallDock.vue";
import FlareCallView from "./FlareCallView.vue";
import FlareGroupCallView from "./FlareGroupCallView.vue";

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

/** The captions under the keys, in display order. */
const captions = (host: ReturnType<typeof mountIn>) => host.findAll(".flare-call-controls .lbl").map((label) => label.text());

describe("switch to video", () => {
  it("sits after the speaker in an audio call when the host can start video, and asks the host", () => {
    let asked = 0;
    const voice = mountIn(FlareCallControls as Component, {
      mode: "audio", canStartVideo: true, showAddMember: true, onStartVideo: () => { asked += 1; },
    });
    expect(captions(voice)).toEqual(["麦克风", "扬声器", "切换到视频", "加人", "挂断"]);
    const key = voice.findAll("button").find((button) => button.text() === "切换到视频")!;
    // An action, not a device switch.
    expect(key.attributes("role")).toBeUndefined();
    void key.trigger("click");
    expect(asked).toBe(1);
    voice.unmount();
  });

  it("is not drawn in a video call, nor when the host cannot start video", () => {
    const video = mountIn(FlareCallControls as Component, { mode: "video", canStartVideo: true });
    expect(captions(video)).not.toContain("切换到视频");
    video.unmount();
    const plain = mountIn(FlareCallControls as Component, { mode: "audio" });
    expect(captions(plain)).toEqual(["麦克风", "扬声器", "挂断"]);
    plain.unmount();
  });

  it("is forwarded by the one-to-one and the group call screens", () => {
    for (const [component, props] of [
      [FlareCallView, { peerName: "周屿", state: "connected" }],
      [FlareGroupCallView, { participants: [{ id: "a", name: "A" }], state: "connected" }],
    ] as const) {
      let asked = 0;
      const voice = mountIn(component as Component, { ...props, mode: "audio", canStartVideo: true, onStartVideo: () => { asked += 1; } });
      void voice.findAll("button").find((button) => button.text() === "切换到视频")!.trigger("click");
      expect(asked).toBe(1);
      voice.unmount();
      const video = mountIn(component as Component, { ...props, mode: "video", canStartVideo: true });
      expect(captions(video)).not.toContain("切换到视频");
      video.unmount();
    }
  });

  it("is labelled from the strings table in English too", () => {
    const english = mount(defineComponent({ setup() {
      useFlareI18nProvider("en-US");
      return () => h(FlareCallControls as Component, { mode: "audio", canStartVideo: true });
    } }), { attachTo: document.body });
    expect(captions(english)).toContain("Switch to video");
    english.unmount();
  });
});
