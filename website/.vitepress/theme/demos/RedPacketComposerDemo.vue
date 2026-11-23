<script setup>
import { computed, ref } from "vue";
import { FlarePaymentConfirmation, FlareRedPacketComposer, FlareSegmentedControl, FlareSelect, FlareStatusBanner } from "@flare-im/vue-ui/components";
import { flareRedPacketAmountMinor, flareRedPacketMoney } from "@flare-im/vue-ui";
import DemoStage from "./DemoStage.vue";
// 群聊默认拼手气；单聊只给 normal，表单不显示种类和个数，金额标签为「金额」。
// 总额、上限和错误由宿主计算，组件只限制输入格式。原命令结果待核对时 locked：只读、按钮不可点、不转圈。
const conversation = ref(0);
// 币种的小数位来自插件 limits（currencyExponent）：人民币 2 位、日元 0 位、科威特第纳尔 3 位。
const CURRENCIES = [{ code: "CNY", exponent: 2 }, { code: "JPY", exponent: 0 }, { code: "KWD", exponent: 3 }];
const currencyIndex = ref(0);
const currency = computed(() => CURRENCIES[currencyIndex.value]);
const kinds = computed(() => (conversation.value === 1 ? ["normal"] : ["lucky", "normal", "exclusive"]));
const locked = computed(() => conversation.value === 2);
const kind = ref("lucky");
const amount = ref("");
const count = ref(0);
const greeting = ref("");
const paying = ref(false);
const recipient = ref("");
const recipients = [{ value: "ivy", label: "林夏" }, { value: "su", label: "苏晚晴" }, { value: "zhou", label: "周屿" }];
// 宿主用整数最小单位算总额，不经浮点。
const total = computed(() => {
  const perShare = kind.value === "normal" && kinds.value.length > 1;
  const minor = BigInt(flareRedPacketAmountMinor(amount.value, currency.value.exponent) ?? "0");
  const shares = BigInt(perShare ? Math.max(count.value, 1) : 1);
  return flareRedPacketMoney(String(minor * shares), currency.value.exponent, currency.value.code) ?? "";
});
const error = computed(() => (Number(amount.value) > 200 ? "单个红包金额不可超过 200 元" : ""));
</script>
<template>
  <DemoStage>
    <div class="controls">
      <FlareSegmentedControl v-model="conversation" class="switch" aria-label="会话场景" :options="['群聊', '单聊', '待核对']" />
      <FlareSegmentedControl v-model="currencyIndex" class="switch" aria-label="币种" :options="CURRENCIES.map((c) => c.code)" />
    </div>
    <div class="frame">
      <FlareStatusBanner v-if="locked" text="上一个红包的结果还在核对，完成前不能再发。" tone="warning" />
      <FlareRedPacketComposer
        v-model:kind="kind"
        v-model:amount="amount"
        v-model:count="count"
        v-model:greeting="greeting"
        :kinds="kinds"
        :currency-exponent="currency.exponent"
        :locked="locked"
        :total="total"
        :error="error || undefined"
        @submit="paying = true"
      >
        <template #recipient>
          <FlareSelect v-model="recipient" :options="recipients" title="指定领取人" placeholder="选择成员" size="sm" />
        </template>
      </FlareRedPacketComposer>
    </div>
    <FlarePaymentConfirmation
      :open="paying"
      :order="{ orderId: 'rp-demo', amount: total.replace(/[^0-9.]/g, '') || '0', currency: 'CNY', payee: '钱包', title: '红包', expiresAtMs: Date.now() + 600000 }"
      plugin-name="红包"
      @confirm="paying = false"
      @cancel="paying = false"
    />
  </DemoStage>
</template>
<style scoped>
.controls { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: var(--flare-size-spacing-sm); margin: 0 auto var(--flare-size-spacing-md); max-width: calc(var(--flare-size-layout-touch-target-min) * 12); }
.switch { width: 100%; box-sizing: border-box; }
.frame { width: 100%; max-width: calc(var(--flare-size-layout-touch-target-min) * 12); margin-inline: auto; border-radius: var(--flare-size-radius-card); background: var(--flare-color-bg-secondary); }
@media (max-width: 400px) { .controls { grid-template-columns: minmax(0, 1fr); } }

</style>
