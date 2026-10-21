<script setup>
import { FlareRedPacketDetail } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";
// 详情是普通页面的正文；宿主把它放进 FlareScreen。金额、时间、名字都由宿主格式化。
// 监听 back 时组件自己画红色标题栏，宿主隐藏自己的导航栏。
const claims = [
  { id: "u1", name: "阿花", time: "10:02", amount: "0.62 元", best: false },
  { id: "u2", name: "大壮", time: "10:03", amount: "0.88 元", best: true },
  { id: "u3", name: "小红", time: "10:05", amount: "0.60 元", best: false },
];
</script>
<template>
  <DemoStage>
    <div class="frame">
      <FlareRedPacketDetail
        sender-name="小明"
        blessing="恭喜发财，大吉大利"
        kind-label="拼"
        amount="0.88 元"
        amount-note="已存入钱包"
        summary="已领取 3/3 个，共 2.10/2.10 元"
        :claims="claims"
        note="未领取的金额将在 24 小时后退回"
        @back="() => {}"
      />
    </div>
  </DemoStage>
</template>
<style scoped>
.frame { max-width: 390px; border: 1px solid var(--flare-color-border-primary); border-radius: 14px; overflow: hidden; }
</style>
