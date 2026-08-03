<script setup>
import FlareResponsiveLayout from "@flare-im/vue-ui/components/layout/FlareResponsiveLayout.vue";
import DemoStage from "./DemoStage.vue";
</script>

<template>
  <DemoStage>
    <div class="stage">
      <FlareResponsiveLayout>
        <template #list><div class="pane list">会话列表</div></template>
        <template #chat><div class="pane chat">聊天窗口</div></template>
      </FlareResponsiveLayout>
    </div>
  </DemoStage>
</template>

<style scoped>
.stage { width: 100%; max-width: 560px; height: 300px; border-radius: 14px; overflow: hidden; border: 1px solid var(--flare-color-border-secondary); }
.pane { display: flex; align-items: center; justify-content: center; height: 100%; color: var(--flare-color-text-tertiary); }
.list { background: var(--flare-color-bg-secondary); }
</style>
