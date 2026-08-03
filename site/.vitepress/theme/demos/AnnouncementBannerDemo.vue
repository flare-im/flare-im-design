<script setup>
import FlareAnnouncementBanner from "@flare-im/vue-ui/components/messages/FlareAnnouncementBanner.vue";
import DemoStage from "./DemoStage.vue";
</script>
<template>
  <DemoStage>
    <div class="stack">
      <FlareAnnouncementBanner
        author="Ivy"
        text="本周五下午 3 点设计评审，请各端负责人带上组件对齐清单；四端奇偶为本次验收硬指标，未达标的组件请在评审前补齐并跑通编译。"
        dismissible
        @close="() => {}"
      />
      <FlareAnnouncementBanner text="欢迎加入 Flare 设计群 🎉" />
    </div>
  </DemoStage>
</template>
<style scoped>
.stack { display: flex; flex-direction: column; gap: 14px; padding: 20px; border-radius: 14px; background: var(--flare-color-bg-secondary); }
</style>
