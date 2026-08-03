<script setup>
import { ref } from "vue";
import FlareGroupCallView from "@flare-im/vue-ui/components/call/FlareGroupCallView.vue";
import DemoStage from "./DemoStage.vue";

const participants = ref([
  { id: "ivy", name: "Ivy Chen", speaking: true },
  { id: "leo", name: "Leo Wang", muted: true },
  { id: "mia", name: "Mia Zhao", cameraOff: true },
  { id: "sam", name: "Sam Li" },
  { id: "me", name: "我", isSelf: true },
]);
const muted = ref(false);
const cameraOn = ref(true);
</script>

<template>
  <DemoStage>
    <div class="stage">
      <FlareGroupCallView
        title="设计评审组"
        mode="video"
        state="connected"
        duration-label="12:07"
        :participants="participants"
        :muted="muted"
        :camera-on="cameraOn"
        @toggle-mute="muted = !muted"
        @toggle-camera="cameraOn = !cameraOn"
      />
    </div>
  </DemoStage>
</template>

<style scoped>
.stage {
  width: 100%;
  max-width: 420px;
  height: 560px;
  border-radius: 18px;
  overflow: hidden;
}
</style>
