<script setup lang="ts">
import FlareMetricTile from "../../../data/FlareMetricTile.vue";
import {
  flarePluginBadgeTone,
  flarePluginTrendDirection,
  type FlarePluginStatsBlock,
} from "../../../../shared/contracts/plugin-ui";

// Figures side by side (vocabulary 2): each a kit MetricTile on the view's surface, its value the text PluginView
// already formatted, its trend the plugin's text with its direction. A tone tints the value; a trend is reported,
// never judged (the plugin did not say whether up is good).
defineProps<{ block: FlarePluginStatsBlock }>();
</script>

<template>
  <div class="flare-plugin-stats" :style="{ '--flare-plugin-stats-count': String(block.items.length) }">
    <FlareMetricTile
      v-for="(item, index) in block.items"
      :key="index"
      class="flare-plugin-stats__item"
      appearance="plain"
      :label="item.label"
      :value="item.value"
      :trend-text="item.trend?.text"
      :trend-direction="flarePluginTrendDirection(item.trend?.direction)"
      :data-stat-tone="item.tone ? flarePluginBadgeTone(item.tone) : undefined"
    />
  </div>
</template>

<style scoped>
.flare-plugin-stats {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(min(100%, 6.5rem), 1fr));
  gap: var(--flare-size-spacing-md);
  min-width: 0;
}
/* R10: a figure in the card is 18/600, tabular. */
.flare-plugin-stats__item :deep(.flare-metric-tile__number) {
  font-size: var(--flare-size-font-size-3xl);
  font-weight: var(--flare-size-font-weight-semibold);
  font-variant-numeric: tabular-nums;
}
.flare-plugin-stats__item[data-stat-tone="info"] :deep(.flare-metric-tile__number) { color: var(--flare-color-info-text); }
.flare-plugin-stats__item[data-stat-tone="success"] :deep(.flare-metric-tile__number) { color: var(--flare-color-success-text); }
.flare-plugin-stats__item[data-stat-tone="warning"] :deep(.flare-metric-tile__number) { color: var(--flare-color-warning-text); }
.flare-plugin-stats__item[data-stat-tone="danger"] :deep(.flare-metric-tile__number) { color: var(--flare-color-error-text); }
</style>
