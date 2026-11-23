// @vitest-environment happy-dom
import { afterEach, expect, it, vi } from "vitest";
import { computed, defineComponent, h, ref } from "vue";
import { flushPromises, mount } from "@vue/test-utils";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import type { VoiceRecorder } from "../../composables/composer/useVoiceRecorder";
import ComposerVoicePanel from "./ComposerVoicePanel.vue";

const hosts: ReturnType<typeof mount>[] = [];
afterEach(() => { hosts.splice(0).forEach(host => host.unmount()); vi.restoreAllMocks(); });
function recorder(): VoiceRecorder {
  return { recording: ref(false), paused: ref(true), requestPending: ref(false), elapsedMs: ref(5000),
    preview: ref({ blob: new Blob(["clip"]), durationMs: 5000, mimeType: "audio/webm", fileName: "voice.webm" }),
    previewUrl: ref("blob:clip"), hasSession: computed(() => true), atLimit: computed(() => false), maxMs: 65000,
    start: vi.fn(), pause: vi.fn(), resume: vi.fn(), finalize: vi.fn(), cancel: vi.fn(), clearPreview: vi.fn() };
}
function render(state: VoiceRecorder, props: Record<string, unknown> = {}) {
  const host = mount(defineComponent({ setup() {
    useFlareI18nProvider("zh-CN");
    return () => h(ComposerVoicePanel, { recorder: state, sendLabel: "发送", ...props });
  } }));
  hosts.push(host);
  return { host, panel: host.getComponent(ComposerVoicePanel) };
}
it("drops a late playback result after the panel is removed and pauses the detached element", async () => {
  let finish!: () => void;
  vi.spyOn(HTMLMediaElement.prototype, "play").mockImplementation(() => new Promise<void>(resolve => { finish = resolve; }));
  const pause = vi.spyOn(HTMLMediaElement.prototype, "pause").mockImplementation(() => {});
  const { host, panel } = render(recorder());
  await panel.get('.voice-preview button').trigger('click');
  expect(panel.get('.voice-preview button').attributes('aria-busy')).toBe('true');
  host.unmount(); hosts.pop();
  finish(); await flushPromises();
  expect(pause).toHaveBeenCalled();
  expect(panel.emitted('previewStarted')).toBeUndefined();
  expect(panel.emitted('previewFailed')).toBeUndefined();
});
it("keeps offline review playable and discardable while blocking resume and send", () => {
  const { panel } = render(recorder(), { sendBlocked: true });
  expect(panel.get('.voice-preview button').attributes('disabled')).toBeUndefined();
  expect(panel.get('[aria-label="删除录音"]').attributes('disabled')).toBeUndefined();
  expect(panel.get('[aria-label="继续录音"]').attributes('disabled')).toBeDefined();
  expect(panel.get('[aria-label="发送"]').attributes('disabled')).toBeDefined();
  expect(panel.get('input[type="range"]').attributes('aria-valuetext')).toBe('00:00 / 00:05');
});
it("names a pending microphone request and provides an explicit cancellation", async () => {
  const state = recorder(); state.paused.value = false; state.requestPending.value = true;
  const { panel } = render(state);
  expect(panel.get('.voice-record').attributes('aria-label')).toBe('正在请求麦克风…');
  expect(panel.get('.voice-record').attributes('disabled')).toBeDefined();
  await panel.get('[aria-label="删除录音"]').trigger('click');
  expect(panel.emitted('discard')).toHaveLength(1);
  expect(panel.find('.voice-preview').exists()).toBe(false);
});

it("cancels a pending microphone request when a mobile hold is released", async () => {
  const state=recorder();state.paused.value=false;state.requestPending.value=true;
  const {panel}=render(state,{holdToTalk:true});
  const hold=panel.get('.flare-voice');
  await hold.trigger('pointerdown',{isPrimary:true,pointerId:1,clientY:200});
  await hold.trigger('pointerup',{pointerId:1});
  expect(panel.emitted('discard')).toHaveLength(1);
  expect(panel.emitted('pause')).toBeUndefined();
  expect(panel.emitted('send')).toBeUndefined();
});
it("reviews a completed mobile hold without automatically sending it", async () => {
  const state=recorder();state.paused.value=false;state.recording.value=false;
  const {panel}=render(state,{holdToTalk:true,onStart:()=>{state.recording.value=true;},onPause:()=>{state.recording.value=false;state.paused.value=true;}});
  const hold=panel.get('.flare-voice');
  await hold.trigger('pointerdown',{isPrimary:true,pointerId:1,clientY:200});
  await hold.trigger('pointerup',{pointerId:1});
  expect(panel.emitted('pause')).toHaveLength(1);
  expect(panel.emitted('send')).toBeUndefined();
  expect(panel.find('.voice-preview').exists()).toBe(true);
});
