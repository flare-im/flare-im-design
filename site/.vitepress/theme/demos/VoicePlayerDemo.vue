<script setup>
import { reactive } from "vue";
import FlareVoicePlayer from "flare-core-vue-im-ui/components/messages/FlareVoicePlayer.vue";
import DemoStage from "./DemoStage.vue";
const amps = Array.from({ length: 32 }, (_, i) => 0.3 + 0.6 * Math.abs(Math.sin(i * 0.55 + 0.6)));
const speeds = [1, 1.5, 2];
const a = reactive({ playing: false, progress: 0.42, speed: 1, trOpen: false });
function toggle() { a.playing = !a.playing; }
function seek(r) { a.progress = r; }
function cycle() { a.speed = speeds[(speeds.indexOf(a.speed) + 1) % speeds.length]; }
</script>
<template>
  <DemoStage>
    <div class="stack">
      <FlareVoicePlayer
        duration-label="0:24" elapsed-label="0:10"
        :amplitudes="amps" :progress="a.progress" :playing="a.playing" :speed="a.speed"
        transcript="周五的四端奇偶评审记得带上组件清单，重点看语音播放器这块。"
        :transcript-open="a.trOpen"
        @toggle="toggle" @seek="seek" @cycle-speed="cycle" @toggle-transcript="a.trOpen = !a.trOpen"
      />
      <FlareVoicePlayer duration-label="0:08" :amplitudes="amps" unplayed outbound @toggle="() => {}" />
    </div>
  </DemoStage>
</template>
<style scoped>
.stack { display: flex; flex-direction: column; gap: 16px; align-items: flex-start; padding: 24px; border-radius: 14px; background: var(--flare-color-bg-secondary); }
</style>
