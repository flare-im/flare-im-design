<script setup lang="ts">
// 红包确认页 —— 清单仍声明确认页时（presentation.renderer: "redPacket.review"）画它：红包弧、大字总额、
// 「拼手气红包 · 3 个」、祝福语和红色主键「发红包」（docs/plugin-experience.md §4.3），替代紫色 hero 的通用插件页。
import { useId } from "vue";
import FlareButton from "../general/FlareButton.vue";
import FlareStatusBanner from "../general/FlareStatusBanner.vue";
import RedPacketArch from "./RedPacketArch.vue";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";

const props = withDefaults(
  defineProps<{
    /** The formatted total ("¥26.64"). */
    amount: string;
    /** Kind and count, such as "拼手气红包 · 3 个". */
    kindLabel?: string;
    /** The greeting. */
    blessing?: string;
    /** Send key label; t('redPacket.send') when absent. */
    submitLabel?: string;
    /** The send runs: the key spins and is locked. */
    busy?: boolean;
    /** Failure text in a danger banner above the key. */
    error?: string;
  }>(),
  { busy: false },
);
const emit = defineEmits<{ (e: "submit"): void }>();
const { t } = useFlareI18nOptional();
const id = useId();
// The group is named by what is being sent: the kind line, then the amount.
const labelledBy = () => [props.kindLabel ? `${id}-kind` : "", `${id}-amount`].filter(Boolean).join(" ");
</script>

<template>
  <section class="flare-rp-review" role="group" :aria-labelledby="labelledBy()" :aria-busy="busy || undefined" data-red-packet-review="true">
    <RedPacketArch compact />
    <div class="flare-rp-review__body">
      <p :id="`${id}-amount`" class="flare-rp-review__amount" data-review-amount="true">{{ amount }}</p>
      <p v-if="kindLabel" :id="`${id}-kind`" class="flare-rp-review__kind">{{ kindLabel }}</p>
      <p v-if="blessing" class="flare-rp-review__blessing">{{ blessing }}</p>
    </div>
    <div class="flare-rp-review__submit">
      <FlareStatusBanner v-if="error" role="alert" tone="danger" :text="error" />
      <FlareButton
        block
        size="lg"
        variant="primary"
        :label="submitLabel ?? t('redPacket.send')"
        :loading="busy"
        data-review-submit="true"
        @click="emit('submit')"
      />
    </div>
  </section>
</template>

<style scoped>
.flare-rp-review {
  display: flex;
  flex-direction: column;
  gap: var(--flare-size-spacing-2xl);
  min-width: 0;
  color: var(--flare-color-text-primary);
}
.flare-rp-review__body {
  display: grid;
  justify-items: center;
  gap: var(--flare-size-spacing-sm);
  padding-inline: var(--flare-size-spacing-lg);
  text-align: center;
}
.flare-rp-review__amount {
  margin: 0;
  font-size: var(--flare-size-component-red-packet-amount-font-size);
  line-height: var(--flare-size-line-height-tight);
  font-weight: var(--flare-size-font-weight-semibold);
  font-variant-numeric: tabular-nums;
  overflow-wrap: anywhere;
}
.flare-rp-review__kind { margin: 0; font-size: var(--flare-size-font-size-md); color: var(--flare-color-text-secondary); }
.flare-rp-review__blessing {
  margin: 0;
  font-size: var(--flare-size-font-size-xl);
  font-weight: var(--flare-size-font-weight-semibold);
  overflow-wrap: anywhere;
}
/* The kit primary key re-tinted to the packet red, as the composer does. */
.flare-rp-review__submit {
  --flare-color-primary: var(--flare-color-red-packet-end);
  --flare-color-primary-hover: var(--flare-color-red-packet-end-hover);
  --flare-color-primary-active: var(--flare-color-red-packet-end-active);
  display: grid;
  gap: var(--flare-size-spacing-md);
  padding: 0 var(--flare-size-spacing-lg) var(--flare-size-spacing-lg);
}
/* PC: 36, §4.3. */
@media (min-width: 900px) {
  .flare-rp-review__amount { font-size: var(--flare-size-component-red-packet-amount-font-size-wide); }
}
</style>
