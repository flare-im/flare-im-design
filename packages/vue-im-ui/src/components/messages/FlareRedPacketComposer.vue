<script setup lang="ts">
// 发红包表单 —— 种类分段、金额、个数(拼手气 / 普通)、收款人插槽(专属)、祝福语、大字总额和「塞钱进红包」。
//
// 组件只做格式限制:金额只收数字和最多两位小数,个数只收数字(spec/red-packet-vectors.json)。
// 上下限、余额和总额都由宿主算好再传回来;专属红包的收款人由宿主用成员选择组件填进 `recipient` 插槽。
import { computed, useId, watch } from "vue";
import FlareButton from "../general/FlareButton.vue";
import FlareSegmentedControl from "../general/FlareSegmentedControl.vue";
import {
  sanitizeRedPacketAmount,
  sanitizeRedPacketCount,
  type FlareRedPacketKind,
} from "../../shared/contracts/red-packet";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";

const props = withDefaults(
  defineProps<{
    /** Kinds the host offers, in segment order; a 1:1 conversation passes only `normal` (no switch, no count). */
    kinds: ReadonlyArray<FlareRedPacketKind>;
    /** The total the host computed, already formatted ("¥0.00"); drawn large. */
    total: string;
    error?: string;
    /** The create command is in flight: every field and the button are locked, with progress on the button. */
    busy?: boolean;
    /**
     * The original command's outcome is unknown and awaits reconciliation: the form is read-only and the
     * button cannot be pressed, without progress. The host usually explains why in a StatusBanner above.
     */
    locked?: boolean;
    submitLabel?: string;
  }>(),
  { busy: false, locked: false },
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
const countId = `flare-rp-count-${uid}`;
const recipientLabelId = `flare-rp-recipient-${uid}`;

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

function selectKind(index: number): void {
  const next = props.kinds[index];
  if (next && !props.locked) kind.value = next;
}
// The filtered value is written back to the element as well: when filtering leaves the model unchanged
// (a letter typed after "8.88"), Vue has nothing to re-render and the letter would stay on screen.
function onAmountInput(event: Event): void {
  const el = event.target as HTMLInputElement;
  const next = sanitizeRedPacketAmount(el.value);
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
function requestSubmit(): void {
  if (!props.busy && !props.locked) emit("submit");
}
</script>

<template>
  <div
    class="flare-rp-composer"
    :class="{ 'is-locked': locked }"
    :aria-busy="busy || undefined"
    :data-kind="activeKind"
  >
    <fieldset class="flare-rp-composer__fields" :disabled="busy">
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
        <div class="flare-rp-composer__row">
          <label class="flare-rp-composer__label" :for="amountId">{{ amountLabel }}</label>
          <input
            :id="amountId"
            class="flare-rp-composer__input"
            type="text"
            inputmode="decimal"
            autocomplete="off"
            placeholder="0.00"
            :readonly="locked"
            :value="amount"
            :aria-invalid="error ? true : undefined"
            @input="onAmountInput"
          />
        </div>
        <div v-if="showsCount" class="flare-rp-composer__row">
          <label class="flare-rp-composer__label" :for="countId">{{ t("redPacket.field.count") }}</label>
          <input
            :id="countId"
            class="flare-rp-composer__input"
            type="text"
            inputmode="numeric"
            autocomplete="off"
            :placeholder="t('redPacket.countPlaceholder')"
            :readonly="locked"
            :value="countText"
            @input="onCountInput"
          />
        </div>
        <div v-if="showsRecipient" class="flare-rp-composer__row">
          <span :id="recipientLabelId" class="flare-rp-composer__label">{{ t("redPacket.field.recipient") }}</span>
          <fieldset class="flare-rp-composer__set flare-rp-composer__recipient" :disabled="locked" :aria-labelledby="recipientLabelId">
            <slot name="recipient" />
          </fieldset>
        </div>
      </div>
      <div class="flare-rp-composer__group flare-rp-composer__group--greeting">
        <input
          class="flare-rp-composer__input flare-rp-composer__greeting"
          type="text"
          autocomplete="off"
          :aria-label="t('redPacket.field.greeting')"
          :placeholder="t('redPacket.defaultGreeting')"
          :readonly="locked"
          :value="greeting"
          @input="onGreetingInput"
        />
      </div>
    </fieldset>
    <p v-if="error" class="flare-rp-composer__error" role="alert">{{ error }}</p>
    <p class="flare-rp-composer__total" aria-live="polite">{{ total }}</p>
    <div class="flare-rp-composer__submit">
      <FlareButton
        block
        size="lg"
        :label="submitLabel ?? t('redPacket.submit')"
        :loading="busy"
        :disabled="locked"
        @click="requestSubmit"
      />
    </div>
  </div>
</template>

<style scoped>
.flare-rp-composer {
  display: flex;
  flex-direction: column;
  gap: var(--flare-size-spacing-lg);
  min-width: 0;
  padding: var(--flare-size-spacing-lg);
  box-sizing: border-box;
  color: var(--flare-color-text-primary);
}
.flare-rp-composer__fields {
  display: flex;
  flex-direction: column;
  gap: var(--flare-size-spacing-md);
  min-width: 0;
  margin: 0;
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
  min-height: var(--flare-size-layout-touch-target);
  padding: 0 var(--flare-size-spacing-lg);
}
.flare-rp-composer__row + .flare-rp-composer__row { border-top: 1px solid var(--flare-color-border-secondary); }
.flare-rp-composer__label {
  flex: 0 0 auto;
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
.flare-rp-composer__input::placeholder { color: var(--flare-color-text-tertiary); }
.flare-rp-composer__input:disabled { color: var(--flare-color-text-disabled); }
.flare-rp-composer__row:focus-within,
.flare-rp-composer__group--greeting:focus-within {
  box-shadow: inset 0 0 0 2px var(--flare-color-border-selected);
}
.flare-rp-composer__greeting { padding: 0 var(--flare-size-spacing-lg); text-align: start; }
.flare-rp-composer__recipient { flex: 1 1 auto; min-width: 0; display: flex; justify-content: flex-end; }
.flare-rp-composer__error {
  margin: 0;
  font-size: var(--flare-size-font-size-md);
  color: var(--flare-color-error-text);
}
.flare-rp-composer__total {
  margin: var(--flare-size-spacing-md) 0 0;
  text-align: center;
  font-size: var(--flare-size-component-red-packet-amount-font-size);
  line-height: var(--flare-size-line-height-tight);
  font-weight: var(--flare-size-font-weight-semibold);
  font-variant-numeric: tabular-nums;
  overflow-wrap: anywhere;
}
/* The kit button, re-tinted for money: the deep red keeps white text above 4.5:1. */
.flare-rp-composer__submit {
  --flare-color-primary: var(--flare-color-red-packet-end);
  --flare-color-primary-hover: color-mix(in srgb, var(--flare-color-red-packet-end) 88%, #000);
  --flare-color-primary-active: color-mix(in srgb, var(--flare-color-red-packet-end) 78%, #000);
  padding: 0 var(--flare-size-spacing-xl);
}
</style>
