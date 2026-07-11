<script setup>
import FlareMessageStatus from "flare-core-vue-im-ui/components/messages/MessageStatus.vue";
import DemoStage from "./DemoStage.vue";

// status codes: 1 sending · 2 sent · 3 delivered · 4 read · 5 failed · 6 recalled
const items = [
  { status: 1, label: "发送中" },
  { status: 2, label: "已发送" },
  { status: 4, label: "已读" },
  { status: 5, label: "失败" },
];
</script>

<template>
  <DemoStage>
    <div class="ms-row">
      <div v-for="it in items" :key="it.status" class="ms">
        <FlareMessageStatus :status="it.status" />
        <span class="ms-lbl">{{ it.label }}</span>
      </div>
    </div>
  </DemoStage>
</template>

<style scoped>
.ms-row { display: flex; gap: 22px; }
.ms { display: flex; flex-direction: column; align-items: center; gap: 6px; min-width: 48px; }
.ms-lbl { font-size: 12px; color: var(--flare-color-text-secondary); }
</style>
