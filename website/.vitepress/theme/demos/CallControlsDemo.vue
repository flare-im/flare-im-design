<script setup>
import { FlareCallControls } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";
</script>

<template>
  <DemoStage>
    <div class="stage">
      <FlareCallControls mode="video" :camera-on="true" :speaker-on="true" />
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
  justify-content: center;
  padding: 24px 16px;
  border-radius: 14px;
  background: linear-gradient(180deg, color-mix(in srgb, var(--flare-color-primary) 20%, #18181b), #101012 58%);
}
</style>
