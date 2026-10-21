<script setup>
import { computed, ref } from "vue";
import { FlareRedPacketComposer, FlareRedPacketPayConfirm, FlareSegmentedControl, FlareStatusBanner } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";
// 群聊默认拼手气；单聊只给 normal，表单不显示种类和个数，金额标签为「金额」。
// 总额、上限和错误由宿主计算，组件只限制输入格式。原命令结果待核对时 locked：只读、按钮不可点、不转圈。
const conversation = ref(0);
const kinds = computed(() => (conversation.value === 1 ? ["normal"] : ["lucky", "normal", "exclusive"]));
const locked = computed(() => conversation.value === 2);
const kind = ref("lucky");
const amount = ref("");
const count = ref(0);
const greeting = ref("");
const paying = ref(false);
const total = computed(() => {
  const perShare = kind.value === "normal" && kinds.value.length > 1;
  const value = Number(amount.value || 0) * (perShare ? Math.max(count.value, 1) : 1);
  return `¥${value.toFixed(2)}`;
});
const error = computed(() => (Number(amount.value) > 200 ? "单个红包金额不可超过 200 元" : ""));
</script>
<template>
  <DemoStage>
    <FlareSegmentedControl v-model="conversation" class="switch" :options="['群聊', '单聊', '待核对']" />
    <div class="frame">
      <FlareStatusBanner v-if="locked" text="上一个红包的结果还在核对，完成前不能再发。" tone="warning" />
      <FlareRedPacketComposer
        v-model:kind="kind"
        v-model:amount="amount"
        v-model:count="count"
        v-model:greeting="greeting"
        :kinds="kinds"
        :locked="locked"
        :total="total"
        :error="error || undefined"
        @submit="paying = true"
      >
        <template #recipient>
          <span class="pick">选择成员</span>
        </template>
      </FlareRedPacketComposer>
    </div>
    <FlareRedPacketPayConfirm
      :open="paying"
      :amount="total"
      method-label="钱包（余额 ¥12.00）"
      @confirm="paying = false"
      @cancel="paying = false"
    />
  </DemoStage>
</template>
<style scoped>
.switch { margin-bottom: 12px; }
.frame { max-width: 390px; border-radius: 14px; background: var(--flare-color-bg-secondary); }
.pick { color: var(--flare-color-text-tertiary); font-size: var(--flare-size-font-size-xl); }
</style>
