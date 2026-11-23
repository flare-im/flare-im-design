<script setup lang="ts">
// 付款确认 —— 引擎的 confirmPayment 请求由宿主收到后画的确认面板（设计 7.3）。
// 金额、收款方、说明、订单号只取订单字段，插件改不了布局；倒计时按服务端时钟走，过期后不能确认。
// 身份验证（支付密码、生物识别）沿用宿主已有的 reauthenticate 流程：确认键只发 `confirm`，
// 宿主验证后把凭证交回引擎；需要在面板里输密码的宿主把输入框放进 `credential` 插槽。
import { computed, onBeforeUnmount, ref, watch } from "vue";
import FlareBottomSheet from "../general/FlareBottomSheet.vue";
import FlareButton from "../general/FlareButton.vue";
import FlareIcon from "../general/FlareIcon.vue";
import FlareIconButton from "../general/FlareIconButton.vue";
import FlareStatusBanner from "../general/FlareStatusBanner.vue";
import { flareIcons } from "../../shared/icons";
import { useFlareI18nOptional, useFlareLocaleOptional } from "../../shared/i18n/useFlareI18n";
import { flareServerNowMs } from "../../shared/server-clock";
import {
  flarePaymentAmountText,
  flareSpokenAmount,
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
    /**
     * Insufficient balance: the formatted missing amount ("¥6.64"). Confirm is disabled, payment.insufficient reads
     * above it and a secondary top-up key emits `topUp` (§4.3 of docs/plugin-experience.md).
     */
    shortfall?: string;
  }>(),
  { busy: false, confirmDisabled: false },
);
const emit = defineEmits<{
  (e: "confirm"): void;
  (e: "cancel"): void;
  /** The order ran out while the panel was open (once). */
  (e: "expire"): void;
  /** Insufficient balance: the viewer asked to top up (the host opens the wallet's top-up page). */
  (e: "topUp"): void;
  /** The order expired and the viewer asked to start again (the expired primary key). */
  (e: "startAgain"): void;
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
// R11: the amount read with the currency's name (人民币 / Chinese Yuan), never the bare symbol.
const locale = useFlareLocaleOptional();
const spokenAmount = computed(() => amountText.value === null ? undefined : flareSpokenAmount(amountText.value, locale.value, props.order.currency));
const countdown = computed(() => flarePaymentCountdown(props.order.expiresAtMs - now.value));
let expiredOrder: string | undefined;
watch(() => [props.open, props.order.orderId, props.order.expiresAtMs, countdown.value.expired] as const,
  ([open, id, deadline, expired]) => {
    if (!open) { expiredOrder = undefined; return; }
    const key = `${id}/${deadline}`;
    if (expired && expiredOrder !== key) { expiredOrder = key; emit("expire"); }
  }, {immediate: true});
const canConfirm = computed(
  () => !props.busy && !props.confirmDisabled && !props.shortfall && !countdown.value.expired && amountText.value !== null,
);
// Under a minute left the countdown turns to the warning colour.
const closing = computed(() => !countdown.value.expired && props.order.expiresAtMs - now.value < 60_000);
const orderShown = ref(false);
watch(() => props.order.orderId, () => { orderShown.value = false; });
async function copyOrder(): Promise<void> {
  try { await navigator.clipboard.writeText(props.order.orderId); } catch { /* clipboard blocked: the id stays readable */ }
}

function requestConfirm(): void {
  if (canConfirm.value) emit("confirm");
}
// An expired order's key reads "Start again": the host declines this order and the plugin's own flow starts over.
function requestPrimary(): void {
  if (countdown.value.expired) { if (!props.busy) emit("startAgain"); }
  else requestConfirm();
}
function requestCancel(): void {
  if (!props.busy) emit("cancel");
}
</script>

<template>
  <FlareBottomSheet :open="open" :title="t('paymentConfirmation.title')" title-hidden :dismissible="!busy" dialog-width="var(--flare-size-component-payment-dialog-width)" @close="requestCancel">
    <div class="flare-pay-confirm" :aria-busy="busy || undefined" data-payment-confirmation="true">
      <!-- §4.3 / §12.19: the panel's own title, 15/600 and centred on the sheet and the dialog alike. -->
      <h2 class="flare-pay-confirm__title" data-payment-title="true">{{ t("paymentConfirmation.title") }}</h2>
      <p v-if="pluginName" class="flare-pay-confirm__meta">{{ t("paymentConfirmation.requestedBy", { plugin: pluginName }) }}</p>
      <p class="flare-pay-confirm__amount" :class="{ 'is-expired': countdown.expired }" :aria-label="spokenAmount" data-payment-amount="true">{{ amountText ?? "—" }}</p>
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
          <dt>
            <button type="button" class="flare-pay-confirm__fold" :aria-expanded="orderShown" data-payment-order-toggle="true" @click="orderShown = !orderShown">
              {{ t("paymentConfirmation.order") }}<FlareIcon name="chevron-right" size="sm" aria-hidden="true" />
            </button>
          </dt>
          <dd v-if="orderShown" class="flare-pay-confirm__order" data-payment-order="true">
            <span>{{ order.orderId }}</span>
            <FlareIconButton :icon="flareIcons.copy" size="sm" :ariaLabel="t('descriptionList.copy', { label: t('paymentConfirmation.order') })" data-payment-order-copy="true" @click="copyOrder" />
          </dd>
        </div>
      </dl>
      <p v-if="amountText === null" class="flare-pay-confirm__alert" role="alert">{{ t("paymentConfirmation.invalid") }}</p>
      <p v-else-if="countdown.expired" class="flare-pay-confirm__alert" role="alert" data-payment-expired="true">
        {{ t("paymentConfirmation.expired") }}
      </p>
      <p v-else class="flare-pay-confirm__meta" :class="{ 'is-closing': closing }" data-payment-countdown="true">
        {{ t("paymentConfirmation.expiresIn", { time: countdown.text }) }}
      </p>
      <div v-if="$slots.credential" class="flare-pay-confirm__credential"><slot name="credential" /></div>
      <FlareStatusBanner v-if="error" role="alert" tone="danger" :text="error" />
      <p v-if="shortfall && !countdown.expired" class="flare-pay-confirm__shortfall" data-payment-shortfall="true">
        {{ t("paymentConfirmation.insufficient", { amount: shortfall }) }}
      </p>
      <div class="flare-pay-confirm__actions">
        <FlareButton
          block
          :label="busy ? t('paymentConfirmation.verifying') : countdown.expired ? t('paymentConfirmation.startAgain') : t('paymentConfirmation.confirm')"
          :loading="busy"
          :disabled="!busy && !countdown.expired && !canConfirm"
          data-payment-confirm="true"
          @click="requestPrimary"
        />
        <FlareButton v-if="shortfall && !countdown.expired" block variant="secondary" :label="t('paymentConfirmation.topUp')" :disabled="busy" data-payment-top-up="true" @click="emit('topUp')" />
        <FlareButton block variant="secondary" :label="t('common.cancel')" :disabled="busy" data-payment-cancel="true" @click="requestCancel" />
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
.flare-pay-confirm__title { margin: 0; text-align: center; font-size: var(--flare-size-font-size-xl); font-weight: var(--flare-size-font-weight-semibold); line-height: var(--flare-size-line-height-snug); }
.flare-pay-confirm__amount {
  margin: 0;
  text-align: center;
  font-size: var(--flare-size-component-amount-hero-font-size);
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
.flare-pay-confirm__amount.is-expired { color: var(--flare-color-text-disabled); }
/* The order number folds behind "订单号 ›" on every kit; opening it shows the id with a copy key. */
.flare-pay-confirm__fold {
  display: inline-flex;
  align-items: center;
  gap: var(--flare-size-spacing-xs);
  min-height: var(--flare-size-layout-touch-target);
  padding: 0;
  border: 0;
  background: transparent;
  color: inherit;
  font: inherit;
  cursor: pointer;
}
.flare-pay-confirm__fold:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: 2px; }
.flare-pay-confirm__fold[aria-expanded="true"] > .flare-icon { transform: rotate(90deg); }
.flare-pay-confirm__order { display: inline-flex; align-items: center; gap: var(--flare-size-spacing-xs); font-variant-numeric: tabular-nums; color: var(--flare-color-text-secondary); }
.flare-pay-confirm__order > span { min-width: 0; overflow-wrap: anywhere; }
.flare-pay-confirm__shortfall {
  margin: 0;
  text-align: center;
  font-size: var(--flare-size-font-size-sm);
  color: var(--flare-color-error-text);
}
.flare-pay-confirm__credential { display: grid; min-width: 0; }
.flare-pay-confirm__meta {
  margin: 0;
  text-align: center;
  font-size: var(--flare-size-font-size-sm);
  color: var(--flare-color-text-secondary);
  font-variant-numeric: tabular-nums;
}
.flare-pay-confirm__meta.is-closing { color: var(--flare-color-warning-text); }
.flare-pay-confirm__alert {
  margin: 0;
  text-align: center;
  font-size: var(--flare-size-font-size-md);
  color: var(--flare-color-error-text);
}
.flare-pay-confirm__actions { display: flex; flex-direction: column; gap: var(--flare-size-spacing-xs); position: sticky; bottom: 0; padding-top: var(--flare-size-spacing-sm); background: var(--flare-color-bg-primary); }
</style>
