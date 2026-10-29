<script setup>
import { ref } from "vue";
import { FlareGroupCallView } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";

const participants = ref([
  { id: "ivy", name: "Ivy Chen", speaking: true },
  { id: "leo", name: "Leo Wang", muted: true },
  { id: "mia", name: "Mia Zhao", cameraOff: true },
  { id: "sam", name: "Sam Li" },
  { id: "me", name: "我", isSelf: true },
]);
const mode = ref("video");
const muted = ref(false);
const cameraOn = ref(true);
// 示意画面：只有这几位有画面，其余开着摄像头的格子仍显示头像。
const streams = new Set(["ivy", "leo", "me"]);
</script>

<template>
  <DemoStage>
    <label class="mode">模式 <select v-model="mode" aria-label="模式"><option value="video">video</option><option value="audio">audio</option></select></label>
    <div class="stage">
      <FlareGroupCallView
        title="设计评审组"
        :mode="mode"
        state="connected"
        duration-label="12:07"
        :participants="participants"
        :muted="muted"
        :camera-on="cameraOn"
        can-start-video
        @toggle-mute="muted = !muted"
        @toggle-camera="cameraOn = !cameraOn"
        @start-video="mode = 'video'"
      >
        <template #tile="{ participant }">
          <div v-if="streams.has(participant.id)" class="stream" role="img" :aria-label="`${participant.name} 的画面`" />
        </template>
      </FlareGroupCallView>
    </div>
  </DemoStage>
</template>

<style scoped>
.mode { display: inline-flex; align-items: center; gap: 6px; min-height: 48px; }
select { min-height: 48px; }
.stage {
  width: 100%;
  max-width: 420px;
  height: 560px;
  border-radius: 18px;
  overflow: hidden;
}
.stream {
  width: 100%;
  height: 100%;
  background: linear-gradient(160deg, #3a4a63, #1c2230);
}
</style>
