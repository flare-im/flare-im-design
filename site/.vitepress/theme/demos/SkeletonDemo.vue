<script setup>
import FlareSkeleton from "flare-core-vue-im-ui/components/general/FlareSkeleton.vue";
import DemoStage from "./DemoStage.vue";
</script>
<template>
  <DemoStage>
    <div class="grid">
      <div class="cell">
        <div class="cap">会话列表</div>
        <FlareSkeleton variant="conversation" :rows="4" />
      </div>
      <div class="cell">
        <div class="cap">消息线程</div>
        <FlareSkeleton variant="message" :rows="4" />
      </div>
      <div class="cell">
        <div class="cap">资料页</div>
        <FlareSkeleton variant="profile" />
      </div>
    </div>
  </DemoStage>
</template>
<style scoped>
.grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 16px; padding: 20px; border-radius: 14px; background: var(--flare-color-bg-secondary); }
.cell { padding: 14px; border-radius: 12px; background: var(--flare-color-bg-primary); border: 1px solid var(--flare-color-border-primary); }
.cap { font-size: 12px; color: var(--flare-color-text-tertiary); margin-bottom: 12px; }
</style>
