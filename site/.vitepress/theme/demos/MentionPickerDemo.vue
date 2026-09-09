<script setup>
import { ref } from "vue";
const selected = ref("");
const closed = ref(false);
import FlareMentionPicker from "@flare-im/vue-ui/components/composer/FlareMentionPicker.vue";
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
      <FlareMentionPicker :candidates="candidates" allow-everyone @select="candidate => selected = candidate.id" @close="closed = true" />
    </div>
    <p role="status">{{ closed ? "选择器已关闭" : selected ? `已选择：${selected}` : "使用方向键选择成员，Enter 确认，Esc 关闭" }}</p>
  </DemoStage>
</template>
<style scoped>
.stage { display: flex; justify-content: center; padding: 24px; border-radius: 14px; background: var(--flare-color-bg-secondary); }
</style>
