<script setup>
import FlareDatePill from "@flare-im/vue-ui/components/messages/FlareDatePill.vue";
import DemoStage from "./DemoStage.vue";
</script>
<template>
  <DemoStage>
    <div class="thread">
      <FlareDatePill label="今天" />
      <div class="row"><span class="bubble">在忙吗？周五的评审要不要提前对一版？</span></div>
      <div class="row me"><span class="bubble me">好啊，我下午整理下清单发你</span></div>
      <FlareDatePill label="昨天" />
      <div class="row"><span class="bubble">四端拉平的进度更新了</span></div>
    </div>
  </DemoStage>
</template>
<style scoped>
.thread { display: flex; flex-direction: column; gap: 10px; padding: 20px; border-radius: 14px; background: var(--flare-color-bg-secondary); }
.row { display: flex; }
.row.me { justify-content: flex-end; }
.bubble { display: inline-block; padding: 8px 12px; border-radius: 12px; font-size: 13px; background: var(--flare-color-bg-primary); color: var(--flare-color-text-primary); border: 1px solid var(--flare-color-border-primary); max-width: 70%; }
.bubble.me { background: var(--flare-color-primary); color: #fff; border-color: transparent; }
</style>
