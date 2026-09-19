<script setup lang="ts">
import { computed, ref, watch } from "vue";
import { NIcon } from "naive-ui";
import { flareIcons } from "../../shared/icons";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import { formatVoiceDuration, type VoiceRecorder } from "../../composables/composer/useVoiceRecorder";

// Desktop voice panel of the composer: start / pause / resume / preview / send.
// Capture state lives in the injected recorder; this panel only owns preview playback.
const props = defineProps<{
  recorder: VoiceRecorder;
  /** A send is in flight; every control freezes until it settles. */
  submitting?: boolean;
  /** Sending is blocked by the host (offline, read-only) even though a clip exists. */
  sendBlocked?: boolean;
  sendLabel: string;
}>();
const emit = defineEmits<{
  (event: "start"): void;
  (event: "pause"): void;
  (event: "resume"): void;
  (event: "discard"): void;
  (event: "send"): void;
  (event: "close"): void;
  (event: "previewFailed"): void;
}>();
const { t } = useFlareI18n();

const audio = ref<HTMLAudioElement | null>(null);
const playing = ref(false);
const playbackMs = ref(0);
const { recording, paused, requestPending, elapsedMs, preview, previewUrl, hasSession, atLimit } = props.recorder;

function pausePlayback(): void { audio.value?.pause(); playing.value = false; }
async function togglePlayback(): Promise<void> {
  if (playing.value) { pausePlayback(); return; }
  try { await audio.value?.play(); playing.value = true; }
  catch { emit("previewFailed"); }
}
function seek(event: Event): void {
  const node = audio.value;
  if (!node) return;
  const seconds = Number((event.target as HTMLInputElement).value) / 1000;
  try { node.currentTime = seconds; playbackMs.value = seconds * 1000; } catch { /* Not yet seekable. */ }
}
watch(previewUrl, () => { pausePlayback(); playbackMs.value = 0; });
watch(() => props.submitting, (busy) => { if (busy) pausePlayback(); });
const shown = computed(() => formatVoiceDuration(playing.value ? playbackMs.value : elapsedMs.value));
</script>

<template>
  <section class="composer-voice-inline" :aria-label="t('composer.voice')">
    <button type="button" :disabled="submitting" :title="t('composer.returnKeyboard')" :aria-label="t('composer.returnKeyboard')" @click="emit('close')"><n-icon aria-hidden="true" :component="flareIcons.keyboard" /></button>
    <button v-if="!paused" type="button" class="voice-primary" :class="{ 'is-recording': recording }" :disabled="sendBlocked || submitting || requestPending" :aria-busy="requestPending" :title="recording ? t('composer.pauseRecording') : t('composer.startRecording')" :aria-label="recording ? t('composer.pauseRecording') : t('composer.startRecording')" @click="recording ? emit('pause') : emit('start')"><n-icon aria-hidden="true" :component="recording ? flareIcons.pause : flareIcons.mic" /></button>
    <button v-else type="button" :disabled="!preview || submitting" :title="t('composer.previewRecording')" :aria-label="t('composer.previewRecording')" :aria-pressed="playing" @click="togglePlayback"><n-icon aria-hidden="true" :component="playing ? flareIcons.pause : flareIcons.play" /></button>
    <div class="voice-track" :class="{ 'is-recording': recording, 'is-paused': paused }"><i v-for="n in 64" :key="n" aria-hidden="true" :style="{ height: `${6 + (n * 17 % 20)}px`, animationDelay: `${n % 7 * -.13}s` }" /><input v-if="paused && preview" type="range" min="0" :max="elapsedMs" :value="playbackMs" :disabled="submitting" :aria-label="t('composer.seekRecording')" @input="seek" /></div>
    <time>{{ shown }}</time>
    <button v-if="paused && hasSession" type="button" class="voice-primary" :disabled="submitting || atLimit" :title="t('composer.resumeRecording')" :aria-label="t('composer.resumeRecording')" @click="emit('resume')"><n-icon aria-hidden="true" :component="flareIcons.mic" /></button>
    <button v-if="paused" type="button" :disabled="submitting" :title="t('composer.discardRecording')" :aria-label="t('composer.discardRecording')" @click="emit('discard')"><n-icon aria-hidden="true" :component="flareIcons.delete" /></button>
    <button v-if="paused" type="button" class="voice-primary" :disabled="!preview || sendBlocked || submitting" :aria-busy="submitting" :title="sendLabel" :aria-label="sendLabel" @click="emit('send')"><n-icon aria-hidden="true" :component="flareIcons.send" /></button>
    <audio v-if="previewUrl" ref="audio" :src="previewUrl" @timeupdate="playbackMs = (audio?.currentTime ?? 0) * 1000" @ended="playing = false" @pause="playing = false" />
  </section>
</template>

<style scoped>
.composer-voice-inline {
  display: flex;
  align-items: center;
  gap: var(--flare-size-spacing-2xs);
  min-height: 58px;
  width: 100%;
  padding: 7px 10px;
  border: 1px solid var(--studio-border, var(--flare-color-border-primary));
  border-radius: var(--studio-radius, var(--flare-size-radius-lg));
  background: var(--studio-surface, var(--flare-color-bg-primary));
}
.composer-voice-inline button {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  flex: 0 0 40px;
  width: var(--flare-size-layout-control-height-md);
  height: var(--flare-size-layout-control-height-md);
  padding: 0;
  border: 0;
  color: var(--flare-color-text-secondary);
  background: transparent;
  box-shadow: none;
  cursor: pointer;
}
.composer-voice-inline button :deep(svg),
.composer-voice-inline button .n-icon {
  width: var(--flare-size-icon-size-md);
  height: var(--flare-size-icon-size-md);
  font-size: var(--flare-size-font-size-4xl);
  stroke-width: 1.7;
}
.composer-voice-inline button:hover,
.composer-voice-inline .voice-primary { color: var(--studio-accent, var(--flare-color-primary-text)); }
.composer-voice-inline .is-recording { color: var(--flare-color-error-text); }
.composer-voice-inline button:disabled { opacity: var(--flare-opacity-disabled, 0.5); cursor: default; }
.composer-voice-inline button:focus-visible { outline: 2px solid var(--studio-focus, var(--flare-color-border-selected)); outline-offset: -2px; }
.composer-voice-inline time { min-width: 36px; color: var(--flare-color-text-secondary); font: 12px var(--flare-component-font-family-mono); font-variant-numeric: tabular-nums; }
.composer-voice-inline audio { display: none; }
.voice-track {
  position: relative;
  display: flex;
  flex: 1;
  align-items: center;
  justify-content: space-between;
  min-width: var(--flare-size-icon-size-sm);
  height: 28px;
  gap: 3px;
  overflow: hidden;
}
.voice-track i { flex: 1 0 2px; max-width: 3px; border-radius: var(--flare-size-radius-full, 999px); background: var(--studio-border, var(--flare-color-border-primary)); }
.voice-track.is-paused i { background: color-mix(in srgb, var(--studio-accent, var(--flare-color-primary)) 35%, var(--studio-border, var(--flare-color-border-primary))); }
.voice-track.is-recording i { background: var(--studio-accent, var(--flare-color-primary)); animation: composer-voice-pulse 0.7s ease-in-out infinite alternate; }
.voice-track input { position: absolute; inset: 0; width: 100%; height: 100%; margin: 0; opacity: 0; cursor: pointer; }
@keyframes composer-voice-pulse { from { transform: scaleY(0.35); } to { transform: scaleY(1); } }
@container flare-composer (max-width: 639px) {
  .composer-voice-inline { gap: 1px; padding: 5px 3px; }
  .composer-voice-inline button { flex-basis: 44px; width: 44px; height: 44px; }
  .composer-voice-inline time { min-width: var(--flare-size-layout-control-height-sm); font-size: var(--flare-size-font-size-xs); }
}
@media (prefers-reduced-motion: reduce) {
  .voice-track i { animation: none !important; }
}
</style>
