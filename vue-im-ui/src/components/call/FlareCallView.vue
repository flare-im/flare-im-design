<script setup lang="ts">
import { computed } from "vue";
import FlareAvatar from "../conversation/FlareAvatar.vue";
import FlareCallControls from "./FlareCallControls.vue";

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
  }>(),
  { muted: false, cameraOn: true, speakerOn: false },
);
const emit = defineEmits<{
  (e: "hangup"): void;
  (e: "toggleMute"): void;
  (e: "toggleCamera"): void;
  (e: "toggleSpeaker"): void;
  (e: "switchCamera"): void;
}>();

const statusText = computed(() => {
  if (props.state === "connected") return props.durationLabel ?? "已接通";
  if (props.state === "ringing") return "对方正在响铃…";
  return props.mode === "video" ? "正在等待对方接受邀请…" : "正在呼叫…";
});
</script>

<template>
  <div class="flare-call-view">
    <div v-if="mode === 'video'" class="flare-call-view__video">
      <slot name="video" />
    </div>
    <div class="flare-call-view__peer">
      <FlareAvatar
        v-if="mode === 'audio' || !$slots.video"
        :user-id="peerName"
        :display-name="peerName"
        :avatar-url="peerAvatarUrl"
        :size="96"
      />
      <div class="flare-call-view__name">{{ peerName }}</div>
      <div class="flare-call-view__status">{{ statusText }}</div>
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
  position: relative; width: 100%; height: 100%; min-height: 420px;
  background: #111318; color: #fff; overflow: hidden;
}
.flare-call-view__video { position: absolute; inset: 0; }
.flare-call-view__peer {
  position: absolute; top: 72px; left: 0; right: 0;
  display: flex; flex-direction: column; align-items: center; gap: 10px;
}
.flare-call-view__name { font-size: 22px; font-weight: 600; }
.flare-call-view__status { color: rgba(255, 255, 255, 0.7); font-size: 14px; }
.flare-call-view__controls {
  position: absolute; bottom: 40px; left: 0; right: 0; display: flex; justify-content: center;
}
</style>
