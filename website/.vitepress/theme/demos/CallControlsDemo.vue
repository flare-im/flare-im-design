<script setup>
import { ref } from "vue";
import { FlareCallControls } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";

const speakerOn = ref(true);
const startVideoCount = ref(0);
</script>

<template>
  <DemoStage>
    <div class="stage">
      <!-- 语音通话：扬声器之后是「切换到视频」，宿主据此把通话升级为视频。 -->
      <FlareCallControls
        mode="audio"
        :speaker-on="speakerOn"
        can-start-video
        @toggle-speaker="speakerOn = !speakerOn"
        @start-video="startVideoCount++"
      />
      <p class="note">切换到视频 {{ startVideoCount }} 次</p>
      <FlareCallControls mode="video" :camera-on="true" />
    </div>
  </DemoStage>
</template>

<style scoped>
/* 通话控件是画在通话画面上的（白字白图标 + 半透明底），所以 demo 也放在
   FlareCallView 那块深色背景上——摆在浅色底上的话标签几乎看不见。 */
.stage {
  width: 100%;
  max-width: 360px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 20px;
  padding: 24px 16px;
  border-radius: 14px;
  background: linear-gradient(180deg, color-mix(in srgb, var(--flare-color-primary) 20%, #18181b), #101012 58%);
}
.note {
  margin: 0;
  font-size: 12px;
  color: rgba(255, 255, 255, 0.62);
}
</style>
