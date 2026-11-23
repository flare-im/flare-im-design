<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref, watch } from "vue";
import FlareButton from "../general/FlareButton.vue";
import FlareIconButton from "../general/FlareIconButton.vue";
import FlareVoiceHoldButton from "./FlareVoiceHoldButton.vue";
import FlareSlider from "../form/FlareSlider.vue";
import { flareIcons } from "../../shared/icons";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import { canFocusFlareModalTarget } from "../../shared/useModalSurface";
import { formatVoiceDuration, type VoiceRecorder } from "../../composables/composer/useVoiceRecorder";

// Shared voice composer: explicit tap-to-record, review, resume and send.
// Capture state lives in the injected recorder; this panel only owns preview playback.
const props = defineProps<{
  recorder: VoiceRecorder;
  /** Phones offer a hold gesture; release reviews the clip before sending. */
  holdToTalk?: boolean;
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
  (event: "previewStarted"): void;
  (event: "tooShort"): void;
}>();
const { t } = useFlareI18n();

const returnButton = ref<InstanceType<typeof FlareIconButton> | null>(null);
onMounted(() => {
  // The editor and its toolbar are hidden while voice mode is open.
  const button = returnButton.value?.$el as HTMLButtonElement | undefined;
  if (button && canFocusFlareModalTarget(button)) button.focus({ preventScroll: true });
});

const audio = ref<HTMLAudioElement | null>(null);
const playing = ref(false);
const playbackPending = ref(false);
const playbackMs = ref(0);
const holding = ref(false);
const { recording, paused, requestPending, elapsedMs, preview, previewUrl, hasSession, atLimit } = props.recorder;

let playbackGeneration = 0;
function pausePlayback(): void { playbackGeneration++; audio.value?.pause(); playing.value = false; playbackPending.value = false; }
async function togglePlayback(): Promise<void> {
  if (playing.value || playbackPending.value) { pausePlayback(); return; }
  const node = audio.value;
  if (!node || !preview.value) return;
  const mine = ++playbackGeneration;
  playbackPending.value = true;
  try {
    if (node.ended) { node.currentTime = 0; playbackMs.value = 0; }
    await node.play();
    if (mine !== playbackGeneration) { node.pause(); return; }
    playing.value = true;
    emit("previewStarted");
  } catch { if (mine === playbackGeneration) emit("previewFailed"); }
  finally { if (mine === playbackGeneration) playbackPending.value = false; }
}
function seek(value: number): void {
  const node = audio.value;
  if (!node) return;
  const seconds = value / 1000;
  try { node.currentTime = seconds; playbackMs.value = seconds * 1000; } catch { /* Not yet seekable. */ }
}
watch(previewUrl, () => { pausePlayback(); playbackMs.value = 0; });
watch(() => props.submitting, (busy) => { if (busy) pausePlayback(); });
onBeforeUnmount(pausePlayback);
const shown = computed(() => formatVoiceDuration(elapsedMs.value));
const keyboardLabel = computed(() => hasSession.value || preview.value || requestPending.value
  ? t('composer.returnKeyboard') : t('composer.returnKeyboardIdle'));
const unavailable = computed(() => props.sendBlocked || props.submitting || requestPending.value);
function startHold(): void { holding.value = true; emit("start"); }
function cancelHold(): void { holding.value = false; emit("discard"); }
function finishHold(): void {
  holding.value = false;
  // Releasing during the permission prompt invalidates that capture request.
  if (requestPending.value) { emit("discard"); return; }
  if (!recording.value) return;
  emit("pause");
  if (elapsedMs.value < 250) { emit("discard"); emit("tooShort"); }
}
</script>

<template>
  <section class="composer-voice-inline" :class="{ 'is-preview': paused }" :aria-label="t('composer.voice')">
    <FlareIconButton ref="returnButton" size="md" :icon="flareIcons.keyboard" :disabled="submitting" :title="keyboardLabel" :ariaLabel="keyboardLabel" @click="emit('close')" />
    <template v-if="!paused">
      <FlareVoiceHoldButton v-if="holdToTalk && (!recording || holding)" class="voice-record"
        :label="t('composer.holdToRecord')" :recording-label="t('composer.releaseToReview')"
        :disabled="sendBlocked || submitting" :busy="requestPending" slide-to-cancel
        @start="startHold" @end="finishHold" @cancel="cancelHold">
        <template #trailing><time v-if="recording">{{ shown }}</time></template>
      </FlareVoiceHoldButton>
      <FlareButton v-else class="voice-record" size="md" variant="secondary"
        :icon="recording ? flareIcons.pause : flareIcons.mic" :disabled="unavailable" :loading="requestPending"
        :aria-label="requestPending ? t('composer.requestingMicrophone') : recording ? t('composer.pauseRecording') : t('composer.startRecording')"
        @click="recording ? emit('pause') : emit('start')">
        <span v-if="recording" class="voice-recording-dot" aria-hidden="true" />
        <span>{{ requestPending ? t('composer.requestingMicrophone') : recording ? t('composer.pauseRecording') : t('composer.startRecording') }}</span>
        <time v-if="recording">{{ shown }}</time>
      </FlareButton>
      <FlareIconButton v-if="hasSession || requestPending" size="md" :icon="flareIcons.delete" :disabled="submitting" :title="t('composer.discardRecording')" :ariaLabel="t('composer.discardRecording')" @click="emit('discard')" />
    </template>
    <template v-else>
      <div class="voice-preview">
        <FlareIconButton size="md" :icon="playing ? flareIcons.pause : flareIcons.play" :disabled="!preview || submitting" :title="t('composer.previewRecording')" :ariaLabel="t('composer.previewRecording')" :toggle="true" :active="playing" :aria-busy="playbackPending" @click="togglePlayback" />
        <div class="voice-scrubber">
          <time aria-hidden="true">{{ formatVoiceDuration(playbackMs) }} / {{ shown }}</time>
          <FlareSlider class="voice-seek" :min="0" :max="elapsedMs" :model-value="playbackMs" :disabled="!preview || submitting" :aria-label="t('composer.seekRecording')" :aria-value-text="t('composer.voicePlaybackPosition', { current: formatVoiceDuration(playbackMs), total: shown })" @update:model-value="seek" />
        </div>
      </div>
      <div class="voice-review-actions">
        <FlareIconButton size="md" :icon="flareIcons.delete" :disabled="submitting" :title="t('composer.discardRecording')" :ariaLabel="t('composer.discardRecording')" @click="emit('discard')" />
        <FlareIconButton v-if="hasSession" size="md" :icon="flareIcons.mic" :disabled="sendBlocked || submitting || atLimit" :title="t('composer.resumeRecording')" :ariaLabel="t('composer.resumeRecording')" @click="emit('resume')" />
        <FlareIconButton size="md" variant="solid" :icon="flareIcons.send" :disabled="!preview || sendBlocked || submitting" :aria-busy="submitting" :title="sendLabel" :ariaLabel="sendLabel" @click="emit('send')" />
      </div>
    </template>
    <audio v-if="previewUrl" ref="audio" :src="previewUrl" @timeupdate="playbackMs = (audio?.currentTime ?? 0) * 1000" @ended="playing = false" @pause="playing = false" />
  </section>
</template>

<style scoped>
.composer-voice-inline {
  --voice-control-gap: calc(var(--flare-size-layout-touch-target) - var(--flare-size-component-icon-button-side-md));
  display: flex; align-items: center; gap: var(--voice-control-gap); flex-wrap: nowrap;
  min-height: var(--flare-size-layout-touch-target); width: 100%; box-sizing: border-box;
  padding: var(--flare-size-spacing-xs) var(--flare-size-spacing-sm);
}
.composer-voice-inline > :first-child, .voice-review-actions { flex: none; }
.voice-record { flex: 1; min-width: 0; }
.composer-voice-inline time { color: var(--flare-color-text-secondary); font: var(--flare-size-font-size-xs) var(--flare-component-font-family-mono); font-variant-numeric: tabular-nums; white-space: nowrap; }
.composer-voice-inline audio { display: none; }
.voice-preview { display: flex; flex: 1; align-items: center; min-width: 0; gap: var(--voice-control-gap); }
.voice-scrubber { position: relative; display: flex; flex: 1; flex-direction: column; justify-content: center; min-width: var(--flare-size-layout-touch-target); height: var(--flare-size-layout-touch-target); }
.voice-scrubber time { position: absolute; inset: 0 0 auto; text-align: center; line-height: 1; pointer-events: none; }
.voice-seek { width: 100%; min-width: 0; min-height: var(--flare-size-layout-touch-target); margin: 0; height: var(--flare-size-layout-touch-target); box-sizing: border-box; padding: 0; cursor: pointer; }
.voice-review-actions { display: flex; align-items: center; gap: var(--voice-control-gap); }
.voice-recording-dot { width: var(--flare-size-spacing-xs); height: var(--flare-size-spacing-xs); border-radius: var(--flare-size-radius-full); background: var(--flare-color-error); animation: voice-record-pulse 1s ease-in-out infinite alternate; }
@keyframes voice-record-pulse { to { opacity: 0.35; } }
@container flare-composer (max-width: 639px) { .composer-voice-inline { padding-inline: 0; } }
@media (prefers-reduced-motion: reduce) { .voice-recording-dot { animation: none; } }
</style>
