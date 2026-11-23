<script setup lang="ts">
import { flareCallAvatar } from "./callSizes";
// The minimized call (docs/plugin-experience.md §3.5): a stage-coloured pill of component.callDockHeight — avatar,
// name, status (duration while connected; short phrases otherwise, §12.17: call.dockWaiting, a warning dot and
// call.reconnectingShort, call.interrupted in colors.call.errorText; statusDetail replaces it), then mic and hangup.
// Keys take controlHover while pressed; their 0.98 press scale stops under reduced motion.
import { NIcon } from "naive-ui";
import { computed } from "vue";
import { flareIcons } from "../../shared/icons";
import FlareAvatar from "../conversation/FlareAvatar.vue";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import type { FlareCallMode, FlareCallState } from "../../shared/contracts";

const props = withDefaults(
  defineProps<{
    /** Peer / group name shown in the dock. */
    title: string;
    avatarUrl?: string;
    /** e.g. "02:14" — the running duration. */
    durationLabel?: string;
    state?: FlareCallState;
    statusDetail?: string;
    mode?: FlareCallMode;
    muted?: boolean;
  }>(),
  { mode: "audio", muted: false, state: "connected" },
);
const emit = defineEmits<{
  (e: "expand"): void;
  (e: "toggleMute"): void;
  (e: "hangup"): void;
}>();

const { t } = useFlareI18n();
const stateText = computed(() => {
  if (props.state === "failed") return t("call.interrupted");
  if (props.state === "reconnecting") return t("call.reconnectingShort");
  if (props.state === "calling" || props.state === "ringing") return t("call.dockWaiting");
  return t("call.connected");
});
const statusText = computed(() => props.statusDetail?.trim() || (props.state === "connected" && props.durationLabel ? props.durationLabel : stateText.value));
</script>

<template>
  <div class="flare-call-dock" :class="`flare-call-dock--${state}`" role="group" :aria-label="stateText">
    <button type="button" class="flare-call-dock__main" :aria-label="t('call.returnToCall')" @click="emit('expand')">
      <span class="flare-call-dock__avatar">
        <FlareAvatar :user-id="title" :display-name="title" :avatar-url="avatarUrl" :size="flareCallAvatar.dock" />
        <span v-if="state === 'connected'" class="flare-call-dock__pulse" />
      </span>
      <span class="flare-call-dock__meta">
        <span class="flare-call-dock__title">{{ title }}</span>
        <span class="flare-call-dock__status" role="status">
          <span v-if="state === 'reconnecting'" class="flare-call-dock__dot" aria-hidden="true" />
          <n-icon v-else aria-hidden="true" size="var(--flare-size-icon-size-sm)" :component="mode === 'video' ? flareIcons.video : flareIcons.phone" />
          {{ statusText }}
        </span>
      </span>
    </button>

    <div class="flare-call-dock__actions">
      <button
        type="button"
        class="flare-call-dock__btn"
        :class="{ 'is-active': muted }"
        role="switch"
        :disabled="state === 'failed'"
        :aria-checked="!muted"
        :aria-label="t('call.microphone')"
        @click="emit('toggleMute')"
      >
        <n-icon aria-hidden="true" size="var(--flare-size-icon-size-md)" :component="muted ? flareIcons['mic-off'] : flareIcons.mic" />
      </button>
      <button
        type="button"
        class="flare-call-dock__btn flare-call-dock__btn--hangup"
        :aria-label="t('call.hangUp')"
        @click="emit('hangup')"
      >
        <n-icon aria-hidden="true" size="var(--flare-size-icon-size-md)" :component="flareIcons['end-call']" />
      </button>
    </div>
  </div>
</template>

<style scoped>
.flare-call-dock {
  --flare-call-dock-key: var(--flare-size-component-call-dock-key-size);
  box-sizing: border-box;
  display: inline-flex;
  max-width: 100%;
  height: var(--flare-size-component-call-dock-height);
  align-items: center;
  gap: var(--flare-size-spacing-sm);
  padding-inline: var(--flare-size-spacing-xs) var(--flare-size-spacing-sm);
  border-radius: var(--flare-size-radius-full);
  background: var(--flare-color-call-stage);
  box-shadow: var(--flare-shadow-lg);
  color: var(--flare-color-call-on-stage);
}
.flare-call-dock__main {
  display: inline-flex;
  align-items: center;
  gap: var(--flare-size-spacing-sm);
  min-width: 0;
  min-height: var(--flare-size-layout-touch-target-min);
  flex: 1;
  padding: 0;
  border: none;
  border-radius: var(--flare-size-radius-full);
  background: transparent;
  color: inherit;
  font: inherit;
  cursor: pointer;
}
.flare-call-dock__avatar { position: relative; display: inline-flex; flex: none; }
/* Connected: a breathing 2-wide speaking ring. */
.flare-call-dock__pulse {
  position: absolute;
  inset: calc(var(--flare-size-spacing-3xs) * -1);
  border-radius: var(--flare-size-radius-full);
  border: 2px solid var(--flare-color-call-speaking);
  animation: flare-dock-breathe 1.6s ease-in-out infinite alternate;
}
@keyframes flare-dock-breathe {
  from { opacity: 1; }
  to { opacity: 0.35; }
}
.flare-call-dock__meta { display: flex; flex-direction: column; align-items: flex-start; min-width: 0; }
.flare-call-dock__title {
  font-size: var(--flare-size-font-size-lg);
  font-weight: var(--flare-size-font-weight-semibold);
  max-width: var(--flare-size-component-call-dock-name-max-width);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.flare-call-dock__status {
  display: inline-flex;
  align-items: center;
  gap: var(--flare-size-spacing-xs);
  max-width: 100%;
  font-size: var(--flare-size-font-size-sm);
  color: var(--flare-color-call-on-stage-secondary);
  font-variant-numeric: tabular-nums;
  overflow-wrap: anywhere;
}
.flare-call-dock--failed .flare-call-dock__status { color: var(--flare-color-call-error-text); }
.flare-call-dock__dot {
  flex: none;
  width: var(--flare-size-spacing-sm);
  height: var(--flare-size-spacing-sm);
  border-radius: var(--flare-size-radius-full);
  background: var(--flare-color-warning);
}
@media (prefers-reduced-motion: reduce) {
  .flare-call-dock__pulse { animation: none; }
}
.flare-call-dock__actions { display: flex; align-items: center; gap: var(--flare-size-spacing-xs); flex-shrink: 0; }
.flare-call-dock__btn {
  position: relative;
  width: var(--flare-call-dock-key);
  height: var(--flare-call-dock-key);
  min-width: 0;
  min-height: 0;
  padding: 0;
  border-radius: var(--flare-size-radius-full);
  border: none;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  background: var(--flare-color-call-control);
  color: var(--flare-color-call-on-stage);
  cursor: pointer;
  transition: background var(--flare-transition-fast), transform var(--flare-transition-fast);
}
/* The hit area reaches the touch target around the drawn key. */
.flare-call-dock__btn::after {
  content: "";
  position: absolute;
  top: 50%;
  left: 50%;
  width: var(--flare-size-layout-touch-target-min);
  height: var(--flare-size-layout-touch-target-min);
  transform: translate(-50%, -50%);
}
@media (hover: hover) {
  .flare-call-dock__btn:not(:disabled):not(.is-active):not(.flare-call-dock__btn--hangup):hover { background: var(--flare-color-call-control-hover); }
}
.flare-call-dock__btn:disabled { opacity: var(--flare-opacity-disabled); cursor: not-allowed; }
.flare-call-dock__btn:not(:disabled):active { transform: scale(var(--flare-size-component-press-scale)); }
.flare-call-dock__btn:not(:disabled):not(.is-active):not(.flare-call-dock__btn--hangup):active { background: var(--flare-color-call-control-hover); }
/* Reduced motion: a press changes colour only (after the scale, so it wins). */
@media (prefers-reduced-motion: reduce) {
  .flare-call-dock__btn:not(:disabled):active { transform: none; }
}
.flare-call-dock__btn.is-active {
  background: var(--flare-color-call-control-active);
  color: var(--flare-color-call-on-control-active);
}
.flare-call-dock__btn--hangup { background: var(--flare-color-call-hangup); }
.flare-call-dock__btn--hangup:active { background: var(--flare-color-call-hangup-pressed); }
.flare-call-dock__main:focus-visible,
.flare-call-dock__btn:focus-visible {
  outline: var(--flare-size-component-focus-ring-width) solid var(--flare-color-border-selected);
  outline-offset: var(--flare-size-component-focus-ring-offset);
}
</style>
