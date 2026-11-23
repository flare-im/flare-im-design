<script setup>
import { ref } from "vue";
import { FlareResultView } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";
const tone = ref("success");
const outcomes = {
  success: { title: "转账成功", amount: "¥99.00", description: "已转入对方钱包" },
  info: { title: "处理中", description: "到账后这里会自动更新" },
  warning: { title: "结果待确认", description: "请先查看原单，勿重新付款" },
  danger: { title: "未成功", description: "余额不足" },
};
</script>
<template>
  <DemoStage>
    <div class="tones">
      <button v-for="(_, key) in outcomes" :key="key" type="button" :aria-pressed="tone === key" @click="tone = key">{{ key }}</button>
    </div>
    <FlareResultView
      :tone="tone"
      :title="outcomes[tone].title"
      :amount="outcomes[tone].amount"
      :description="outcomes[tone].description"
      :details="[{ label: '收款方', value: '周屿' }, { label: '时间', value: '2026-11-19 10:24' }]"
      secondary-label="查看原单"
      @done="() => {}"
      @secondary="() => {}"
    />
  </DemoStage>
</template>
<style scoped>
.tones { display: flex; gap: var(--flare-size-spacing-sm); margin-bottom: var(--flare-size-spacing-lg); }
</style>
