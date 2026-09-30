<script setup lang="ts">
import { computed, useId } from "vue";
import { useFlareI18nOptional, useFlareLocaleOptional } from "../../shared/i18n/useFlareI18n";
import { formatChartNumber, isReading, withUnit } from "./chart-geometry";

/**
 * A metric tile — one number a dashboard leads with: what is measured, its value, and optionally the
 * change since the last period and a line of context (the period, the quota it is measured against).
 *
 * The host owns the reading and its meaning. This formats a number in the kit's language (or
 * `locale`), shows a string as it is, and draws `null` as a dash that says "no data" to a screen
 * reader instead of a misleading 0. Whether a rise is good news is the host's call (`polarity`); by
 * default a change is only reported, never coloured as praise or alarm.
 */
const props = withDefaults(defineProps<{
  /** What is measured. Names the tile for assistive technology. */
  label: string;
  /** The reading. A number is formatted per locale; a string is shown as it is; `null` is "no data". */
  value: number | string | null;
  /** Unit after the value: a lone symbol such as % sits on the number, a word takes a space. */
  unit?: string;
  /** One line of context under the value — the period, the quota, a collection time. */
  caption?: string;
  /** Change since the previous period, drawn signed with a direction mark. `null` draws nothing. */
  delta?: number | null;
  /** Unit after the change, e.g. % for a relative change. */
  deltaUnit?: string;
  /** Which direction is good news: colours the change. `neutral` reports it without judging. */
  polarity?: "neutral" | "higher-is-better" | "lower-is-better";
  /** Abbreviate large numbers (1.2万 / 12K). */
  compact?: boolean;
  /** Draw a placeholder instead of the value while the host fetches it. */
  loading?: boolean;
  /** `card` draws its own surface; `plain` sits inside a surface the host already drew. */
  appearance?: "card" | "plain";
  /** BCP-47 tag for the digits. Default: the kit's language. */
  locale?: string;
}>(), {
  unit: undefined,
  caption: undefined,
  delta: null,
  deltaUnit: undefined,
  polarity: "neutral",
  compact: false,
  loading: false,
  appearance: "card",
  locale: undefined,
});

const { t } = useFlareI18nOptional();
const kitLocale = useFlareLocaleOptional();
const locale = computed(() => props.locale ?? kitLocale.value);
const labelId = `flare-metric-tile-${useId()}`;

const empty = computed(() => props.value == null || props.value === "" || (typeof props.value === "number" && !isReading(props.value)));
const valueText = computed(() => {
  if (typeof props.value === "number") return formatChartNumber(props.value, locale.value, { compact: props.compact });
  return props.value ?? "";
});

const hasDelta = computed(() => isReading(props.delta));
const trend = computed<"up" | "down" | "flat">(() => {
  const delta = props.delta ?? 0;
  return delta > 0 ? "up" : delta < 0 ? "down" : "flat";
});
const sentiment = computed<"positive" | "negative" | "neutral">(() => {
  if (props.polarity === "neutral" || trend.value === "flat") return "neutral";
  const good = props.polarity === "higher-is-better" ? "up" : "down";
  return trend.value === good ? "positive" : "negative";
});
const deltaText = computed(() => (hasDelta.value
  ? withUnit(formatChartNumber(props.delta as number, locale.value, { signed: true, compact: props.compact }), props.deltaUnit)
  : ""));
const deltaSpoken = computed(() => {
  if (!hasDelta.value) return "";
  if (trend.value === "flat") return t("metricTile.unchanged");
  const magnitude = withUnit(formatChartNumber(Math.abs(props.delta as number), locale.value, { compact: props.compact }), props.deltaUnit);
  return t(trend.value === "up" ? "metricTile.increase" : "metricTile.decrease", { value: magnitude });
});
</script>

<template>
  <div
    class="flare-metric-tile"
    :class="`flare-metric-tile--${appearance}`"
    role="group"
    :aria-labelledby="labelId"
    :aria-busy="loading || undefined"
  >
    <p :id="labelId" class="flare-metric-tile__label">{{ label }}</p>
    <p class="flare-metric-tile__value">
      <template v-if="loading">
        <span class="flare-metric-tile__placeholder" aria-hidden="true"></span>
        <span class="flare-metric-tile__spoken">{{ t("metricTile.loading") }}</span>
      </template>
      <template v-else-if="empty">
        <span class="flare-metric-tile__number" aria-hidden="true">—</span>
        <span class="flare-metric-tile__spoken">{{ t("metricTile.empty") }}</span>
      </template>
      <template v-else>
        <span class="flare-metric-tile__number">{{ valueText }}</span>
        <span v-if="unit" class="flare-metric-tile__unit">{{ unit }}</span>
      </template>
    </p>
    <p v-if="!loading && (hasDelta || caption)" class="flare-metric-tile__foot">
      <span
        v-if="hasDelta"
        class="flare-metric-tile__delta"
        :data-trend="trend"
        :data-sentiment="sentiment"
      >
        <svg v-if="trend !== 'flat'" class="flare-metric-tile__caret" viewBox="0 0 8 8" aria-hidden="true" focusable="false">
          <path d="M4 1.5 7.5 6.5H0.5Z" />
        </svg>
        <span aria-hidden="true">{{ deltaText }}</span>
        <span class="flare-metric-tile__spoken">{{ deltaSpoken }}</span>
      </span>
      <span v-if="caption" class="flare-metric-tile__caption">{{ caption }}</span>
    </p>
  </div>
</template>

<style scoped>
.flare-metric-tile {
  position: relative;
  display: flex;
  flex-direction: column;
  gap: var(--flare-size-spacing-xs);
  min-width: 0;
  box-sizing: border-box;
}
.flare-metric-tile--card {
  padding: var(--flare-size-spacing-lg);
  border: 1px solid var(--flare-color-border-secondary);
  border-radius: var(--flare-size-radius-card);
  background: var(--flare-color-bg-primary);
}
.flare-metric-tile p { margin: 0; }
.flare-metric-tile__label {
  overflow: hidden;
  color: var(--flare-color-text-secondary);
  font-size: var(--flare-text-caption-font-size);
  line-height: var(--flare-text-caption-line-height);
  text-overflow: ellipsis;
  white-space: nowrap;
}
.flare-metric-tile__value {
  display: flex;
  align-items: baseline;
  gap: var(--flare-size-spacing-xs);
  min-width: 0;
  color: var(--flare-color-text-primary);
  line-height: var(--flare-size-line-height-tight);
}
/* Tabular figures: a row of tiles, or one tile that refreshes, does not shift as the digits change. */
.flare-metric-tile__number {
  overflow: hidden;
  font-size: var(--flare-size-font-size-5xl);
  font-variant-numeric: tabular-nums;
  font-weight: var(--flare-size-font-weight-semibold);
  text-overflow: ellipsis;
  white-space: nowrap;
}
.flare-metric-tile__unit {
  flex: none;
  color: var(--flare-color-text-secondary);
  font-size: var(--flare-size-font-size-md);
}
/* The placeholder holds the value's line so the tile does not jump when the number arrives. */
.flare-metric-tile__placeholder {
  display: block;
  width: 40%;
  height: calc(var(--flare-size-line-height-tight) * 1em);
  font-size: var(--flare-size-font-size-5xl);
  border-radius: var(--flare-size-radius-sm);
  background: var(--flare-color-bg-secondary);
}
.flare-metric-tile__foot {
  display: flex;
  flex-wrap: wrap;
  align-items: baseline;
  column-gap: var(--flare-size-spacing-sm);
  min-width: 0;
  color: var(--flare-color-text-tertiary);
  font-size: var(--flare-text-caption-font-size);
  line-height: var(--flare-text-caption-line-height);
}
.flare-metric-tile__delta {
  display: inline-flex;
  align-items: center;
  gap: var(--flare-size-spacing-3xs);
  color: var(--flare-color-text-secondary);
  font-variant-numeric: tabular-nums;
  font-weight: var(--flare-size-font-weight-medium);
}
.flare-metric-tile__delta[data-sentiment="positive"] { color: var(--flare-color-success-text); }
.flare-metric-tile__delta[data-sentiment="negative"] { color: var(--flare-color-error-text); }
.flare-metric-tile__caret {
  width: 0.75em;
  height: 0.75em;
  fill: currentColor;
}
.flare-metric-tile__delta[data-trend="down"] .flare-metric-tile__caret { transform: rotate(180deg); }
.flare-metric-tile__caption { min-width: 0; overflow-wrap: anywhere; }
/* Heard, not seen: the dash, the placeholder and the signed number are the sighted half. */
.flare-metric-tile__spoken {
  position: absolute;
  width: 1px;
  height: 1px;
  margin: -1px;
  padding: 0;
  overflow: hidden;
  clip-path: inset(50%);
  white-space: nowrap;
  border: 0;
}
</style>
