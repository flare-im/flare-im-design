// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { describe, expect, it, vi } from "vitest";
import { defineComponent, h, type Component } from "vue";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import { useFlarePlatformProvider } from "../../shared/platform/useFlarePlatform";
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
    expect(switches(video)).toEqual([["麦克风", "false"], ["扬声器", "false"], ["摄像头", "true"]]); // §3.4: mic, speaker, then camera
    video.unmount();
    const voice = mountIn(FlareCallControls as Component, { mode: "audio", muted: false, speakerOn: false });
    expect(switches(voice)).toEqual([["麦克风", "true"], ["扬声器", "false"]]);
    voice.unmount();
  });

  it("desktop speaker selection is an action in video calls, not a muted-speaker switch", async () => {
    let opened = 0;
    const view = mountIn(FlareCallControls as Component, {mode: "video", speakerPicker: true, onToggleSpeaker: () => opened++});
    const speaker = view.findAll("button").find(b => b.text() === "扬声器")!;
    expect(speaker.attributes("role")).toBe("button");
    expect(speaker.attributes("aria-haspopup")).toBe("dialog");
    expect(speaker.attributes("aria-checked")).toBeUndefined();
    await speaker.trigger("click");
    expect(opened).toBe(1);
    view.unmount();
  });

  it("names the dock's main button after what it does", () => {
    const dock = mountIn(FlareCallDock as Component, { title: "周屿", mode: "audio", muted: true });
    expect(dock.get(".flare-call-dock__main").attributes("aria-label")).toBe("返回通话");
    expect(switches(dock)).toEqual([["麦克风", "false"]]);
    dock.unmount();
  });

  it("a failed minimized call cannot claim it is connected or offer a live microphone", () => {
    const dock = mountIn(FlareCallDock as Component, { title: "周屿", state: "failed", durationLabel: "01:24" });
    expect(dock.get('[role="group"]').attributes("aria-label")).toBe("通话中断");
    expect(dock.text()).toContain("通话中断");
    expect(dock.text()).not.toContain("01:24");
    expect(dock.get('[role="switch"]').attributes("disabled")).toBeDefined();
    expect(dock.find(".flare-call-dock__pulse").exists()).toBe(false);
    expect(dock.get('.flare-call-dock__btn--hangup').attributes("disabled")).toBeUndefined();
    dock.unmount();
  });

  it("the dock says waiting, reconnecting and failed in short phrases, and the duration once connected (§12.17)", () => {
    for (const [state, label] of [["calling", "等待接听"], ["ringing", "等待接听"], ["reconnecting", "正在重连"], ["failed", "通话中断"], ["connected", "01:24"]]) {
      const dock = mountIn(FlareCallDock as Component, { title: "周屿", state, durationLabel: "01:24" });
      expect(dock.get('.flare-call-dock__status').text()).toBe(label);
      expect(dock.find(".flare-call-dock__dot").exists()).toBe(state === "reconnecting");
      dock.unmount();
    }
  });

  it("the dock's status line gives way to the host's detail", () => {
    const dock = mountIn(FlareCallDock as Component, { title: "周屿", state: "failed", statusDetail: "对方暂时无法接听" });
    expect(dock.get(".flare-call-dock__status").text()).toBe("对方暂时无法接听");
    dock.unmount();
  });
});

describe("keyboard shortcuts on a PC", () => {
  function withKeys(props: Record<string, unknown>) {
    return mount(defineComponent({ setup() {
      useFlareI18nProvider("zh-CN");
      useFlarePlatformProvider({ capabilities: { keyboardShortcut: true } });
      return () => h(FlareCallControls as Component, props);
    } }), { attachTo: document.body });
  }
  const press = (init: KeyboardEventInit, target: EventTarget = window) =>
    target.dispatchEvent(new KeyboardEvent("keydown", { bubbles: true, cancelable: true, ...init }));

  it("M toggles the mic, V the camera, Ctrl+Shift+H hangs up, and the keys name their shortcut", () => {
    const onToggleMute = vi.fn(), onToggleCamera = vi.fn(), onHangup = vi.fn();
    const view = withKeys({ mode: "video", onToggleMute, onToggleCamera, onHangup });
    press({ key: "m" });
    press({ key: "v" });
    press({ key: "H", ctrlKey: true, shiftKey: true });
    expect([onToggleMute.mock.calls.length, onToggleCamera.mock.calls.length, onHangup.mock.calls.length]).toEqual([1, 1, 1]);
    expect(view.get('[role="switch"]').attributes("title")).toBe("麦克风 (M)");
    view.unmount();
  });

  it("ignores the keys while the viewer types, and single-key hangup never exists", () => {
    const onToggleMute = vi.fn(), onHangup = vi.fn();
    const view = withKeys({ mode: "audio", onToggleMute, onHangup });
    const input = document.createElement("input");
    document.body.appendChild(input);
    press({ key: "m" }, input);
    press({ key: "h" });
    expect(onToggleMute).not.toHaveBeenCalled();
    expect(onHangup).not.toHaveBeenCalled();
    input.remove();
    view.unmount();
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
    // The speaker (the device key on PC) stays in video too, right after the microphone; flip is a phone key (§3.3).
    expect(captions(video)).toEqual(["麦克风", "扬声器", "摄像头", "挂断"]);
    video.unmount();
    const phoneVideo = mount(defineComponent({ setup() {
      useFlareI18nProvider("zh-CN");
      useFlarePlatformProvider({ capabilities: { bottomSheet: true } });
      return () => h(FlareCallControls as Component, { mode: "video" });
    } }), { attachTo: document.body });
    expect(captions(phoneVideo)).toEqual(["麦克风", "扬声器", "摄像头", "翻转", "挂断"]);
    phoneVideo.unmount();
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

it("keeps the device popup anchored and consumes Escape before the call modal", async () => {
  const view = mount(defineComponent({setup(){useFlareI18nProvider('zh-CN');return () => h(FlareCallControls, {mode:'video',speakerPicker:true}, {devices: () => h('button', {class:'device-choice'}, 'USB')});}}), {attachTo:document.body});
  const speaker = view.findAll('button').find(b=>b.text()==='扬声器')!;
  await speaker.trigger('click');
  const popup = view.findComponent({name:'Popover'});
  expect(popup.props('placement')).toBe('top');
  expect(popup.props('show')).toBe(true);
  const event = new KeyboardEvent('keydown', {key:'Escape', bubbles:true, cancelable:true});
  speaker.element.dispatchEvent(event);await view.vm.$nextTick();
  expect(event.defaultPrevented).toBe(true);expect(popup.props('show')).toBe(false);
  expect(document.activeElement).toBe(speaker.element);view.unmount();
});
