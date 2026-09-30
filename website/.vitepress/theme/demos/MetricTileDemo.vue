<script setup>
import { FlareMetricTile } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";

// 控制台概览的一排指标:宿主给读数和与上期的差值,「涨了是好是坏」也由宿主说(polarity)。
// 消息量这一格还没采集到,传 null:显示横线、读屏读「暂无数据」,而不是一个假的 0。
</script>

<template>
  <DemoStage>
    <div class="metric-demo">
      <FlareMetricTile label="用户总数" :value="12480" caption="上限 20,000" :delta="3.2" delta-unit="%" polarity="higher-is-better" />
      <FlareMetricTile label="近 24 小时注册" :value="86" caption="较前 24 小时" :delta="-12" polarity="higher-is-better" />
      <FlareMetricTile label="冻结用户" :value="7" caption="较上周" :delta="2" polarity="lower-is-better" />
      <FlareMetricTile label="今日消息量" :value="null" caption="今日尚未采集" />
    </div>
  </DemoStage>
</template>

<style scoped>
/* 两列两行:auto-fit 在预览这种不定宽的容器里会按 max-width 算列数,把第四张挤出框外。 */
.metric-demo {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: var(--flare-size-spacing-md);
  width: 100%;
  max-width: 560px;
}
</style>
