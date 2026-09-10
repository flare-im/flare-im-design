// @vitest-environment happy-dom
import { afterEach, describe, expect, it, vi } from "vitest";
import { defineComponent, h, nextTick, reactive, type Component } from "vue";
import { mount, flushPromises } from "@vue/test-utils";
import Composer from "./EnhancedComposer.vue";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";

const wrappers: ReturnType<typeof mount>[] = [];
function setup(props: Record<string, unknown> = {}) {
  const host = mount(defineComponent({
    setup() { useFlareI18nProvider("zh-CN"); return () => h(Composer as Component, props); },
  }), { attachTo: document.body });
  wrappers.push(host);
  return host.findComponent(Composer);
}
afterEach(() => { wrappers.splice(0).forEach(w => w.unmount()); vi.unstubAllGlobals(); vi.restoreAllMocks(); });

describe("FlareComposer interaction boundaries", () => {
  it("keeps an offline draft editable while blocking keyboard and button sends", async () => {
    const wrapper = setup({ modelValue: "未发送的草稿", sendBlocked: true });
    expect(wrapper.get("textarea").attributes("disabled")).toBeUndefined();
    expect(wrapper.get('[aria-label="发送"]').attributes("disabled")).toBeDefined();
    await wrapper.get("textarea").trigger("keydown", { key: "Enter" });
    expect(wrapper.emitted("send")).toBeUndefined();
    expect(wrapper.props("modelValue")).toBe("未发送的草稿");
  });
  it("makes a muted draft read-only without deleting it", async () => {
    const wrapper = setup({ modelValue: "保留草稿", readOnly: true, statusHint: "你已被禁言" });
    expect(wrapper.get("textarea").attributes("disabled")).toBeDefined();
    await wrapper.vm.insertAtCursor("禁止插入");
    expect(wrapper.emitted("update:modelValue")).toBeUndefined();
    expect(wrapper.text()).toContain("你已被禁言");
  });
  it("treats an empty action configuration as empty, and suppresses disabled actions", async () => {
    const empty = setup({ activePanel: "more", attachActions: [] });
    expect(empty.findAll(".composer-more-tile")).toHaveLength(0);
    expect(empty.text()).toContain("暂无可用内容");
    const wrapper = setup({ activePanel: "more", attachActions: [{ op: "custom", label: "企业审批", disabled: true, disabledReason: "无权限" }] });
    await wrapper.get(".composer-more-tile").trigger("click");
    expect(wrapper.emitted("build")).toBeUndefined();
  });
  it("filters paginated actions and removes hidden search filters", async () => {
    const props = reactive({ activePanel: "more", moreSearchVisible: true });
    const wrapper = setup(props);
    expect(wrapper.findAll(".composer-more-tile")).toHaveLength(8);
    await wrapper.get('[aria-label="第 2 页"]').trigger("click");
    expect(wrapper.text()).toContain("小程序");
    await wrapper.get(".composer-panel-search").setValue("文件");
    expect(wrapper.findAll(".composer-more-tile")).toHaveLength(1);
    expect(wrapper.find(".composer-pages").exists()).toBe(false);
    props.moreSearchVisible = false;
    await nextTick();
    expect(wrapper.findAll(".composer-more-tile")).toHaveLength(8);
  });
  it("opens @ search even with an empty roster, and Escape dismisses it", async () => {
    const wrapper = setup();
    await wrapper.get('[aria-label="@"]').trigger("click");
    expect(wrapper.find(".composer-mention-menu").exists()).toBe(true);
    await wrapper.get(".composer-panel-search").setValue("Nobody");
    expect(wrapper.text()).toContain("暂无可用内容");
    await wrapper.get(".composer-panel-search").trigger("keydown", { key: "Escape" });
    expect(wrapper.find(".composer-mention-menu").exists()).toBe(false);
  });
  it("does not acquire or leak a microphone after the panel was dismissed", async () => {
    let resolveStream!: (stream: MediaStream) => void;
    const stop = vi.fn();
    const getUserMedia = vi.fn(() => new Promise<MediaStream>(resolve => { resolveStream = resolve; }));
    vi.stubGlobal("navigator", { mediaDevices: { getUserMedia } });
    vi.stubGlobal("MediaRecorder", class {});
    const wrapper = setup();
    await wrapper.get('[aria-label="语音"]').trigger("click");
    await wrapper.get('[aria-label="开始录音"]').trigger("click");
    await wrapper.get('[aria-label="返回键盘并删除录音"]').trigger("click");
    resolveStream({ getTracks: () => [{ stop }] } as unknown as MediaStream);
    await flushPromises();
    expect(stop).toHaveBeenCalledOnce();
    expect(wrapper.emitted("send-voice")).toBeUndefined();
  });
  it("records to a preview and only sends after explicit confirmation", async () => {
    let now = 1000;
    vi.spyOn(Date, "now").mockImplementation(() => now);
    const stop = vi.fn();
    vi.stubGlobal("navigator", { mediaDevices: { getUserMedia: async () => ({ getTracks: () => [{ stop }] }) } });
    vi.stubGlobal("MediaRecorder", class {
      static isTypeSupported() { return true; }
      mimeType = "audio/webm";
      state = "inactive";
      ondataavailable: ((event: { data: Blob }) => void) | null = null;
      onstop: (() => void) | null = null;
      start() { this.state = "recording"; }
      pause() { this.state = "paused"; }
      resume() { this.state = "recording"; }
      requestData() { this.ondataavailable?.({ data: new Blob(["recording"]) }); }
      stop() { this.state = "inactive"; this.onstop?.(); }
    });
    vi.spyOn(URL, "createObjectURL").mockReturnValue("blob:preview");
    vi.spyOn(URL, "revokeObjectURL").mockImplementation(() => {});
    const send = vi.fn();
    const wrapper = setup({ modelValue: "文字草稿", sendVoiceHandler: send });
    await wrapper.get('[aria-label="语音"]').trigger("click");
    await wrapper.get('[aria-label="开始录音"]').trigger("click");
    await flushPromises();
    now = 2000;
    await wrapper.get('[aria-label="暂停录音"]').trigger("click");
    expect(wrapper.get("audio").attributes("src")).toBe("blob:preview");
    expect(send).not.toHaveBeenCalled();
    expect(stop).not.toHaveBeenCalled();
    now = 8000;
    await wrapper.get('[aria-label="继续录音"]').trigger("click");
    now = 9000;
    await wrapper.get('[aria-label="暂停录音"]').trigger("click");
    await wrapper.get('.composer-voice-inline [aria-label="发送"]').trigger("click");
    await flushPromises();
    expect(send).toHaveBeenCalledOnce();
    expect(send.mock.calls[0][0].durationMs).toBe(2000);
    expect(stop).toHaveBeenCalledOnce();
    expect(wrapper.props("modelValue")).toBe("文字草稿");
    expect(wrapper.find("audio").exists()).toBe(false);
  });
  it("discards late recorder callbacks after returning to keyboard", async () => {
    const stopTrack = vi.fn();
    let recorder: any;
    vi.stubGlobal("navigator", { mediaDevices: { getUserMedia: async () => ({ getTracks: () => [{ stop: stopTrack }] }) } });
    vi.stubGlobal("MediaRecorder", class {
      state = "inactive"; mimeType = "audio/webm";
      ondataavailable: any; onstop: any;
      constructor() { recorder = this; }
      start() { this.state = "recording"; }
      stop() { this.state = "inactive"; }
    });
    const wrapper = setup({ modelValue: "保留文字" });
    await wrapper.get('[aria-label="语音"]').trigger("click");
    await wrapper.get('[aria-label="开始录音"]').trigger("click");
    await flushPromises();
    await wrapper.get('[aria-label="返回键盘并删除录音"]').trigger("click");
    recorder.ondataavailable({ data: new Blob(["late data"]) });
    recorder.onstop();
    await wrapper.get('[aria-label="语音"]').trigger("click");
    expect(stopTrack).toHaveBeenCalledOnce();
    expect(wrapper.find("audio").exists()).toBe(false);
    expect(wrapper.get("time").text()).toBe("00:00");
    expect(wrapper.props("modelValue")).toBe("保留文字");
  });
  it("retains the finalized clip when upload fails and retries the same blob", async () => {
    let now = 1000;
    vi.spyOn(Date, "now").mockImplementation(() => now);
    vi.stubGlobal("navigator", { mediaDevices: { getUserMedia: async () => ({ getTracks: () => [{ stop: vi.fn() }] }) } });
    vi.stubGlobal("MediaRecorder", class {
      state = "inactive"; mimeType = "audio/webm";
      ondataavailable: any; onstop: any;
      start() { this.state = "recording"; }
      pause() { this.state = "paused"; }
      requestData() { this.ondataavailable({ data: new Blob(["clip"]) }); }
      stop() { this.state = "inactive"; this.onstop(); }
    });
    vi.spyOn(URL, "createObjectURL").mockReturnValue("blob:retry");
    vi.spyOn(URL, "revokeObjectURL").mockImplementation(() => {});
    const send = vi.fn().mockRejectedValueOnce(new Error("offline")).mockResolvedValueOnce(undefined);
    const wrapper = setup({ sendVoiceHandler: send });
    await wrapper.get('[aria-label="语音"]').trigger("click");
    await wrapper.get('[aria-label="开始录音"]').trigger("click");
    await flushPromises(); now = 2500;
    await wrapper.get('[aria-label="暂停录音"]').trigger("click");
    await wrapper.get('.composer-voice-inline [aria-label="发送"]').trigger("click");
    await flushPromises();
    expect(wrapper.find("audio").exists()).toBe(true);
    await wrapper.get('.composer-voice-inline [aria-label="发送"]').trigger("click");
    await flushPromises();
    expect(send).toHaveBeenCalledTimes(2);
    expect(send.mock.calls[1][0].blob).toBe(send.mock.calls[0][0].blob);
    expect(wrapper.find("audio").exists()).toBe(false);
  });
  it("dismisses transient panels on a conversation change", async () => {
    const props = reactive({ conversationKey: "a" });
    const wrapper = setup(props);
    await wrapper.get('[aria-label="语音"]').trigger("click");
    expect(wrapper.find(".composer-voice-inline").exists()).toBe(true);
    props.conversationKey = "b";
    await nextTick();
    expect(wrapper.find(".composer-voice-inline").exists()).toBe(false);
  });
  it("shares the diagonal resize state between layouts and preserves the draft on collapse", async () => {
    const wrapper = setup({ modelValue: "展开前的草稿", targetName: "Ivy Chen" });
    expect(wrapper.get("textarea").attributes("placeholder")).toBe("发送给 Ivy Chen");
    const mobile = wrapper.get(".composer-field-expand");
    const desktop = wrapper.get(".composer-expand");
    expect(mobile.attributes("aria-expanded")).toBe("false");
    await mobile.trigger("click");
    expect(mobile.attributes("aria-expanded")).toBe("true");
    expect(desktop.attributes("aria-expanded")).toBe("true");
    expect(mobile.get("path").attributes("d")).toBe(desktop.get("path").attributes("d"));
    await wrapper.get("textarea").trigger("keydown", { key: "Escape" });
    expect(mobile.attributes("aria-expanded")).toBe("false");
    expect(wrapper.props("modelValue")).toBe("展开前的草稿");
  });
  it("never submits during IME composition", async () => {
    const wrapper = setup({ modelValue: "拼音输入" });
    await wrapper.get("textarea").trigger("keydown", { key: "Enter", isComposing: true });
    expect(wrapper.emitted("send")).toBeUndefined();
    await nextTick();
  });
});
