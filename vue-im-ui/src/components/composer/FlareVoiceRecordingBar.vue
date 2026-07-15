<script setup lang="ts">
import { computed } from "vue";
import { NIcon } from "naive-ui";
import { TrashOutline, SendOutline, MicOutline } from "@vicons/ionicons5";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";

const props = withDefaults(
  defineProps<{
    /** e.g. "0:07" — the running record time. */
    durationLabel: string;
    /** Recent amplitude samples (0–1) driving the live waveform. */
    amplitudes?: number[];
    /** Finger is over the cancel zone — bar turns to a release-to-cancel state. */
    cancelling?: boolean;
  }>(),
  { amplitudes: () => [], cancelling: false },
);
const emit = defineEmits<{
  (e: "cancel"): void;
  (e: "send"): void;
}>();

const { t } = useFlareI18n();
// Always render a fixed number of bars; pad/trim the incoming samples.
const bars = computed(() => {
  const n = 28;
  const src = props.amplitudes.length ? props.amplitudes : Array.from({ length: n }, (_, i) => 0.2 + 0.5 * Math.abs(Math.sin(i * 0.7)));
  const out: number[] = [];
  for (let i = 0; i < n; i++) out.push(src[i % src.length] ?? 0.3);
  return out;
});
</script>

<template>
  <div class="flare-voice-rec" :class="{ 'is-cancelling': cancelling }" role="group">
    <button type="button" class="flare-voice-rec__cancel" :aria-label="t('recording.cancel')" @click="emit('cancel')">
      <n-icon :size="18" :component="TrashOutline" />
    </button>

    <div class="flare-voice-rec__center">
      <span class="flare-voice-rec__dot" />
      <span class="flare-voice-rec__time">{{ durationLabel }}</span>
      <span class="flare-voice-rec__wave" aria-hidden="true">
        <i v-for="(a, i) in bars" :key="i" :style="{ height: `${Math.round(4 + a * 20)}px` }" />
      </span>
    </div>

    <span v-if="cancelling" class="flare-voice-rec__hint">{{ t("recording.releaseToCancel") }}</span>
    <button
      v-else
      type="button"
      class="flare-voice-rec__send"
      :aria-label="t('recording.send')"
      @click="emit('send')"
    >
      <n-icon :size="18" :component="SendOutline" />
    </button>
  </div>
</template>

<style scoped>
.flare-voice-rec {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 8px 10px;
  border-radius: 999px;
  background: var(--flare-color-bg-primary, #fff);
  border: 1px solid var(--flare-color-border-primary, #e9e6f1);
  box-shadow: var(--flare-shadow-md, 0 6px 18px rgba(21, 18, 32, 0.1));
  transition: background var(--flare-transition-fast, 150ms ease), border-color var(--flare-transition-fast, 150ms ease);
}
.flare-voice-rec.is-cancelling {
  background: color-mix(in srgb, var(--flare-color-error, #ef4444) 10%, var(--flare-color-bg-primary, #fff));
  border-color: color-mix(in srgb, var(--flare-color-error, #ef4444) 40%, transparent);
}
.flare-voice-rec__cancel,
.flare-voice-rec__send {
  flex: 0 0 auto;
  width: 36px;
  height: 36px;
  border-radius: 50%;
  border: none;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  transition: transform var(--flare-transition-fast, 150ms ease), filter var(--flare-transition-fast, 150ms ease);
}
.flare-voice-rec__cancel {
  background: var(--flare-color-bg-secondary, #f6f5fb);
  color: var(--flare-color-text-secondary, #6b6780);
}
.flare-voice-rec.is-cancelling .flare-voice-rec__cancel {
  background: var(--flare-color-error, #ef4444);
  color: #fff;
}
.flare-voice-rec__send {
  background: var(--im-brand-gradient, var(--flare-color-primary, #7c3aed));
  color: #fff;
}
.flare-voice-rec__cancel:active,
.flare-voice-rec__send:active { transform: scale(0.94); }
.flare-voice-rec__center {
  flex: 1;
  min-width: 0;
  display: flex;
  align-items: center;
  gap: 8px;
}
.flare-voice-rec__dot {
  width: 9px;
  height: 9px;
  flex: 0 0 auto;
  border-radius: 50%;
  background: var(--flare-color-error, #ef4444);
  animation: flare-rec-blink 1.1s ease-in-out infinite;
}
@media (prefers-reduced-motion: reduce) {
  .flare-voice-rec__dot { animation: none; }
}
@keyframes flare-rec-blink {
  50% { opacity: 0.25; }
}
.flare-voice-rec__time {
  flex: 0 0 auto;
  font-size: 13px;
  font-variant-numeric: tabular-nums;
  color: var(--flare-color-text-primary, #15131c);
}
.flare-voice-rec__wave {
  flex: 1;
  min-width: 0;
  display: flex;
  align-items: center;
  gap: 2px;
  height: 24px;
  overflow: hidden;
}
.flare-voice-rec__wave i {
  flex: 1;
  min-width: 2px;
  border-radius: 2px;
  background: var(--flare-color-primary, #7c3aed);
  opacity: 0.7;
}
.flare-voice-rec.is-cancelling .flare-voice-rec__wave i { background: var(--flare-color-error, #ef4444); }
.flare-voice-rec__hint {
  flex: 0 0 auto;
  font-size: 12px;
  font-weight: 500;
  color: var(--flare-color-error, #ef4444);
  padding-right: 4px;
}
</style>
