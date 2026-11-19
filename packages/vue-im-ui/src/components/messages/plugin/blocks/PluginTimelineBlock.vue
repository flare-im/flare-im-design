<script setup lang="ts">
import { computed } from "vue";
import FlareTag from "../../../general/FlareTag.vue";
import { useFlareI18nOptional } from "../../../../shared/i18n/useFlareI18n";
import { flareServerNowMs } from "../../../../shared/server-clock";
import {
  flarePluginBadgeTone,
  flarePluginDateTime,
  flarePluginInstant,
  flarePluginIsoTime,
  type FlarePluginStrings,
  type FlarePluginTimelineBlock,
} from "../../../../shared/contracts/plugin-ui";

// Dated items (vocabulary 2): each its time (as plugin time blocks write it), title, detail and status tag, on a
// rail, in the plugin's order. No item: the empty text.
const props = defineProps<{
  block: FlarePluginTimelineBlock;
  strings: Pick<FlarePluginStrings, "dateTime" | "dateTimeYear">;
  formatTime?: (ms: number) => string;
}>();
const { t } = useFlareI18nOptional();
const items = computed(() => {
  const now = flareServerNowMs();
  // An item whose instant no kit can draw is left out, as in every kit.
  return props.block.items
    .filter((item) => flarePluginInstant(item.atMs) !== undefined)
    .map((item) => ({
      ...item,
      time: props.formatTime?.(item.atMs) ?? flarePluginDateTime(item.atMs, now, props.strings),
    }));
});
</script>

<template>
  <p v-if="!items.length" class="flare-plugin-timeline__empty" data-timeline-empty="true">{{ block.emptyText || t("pluginView.empty") }}</p>
  <ol v-else class="flare-plugin-timeline">
    <li v-for="(item, index) in items" :key="index" class="flare-plugin-timeline__item">
      <span class="flare-plugin-timeline__dot" aria-hidden="true" />
      <div class="flare-plugin-timeline__body">
        <div class="flare-plugin-timeline__head">
          <span class="flare-plugin-timeline__title">{{ item.title }}</span>
          <FlareTag v-if="item.status" :label="item.status.text" :tone="flarePluginBadgeTone(item.status.tone)" />
        </div>
        <p v-if="item.detail" class="flare-plugin-timeline__detail">{{ item.detail }}</p>
        <time class="flare-plugin-timeline__time" :datetime="flarePluginIsoTime(item.atMs)">{{ item.time }}</time>
      </div>
    </li>
  </ol>
</template>

<style scoped>
.flare-plugin-timeline { display: grid; margin: 0; padding: 0; list-style: none; min-width: 0; }
.flare-plugin-timeline__item { position: relative; display: grid; grid-template-columns: var(--flare-size-spacing-md) minmax(0, 1fr); gap: var(--flare-size-spacing-sm); padding-bottom: var(--flare-size-spacing-md); }
.flare-plugin-timeline__item:not(:last-child)::before {
  content: "";
  position: absolute;
  top: var(--flare-size-spacing-md);
  bottom: 0;
  left: calc(var(--flare-size-spacing-md) / 2 - 1px);
  border-left: 2px solid var(--flare-color-border-secondary);
}
.flare-plugin-timeline__dot {
  width: var(--flare-size-spacing-sm);
  height: var(--flare-size-spacing-sm);
  margin: var(--flare-size-spacing-3xs) auto 0;
  border-radius: var(--flare-size-radius-full);
  background: var(--flare-color-primary);
}
.flare-plugin-timeline__body { display: grid; gap: var(--flare-size-spacing-3xs); min-width: 0; }
.flare-plugin-timeline__head { display: flex; flex-wrap: wrap; align-items: center; gap: var(--flare-size-spacing-xs); min-width: 0; }
.flare-plugin-timeline__title { font-size: var(--flare-size-font-size-md); color: var(--flare-color-text-primary); overflow-wrap: anywhere; }
.flare-plugin-timeline__detail { margin: 0; font-size: var(--flare-size-font-size-sm); color: var(--flare-color-text-secondary); overflow-wrap: anywhere; }
.flare-plugin-timeline__time { font-size: var(--flare-size-font-size-xs); color: var(--flare-color-text-tertiary); font-variant-numeric: tabular-nums; }
.flare-plugin-timeline__empty { margin: 0; font-size: var(--flare-size-font-size-md); color: var(--flare-color-text-tertiary); }
</style>
