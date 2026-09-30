<script setup lang="ts">
import { computed, useId } from "vue";
import type { FlareTone } from "../../shared/contracts/tone";
import { useFlareI18nOptional, useFlareLocaleOptional } from "../../shared/i18n/useFlareI18n";
import {
  chartAreaPath,
  chartBars,
  chartDomain,
  chartLinePath,
  chartMarkers,
  chartPathCoordinate,
  chartReadings,
  chartSegments,
  chartSlots,
  chartTicks,
  formatChartNumber,
  isReading,
  isSymbolUnit,
  withUnit,
  type FlareChartPoint,
} from "./chart-geometry";

/**
 * A chart card — one series over time (daily sign-ups, messages per day, members) as bars or a line,
 * in a titled card with room for the host's controls (`extra`) and a note under the plot (`footer`).
 *
 * Drawn as plain SVG from kit tokens only, with no chart library: the series takes the `tone`'s
 * colour, gridlines and labels take the surface's, so a theme or dark mode restyles it with the rest
 * of the page. The plot is `role="img"` named by a numeric summary (how many points, from which label
 * to which, lowest, highest, latest), and every reading is also in a table that only assistive
 * technology reads — the picture is never the only way to the numbers. A pointer shows each reading
 * over its slot.
 *
 * Edge cases are part of the contract: no readings draw the empty line instead of an empty axis; one
 * reading is one bar or one dot; a series of zeros draws the zero line alone; a `null` reading is a
 * gap (no bar, a break in the line), never a zero. The plot's height is
 * `--flare-chart-card-plot-height` on the card.
 */
const props = withDefaults(defineProps<{
  /** Card heading; also names the plot for assistive technology. */
  title: string;
  /** The series in order. `value: null` is a label with no reading. */
  points: readonly FlareChartPoint[];
  /** `bar` for counts per period, `line` for a level over time. */
  kind?: "bar" | "line";
  /** Colour of the series. `brand` is the theme's primary colour. */
  tone?: "brand" | FlareTone;
  /** One line under the title — the period, the source. */
  description?: string;
  /** Unit of the readings, used in the summary and on hover; a lone symbol such as % also marks the scale. */
  unit?: string;
  /** Shown when there is no reading to draw. Default: the kit's "暂无数据". */
  emptyText?: string;
  /** Draw a placeholder of the plot's size while the host fetches the series. */
  loading?: boolean;
  /** `card` draws its own surface; `plain` sits inside a surface the host already drew. */
  appearance?: "card" | "plain";
  /** BCP-47 tag for the digits. Default: the kit's language. */
  locale?: string;
}>(), {
  kind: "bar",
  tone: "brand",
  description: undefined,
  unit: undefined,
  emptyText: undefined,
  loading: false,
  appearance: "card",
  locale: undefined,
});

const { t } = useFlareI18nOptional();
const kitLocale = useFlareLocaleOptional();
const locale = computed(() => props.locale ?? kitLocale.value);
const titleId = `flare-chart-card-${useId()}`;

const readings = computed(() => chartReadings(props.points));
const domain = computed(() => chartDomain(readings.value));
const slots = computed(() => chartSlots(props.points.length));
const bars = computed(() => (props.kind === "bar" ? chartBars(props.points, domain.value) : []));
const segments = computed(() => (props.kind === "line" ? chartSegments(props.points, domain.value) : []));
const linePath = computed(() => chartLinePath(segments.value));
const areaPath = computed(() => chartAreaPath(segments.value, domain.value));
const markers = computed(() => chartMarkers(segments.value).map((vertex) => ({
  index: vertex.index,
  d: `M${chartPathCoordinate(vertex.x)} ${chartPathCoordinate(vertex.y)} L${chartPathCoordinate(vertex.x)} ${chartPathCoordinate(vertex.y)}`,
})));

const full = (value: number) => withUnit(formatChartNumber(value, locale.value), props.unit);
const ticks = computed(() => chartTicks(domain.value).map((tick) => {
  const text = formatChartNumber(tick.value, locale.value, { compact: true });
  return { ...tick, text: props.unit && isSymbolUnit(props.unit) ? `${text}${props.unit}` : text };
}));
// The tick column is as wide as its widest label; the labels themselves are positioned on the gridlines.
const widestTick = computed(() => ticks.value.reduce((wide, tick) => (tick.text.length > wide.length ? tick.text : wide), ""));

const firstLabel = computed(() => props.points[0]?.label ?? "");
const lastLabel = computed(() => props.points[props.points.length - 1]?.label ?? "");

function readingText(value: number | null): string {
  return isReading(value) ? full(value) : t("chartCard.noValue");
}
function pointText(index: number): string {
  const point = props.points[index];
  return point ? t("chartCard.point", { label: point.label, value: readingText(point.value) }) : "";
}

const summary = computed(() => {
  const values = readings.value;
  if (props.points.length === 1) {
    return t("chartCard.summaryOne", { title: props.title, label: firstLabel.value, value: readingText(props.points[0].value) });
  }
  return t("chartCard.summary", {
    title: props.title,
    count: props.points.length,
    first: firstLabel.value,
    last: lastLabel.value,
    min: full(values.reduce((low, value) => Math.min(low, value))),
    max: full(values.reduce((high, value) => Math.max(high, value))),
    latest: full(values[values.length - 1]),
  });
});
</script>

<template>
  <section
    class="flare-chart-card"
    :class="[`flare-chart-card--${appearance}`, `flare-chart-card--${tone}`]"
    :data-kind="kind"
    :aria-labelledby="titleId"
    :aria-busy="loading || undefined"
  >
    <header class="flare-chart-card__head">
      <div class="flare-chart-card__heading">
        <h3 :id="titleId" class="flare-chart-card__title">{{ title }}</h3>
        <p v-if="description" class="flare-chart-card__description">{{ description }}</p>
      </div>
      <div v-if="$slots.extra" class="flare-chart-card__extra"><slot name="extra" /></div>
    </header>

    <div v-if="loading" class="flare-chart-card__state">
      <span class="flare-chart-card__placeholder" aria-hidden="true"></span>
      <span class="flare-chart-card__spoken">{{ t("chartCard.loading") }}</span>
    </div>
    <p v-else-if="!readings.length" class="flare-chart-card__state flare-chart-card__empty">
      {{ emptyText ?? t("chartCard.empty") }}
    </p>
    <template v-else>
      <!-- The plot reads left to right in every language, so its labels and scale do too. -->
      <div class="flare-chart-card__figure" dir="ltr">
        <div class="flare-chart-card__scale" aria-hidden="true">
          <span class="flare-chart-card__scale-sizer">{{ widestTick }}</span>
          <span
            v-for="tick in ticks"
            :key="tick.value"
            class="flare-chart-card__tick"
            :style="{ top: `${tick.y}%` }"
          >{{ tick.text }}</span>
        </div>
        <svg
          class="flare-chart-card__plot"
          viewBox="0 0 100 100"
          preserveAspectRatio="none"
          role="img"
          :aria-label="summary"
          focusable="false"
        >
          <g class="flare-chart-card__grid">
            <line
              v-for="tick in ticks"
              :key="tick.value"
              x1="0"
              x2="100"
              :y1="tick.y"
              :y2="tick.y"
              :class="{ 'is-zero': tick.value === 0 }"
            />
          </g>
          <g class="flare-chart-card__slots">
            <rect v-for="slot in slots" :key="slot.index" :x="slot.x" y="0" :width="slot.width" height="100">
              <title>{{ pointText(slot.index) }}</title>
            </rect>
          </g>
          <g v-if="kind === 'bar'" class="flare-chart-card__bars">
            <rect
              v-for="bar in bars"
              :key="bar.index"
              :x="bar.x"
              :y="bar.y"
              :width="bar.width"
              :height="bar.height"
            />
          </g>
          <g v-else class="flare-chart-card__line">
            <path v-if="areaPath" class="flare-chart-card__area" :d="areaPath" />
            <path v-if="linePath" class="flare-chart-card__stroke" :d="linePath" />
            <path v-for="marker in markers" :key="`halo-${marker.index}`" class="flare-chart-card__halo" :d="marker.d" />
            <path v-for="marker in markers" :key="`dot-${marker.index}`" class="flare-chart-card__dot" :d="marker.d" />
          </g>
        </svg>
        <div class="flare-chart-card__labels" :class="{ 'is-single': points.length === 1 }" aria-hidden="true">
          <span dir="auto">{{ firstLabel }}</span>
          <span v-if="points.length > 1" dir="auto">{{ lastLabel }}</span>
        </div>
      </div>
      <table class="flare-chart-card__spoken">
        <caption>{{ title }}</caption>
        <thead>
          <tr>
            <th scope="col">{{ t("chartCard.label") }}</th>
            <th scope="col">{{ t("chartCard.value") }}</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="(point, index) in points" :key="index">
            <th scope="row">{{ point.label }}</th>
            <td>{{ readingText(point.value) }}</td>
          </tr>
        </tbody>
      </table>
    </template>

    <footer v-if="$slots.footer" class="flare-chart-card__foot"><slot name="footer" /></footer>
  </section>
</template>

<style scoped>
.flare-chart-card {
  --flare-chart-card-plot-height: calc(var(--flare-size-layout-control-height-lg) * 3);
  --flare-chart-card-series: var(--flare-color-primary-text);
  position: relative;
  display: flex;
  flex-direction: column;
  gap: var(--flare-size-spacing-md);
  min-width: 0;
  box-sizing: border-box;
  color: var(--flare-color-text-primary);
}
.flare-chart-card--card {
  padding: var(--flare-size-spacing-lg);
  border: 1px solid var(--flare-color-border-secondary);
  border-radius: var(--flare-size-radius-card);
  background: var(--flare-color-bg-primary);
}
/* The series is a graphic the reader needs, so it takes the tone's text colour: the fill colours
   (--flare-color-primary and friends) fall under 3:1 on the dark surface in every brand. */
.flare-chart-card--info { --flare-chart-card-series: var(--flare-color-info-text); }
.flare-chart-card--success { --flare-chart-card-series: var(--flare-color-success-text); }
.flare-chart-card--warning { --flare-chart-card-series: var(--flare-color-warning-text); }
.flare-chart-card--danger { --flare-chart-card-series: var(--flare-color-error-text); }
.flare-chart-card--neutral { --flare-chart-card-series: var(--flare-color-text-secondary); }

.flare-chart-card__head {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: var(--flare-size-spacing-sm);
  min-width: 0;
}
.flare-chart-card__heading { min-width: 0; }
.flare-chart-card__title {
  margin: 0;
  font-size: var(--flare-text-body-font-size);
  font-weight: var(--flare-size-font-weight-semibold);
  line-height: var(--flare-text-body-line-height);
}
.flare-chart-card__description {
  margin: 0;
  color: var(--flare-color-text-tertiary);
  font-size: var(--flare-text-caption-font-size);
  line-height: var(--flare-text-caption-line-height);
}
.flare-chart-card__extra { display: flex; flex: none; align-items: center; gap: var(--flare-size-spacing-xs); }

/* Loading and empty keep the plot's height, so the card does not jump when the series arrives. */
.flare-chart-card__state {
  display: grid;
  place-items: center;
  min-height: var(--flare-chart-card-plot-height);
  margin: 0;
}
.flare-chart-card__placeholder {
  width: 100%;
  height: var(--flare-chart-card-plot-height);
  border-radius: var(--flare-size-radius-md);
  background: var(--flare-color-bg-secondary);
}
.flare-chart-card__empty {
  color: var(--flare-color-text-tertiary);
  font-size: var(--flare-text-caption-font-size);
}

/* Two columns — the scale, then the plot — and the labels under the plot only. The top padding is room
   for the highest tick, which is centred on the top gridline. */
.flare-chart-card__figure {
  display: grid;
  grid-template-columns: auto minmax(0, 1fr);
  grid-template-rows: var(--flare-chart-card-plot-height) auto;
  column-gap: var(--flare-size-spacing-sm);
  row-gap: var(--flare-size-spacing-xs);
  padding-block-start: var(--flare-size-spacing-2sm);
  color: var(--flare-color-text-tertiary);
  font-size: var(--flare-text-caption-font-size);
  line-height: var(--flare-text-caption-line-height);
  font-variant-numeric: tabular-nums;
}
.flare-chart-card__scale { position: relative; grid-row: 1; grid-column: 1; text-align: end; }
.flare-chart-card__scale-sizer { display: block; height: 0; overflow: hidden; visibility: hidden; white-space: nowrap; }
.flare-chart-card__tick { position: absolute; inset-inline-end: 0; transform: translateY(-50%); white-space: nowrap; }
.flare-chart-card__plot {
  display: block;
  grid-row: 1;
  grid-column: 2;
  width: 100%;
  height: 100%;
  overflow: visible;
}
.flare-chart-card__labels {
  display: flex;
  grid-row: 2;
  grid-column: 2;
  justify-content: space-between;
  gap: var(--flare-size-spacing-sm);
  min-width: 0;
}
.flare-chart-card__labels.is-single { justify-content: center; }
.flare-chart-card__labels span { min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }

.flare-chart-card__grid line {
  stroke: var(--flare-color-border-secondary);
  stroke-width: 1;
  vector-effect: non-scaling-stroke;
}
.flare-chart-card__grid line.is-zero { stroke: var(--flare-color-border-primary); }
.flare-chart-card__slots rect { fill: transparent; }
@media (hover: hover) {
  .flare-chart-card__slots rect:hover { fill: var(--flare-color-bg-hover); }
}
.flare-chart-card__bars rect { fill: var(--flare-chart-card-series); pointer-events: none; }
.flare-chart-card__line path { fill: none; pointer-events: none; vector-effect: non-scaling-stroke; }
.flare-chart-card__line .flare-chart-card__area {
  fill: var(--flare-chart-card-series);
  fill-opacity: var(--flare-opacity-tint-weak);
  stroke: none;
}
.flare-chart-card__stroke {
  stroke: var(--flare-chart-card-series);
  stroke-width: 2;
  stroke-linecap: round;
  stroke-linejoin: round;
}
/* A zero-length round-capped stroke is a dot that stays round however the plot is stretched. */
.flare-chart-card__halo { stroke: var(--flare-color-bg-primary); stroke-width: 10; stroke-linecap: round; }
.flare-chart-card__dot { stroke: var(--flare-chart-card-series); stroke-width: 6; stroke-linecap: round; }
.flare-chart-card--plain .flare-chart-card__halo { stroke: transparent; }

.flare-chart-card__foot {
  color: var(--flare-color-text-tertiary);
  font-size: var(--flare-text-caption-font-size);
  line-height: var(--flare-text-caption-line-height);
}

/* Heard, not seen: the summary names the plot, this table carries every reading. */
.flare-chart-card__spoken {
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
