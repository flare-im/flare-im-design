<script setup lang="ts">
/**
 * The outcome of a fund action, a submission or a send (spec ResultView, docs/plugin-experience.md R7): a tone icon in
 * a tinted circle, the title, the amount, one explanatory paragraph, the details as a DescriptionList, the done key
 * and an optional secondary key, then the `actions` slot (more secondary keys). Phones pin the keys to the bottom of the
 * scroller; PC centres them at 240 wide. The title and description are announced once per title.
 */
import { computed } from "vue";
import FlareButton from "../general/FlareButton.vue";
import FlareIcon from "../general/FlareIcon.vue";
import FlareDescriptionList from "../data/FlareDescriptionList.vue";
import { useFlareI18nOptional, useFlareLocaleOptional } from "../../shared/i18n/useFlareI18n";
import { flareSpokenAmount } from "../../shared/contracts/capability-ui";
import { useFlarePlatformSafe } from "../../shared/platform/useFlarePlatform";
import { flarePluginBadgeTone, type FlarePluginField } from "../../shared/contracts/plugin-ui";
import { flarePluginResultIcon, flarePluginSplitReferences } from "../../shared/contracts/plugin-experience";
import PluginFieldList from "./plugin/PluginFieldList.vue";

const props = withDefaults(
  defineProps<{
    title: string;
    tone?: string;
    amount?: string;
    description?: string;
    details?: ReadonlyArray<FlarePluginField>;
    doneLabel?: string;
    secondaryLabel?: string;
    busy?: boolean;
  }>(),
  { tone: "info", amount: undefined, description: undefined, details: () => [], doneLabel: undefined, secondaryLabel: undefined, busy: false },
);
const emit = defineEmits<{ done: []; secondary: [] }>();
const { t } = useFlareI18nOptional();
const locale = useFlareLocaleOptional();
/** R11: the amount read with its currency's name. */
const spokenAmount = computed(() => props.amount ? flareSpokenAmount(props.amount, locale.value) : undefined);
const platform = useFlarePlatformSafe();
const phone = computed(() => platform.capabilities.value.bottomSheet);
const shownTone = computed(() => flarePluginBadgeTone(props.tone));
const icon = computed(() => flarePluginResultIcon(shownTone.value));
// R3: reference fields (fund and order numbers) leave the details for the folded 「单号与凭据」 group.
const split = computed(() => flarePluginSplitReferences(props.details));
const items = computed(() => split.value.main.map((field, index) => ({ key: String(index), label: field.label, value: field.value })));
const announce = computed(() => [props.title, props.description].filter(Boolean).join(" "));
</script>

<template>
  <section class="flare-result" :class="[`is-${shownTone}`, { 'is-phone': phone }]" :aria-busy="busy" :data-result-tone="shownTone">
    <span class="flare-result__icon" :data-result-icon="icon"><FlareIcon :name="icon" size="xl" /></span>
    <h2 class="flare-result__title">{{ title }}</h2>
    <p v-if="amount" class="flare-result__amount" :aria-label="spokenAmount" data-result-amount="true">{{ amount }}</p>
    <p v-if="description" class="flare-result__description">{{ description }}</p>
    <!-- One polite announcement per outcome: the key re-creates the node when the words change. -->
    <p :key="announce" class="flare-result__spoken" role="status" aria-live="polite">{{ announce }}</p>
    <FlareDescriptionList v-if="items.length" class="flare-result__details" :items="items" :columns="1" appearance="card" />
    <PluginFieldList v-if="split.references.length" class="flare-result__references" :fields="split.references" />
    <div class="flare-result__keys" :class="{ 'is-pinned': phone }" data-result-keys="true">
      <FlareButton
        class="flare-result__key"
        :label="doneLabel ?? t('pluginView.done')"
        :block="phone"
        :disabled="busy"
        data-result-done="true"
        @click="emit('done')"
      />
      <FlareButton
        v-if="secondaryLabel"
        class="flare-result__key"
        variant="secondary"
        :label="secondaryLabel"
        :block="phone"
        :disabled="busy"
        data-result-secondary="true"
        @click="emit('secondary')"
      />
      <slot name="actions" />
    </div>
  </section>
</template>

<style scoped>
.flare-result {
  --flare-result-tone: var(--flare-color-info);
  --flare-result-ink: var(--flare-color-info-text);
  display: grid;
  justify-items: center;
  gap: var(--flare-size-spacing-md);
  width: 100%;
  max-width: var(--flare-size-component-form-column-width);
  margin-inline: auto;
  box-sizing: border-box;
  text-align: center;
}
.flare-result.is-success { --flare-result-tone: var(--flare-color-success); --flare-result-ink: var(--flare-color-success-text); }
.flare-result.is-warning { --flare-result-tone: var(--flare-color-warning); --flare-result-ink: var(--flare-color-warning-text); }
.flare-result.is-danger { --flare-result-tone: var(--flare-color-error); --flare-result-ink: var(--flare-color-error-text); }
.flare-result.is-neutral { --flare-result-tone: var(--flare-color-text-secondary); --flare-result-ink: var(--flare-color-text-secondary); }
.flare-result__icon {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: var(--flare-size-component-result-icon-size);
  height: var(--flare-size-component-result-icon-size);
  border-radius: var(--flare-size-radius-full);
  color: var(--flare-result-ink);
  background: color-mix(in srgb, var(--flare-result-tone) calc(var(--flare-opacity-tint-weak) * 100%), transparent);
}
@media (prefers-reduced-motion: no-preference) {
  .flare-result__icon { animation: flare-result-in var(--flare-transition-spring) both; }
}
@keyframes flare-result-in { from { transform: scale(0.6); opacity: 0; } to { transform: scale(1); opacity: 1; } }
.flare-result__title {
  margin: 0;
  font-size: var(--flare-size-font-size-4xl);
  font-weight: var(--flare-size-font-weight-bold);
  color: var(--flare-color-text-primary);
  overflow-wrap: anywhere;
}
.flare-result__amount {
  margin: 0;
  font-size: var(--flare-size-component-amount-hero-font-size);
  font-weight: var(--flare-size-font-weight-bold);
  font-variant-numeric: tabular-nums;
  color: var(--flare-color-text-primary);
}
.flare-result__description {
  margin: 0;
  font-size: var(--flare-size-font-size-lg);
  color: var(--flare-color-text-secondary);
  display: -webkit-box;
  -webkit-box-orient: vertical;
  -webkit-line-clamp: 3;
  line-clamp: 3;
  overflow: hidden;
  overflow-wrap: anywhere;
}
.flare-result__spoken { position: absolute; width: 1px; height: 1px; overflow: hidden; clip: rect(0 0 0 0); white-space: nowrap; margin: 0; }
.flare-result__details { width: 100%; text-align: start; }
.flare-result__keys {
  display: grid;
  justify-items: center;
  gap: var(--flare-size-spacing-sm);
  width: 100%;
  margin-top: var(--flare-size-spacing-sm);
}
.flare-result__key { width: var(--flare-size-component-result-action-width); max-width: 100%; }
.flare-result.is-phone .flare-result__keys { justify-items: stretch; }
.flare-result.is-phone .flare-result__key { width: 100%; }
/* Phone: the done key stays reachable at the bottom of the page's scroller, over the safe area. */
.flare-result__keys.is-pinned {
  position: sticky;
  bottom: 0;
  z-index: var(--flare-z-index-sticky);
  box-sizing: border-box;
  padding: var(--flare-size-spacing-md) 0 calc(var(--flare-size-spacing-md) + env(safe-area-inset-bottom, 0px));
  border-top: 1px solid var(--flare-color-border-secondary);
  background: var(--flare-color-bg-primary);
}
.flare-result.is-phone .flare-result__key { min-height: var(--flare-size-layout-control-height-lg); }
</style>
