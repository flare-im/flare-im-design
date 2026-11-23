<script setup lang="ts">
// 发红包表单 —— 种类分段、金额、个数(拼手气 / 普通)、收款人插槽(专属)、祝福语、大字总额和「塞钱进红包」。
//
// 组件只做格式限制:金额只收数字和币种小数位以内的小数(currencyExponent,0 位时不收小数点),个数只收数字
// (spec/red-packet-vectors.json)。
// 上下限、余额和总额都由宿主算好再传回来;专属红包的收款人由宿主用成员选择组件填进 `recipient` 插槽。
import { computed, ref, useId, watch } from "vue";
import FlareButton from "../general/FlareButton.vue";
import FlareStatusBanner from "../general/FlareStatusBanner.vue";
import RedPacketArch from "./RedPacketArch.vue";
import FlareSegmentedControl from "../general/FlareSegmentedControl.vue";
import {
  flareRedPacketAmountMinor,
  flareRedPacketAmountText,
  flareRedPacketExponent,
  sanitizeRedPacketAmount,
  sanitizeRedPacketCount,
  type FlareRedPacketKind,
  type FlareRedPacketField,
} from "../../shared/contracts/red-packet";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";

const props = withDefaults(
  defineProps<{
    /** Kinds the host offers, in segment order; a 1:1 conversation passes only `normal` (no switch, no count). */
    kinds: ReadonlyArray<FlareRedPacketKind>;
    /** The total the host computed, already formatted ("¥0.00"); drawn large. */
    total: string;
    error?: string;
    /** Scope validation to a field; service failures use `form`. Omitted retains amount-error behavior. */
    errorField?: FlareRedPacketField | "form";
    /** The create command is in flight: every field and the button are locked, with progress on the button. */
    busy?: boolean;
    /**
     * The original command's outcome is unknown and awaits reconciliation: the form is read-only and the
     * button cannot be pressed, without progress. The host usually explains why in a StatusBanner above.
     */
    locked?: boolean;
    submitLabel?: string;
    /**
     * The currency's ISO 4217 exponent from the plugin's limits (0 JPY, 2 CNY, 3 KWD): the amount field keeps at
     * most that many decimals (whole numbers at 0) and its placeholder has that many. The host turns the text into
     * minor units with `flareRedPacketAmountMinor(amount, currencyExponent)`.
     */
    currencyExponent?: number;
    /** Symbol drawn before the amount field ("¥"); none when absent. */
    currencySymbol?: string;
    /** The group's head count: redPacket.groupMembers under the count row (groups only, never 1:1). */
    memberCount?: number;
  }>(),
  { busy: false, locked: false, currencyExponent: 2 },
);
const kind = defineModel<FlareRedPacketKind>("kind", { default: "lucky" });
const amount = defineModel<string>("amount", { default: "" });
/** Share count for lucky / normal packets in a group; 0 while the field is empty. */
const count = defineModel<number>("count", { default: 0 });
const greeting = defineModel<string>("greeting", { default: "" });
const emit = defineEmits<{ (e: "submit"): void }>();

const { t } = useFlareI18nOptional();
const uid = useId();
const amountId = `flare-rp-amount-${uid}`;
const amountLabelId = `flare-rp-amount-label-${uid}`;
const badgeId = `flare-rp-badge-${uid}`;
const errorId = `flare-rp-error-${uid}`;
const unavailable = computed(() => props.kinds.length === 0);
const countId = `flare-rp-count-${uid}`;
const recipientLabelId = `flare-rp-recipient-${uid}`;
const amountInput = ref<HTMLInputElement>();
const countInput = ref<HTMLInputElement>();
const greetingInput = ref<HTMLInputElement>();
const recipientInput = ref<HTMLFieldSetElement>();
const invalid = (field: FlareRedPacketField) => Boolean(props.error && (props.errorField ?? 'amount') === field);
// A service failure ('form') is a banner above the card; a field error is a caption under its own row.
const formError = computed(() => {
  const field = props.errorField ?? 'amount';
  const shown = field === 'count' ? showsCount.value : field === 'recipient' ? showsRecipient.value : field !== 'form';
  return Boolean(props.error && !shown);
});
function focusField(field: FlareRedPacketField): void {
  if (props.busy || props.locked || unavailable.value) return;
  if (field === 'recipient') recipientInput.value?.querySelector<HTMLButtonElement>('button:not(:disabled)')?.focus();
  else ({ amount: amountInput, count: countInput, greeting: greetingInput })[field].value?.focus();
}
defineExpose({ focusField });

// The model's type admits `undefined` on older TypeScript (5.6 types `defineModel` with a default that way),
// so every read goes through one narrowed value with the same fallback as the default.
const currentKind = computed<FlareRedPacketKind>(() => kind.value ?? "lucky");

// A kind the host no longer offers (a group became a 1:1 chat) snaps to the first one it does.
watch(
  () => [currentKind.value, props.kinds] as const,
  ([current, offered]) => {
    const first = offered[0];
    if (first !== undefined && !offered.includes(current)) kind.value = first;
  },
  { immediate: true },
);

// What the form draws while a stale kind is being snapped: never a kind the host does not offer.
const activeKind = computed<FlareRedPacketKind>(() => {
  const first = props.kinds[0];
  return first === undefined || props.kinds.includes(currentKind.value) ? currentKind.value : first;
});
const kindIndex = computed(() => Math.max(0, props.kinds.indexOf(activeKind.value)));
const kindLabels = computed(() => props.kinds.map((k) => t(`redPacket.kind.${k}`)));
// Only `normal` on offer is a 1:1 conversation: one packet for the one peer, so there is no count to
// ask for and the amount is simply the amount (spec/red-packet-vectors.json → composer).
const direct = computed(() => props.kinds.length === 1 && props.kinds[0] === "normal");
// The amount field means a different thing per kind: the pool, one share, or the one packet.
const amountLabel = computed(() =>
  activeKind.value === "lucky"
    ? t("redPacket.field.total")
    : activeKind.value === "normal" && !direct.value
      ? t("redPacket.field.each")
      : t("redPacket.field.amount"),
);
const showsCount = computed(() => activeKind.value !== "exclusive" && !direct.value);
const showsRecipient = computed(() => activeKind.value === "exclusive");
const countText = computed(() => ((count.value ?? 0) > 0 ? String(count.value) : ""));
const exponent = computed(() => flareRedPacketExponent(props.currencyExponent));
// "0", "0.00", "0.000": the amount the field asks for, in the currency's decimals.
const amountPlaceholder = computed(() => flareRedPacketAmountText("0", exponent.value) ?? "0");

// A currency with fewer decimals (the host switched currency) trims what was typed for the old one.
watch(exponent, (scale) => {
  const current = amount.value ?? "";
  const next = sanitizeRedPacketAmount(current, scale);
  if (next !== current) amount.value = next;
});

function selectKind(index: number): void {
  const next = props.kinds[index];
  if (next && !props.locked) kind.value = next;
}
// The filtered value is written back to the element as well: when filtering leaves the model unchanged
// (a letter typed after "8.88"), Vue has nothing to re-render and the letter would stay on screen.
function onAmountInput(event: Event): void {
  const el = event.target as HTMLInputElement;
  const next = sanitizeRedPacketAmount(el.value, exponent.value);
  if (el.value !== next) el.value = next;
  amount.value = next;
}
function onCountInput(event: Event): void {
  const el = event.target as HTMLInputElement;
  const next = sanitizeRedPacketCount(el.value);
  const text = next > 0 ? String(next) : "";
  if (el.value !== text) el.value = text;
  count.value = next;
}
function onGreetingInput(event: Event): void {
  greeting.value = (event.target as HTMLInputElement).value;
}
function onFieldKeydown(event: KeyboardEvent): void {
  // Let Enter finish Chinese/Japanese composition before it can submit money-related UI.
  if (event.key !== "Enter" || event.isComposing || event.keyCode === 229) return;
  event.preventDefault();
  requestSubmit();
}
// §4.2: no sending a zero total or past a field error. The total is the host's formatted text, so zero is read from
// the amount it is built from: empty or 0 makes every kind's total 0.
const blocked = computed(() => {
  const minor = flareRedPacketAmountMinor(amount.value ?? "", exponent.value);
  return minor === null || /^0+$/.test(minor) || Boolean(props.error && (props.errorField ?? "amount") !== "form");
});
function requestSubmit(): void {
  if (!props.busy && !props.locked && !unavailable.value && !blocked.value) emit("submit");
}
</script>

<template>
  <div
    class="flare-rp-composer"
    :class="{ 'is-locked': locked }"
    :aria-busy="busy || undefined"
    :data-kind="activeKind"
  >
    <RedPacketArch compact />
    <FlareStatusBanner v-if="formError" :id="errorId" class="flare-rp-composer__banner" role="alert" tone="danger" :text="error!" />
    <fieldset class="flare-rp-composer__fields" :disabled="busy || unavailable" :aria-describedby="error ? errorId : undefined">
      <fieldset v-if="kinds.length > 1" class="flare-rp-composer__set" :disabled="locked">
        <FlareSegmentedControl
          class="flare-rp-composer__kinds"
          :aria-label="t('redPacket.kindLabel')"
          :options="kindLabels"
          :model-value="kindIndex"
          accent="var(--flare-color-red-packet-accent)"
          @update:model-value="selectKind"
        />
      </fieldset>
      <div class="flare-rp-composer__group">
        <div class="flare-rp-composer__row" :class="{ 'is-invalid': invalid('amount'), 'has-currency': Boolean(currencySymbol) }">
          <span class="flare-rp-composer__label">
            <span v-if="activeKind === 'lucky'" :id="badgeId" class="flare-rp-composer__badge" data-lucky-badge="true">{{ t("redPacket.badge.luckyShort") }}</span>
            <label :id="amountLabelId" :for="amountId">{{ amountLabel }}</label>
          </span>
          <!-- The symbol sits against the digits: the field is sized to what it holds and pushed to the end. -->
          <span v-if="currencySymbol" class="flare-rp-composer__currency" aria-hidden="true" data-currency-symbol="true">{{ currencySymbol }}</span>
          <input
            ref="amountInput"
            :id="amountId"
            class="flare-rp-composer__input flare-rp-composer__amount"
            type="text"
            :inputmode="exponent > 0 ? 'decimal' : 'numeric'"
            autocomplete="off"
            :placeholder="amountPlaceholder"
            :size="currencySymbol ? Math.max((amount ?? '').length, amountPlaceholder.length, 1) : undefined"
            :readonly="locked"
            :value="amount"
            :aria-labelledby="activeKind === 'lucky' ? `${badgeId} ${amountLabelId}` : undefined"
            :aria-invalid="invalid('amount') || undefined"
            :aria-describedby="invalid('amount') ? errorId : undefined"
            @input="onAmountInput"
            @keydown="onFieldKeydown"
          />
        </div>
        <p v-if="invalid('amount')" :id="errorId" class="flare-rp-composer__field-error" role="alert">{{ error }}</p>
        <div v-if="showsCount" class="flare-rp-composer__row" :class="{ 'is-invalid': invalid('count') }">
          <label class="flare-rp-composer__label" :for="countId">{{ t("redPacket.field.count") }}</label>
          <input
            ref="countInput"
            :id="countId"
            class="flare-rp-composer__input"
            type="text"
            inputmode="numeric"
            autocomplete="off"
            :placeholder="t('redPacket.countPlaceholder')"
            :readonly="locked"
            :value="countText"
            :aria-invalid="invalid('count') || undefined"
            :aria-describedby="invalid('count') ? errorId : undefined"
            @input="onCountInput"
            @keydown="onFieldKeydown"
          />
          <span v-if="t('redPacket.countUnit')" class="flare-rp-composer__unit" aria-hidden="true" data-count-unit="true">{{ t("redPacket.countUnit") }}</span>
        </div>
        <p v-if="showsCount && invalid('count')" :id="errorId" class="flare-rp-composer__field-error" role="alert">{{ error }}</p>
        <div v-if="showsRecipient" class="flare-rp-composer__row" :class="{ 'is-invalid': invalid('recipient') }">
          <span :id="recipientLabelId" class="flare-rp-composer__label">{{ t("redPacket.field.recipient") }}</span>
          <fieldset ref="recipientInput" class="flare-rp-composer__set flare-rp-composer__recipient" :disabled="locked" :aria-labelledby="recipientLabelId" :aria-invalid="invalid('recipient') || undefined" :aria-describedby="invalid('recipient') ? errorId : undefined">
            <slot name="recipient" />
          </fieldset>
        </div>
        <p v-if="showsRecipient && invalid('recipient')" :id="errorId" class="flare-rp-composer__field-error" role="alert">{{ error }}</p>
      </div>
      <!-- The count row ends the card, so the head count sits right under it. -->
      <p v-if="showsCount && memberCount !== undefined" class="flare-rp-composer__members" data-member-count="true">{{ t("redPacket.groupMembers", { count: memberCount }) }}</p>
      <div class="flare-rp-composer__group flare-rp-composer__group--greeting" :class="{ 'is-invalid': invalid('greeting') }">
        <input
          ref="greetingInput"
          class="flare-rp-composer__input flare-rp-composer__greeting"
          type="text"
          autocomplete="off"
          :aria-label="t('redPacket.field.greeting')"
          :placeholder="t('redPacket.defaultGreeting')"
          maxlength="24"
          :readonly="locked"
          :value="greeting"
          :aria-invalid="invalid('greeting') || undefined"
          :aria-describedby="invalid('greeting') ? errorId : undefined"
          @input="onGreetingInput"
          @keydown="onFieldKeydown"
        />
        <p v-if="invalid('greeting')" :id="errorId" class="flare-rp-composer__field-error" role="alert">{{ error }}</p>
      </div>
    </fieldset>
    <div class="flare-rp-composer__summary">
      <span class="flare-rp-composer__sr">{{ t('redPacket.field.total') }}</span>
      <p class="flare-rp-composer__total" aria-live="polite">{{ total }}</p>
    </div>
    <div class="flare-rp-composer__submit">
      <FlareButton
        block
        size="lg"
        variant="primary"
        :label="submitLabel ?? t('redPacket.putMoneyIn')"
        :loading="busy"
        :disabled="locked || unavailable || blocked"
        @click="requestSubmit"
      />
      <p class="flare-rp-composer__notice">{{ t('redPacket.refundNotice') }}</p>
    </div>
  </div>
</template>

<style scoped>
.flare-rp-composer {
  display: flex;
  flex-direction: column;
  gap: var(--flare-size-spacing-md);
  max-width: calc(var(--flare-size-layout-touch-target-min) * 12);
  margin-inline: auto;
  min-width: 0;
  padding: 0;
  box-sizing: border-box;
  color: var(--flare-color-text-primary);
}
.flare-rp-composer__banner { margin-inline: var(--flare-size-spacing-lg); }
.flare-rp-composer__fields {
  display: flex;
  flex-direction: column;
  gap: var(--flare-size-spacing-md);
  min-width: 0;
  margin: 0 var(--flare-size-spacing-lg);
  padding: 0;
  border: none;
}
.flare-rp-composer__set { min-width: 0; margin: 0; padding: 0; border: none; }
.flare-rp-composer__kinds { display: flex; width: 100%; box-sizing: border-box; }
.flare-rp-composer.is-locked .flare-rp-composer__input { color: var(--flare-color-text-secondary); }
.flare-rp-composer__group {
  display: flex;
  flex-direction: column;
  border-radius: var(--flare-size-radius-card);
  background: var(--flare-color-bg-primary);
  border: 1px solid var(--flare-color-border-secondary);
  overflow: hidden;
}
.flare-rp-composer__row {
  display: flex;
  align-items: center;
  gap: var(--flare-size-spacing-md);
  min-height: var(--flare-size-component-red-packet-form-row-height);
  padding: 0 var(--flare-size-spacing-lg);
}
.flare-rp-composer__row + .flare-rp-composer__row { border-top: 1px solid var(--flare-color-border-secondary); }
.flare-rp-composer__unit { flex: none; font-size: var(--flare-size-font-size-xl); color: var(--flare-color-text-secondary); }
.flare-rp-composer__label {
  flex: 0 0 auto;
  display: inline-flex;
  align-items: center;
  gap: var(--flare-size-spacing-xs);
  font-size: var(--flare-size-font-size-xl);
  color: var(--flare-color-text-primary);
}
.flare-rp-composer__input {
  flex: 1 1 auto;
  min-width: 0;
  min-height: var(--flare-size-layout-touch-target);
  padding: 0;
  border: none;
  outline: none;
  background: transparent;
  font: inherit;
  font-size: var(--flare-size-font-size-xl);
  color: var(--flare-color-text-primary);
  text-align: end;
  font-variant-numeric: tabular-nums;
}
.flare-rp-composer__amount,
.flare-rp-composer__currency {
  font-size: var(--flare-size-font-size-3xl);
  font-weight: var(--flare-size-font-weight-semibold);
}
.flare-rp-composer__currency { flex: none; margin-inline-start: auto; font-variant-numeric: tabular-nums; }
.flare-rp-composer__row.has-currency { column-gap: var(--flare-size-spacing-2xs); }
.flare-rp-composer__row.has-currency .flare-rp-composer__label { margin-inline-end: var(--flare-size-spacing-md); }
.flare-rp-composer__row.has-currency .flare-rp-composer__amount { flex: 0 1 auto; width: auto; }
/* The lucky packet's 「拼」 mark leads the amount label, in the packet accent (§4.2). */
.flare-rp-composer__badge {
  padding: 0 var(--flare-size-spacing-2xs);
  border-radius: var(--flare-size-radius-sm);
  background: color-mix(in srgb, var(--flare-color-red-packet-accent) calc(var(--flare-opacity-tint-weak) * 100%), transparent);
  color: var(--flare-color-red-packet-accent);
  font-size: var(--flare-size-font-size-sm);
  font-weight: var(--flare-size-font-weight-semibold);
  line-height: var(--flare-size-line-height-normal);
}
.flare-rp-composer__input::placeholder { color: var(--flare-color-text-tertiary); }
/* A field error: the row and its caption on the failed-message tint (§4.2). */
.flare-rp-composer__row.is-invalid,
.flare-rp-composer__group--greeting.is-invalid,
.flare-rp-composer__field-error { background: var(--flare-color-message-failed-background); }
.flare-rp-composer__field-error {
  margin: 0;
  padding: 0 var(--flare-size-spacing-lg) var(--flare-size-spacing-sm);
  font-size: var(--flare-size-font-size-sm);
  line-height: var(--flare-size-line-height-normal);
  color: var(--flare-color-error-text);
  overflow-wrap: anywhere;
}
.flare-rp-composer__input:disabled { color: var(--flare-color-text-disabled); }
.flare-rp-composer__members {
  margin: 0;
  padding-inline: var(--flare-size-spacing-lg);
  font-size: var(--flare-size-font-size-sm);
  line-height: var(--flare-size-line-height-normal);
  color: var(--flare-color-text-secondary);
}
.flare-rp-composer__row:focus-within,
.flare-rp-composer__group--greeting:focus-within {
  box-shadow: inset 0 0 0 2px var(--flare-color-border-selected);
}
/* Every row of the form is one height (§4.2), the greeting's too. */
.flare-rp-composer__greeting { min-height: var(--flare-size-component-red-packet-form-row-height); padding: 0 var(--flare-size-spacing-lg); text-align: start; }
.flare-rp-composer__recipient { flex: 1 1 auto; min-width: 0; display: flex; justify-content: flex-end; }
.flare-rp-composer__summary { margin: var(--flare-size-spacing-sm) var(--flare-size-spacing-lg) 0; min-width: 0; }
.flare-rp-composer__sr {
  position: absolute;
  width: 1px;
  height: 1px;
  overflow: hidden;
  clip-path: inset(50%);
  white-space: nowrap;
}
.flare-rp-composer__total {
  min-width: 0;
  margin: 0;
  text-align: center;
  font-size: var(--flare-size-component-red-packet-amount-font-size);
  line-height: var(--flare-size-line-height-tight);
  font-weight: var(--flare-size-font-weight-semibold);
  font-variant-numeric: tabular-nums;
  overflow-wrap: anywhere;
  color: var(--flare-color-text-primary);
}
/* Standard Kit primary button; red is confined to the main action. */
.flare-rp-composer__submit {
  --flare-color-primary: var(--flare-color-red-packet-end);
  --flare-color-primary-hover: var(--flare-color-red-packet-end-hover);
  --flare-color-primary-active: var(--flare-color-red-packet-end-active);
  margin: 0 var(--flare-size-spacing-lg) var(--flare-size-spacing-lg);
  padding: 0;
}
.flare-rp-composer__notice {
  margin: var(--flare-size-spacing-sm) 0 0;
  text-align: center;
  font-size: var(--flare-size-font-size-sm);
  color: var(--flare-color-text-tertiary);
}
/* PC: the total steps down to 36 inside the 420-wide detail pane (§4.2). */
@media (min-width: 900px) {
  .flare-rp-composer__total { font-size: var(--flare-size-component-red-packet-amount-font-size-wide); }
}
</style>
