<script setup lang="ts">
import { NIcon } from "naive-ui";
import {
  MicOffOutline,
  MicOutline,
  CallOutline,
  ExpandOutline,
  VideocamOutline,
} from "@vicons/ionicons5";
import FlareAvatar from "../conversation/FlareAvatar.vue";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import type { FlareCallMode } from "../../shared/contracts";

const props = withDefaults(
  defineProps<{
    /** Peer / group name shown in the dock. */
    title: string;
    avatarUrl?: string;
    /** e.g. "02:14" — the running duration. */
    durationLabel?: string;
    mode?: FlareCallMode;
    muted?: boolean;
  }>(),
  { mode: "audio", muted: false },
);
const emit = defineEmits<{
  (e: "expand"): void;
  (e: "toggleMute"): void;
  (e: "hangup"): void;
}>();

const { t } = useFlareI18n();
</script>

<template>
  <div class="flare-call-dock" role="group" :aria-label="t('call.connected')">
    <button type="button" class="flare-call-dock__main" :aria-label="t('call.minimize')" @click="emit('expand')">
      <span class="flare-call-dock__avatar">
        <FlareAvatar :user-id="title" :display-name="title" :avatar-url="avatarUrl" :size="34" />
        <span class="flare-call-dock__pulse" />
      </span>
      <span class="flare-call-dock__meta">
        <span class="flare-call-dock__title">{{ title }}</span>
        <span class="flare-call-dock__status">
          <n-icon :size="12" :component="mode === 'video' ? VideocamOutline : CallOutline" />
          {{ durationLabel || t("call.connected") }}
        </span>
      </span>
      <n-icon :size="16" :component="ExpandOutline" class="flare-call-dock__expand" />
    </button>

    <div class="flare-call-dock__actions">
      <button
        type="button"
        class="flare-call-dock__btn"
        :class="{ 'is-active': muted }"
        :aria-label="t('call.microphone')"
        @click="emit('toggleMute')"
      >
        <n-icon :size="18" :component="muted ? MicOffOutline : MicOutline" />
      </button>
      <button
        type="button"
        class="flare-call-dock__btn flare-call-dock__btn--hangup"
        :aria-label="t('call.hangUp')"
        @click="emit('hangup')"
      >
        <n-icon :size="18" :component="CallOutline" class="flare-call-dock__hangup-ico" />
      </button>
    </div>
  </div>
</template>

<style scoped>
.flare-call-dock {
  display: inline-flex;
  align-items: center;
  gap: 10px;
  padding: 8px 10px 8px 8px;
  border-radius: 999px;
  background: linear-gradient(135deg, #2a2438, #191320);
  box-shadow: 0 14px 34px rgba(21, 18, 32, 0.34);
  color: #fff;
}
.flare-call-dock__main {
  display: inline-flex;
  align-items: center;
  gap: 10px;
  border: none;
  background: transparent;
  color: inherit;
  cursor: pointer;
  padding: 0 4px 0 0;
}
.flare-call-dock__avatar { position: relative; display: inline-flex; }
.flare-call-dock__pulse {
  position: absolute;
  inset: -3px;
  border-radius: 50%;
  border: 2px solid var(--flare-color-success, #34d17f);
  animation: flare-dock-pulse 1.8s ease-out infinite;
}
@media (prefers-reduced-motion: reduce) {
  .flare-call-dock__pulse { animation: none; }
}
@keyframes flare-dock-pulse {
  0% { opacity: 0.9; transform: scale(1); }
  100% { opacity: 0; transform: scale(1.35); }
}
.flare-call-dock__meta { display: flex; flex-direction: column; align-items: flex-start; min-width: 0; }
.flare-call-dock__title {
  font-size: 14px;
  font-weight: 600;
  max-width: 120px;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.flare-call-dock__status {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  font-size: 12px;
  color: rgba(255, 255, 255, 0.66);
  font-variant-numeric: tabular-nums;
}
.flare-call-dock__expand { color: rgba(255, 255, 255, 0.5); margin-left: 2px; }
.flare-call-dock__actions { display: flex; align-items: center; gap: 6px; }
.flare-call-dock__btn {
  width: 36px;
  height: 36px;
  border-radius: 50%;
  border: none;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  background: rgba(255, 255, 255, 0.14);
  color: #fff;
  cursor: pointer;
  transition: background var(--flare-transition-fast, 150ms ease), transform var(--flare-transition-fast, 150ms ease);
}
.flare-call-dock__btn:hover { background: rgba(255, 255, 255, 0.22); }
.flare-call-dock__btn:active { transform: scale(0.94); }
.flare-call-dock__btn.is-active { background: #fff; color: #17131f; }
.flare-call-dock__btn--hangup { background: var(--flare-color-error, #ef4444); }
.flare-call-dock__btn--hangup:hover { background: #dc2626; }
.flare-call-dock__hangup-ico { transform: rotate(135deg); }
</style>
