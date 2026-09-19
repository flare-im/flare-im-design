<script setup>
import { computed } from "vue";
import { FlareMessageStatus } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";

const props = defineProps({ previewState: { type: String, default: "all" } });

const items = [
  { status: "pending", label: "等待" },
  { status: "sending", label: "发送中" },
  { status: "sent", label: "已发送" },
  { status: "delivered", label: "已送达" },
  { status: "read", label: "已读" },
  { status: "failed", label: "失败" },
  { status: "retrying", label: "重试中" },
];
const visibleItems = computed(() => props.previewState === "all"
  ? items
  : items.filter((item) => item.status === props.previewState));
</script>

<template>
  <DemoStage>
    <div class="ms-row">
      <div v-for="it in visibleItems" :key="it.status" class="ms" :data-status="it.status">
        <FlareMessageStatus :status="it.status" />
        <span class="ms-lbl">{{ it.label }}</span>
      </div>
    </div>
  </DemoStage>
</template>

<style scoped>
.ms-row { display: flex; flex-wrap: wrap; gap: 22px; }
.ms { display: flex; flex-direction: column; align-items: center; gap: 6px; min-width: 48px; }
.ms-lbl { font-size: 12px; color: var(--flare-color-text-secondary); }
</style>
