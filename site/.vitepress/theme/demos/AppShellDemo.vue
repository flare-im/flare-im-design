<script setup>
import FlareAppShell from "@flare-im/vue-ui/components/layout/FlareAppShell.vue";
import DemoStage from "./DemoStage.vue";

const items = [
  { key: "chat", label: "消息", badge: 3 },
  { key: "contacts", label: "通讯录" },
  { key: "me", label: "我" },
];
</script>

<template>
  <DemoStage>
    <div class="stage">
      <FlareAppShell :items="items" active-key="chat">
        <div class="pane">主内容区</div>
      </FlareAppShell>
    </div>
  </DemoStage>
</template>

<style scoped>
.stage { width: 100%; max-width: 520px; height: 320px; border-radius: 14px; overflow: hidden; border: 1px solid var(--flare-color-border-secondary); }
.pane { display: flex; align-items: center; justify-content: center; height: 100%; color: var(--flare-color-text-tertiary); }
</style>
