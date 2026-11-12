<script setup lang="ts">
// 付款确认 —— 引擎的 confirmPayment 请求由宿主收到后画的确认面板（设计 7.3）。
// 金额、收款方、说明、订单号只取订单字段，插件改不了布局；倒计时按服务端时钟走，过期后不能确认。
// 身份验证（支付密码、生物识别）沿用宿主已有的 reauthenticate 流程：确认键只发 `confirm`，
// 宿主验证后把凭证交回引擎；需要在面板里输密码的宿主把输入框放进 `credential` 插槽。
import { computed, onBeforeUnmount, ref, watch } from "vue";
import FlareBottomSheet from "../general/FlareBottomSheet.vue";
import FlareButton from "../general/FlareButton.vue";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";
import { flareServerNowMs } from "../../shared/server-clock";
import {
  flarePaymentAmountText,
  flarePaymentCountdown,
  type FlarePaymentOrder,
} from "../../shared/contracts/capability-ui";

const props = withDefaults(
  defineProps<{
    /** Whether the panel is shown. */
    open: boolean;
    /** The engine's `confirmPayment.order`. */
    order: FlarePaymentOrder;
    /** The plugin's display name: "Requested by …". */
    pluginName?: string;
    /** The host is verifying the viewer (its reauthenticate flow): every key and way out is locked. */
    busy?: boolean;
    /** The host's last failure (a wrong password); the panel stays open. */
    error?: string;
    /** The host's own gate on confirm, e.g. a password not yet complete in the credential slot. */
    confirmDisabled?: boolean;
  }>(),
  { busy: false, confirmDisabled: false },
);
const emit = defineEmits<{
  (e: "confirm"): void;
  (e: "cancel"): void;
  /** The order ran out while the panel was open (once). */
  (e: "expire"): void;
}>();

const { t } = useFlareI18nOptional();
const now = ref(flareServerNowMs());
let timer: ReturnType<typeof setInterval> | undefined;
function stop(): void {
  if (timer !== undefined) clearInterval(timer);
  timer = undefined;
}
watch(
  () => props.open,
  (open) => {
    stop();
    if (!open) return;
    now.value = flareServerNowMs();
    timer = setInterval(() => {
      now.value = flareServerNowMs();
    }, 1000);
  },
  { immediate: true },
);
onBeforeUnmount(stop);

const amountText = computed(() => flarePaymentAmountText(props.order.amount, props.order.currency));
const countdown = computed(() => flarePaymentCountdown(props.order.expiresAtMs - now.value));
watch(
  () => countdown.value.expired,
  (expired) => {
    if (expired && props.open) emit("expire");
  },
);
const canConfirm = computed(
  () => !props.busy && !props.confirmDisabled && !countdown.value.expired && amountText.value !== null,
);

function requestConfirm(): void {
  if (canConfirm.value) emit("confirm");
}
function requestCancel(): void {
  if (!props.busy) emit("cancel");
}
</script>

<template>
  <FlareBottomSheet :open="open" :title="t('paymentConfirmation.title')" :dismissible="!busy" @close="requestCancel">
    <div class="flare-pay-confirm" :aria-busy="busy || undefined" data-payment-confirmation="true">
      <p class="flare-pay-confirm__amount" data-payment-amount="true">{{ amountText ?? "—" }}</p>
      <dl class="flare-pay-confirm__rows">
        <div class="flare-pay-confirm__row">
          <dt>{{ t("paymentConfirmation.payee") }}</dt>
          <dd data-payment-payee="true">{{ order.payee }}</dd>
        </div>
        <div v-if="order.title" class="flare-pay-confirm__row">
          <dt>{{ t("paymentConfirmation.item") }}</dt>
          <dd>{{ order.title }}</dd>
        </div>
        <div class="flare-pay-confirm__row">
          <dt>{{ t("paymentConfirmation.order") }}</dt>
          <dd class="flare-pay-confirm__order">{{ order.orderId }}</dd>
        </div>
      </dl>
      <p v-if="amountText === null" class="flare-pay-confirm__alert" role="alert">{{ t("paymentConfirmation.invalid") }}</p>
      <p v-else-if="countdown.expired" class="flare-pay-confirm__alert" role="alert" data-payment-expired="true">
        {{ t("paymentConfirmation.expired") }}
      </p>
      <p v-else class="flare-pay-confirm__meta" data-payment-countdown="true">
        {{ t("paymentConfirmation.expiresIn", { time: countdown.text }) }}
      </p>
      <p v-if="pluginName" class="flare-pay-confirm__meta">{{ t("paymentConfirmation.requestedBy", { plugin: pluginName }) }}</p>
      <slot name="credential" />
      <p v-if="error" class="flare-pay-confirm__alert" role="alert">{{ error }}</p>
      <div class="flare-pay-confirm__actions">
        <FlareButton
          block
          size="lg"
          :label="busy ? t('paymentConfirmation.verifying') : t('paymentConfirmation.confirm')"
          :loading="busy"
          :disabled="!canConfirm && !busy"
          data-payment-confirm="true"
          @click="requestConfirm"
        />
        <FlareButton block size="lg" variant="quiet" :label="t('common.cancel')" :disabled="busy" @click="requestCancel" />
      </div>
    </div>
  </FlareBottomSheet>
</template>

<style scoped>
.flare-pay-confirm {
  display: flex;
  flex-direction: column;
  gap: var(--flare-size-spacing-md);
  padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-lg) var(--flare-size-spacing-lg);
  color: var(--flare-color-text-primary);
}
.flare-pay-confirm__amount {
  margin: 0;
  text-align: center;
  font-size: var(--flare-size-component-red-packet-amount-font-size);
  line-height: var(--flare-size-line-height-tight);
  font-weight: var(--flare-size-font-weight-semibold);
  font-variant-numeric: tabular-nums;
  overflow-wrap: anywhere;
}
.flare-pay-confirm__rows {
  margin: 0;
  border-top: 1px solid var(--flare-color-border-secondary);
  border-bottom: 1px solid var(--flare-color-border-secondary);
}
.flare-pay-confirm__row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--flare-size-spacing-md);
  min-height: var(--flare-size-layout-touch-target);
  padding: 0 var(--flare-size-spacing-xs);
  font-size: var(--flare-size-font-size-md);
}
.flare-pay-confirm__row dt { flex: 0 0 auto; color: var(--flare-color-text-secondary); }
.flare-pay-confirm__row dd { margin: 0; min-width: 0; text-align: end; overflow-wrap: anywhere; }
.flare-pay-confirm__order { font-variant-numeric: tabular-nums; color: var(--flare-color-text-secondary); }
.flare-pay-confirm__meta {
  margin: 0;
  text-align: center;
  font-size: var(--flare-size-font-size-sm);
  color: var(--flare-color-text-secondary);
  font-variant-numeric: tabular-nums;
}
.flare-pay-confirm__alert {
  margin: 0;
  text-align: center;
  font-size: var(--flare-size-font-size-md);
  color: var(--flare-color-error-text);
}
.flare-pay-confirm__actions { display: flex; flex-direction: column; gap: var(--flare-size-spacing-sm); }
</style>
