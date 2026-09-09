<script setup>
import { computed, ref } from 'vue';
import FlareSearchDateRangeFilter from '@flare-im/vue-ui/components/general/FlareSearchDateRangeFilter.vue';
import { dayEndMs, dayStartMs, datesFromRange } from '@flare-im/vue-ui/shared/contracts/search-date-range';
import DemoStage from './DemoStage.vue';

// The host owns the clock. Presets are built here, in the viewer's own zone, and
// handed to the component as plain epoch bounds — the component never asks what
// "today" is.
const pad = (n) => String(n).padStart(2, '0');
const dateOf = (offsetDays) => {
  const d = new Date();
  d.setDate(d.getDate() + offsetDays);
  return `${d.getFullYear()}-${pad(d.getMonth() + 1)}-${pad(d.getDate())}`;
};
const today = dateOf(0);
const options = [
  { id: 'today', label: '今天', fromTime: dayStartMs(today), toTime: dayEndMs(today) },
  { id: 'week', label: '近 7 天', fromTime: dayStartMs(dateOf(-6)), toTime: dayEndMs(today) },
  { id: 'month', label: '近 30 天', fromTime: dayStartMs(dateOf(-29)), toTime: dayEndMs(today) },
];

const value = ref({});
const disabled = ref(false);
const allowCustom = ref(true);
const customActive = ref(false);
const last = ref('尚未筛选');

const payload = computed(() => {
  const dates = datesFromRange(value.value);
  const bounds = [
    value.value.fromTime === undefined ? 'fromTime 未设置' : `fromTime ${value.value.fromTime}（${dates.from} 00:00:00.000）`,
    value.value.toTime === undefined ? 'toTime 未设置' : `toTime ${value.value.toTime}（${dates.to} 23:59:59.999）`,
  ];
  return bounds.join(' · ');
});

function onChange(range) {
  value.value = range;
  last.value = 'change · 宿主把它并进 FlareSearchCriteria 后重新发起检索';
}
function onClear() {
  value.value = {};
  last.value = 'clear · 宿主清空时间条件并重新发起检索';
}
</script>

<template>
  <DemoStage>
    <div class="sdr-demo">
      <FlareSearchDateRangeFilter
        :value="value"
        :options="options"
        :allow-custom="allowCustom"
        :custom-active="customActive"
        min-date="2020-01-01"
        max-date="2030-12-31"
        :disabled="disabled"
        @change="onChange"
        @clear="onClear"
      />
      <div class="controls">
        <button type="button" @click="disabled = !disabled">{{ disabled ? '解除禁用' : '模拟禁用' }}</button>
        <button type="button" @click="allowCustom = !allowCustom">{{ allowCustom ? '关闭自定义' : '开放自定义' }}</button>
        <button type="button" @click="customActive = !customActive">{{ customActive ? '取消强制展开' : '强制展开自定义' }}</button>
        <button type="button" @click="value = { fromTime: dayStartMs('2026-03-20'), toTime: dayEndMs('2026-03-25') }">载入一段自定义区间</button>
      </div>
      <p role="status">{{ last }}。</p>
      <p class="payload">{{ payload }}</p>
      <p class="note">预设由本页计算，组件只比较数值；本地模拟，不发起任何检索请求。</p>
    </div>
  </DemoStage>
</template>

<style scoped>
.sdr-demo { width: 100%; max-width: 520px; min-width: 0; display: grid; gap: 16px; }
.controls { display: flex; flex-wrap: wrap; gap: 8px; }
.controls button {
  min-height: 48px; padding: 8px 12px; border: 1px solid var(--flare-color-border-primary);
  border-radius: 8px; background: var(--flare-color-bg-primary); color: var(--flare-color-text-primary);
}
p { margin: 0; font-size: 13px; overflow-wrap: anywhere; }
.payload { font-family: var(--vp-font-family-mono, monospace); color: var(--flare-color-text-secondary); }
.note { color: var(--flare-color-text-secondary); }
</style>
