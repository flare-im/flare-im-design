<script setup>
import FlareMomentComposer from "flare-core-vue-im-ui/components/moments/FlareMomentComposer.vue";
import DemoStage from "./DemoStage.vue";
const sw = (a, b) => "data:image/svg+xml;utf8," + encodeURIComponent(
  `<svg xmlns='http://www.w3.org/2000/svg' width='80' height='80'><rect width='80' height='80' fill='${a}'/></svg>`.replace(/#/g, "%23"));
const images = [sw("#a78bfa"), sw("#fca5a5"), sw("#6ee7b7")];
</script>
<template>
  <DemoStage>
    <div class="stage">
      <FlareMomentComposer :images="images" location="上海 · 徐汇" visibility="公开" @submit="() => {}" @cancel="() => {}" @add-image="() => {}" />
    </div>
  </DemoStage>
</template>
<style scoped>
.stage { display: flex; justify-content: center; padding: 24px; border-radius: 14px; background: var(--flare-color-bg-secondary); }
</style>
