<script setup>
import FlareForwardPicker from "flare-core-vue-im-ui/components/conversation/FlareForwardPicker.vue";
import DemoStage from "./DemoStage.vue";
const targets = [
  { id: "ivy", name: "Ivy Chen", subtitle: "在线" },
  { id: "design", name: "Flare 设计评审", subtitle: "12 名成员" },
  { id: "leo", name: "Leo Wang", subtitle: "前端 · Web" },
  { id: "eng", name: "工程周会", subtitle: "群聊 · 34 名成员" },
  { id: "mia", name: "Mia Zhou", subtitle: "iOS 客户端" },
];
</script>
<template>
  <DemoStage>
    <div class="stage">
      <FlareForwardPicker :targets="targets" @confirm="() => {}" @close="() => {}" />
    </div>
  </DemoStage>
</template>
<style scoped>
.stage { display: flex; justify-content: center; padding: 24px; border-radius: 14px; background: var(--flare-color-bg-secondary); }
</style>
