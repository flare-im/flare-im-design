<script setup>
import DemoIcon from "./DemoIcon.vue";
const items = [
  { k: "pending", label: "发送中", color: "var(--flare-color-text-tertiary)" },
  { k: "sent", label: "已发送", color: "var(--flare-color-text-tertiary)" },
  { k: "read", label: "已读", color: "var(--flare-color-primary)" },
  { k: "failed", label: "失败", color: "var(--flare-color-error)" },
];
</script>

<template>
  <div v-for="it in items" :key="it.k" class="ms">
    <span class="ms-ico" :style="{ color: it.color }">
      <span v-if="it.k === 'pending'" class="spin" />
      <DemoIcon v-else-if="it.k === 'sent'" name="check" :size="16" />
      <DemoIcon v-else-if="it.k === 'read'" name="checkDouble" :size="16" />
      <DemoIcon v-else name="error" :size="16" />
    </span>
    <span class="ms-lbl">{{ it.label }}</span>
  </div>
</template>

<style scoped>
.ms { display: flex; flex-direction: column; align-items: center; gap: 6px; min-width: 56px; }
.ms-ico { height: 18px; display: flex; align-items: center; }
.ms-lbl { font-size: 12px; color: var(--flare-color-text-secondary); }
.spin {
  width: 12px; height: 12px; border-radius: 50%;
  border: 1.5px solid var(--flare-color-border-primary);
  border-top-color: var(--flare-color-text-tertiary);
  animation: sp 0.8s linear infinite;
}
@keyframes sp { to { transform: rotate(360deg); } }
</style>
