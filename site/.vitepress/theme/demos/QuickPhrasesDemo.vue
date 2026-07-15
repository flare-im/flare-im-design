<script setup>
import FlareQuickPhrases from "flare-core-vue-im-ui/components/composer/FlareQuickPhrases.vue";
import DemoStage from "./DemoStage.vue";
const groups = [
  {
    key: "common",
    title: "常用",
    phrases: [
      { id: "1", text: "好的，收到，这就安排。" },
      { id: "2", text: "稍等，我确认一下再回复你。" },
      { id: "3", text: "方便的话，我们约个时间同步一下？" },
    ],
  },
  {
    key: "after-sale",
    title: "售后",
    phrases: [
      { id: "4", text: "已为您登记，48 小时内处理完成。" },
      { id: "5", text: "麻烦提供一下订单号，我帮您查询。" },
    ],
  },
];
</script>
<template>
  <DemoStage>
    <div class="stage">
      <FlareQuickPhrases :groups="groups" manageable @select="() => {}" @manage="() => {}" />
    </div>
  </DemoStage>
</template>
<style scoped>
.stage { display: flex; justify-content: center; padding: 24px; border-radius: 14px; background: var(--flare-color-bg-secondary); }
</style>
