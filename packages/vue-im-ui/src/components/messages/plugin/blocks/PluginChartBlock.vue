<script setup lang="ts">
import { computed } from "vue";
import {
  CHART_VIEWBOX,
  chartDomain,
  chartLinePath,
  chartPathCoordinate,
  chartSegments,
  chartSlots,
  chartTicks,
  chartY,
} from "../../../data/chart-geometry";
import { useFlareI18nOptional } from "../../../../shared/i18n/useFlareI18n";
import {
  flarePluginChartHasPoints,
  flarePluginDonutSlices,
  type FlarePluginChartBlock,
} from "../../../../shared/contracts/plugin-ui";

// A chart (vocabulary 2): bars, lines or a donut drawn as plain SVG from kit tokens, on the kit's chart geometry
// (data/chart-geometry.ts, shared with ChartCard), no chart library. Up to 3 series take the brand, info and
// success colours in order; a donut's slices cycle through the kit's status colours. The plot is an image named by
// the series; every point is also in a table only assistive technology reads. No point at all: the empty text.
const props = defineProps<{ block: FlarePluginChartBlock }>();
const { t } = useFlareI18nOptional();
const SERIES = ["primary", "info", "success"] as const;
const SLICES = ["primary", "info", "success", "warning", "important", "pinned"] as const;
/** A bar takes this share of its slot, split between the series. */
const BAR_FILL = 0.64;

const hasPoints = computed(() => flarePluginChartHasPoints(props.block));
const series = computed(() => props.block.series.slice(0, props.block.chartKind === "donut" ? 1 : 3));
/** The labels along the axis: the longest series' (series share their labels by position). */
const labels = computed(() =>
  series.value.reduce<string[]>((longest, s) => (s.points.length > longest.length ? s.points.map((p) => p.label) : longest), []),
);
const domain = computed(() =>
  chartDomain(series.value.flatMap((s) => s.points.map((p) => p.value)).filter((v) => Number.isFinite(v))),
);
const slots = computed(() => chartSlots(labels.value.length));
const ticks = computed(() => chartTicks(domain.value));
const bars = computed(() => {
  if (props.block.chartKind !== "bar") return [];
  const count = series.value.length || 1;
  const zero = chartY(0, domain.value);
  return series.value.flatMap((s, si) =>
    s.points.flatMap((point, index) => {
      const slot = slots.value[index];
      if (!slot || !Number.isFinite(point.value)) return [];
      const width = Math.min((slot.width * BAR_FILL) / count, 12);
      const top = chartY(point.value, domain.value);
      const left = slot.center - (width * count) / 2 + width * si;
      return [{ key: `${si}-${index}`, series: si, x: left, y: Math.min(top, zero), width, height: Math.abs(zero - top) }];
    }),
  );
});
const lines = computed(() =>
  props.block.chartKind !== "line"
    ? []
    : series.value.map((s, si) => ({
        series: si,
        d: chartLinePath(
          chartSegments(
            labels.value.map((label, index) => ({ label, value: s.points[index]?.value ?? null })),
            domain.value,
          ),
        ),
        dots: s.points.length === 1
          ? [{ x: slots.value[0]?.center ?? CHART_VIEWBOX / 2, y: chartY(s.points[0].value, domain.value) }]
          : [],
      })),
);
// A donut on a circle of circumference 100: each slice a dash of its sweep, turned to start at the top.
const RADIUS = 100 / (2 * Math.PI);
const slices = computed(() =>
  props.block.chartKind !== "donut"
    ? []
    : flarePluginDonutSlices(series.value[0]?.points ?? []).map((slice) => ({
        ...slice,
        colour: SLICES[slice.index % SLICES.length],
        dash: `${chartPathCoordinate(slice.sweep * 100)} ${chartPathCoordinate(100 - slice.sweep * 100)}`,
        offset: chartPathCoordinate(25 - slice.start * 100),
      })),
);
const legend = computed(() =>
  props.block.chartKind === "donut"
    ? (series.value[0]?.points ?? []).map((point, index) => ({ key: `p${index}`, label: point.label, text: point.text, colour: SLICES[index % SLICES.length] }))
    : series.value.length > 1
      ? series.value.map((s, si) => ({ key: `s${si}`, label: s.label ?? "", text: "", colour: SERIES[si] }))
      : [],
);
const summary = computed(() =>
  series.value
    .map((s) => [s.label, ...s.points.map((p) => `${p.label} ${p.text}`)].filter(Boolean).join(", "))
    .join("; "),
);
</script>

<template>
  <p v-if="!hasPoints" class="flare-plugin-chart__empty" data-chart-empty="true">
    {{ block.emptyText || t("pluginView.empty") }}
  </p>
  <figure v-else class="flare-plugin-chart" :data-chart-kind="block.chartKind">
    <div v-if="block.chartKind === 'donut'" class="flare-plugin-chart__donut">
      <svg viewBox="0 0 42 42" role="img" :aria-label="summary" focusable="false">
        <circle class="flare-plugin-chart__track" cx="21" cy="21" :r="RADIUS" />
        <circle
          v-for="slice in slices"
          :key="slice.index"
          class="flare-plugin-chart__slice"
          :data-colour="slice.colour"
          cx="21"
          cy="21"
          :r="RADIUS"
          :stroke-dasharray="slice.dash"
          :stroke-dashoffset="slice.offset"
        />
      </svg>
    </div>
    <div v-else class="flare-plugin-chart__figure" dir="ltr">
      <svg
        class="flare-plugin-chart__plot"
        :viewBox="`0 0 ${CHART_VIEWBOX} ${CHART_VIEWBOX}`"
        preserveAspectRatio="none"
        role="img"
        :aria-label="summary"
        focusable="false"
      >
        <line
          v-for="tick in ticks"
          :key="tick.value"
          class="flare-plugin-chart__grid"
          :class="{ 'is-zero': tick.value === 0 }"
          x1="0"
          :x2="CHART_VIEWBOX"
          :y1="tick.y"
          :y2="tick.y"
        />
        <rect
          v-for="bar in bars"
          :key="bar.key"
          class="flare-plugin-chart__bar"
          :data-colour="SERIES[bar.series]"
          :x="bar.x"
          :y="bar.y"
          :width="bar.width"
          :height="bar.height"
        />
        <template v-for="line in lines" :key="line.series">
          <path v-if="line.d" class="flare-plugin-chart__line" :data-colour="SERIES[line.series]" :d="line.d" />
          <path
            v-for="(dot, index) in line.dots"
            :key="index"
            class="flare-plugin-chart__dot"
            :data-colour="SERIES[line.series]"
            :d="`M${chartPathCoordinate(dot.x)} ${chartPathCoordinate(dot.y)} L${chartPathCoordinate(dot.x)} ${chartPathCoordinate(dot.y)}`"
          />
        </template>
      </svg>
      <div class="flare-plugin-chart__labels" aria-hidden="true">
        <span dir="auto">{{ labels[0] }}</span>
        <span v-if="labels.length > 1" dir="auto">{{ labels[labels.length - 1] }}</span>
      </div>
    </div>
    <ul v-if="legend.length" class="flare-plugin-chart__legend" aria-hidden="true">
      <li v-for="item in legend" :key="item.key">
        <span class="flare-plugin-chart__swatch" :data-colour="item.colour" />
        <span class="flare-plugin-chart__legend-label">{{ item.label }}</span>
        <span v-if="item.text" class="flare-plugin-chart__legend-value">{{ item.text }}</span>
      </li>
    </ul>
    <table class="flare-plugin-chart__spoken">
      <tbody>
        <template v-for="(s, si) in series" :key="si">
          <tr v-for="(point, index) in s.points" :key="`${si}-${index}`">
            <th scope="row">{{ [s.label, point.label].filter(Boolean).join(" · ") }}</th>
            <td>{{ point.text }}</td>
          </tr>
        </template>
      </tbody>
    </table>
  </figure>
</template>

<style scoped>
.flare-plugin-chart {
  display: grid;
  gap: var(--flare-size-spacing-sm);
  min-width: 0;
  margin: 0;
}
.flare-plugin-chart [data-colour="primary"] { --flare-plugin-chart-colour: var(--flare-color-primary); }
.flare-plugin-chart [data-colour="info"] { --flare-plugin-chart-colour: var(--flare-color-info); }
.flare-plugin-chart [data-colour="success"] { --flare-plugin-chart-colour: var(--flare-color-success); }
.flare-plugin-chart [data-colour="warning"] { --flare-plugin-chart-colour: var(--flare-color-warning); }
.flare-plugin-chart [data-colour="important"] { --flare-plugin-chart-colour: var(--flare-color-important); }
.flare-plugin-chart [data-colour="pinned"] { --flare-plugin-chart-colour: var(--flare-color-pinned); }
.flare-plugin-chart__figure { display: grid; gap: var(--flare-size-spacing-2xs); min-width: 0; }
.flare-plugin-chart__plot {
  display: block;
  width: 100%;
  height: calc(var(--flare-size-layout-control-height-lg) * 3);
  overflow: visible;
}
.flare-plugin-chart__grid { stroke: var(--flare-color-border-secondary); stroke-width: 1; vector-effect: non-scaling-stroke; }
.flare-plugin-chart__grid.is-zero { stroke: var(--flare-color-border-primary); }
.flare-plugin-chart__bar { fill: var(--flare-plugin-chart-colour); }
.flare-plugin-chart__line { fill: none; stroke: var(--flare-plugin-chart-colour); stroke-width: 2; stroke-linejoin: round; vector-effect: non-scaling-stroke; }
.flare-plugin-chart__dot { stroke: var(--flare-plugin-chart-colour); stroke-width: 6; stroke-linecap: round; vector-effect: non-scaling-stroke; }
.flare-plugin-chart__labels {
  display: flex;
  justify-content: space-between;
  gap: var(--flare-size-spacing-sm);
  color: var(--flare-color-text-tertiary);
  font-size: var(--flare-size-font-size-xs);
}
.flare-plugin-chart__donut { display: flex; justify-content: center; }
.flare-plugin-chart__donut svg { width: min(100%, calc(var(--flare-size-layout-control-height-lg) * 4)); height: auto; }
.flare-plugin-chart__track { fill: none; stroke: var(--flare-color-bg-tertiary); stroke-width: 6; }
.flare-plugin-chart__slice { fill: none; stroke: var(--flare-plugin-chart-colour); stroke-width: 6; }
.flare-plugin-chart__legend {
  display: flex;
  flex-wrap: wrap;
  gap: var(--flare-size-spacing-xs) var(--flare-size-spacing-md);
  margin: 0;
  padding: 0;
  list-style: none;
  font-size: var(--flare-size-font-size-sm);
  color: var(--flare-color-text-secondary);
}
.flare-plugin-chart__legend li { display: inline-flex; align-items: center; gap: var(--flare-size-spacing-2xs); min-width: 0; }
.flare-plugin-chart__swatch {
  flex: none;
  width: var(--flare-size-spacing-sm);
  height: var(--flare-size-spacing-sm);
  border-radius: var(--flare-size-radius-sm);
  background: var(--flare-plugin-chart-colour);
}
.flare-plugin-chart__legend-value { color: var(--flare-color-text-primary); font-variant-numeric: tabular-nums; }
.flare-plugin-chart__empty { margin: 0; font-size: var(--flare-size-font-size-md); color: var(--flare-color-text-tertiary); }
.flare-plugin-chart__spoken {
  position: absolute;
  width: 1px;
  height: 1px;
  overflow: hidden;
  clip-path: inset(50%);
  white-space: nowrap;
}
@media (forced-colors: active) {
  .flare-plugin-chart__bar, .flare-plugin-chart__swatch { fill: CanvasText; background: CanvasText; }
  .flare-plugin-chart__line, .flare-plugin-chart__slice, .flare-plugin-chart__dot { stroke: CanvasText; }
}
</style>
