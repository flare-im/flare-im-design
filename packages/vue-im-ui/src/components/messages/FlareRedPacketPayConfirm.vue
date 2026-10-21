<script setup lang="ts">
// 支付确认 —— 「塞钱进红包」之后的底部面板:大字金额、支付方式行、确认 / 取消。
// 面板本身就是 FlareBottomSheet(手机形态是底部面板,其余形态交给 FlareModal),这里只画内容。
// 余额是否足够由宿主判定:`insufficient` 时确认不可用并说明原因;`busy` 时任何关闭方式都失效。
import { computed } from "vue";
import FlareBottomSheet from "../general/FlareBottomSheet.vue";
import FlareButton from "../general/FlareButton.vue";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";

const props = withDefaults(
  defineProps<{
    /** Whether the panel is shown. */
    open: boolean;
    /** The amount to pay, formatted by the host ("¥5.00"). */
    amount: string;
    /** The paying account, e.g. "钱包（余额 ¥12.00）". */
    methodLabel: string;
    insufficient?: boolean;
    busy?: boolean;
  }>(),
  { insufficient: false, busy: false },
);
const emit = defineEmits<{ (e: "confirm"): void; (e: "cancel"): void }>();

const { t } = useFlareI18nOptional();
const canConfirm = computed(() => !props.insufficient && !props.busy);

function requestConfirm(): void {
  if (canConfirm.value) emit("confirm");
}
function requestCancel(): void {
  if (!props.busy) emit("cancel");
}
</script>

<template>
  <FlareBottomSheet :open="open" :title="t('redPacket.pay.title')" :dismissible="!busy" @close="requestCancel">
    <div class="flare-rp-pay" :aria-busy="busy || undefined">
      <p class="flare-rp-pay__amount">{{ amount }}</p>
      <div class="flare-rp-pay__method">
        <span class="flare-rp-pay__method-label">{{ t("redPacket.pay.method") }}</span>
        <span class="flare-rp-pay__method-value">{{ methodLabel }}</span>
      </div>
      <p v-if="insufficient" class="flare-rp-pay__insufficient" role="alert">{{ t("redPacket.pay.insufficient") }}</p>
      <div class="flare-rp-pay__actions">
        <div class="flare-rp-pay__confirm">
          <FlareButton
            block
            size="lg"
            :label="t('redPacket.pay.confirm')"
            :loading="busy"
            :disabled="insufficient"
            @click="requestConfirm"
          />
        </div>
        <FlareButton block size="lg" variant="quiet" :label="t('common.cancel')" :disabled="busy" @click="requestCancel" />
      </div>
    </div>
  </FlareBottomSheet>
</template>

<style scoped>
.flare-rp-pay {
  display: flex;
  flex-direction: column;
  gap: var(--flare-size-spacing-lg);
  padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-lg) var(--flare-size-spacing-lg);
  color: var(--flare-color-text-primary);
}
.flare-rp-pay__amount {
  margin: 0;
  text-align: center;
  font-size: var(--flare-size-component-red-packet-amount-font-size);
  line-height: var(--flare-size-line-height-tight);
  font-weight: var(--flare-size-font-weight-semibold);
  font-variant-numeric: tabular-nums;
  overflow-wrap: anywhere;
}
.flare-rp-pay__method {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--flare-size-spacing-md);
  min-height: var(--flare-size-layout-touch-target);
  padding: 0 var(--flare-size-spacing-xs);
  border-top: 1px solid var(--flare-color-border-secondary);
  border-bottom: 1px solid var(--flare-color-border-secondary);
  font-size: var(--flare-size-font-size-lg);
}
.flare-rp-pay__method-label { flex: 0 0 auto; color: var(--flare-color-text-secondary); }
.flare-rp-pay__method-value { min-width: 0; text-align: end; overflow-wrap: anywhere; }
.flare-rp-pay__insufficient {
  margin: calc(var(--flare-size-spacing-sm) * -1) 0 0;
  text-align: end;
  font-size: var(--flare-size-font-size-md);
  color: var(--flare-color-error-text);
}
.flare-rp-pay__actions { display: flex; flex-direction: column; gap: var(--flare-size-spacing-sm); }
/* The kit button, re-tinted for money (same red as the composer's submit). */
.flare-rp-pay__confirm {
  --flare-color-primary: var(--flare-color-red-packet-end);
  --flare-color-primary-hover: color-mix(in srgb, var(--flare-color-red-packet-end) 88%, #000);
  --flare-color-primary-active: color-mix(in srgb, var(--flare-color-red-packet-end) 78%, #000);
}
</style>
