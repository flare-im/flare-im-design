<script setup lang="ts">
import { computed } from "vue";
import { NIcon } from "naive-ui";
import { PlayOutline, PauseOutline, DocumentTextOutline } from "../../shared/icon-glyphs";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";

const props = withDefaults(
  defineProps<{
    /** Total length label, e.g. "0:24". */
    durationLabel: string;
    /** Elapsed label while playing, e.g. "0:07". */
    elapsedLabel?: string;
    /** Playback position 0–1 — fills the waveform up to here. */
    progress?: number;
    playing?: boolean;
    /** Waveform samples 0–1; a default sine is drawn when omitted. */
    amplitudes?: number[];
    /** Current speed; clicking cycles it via the `cycleSpeed` event. */
    speed?: number;
    /** Show the transcript expander + text. */
    transcript?: string;
    transcriptOpen?: boolean;
    /** Unplayed dot for a not-yet-heard message. */
    unplayed?: boolean;
    /** Self / outbound styling (brand-tinted). */
    outbound?: boolean;
  }>(),
  { progress: 0, playing: false, speed: 1 },
);
const emit = defineEmits<{
  (e: "toggle"): void;
  (e: "seek", ratio: number): void;
  (e: "cycleSpeed"): void;
  (e: "toggleTranscript"): void;
}>();

const { t } = useFlareI18n();
const bars = computed(() => {
  const n = 32;
  const src = props.amplitudes?.length
    ? props.amplitudes
    : Array.from({ length: n }, (_, i) => 0.25 + 0.6 * Math.abs(Math.sin(i * 0.6)));
  return Array.from({ length: n }, (_, i) => src[i % src.length] ?? 0.3);
});
const filled = computed(() => Math.round(Math.min(1, Math.max(0, props.progress)) * bars.value.length));
const speedLabel = computed(() => `${props.speed % 1 === 0 ? props.speed : props.speed.toFixed(1)}×`);

function seekAt(e: MouseEvent): void {
  const el = e.currentTarget as HTMLElement;
  const rect = el.getBoundingClientRect();
  emit("seek", Math.min(1, Math.max(0, (e.clientX - rect.left) / rect.width)));
}
</script>

<template>
  <div class="flare-voice-player" :class="{ 'is-outbound': outbound }">
    <div class="flare-voice-player__bar">
      <button
        type="button"
        class="flare-voice-player__play"
        :aria-label="playing ? t('voicePlayer.pause') : t('voicePlayer.play')"
        @click="emit('toggle')"
      >
        <n-icon aria-hidden="true" :size="18" :component="playing ? PauseOutline : PlayOutline" />
        <span v-if="unplayed && !playing" class="flare-voice-player__dot" />
      </button>

      <button type="button" class="flare-voice-player__wave" :aria-label="t('voicePlayer.progress')" @click="seekAt">
        <i
          v-for="(a, i) in bars"
          :key="i"
          :class="{ 'is-filled': i < filled }"
          :style="{ height: `${Math.round(4 + a * 18)}px` }"
        />
      </button>

      <span class="flare-voice-player__time">{{ playing && elapsedLabel ? elapsedLabel : durationLabel }}</span>

      <button
        type="button"
        class="flare-voice-player__speed"
        :aria-label="t('voicePlayer.speed')"
        @click="emit('cycleSpeed')"
      >{{ speedLabel }}</button>
    </div>

    <button
      v-if="transcript"
      type="button"
      class="flare-voice-player__tr-toggle"
      @click="emit('toggleTranscript')"
    >
      <n-icon aria-hidden="true" :size="13" :component="DocumentTextOutline" />
      {{ transcriptOpen ? t("voicePlayer.hideText") : t("voicePlayer.toText") }}
    </button>
    <p v-if="transcript && transcriptOpen" class="flare-voice-player__tr">{{ transcript }}</p>
  </div>
</template>

<style scoped>
.flare-voice-player {
  display: inline-flex;
  flex-direction: column;
  gap: 6px;
  padding: var(--flare-size-spacing-2sm) 12px;
  border-radius: 16px 16px 16px 4px;
  background: var(--flare-color-bg-primary);
  border: 1px solid var(--flare-color-border-primary);
  box-shadow: var(--flare-shadow-sm);
  max-width: 100%;
}
.flare-voice-player.is-outbound {
  background: var(--flare-color-bg-selected);
  border-color: color-mix(in srgb, var(--flare-color-primary) 24%, transparent);
  border-radius: 16px 16px 4px 16px;
}
.flare-voice-player__bar { display: flex; align-items: center; gap: var(--flare-size-spacing-2sm); }
.flare-voice-player__play {
  position: relative;
  flex: 0 0 auto;
  width: 36px;
  height: 36px;
  border-radius: 50%;
  border: none;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  color: #fff;
  background: var(--flare-component-brand-primary);
  cursor: pointer;
  transition: transform var(--flare-transition-fast);
}
.flare-voice-player__play:active { transform: scale(0.94); }
.flare-voice-player__dot {
  position: absolute;
  top: -1px;
  right: -1px;
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: var(--flare-color-error);
  border: 1.5px solid var(--flare-color-bg-primary);
}
.flare-voice-player__wave {
  flex: 1;
  min-width: 120px;
  display: flex;
  align-items: center;
  gap: 2px;
  height: 26px;
  border: none;
  background: transparent;
  padding: 0;
  cursor: pointer;
}
.flare-voice-player__wave i {
  flex: 1;
  min-width: 2px;
  border-radius: 2px;
  background: var(--flare-color-border-hover);
  transition: background var(--flare-transition-fast);
}
.flare-voice-player__wave i.is-filled { background: var(--flare-color-primary); }
.flare-voice-player__time {
  flex: 0 0 auto;
  font-size: 12px;
  font-variant-numeric: tabular-nums;
  color: var(--flare-color-text-tertiary);
  min-width: 30px;
  text-align: right;
}
.flare-voice-player__speed {
  flex: 0 0 auto;
  border: 1px solid var(--flare-color-border-primary);
  background: var(--flare-color-bg-secondary);
  color: var(--flare-color-text-secondary);
  font-size: 11px;
  font-weight: 600;
  border-radius: 999px;
  padding: 2px 8px;
  cursor: pointer;
  font-variant-numeric: tabular-nums;
}
.flare-voice-player__tr-toggle {
  align-self: flex-start;
  display: inline-flex;
  align-items: center;
  gap: 4px;
  border: none;
  background: transparent;
  color: var(--flare-color-primary-text);
  font-size: 12px;
  cursor: pointer;
  padding: 0;
}
.flare-voice-player__tr {
  margin: 0;
  padding-top: 6px;
  border-top: 1px dashed var(--flare-color-border-primary);
  font-size: 13px;
  line-height: 1.5;
  color: var(--flare-color-text-secondary);
  white-space: pre-wrap;
  overflow-wrap: anywhere;
}
</style>
