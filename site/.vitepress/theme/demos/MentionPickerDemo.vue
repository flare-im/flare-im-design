<script setup>
import FlareMentionPicker from "flare-core-vue-im-ui/components/composer/FlareMentionPicker.vue";
import DemoStage from "./DemoStage.vue";
const candidates = [
  { id: "ivy", name: "Ivy Chen", detail: "设计 · 组件组", presence: "online" },
  { id: "leo", name: "Leo Wang", detail: "前端 · Web" },
  { id: "ada", name: "Ada Li", detail: "产品经理" },
  { id: "mia", name: "Mia Zhou", detail: "iOS 客户端" },
  { id: "sam", name: "Sam Gao", detail: "Android 客户端" },
];
</script>
<template>
  <DemoStage>
    <div class="stage">
      <FlareMentionPicker :candidates="candidates" allow-everyone @select="() => {}" @close="() => {}" />
    </div>
  </DemoStage>
</template>
<style scoped>
.stage { display: flex; justify-content: center; padding: 24px; border-radius: 14px; background: var(--flare-color-bg-secondary); }
</style>
