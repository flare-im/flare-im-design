<script setup lang="ts">
withDefaults(
  defineProps<{
    muted?: boolean;
    cameraOn?: boolean;
    speakerOn?: boolean;
    mode?: "audio" | "video";
  }>(),
  { muted: false, cameraOn: true, speakerOn: false, mode: "video" },
);
const emit = defineEmits<{
  (e: "toggleMute"): void;
  (e: "toggleCamera"): void;
  (e: "toggleSpeaker"): void;
  (e: "switchCamera"): void;
  (e: "hangup"): void;
}>();
</script>

<template>
  <div class="flare-call-controls">
    <button class="flare-call-controls__btn" @click="emit('toggleMute')">
      <span class="ico" :class="{ on: muted }">{{ muted ? "🔇" : "🎙️" }}</span>
      <span class="lbl">麦克风</span>
    </button>
    <template v-if="mode === 'video'">
      <button class="flare-call-controls__btn" @click="emit('toggleCamera')">
        <span class="ico" :class="{ on: !cameraOn }">{{ cameraOn ? "🎥" : "🚫" }}</span>
        <span class="lbl">摄像头</span>
      </button>
      <button class="flare-call-controls__btn" @click="emit('switchCamera')">
        <span class="ico">🔄</span>
        <span class="lbl">翻转</span>
      </button>
    </template>
    <button v-else class="flare-call-controls__btn" @click="emit('toggleSpeaker')">
      <span class="ico" :class="{ on: speakerOn }">🔊</span>
      <span class="lbl">扬声器</span>
    </button>
    <button class="flare-call-controls__btn" @click="emit('hangup')">
      <span class="ico is-end">📞</span>
      <span class="lbl">挂断</span>
    </button>
  </div>
</template>

<style scoped>
.flare-call-controls { display: flex; gap: 18px; }
.flare-call-controls__btn {
  display: flex; flex-direction: column; align-items: center; gap: 6px;
  border: none; background: none; cursor: pointer;
}
.ico {
  width: 52px; height: 52px; border-radius: 50%;
  display: flex; align-items: center; justify-content: center; font-size: 22px;
  background: rgba(255, 255, 255, 0.16);
}
.ico.on { background: #fff; }
.ico.is-end { background: #ef4444; }
.lbl { font-size: 11px; color: rgba(255, 255, 255, 0.75); }
</style>
