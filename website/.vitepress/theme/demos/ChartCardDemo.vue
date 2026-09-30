<script setup>
import { computed, ref } from "vue";
import { FlareChartCard, FlareSegmentedControl } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";

// 宿主把日期格式化成标签、按时间顺序给出读数;9/24 那天采集失败,传 null —— 柱状图留空、折线断开,不画成 0。
// 右上角的切换放在 extra 插槽里,采集时间放在 footer 插槽里。
const daily = [42, 38, 51, 47, 60, 58, 73, null, 66, 81, 77, 92, 88, 104];
const points = daily.map((value, index) => ({ label: `9/${17 + index}`, value }));
const kinds = ["柱状图", "折线图"];
const kindIndex = ref(0);
const kind = computed(() => (kindIndex.value === 0 ? "bar" : "line"));
</script>

<template>
  <DemoStage>
    <div class="chart-demo">
      <FlareChartCard title="每日新增用户" description="近 14 天" :points="points" :kind="kind" unit="人">
        <template #extra>
          <FlareSegmentedControl v-model="kindIndex" :options="kinds" />
        </template>
        <template #footer>采集时间 2026-09-30 08:00</template>
      </FlareChartCard>
      <FlareChartCard title="群组总数" description="近 14 天" :points="[]" tone="warning" empty-text="还没有用量数据" />
    </div>
  </DemoStage>
</template>

<style scoped>
.chart-demo {
  display: grid;
  gap: var(--flare-size-spacing-md);
  width: 100%;
  max-width: 560px;
}
</style>
