<script setup>
import { computed } from "vue";
import { useRoute } from "vitepress";
import { FlareProgressBar } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";

const route = useRoute();
const en = computed(() => route.path.startsWith("/en"));
const rows = computed(() => [
  { label: en.value ? "Downloading" : "下载中", value: 0.42, tone: "primary" },
  { label: en.value ? "Done" : "已完成", value: 1, tone: "success" },
  { label: en.value ? "Almost full" : "接近上限", value: 0.86, tone: "warning" },
  { label: en.value ? "Stopped" : "已中断", value: 0.3, tone: "danger" },
  { label: en.value ? "Paused" : "已暂停", value: 0.6, tone: "neutral" },
]);
</script>

<template>
  <DemoStage>
    <div class="stage">
      <div v-for="row in rows" :key="row.tone" class="row">
        <span>{{ row.label }}</span>
        <FlareProgressBar :value="row.value" :tone="row.tone" :label="row.label" />
      </div>
      <div class="row">
        <span>{{ en ? "Length not known" : "长度未知" }}</span>
        <FlareProgressBar indeterminate :label="en ? 'Verifying' : '正在校验'" />
      </div>
    </div>
  </DemoStage>
</template>

<style scoped>
.stage { display: flex; flex-direction: column; gap: 14px; width: 100%; max-width: 420px; padding: 20px; border-radius: 14px; background: var(--flare-color-bg-primary); }
.row { display: flex; flex-direction: column; gap: 6px; color: var(--flare-color-text-secondary); font-size: var(--flare-text-caption-font-size); }
</style>
