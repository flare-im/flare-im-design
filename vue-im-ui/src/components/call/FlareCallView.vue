<script setup lang="ts">
import { computed } from "vue";
import { NIcon } from "naive-ui";
import { ChevronDownOutline, LockClosedOutline } from "../../shared/icon-glyphs";
import FlareAvatar from "../conversation/FlareAvatar.vue";
import FlareCallControls from "./FlareCallControls.vue";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";

const props = withDefaults(
  defineProps<{
    peerName: string;
    mode: "audio" | "video";
    state: "calling" | "ringing" | "connected";
    durationLabel?: string;
    peerAvatarUrl?: string;
    muted?: boolean;
    cameraOn?: boolean;
    speakerOn?: boolean;
    /** Show the end-to-end-encrypted hint under the status. */
    encrypted?: boolean;
  }>(),
  { muted: false, cameraOn: true, speakerOn: false, encrypted: true },
);
const emit = defineEmits<{
  (e: "hangup"): void;
  (e: "toggleMute"): void;
  (e: "toggleCamera"): void;
  (e: "toggleSpeaker"): void;
  (e: "switchCamera"): void;
  (e: "minimize"): void;
}>();

const { t } = useFlareI18n();
const statusText = computed(() => {
  if (props.state === "connected") return props.durationLabel ?? t("call.connected");
  if (props.state === "ringing") return t("call.ringing");
  return props.mode === "video" ? t("call.waitingAnswer") : t("call.calling");
});
const pulsing = computed(() => props.state !== "connected");
</script>

<template>
  <div class="flare-call-view" :class="`flare-call-view--${state}`">
    <div v-if="mode === 'video'" class="flare-call-view__video">
      <slot name="video" />
    </div>

    <button type="button" class="flare-call-view__minimize" :aria-label="t('call.minimize')" @click="emit('minimize')">
      <n-icon :size="22" :component="ChevronDownOutline" />
    </button>

    <div class="flare-call-view__peer">
      <div v-if="mode === 'audio' || !$slots.video" class="flare-call-view__avatar" :class="{ 'is-pulsing': pulsing }">
        <FlareAvatar :user-id="peerName" :display-name="peerName" :avatar-url="peerAvatarUrl" :size="104" />
      </div>
      <div class="flare-call-view__name">{{ peerName }}</div>
      <div class="flare-call-view__status">{{ statusText }}</div>
      <div v-if="encrypted" class="flare-call-view__secure">
        <n-icon :size="12" :component="LockClosedOutline" />
        <span>End-to-end encrypted</span>
      </div>
    </div>

    <div class="flare-call-view__controls">
      <FlareCallControls
        :muted="muted"
        :camera-on="cameraOn"
        :speaker-on="speakerOn"
        :mode="mode"
        @toggle-mute="emit('toggleMute')"
        @toggle-camera="emit('toggleCamera')"
        @toggle-speaker="emit('toggleSpeaker')"
        @switch-camera="emit('switchCamera')"
        @hangup="emit('hangup')"
      />
    </div>
  </div>
</template>

<style scoped>
.flare-call-view {
  position: relative;
  width: 100%;
  height: 100%;
  min-height: 460px;
  color: #fff;
  overflow: hidden;
  background:
    radial-gradient(120% 70% at 50% -6%, rgba(124, 58, 237, 0.34), transparent 60%),
    linear-gradient(168deg, #221d31 0%, #17131f 46%, #100c17 100%);
}
.flare-call-view__video {
  position: absolute;
  inset: 0;
}
.flare-call-view__minimize {
  position: absolute;
  top: 16px;
  left: 16px;
  z-index: 2;
  display: grid;
  place-items: center;
  width: 38px;
  height: 38px;
  border: 0;
  border-radius: 50%;
  color: #fff;
  background: rgba(255, 255, 255, 0.12);
  backdrop-filter: blur(6px);
  cursor: pointer;
  transition: background var(--flare-transition-fast, 150ms ease);
}
.flare-call-view__minimize:hover {
  background: rgba(255, 255, 255, 0.2);
}
.flare-call-view__peer {
  position: absolute;
  top: 84px;
  left: 0;
  right: 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12px;
}
.flare-call-view__avatar {
  position: relative;
  border-radius: 50%;
  box-shadow: 0 0 0 6px rgba(255, 255, 255, 0.08), 0 18px 44px rgba(0, 0, 0, 0.42);
}
/* Ringing / calling — a soft expanding halo around the avatar. */
.flare-call-view__avatar.is-pulsing::before,
.flare-call-view__avatar.is-pulsing::after {
  content: "";
  position: absolute;
  inset: -6px;
  border-radius: 50%;
  border: 2px solid rgba(167, 139, 250, 0.5);
  animation: flare-call-pulse 2s ease-out infinite;
}
.flare-call-view__avatar.is-pulsing::after {
  animation-delay: 1s;
}
@keyframes flare-call-pulse {
  0% { transform: scale(1); opacity: 0.7; }
  100% { transform: scale(1.5); opacity: 0; }
}
@media (prefers-reduced-motion: reduce) {
  .flare-call-view__avatar.is-pulsing::before,
  .flare-call-view__avatar.is-pulsing::after { animation: none; }
}
.flare-call-view__name {
  font-size: 24px;
  font-weight: 600;
  letter-spacing: 0.01em;
}
.flare-call-view__status {
  color: rgba(255, 255, 255, 0.72);
  font-size: 14px;
}
.flare-call-view__secure {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  padding: 3px 10px;
  border-radius: 999px;
  color: rgba(255, 255, 255, 0.66);
  background: rgba(255, 255, 255, 0.08);
  font-size: 11px;
}
.flare-call-view__controls {
  position: absolute;
  bottom: 44px;
  left: 0;
  right: 0;
  display: flex;
  justify-content: center;
}
</style>
