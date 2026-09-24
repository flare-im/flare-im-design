<script setup lang="ts">
import { computed } from "vue";
import MsgIcon from "./MsgIcon.vue";
import { useFlareI18nOptional } from "../../../shared/i18n/useFlareI18n";

const props = withDefaults(
  defineProps<{
    seconds?: number;
    elapsedSeconds?: number;
    playing?: boolean;
    progress?: number;
    disabled?: boolean;
    outbound?: boolean;
    embedded?: boolean;
  }>(),
  {
    seconds: 1,
    elapsedSeconds: 0,
    playing: false,
    progress: 0,
    disabled: false,
    outbound: false,
    embedded: false,
  },
);

const emit = defineEmits<{
  (event: "play"): void;
  (event: "seek", ratio: number): void;
}>();

const { t } = useFlareI18nOptional();
const amplitudes = [0.34, 0.58, 0.82, 0.48, 0.72, 1, 0.62, 0.42, 0.76, 0.9, 0.54, 0.7, 0.38, 0.64, 0.86, 0.5, 0.72, 0.4];
const normalizedSeconds = computed(() => Math.max(0, Math.round(props.seconds || 0)));
const normalizedProgress = computed(() => Math.min(1, Math.max(0, props.progress || 0)));
const filledBars = computed(() => Math.round(normalizedProgress.value * amplitudes.length));
const voiceWidth = computed(() => {
  const duration = normalizedSeconds.value || 8;
  return Math.round(Math.min(276, Math.max(184, 174 + Math.min(duration, 60) * 1.7)));
});
const durationLabel = computed(() => {
  if (props.playing && props.elapsedSeconds > 0 && normalizedSeconds.value > 0) {
    return `${formatTime(props.elapsedSeconds)} / ${formatTime(normalizedSeconds.value)}`;
  }
  if (normalizedSeconds.value > 0) return `${normalizedSeconds.value}\"`;
  return props.disabled ? t("voicePlayer.unavailable") : t("voicePlayer.voice");
});
const playLabel = computed(() => {
  if (props.disabled) return t("voicePlayer.unavailable");
  return props.playing ? t("voicePlayer.pause") : t("voicePlayer.play");
});
const progressLabel = computed(() =>
  `${t("voicePlayer.progress")} ${Math.round(normalizedProgress.value * 100)}%`,
);

function formatTime(seconds: number): string {
  const safe = Math.max(0, Math.round(seconds));
  return `${Math.floor(safe / 60)}:${String(safe % 60).padStart(2, "0")}`;
}

function seekAt(event: MouseEvent): void {
  if (props.disabled) return;
  const rect = (event.currentTarget as HTMLElement).getBoundingClientRect();
  if (!rect.width) return;
  emit("seek", Math.min(1, Math.max(0, (event.clientX - rect.left) / rect.width)));
}
</script>

<template>
  <div
    class="fm-voice"
    :class="{
      'fm-voice--playing': playing,
      'fm-voice--disabled': disabled,
      'fm-voice--outbound': outbound,
      'fm-voice--embedded': embedded,
    }"
    :style="{ '--flare-component-voice-width': `${voiceWidth}px` }"
    role="group"
    :aria-label="`${t('voicePlayer.voice')}, ${durationLabel}`"
  >
    <button
      type="button"
      class="fm-voice__play"
      :disabled="disabled"
      :aria-label="playLabel"
      :title="playLabel"
      @click="emit('play')"
    >
      <MsgIcon :name="playing ? 'volume' : 'play'" :size="17" />
    </button>

    <button
      type="button"
      class="fm-voice__wave"
      :disabled="disabled"
      :aria-label="progressLabel"
      :title="progressLabel"
      @click="seekAt"
    >
      <i
        v-for="(amplitude, index) in amplitudes"
        :key="index"
        :class="{ 'is-filled': index < filledBars }"
        :style="{ height: `${Math.round(5 + amplitude * 15)}px` }"
      />
    </button>

    <span class="fm-voice__duration">{{ durationLabel }}</span>
  </div>
</template>

<style scoped>
.fm-voice {
  --flare-component-voice-accent: var(--flare-color-primary);

  box-sizing: border-box;
  display: inline-flex;
  width: min(var(--flare-component-voice-width), 100%);
  min-width: min(184px, 100%);
  min-height: 48px;
  align-items: center;
  gap: 9px;
  padding: 6px var(--flare-size-spacing-2sm);
  border: 1px solid var(--flare-color-border-primary);
  border-radius: 13px 13px 13px 5px;
  color: var(--flare-color-text-secondary);
  background: var(--flare-color-bg-primary);
  box-shadow: var(--flare-shadow-sm);
}

.fm-voice--outbound:not(.fm-voice--embedded) {
  border-color: color-mix(in srgb, var(--flare-color-primary) 24%, transparent);
  border-radius: 13px 13px 5px 13px;
  background: var(--flare-color-bg-selected);
}

.fm-voice--embedded {
  --flare-component-voice-accent: currentColor;

  min-height: 36px;
  padding: 0;
  border: 0;
  border-radius: 0;
  color: inherit;
  background: transparent;
  box-shadow: none;
}

.fm-voice__play,
.fm-voice__wave {
  color: inherit;
  cursor: pointer;
}

.fm-voice__play {
  display: grid;
  width: 36px;
  height: 36px;
  flex: 0 0 36px;
  place-items: center;
  padding: 0;
  border: 1px solid color-mix(in srgb, currentColor 20%, transparent);
  border-radius: 50%;
  background: color-mix(in srgb, currentColor 9%, transparent);
  transition:
    transform var(--flare-component-motion-fast),
    background var(--flare-component-motion-fast);
}

.fm-voice__play:hover,
.fm-voice__play:focus-visible {
  background: color-mix(in srgb, currentColor 15%, transparent);
}

.fm-voice__play:focus-visible,
.fm-voice__wave:focus-visible {
  outline: 2px solid var(--flare-color-border-selected);
  outline-offset: 2px;
}

.fm-voice__play:active {
  transform: scale(0.95);
}

.fm-voice__wave {
  display: flex;
  height: 32px;
  min-width: 0;
  flex: 1 1 auto;
  align-items: center;
  gap: 2px;
  padding: 5px 0;
  border: 0;
  background: transparent;
}

.fm-voice__wave i {
  width: 2px;
  min-width: 2px;
  border-radius: 999px;
  background: color-mix(in srgb, currentColor 30%, transparent);
  transition: background var(--flare-component-motion-fast);
}

.fm-voice__wave i.is-filled,
.fm-voice--playing .fm-voice__wave i {
  background: var(--flare-component-voice-accent);
}

.fm-voice__duration {
  min-width: 24px;
  flex: 0 0 auto;
  /* 68% 的当前色在白底上只有 3:1；90% 既保留“更安静”的层级，又过 AA。 */
  color: color-mix(in srgb, currentColor 90%, transparent);
  font-size: 12px;
  font-variant-numeric: tabular-nums;
  line-height: 1;
  text-align: end;
  white-space: nowrap;
}

.fm-voice--disabled {
  opacity: 0.68;
}

.fm-voice--disabled .fm-voice__play,
.fm-voice--disabled .fm-voice__wave {
  cursor: not-allowed;
}

@container flare-timeline (max-width: 479px) {
  .fm-voice {
    max-width: min(248px, calc(100vw - 112px));
  }

  .fm-voice__play {
    width: 40px;
    height: 40px;
    flex-basis: 40px;
  }
}

@media (prefers-reduced-motion: reduce) {
  .fm-voice__play,
  .fm-voice__wave i {
    transition: none;
  }
}
</style>
