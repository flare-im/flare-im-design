<script setup lang="ts">
import { computed, onBeforeUnmount, ref, watch } from "vue";
import {
  flarePluginCountdown,
  flarePluginTimeText,
  type FlarePluginStrings,
  type FlarePluginTimeBlock,
} from "../../../shared/contracts/plugin-ui";
import { flareServerNowMs } from "../../../shared/server-clock";

// An instant or a range in the device's zone, optionally counting down to `atMs`: every second under an
// hour, every minute otherwise, and "closed" once it has passed (spec/plugin-view-vectors.json → time,
// countdown). `atMs` is the server's clock, so now is the server's too (spec/server-clock-vectors.json).
const props = defineProps<{ block: FlarePluginTimeBlock; strings: FlarePluginStrings }>();

const now = ref(flareServerNowMs());
const text = computed(() => flarePluginTimeText(props.block.atMs, props.block.endMs, now.value, props.strings));
const countdown = computed(() => (props.block.countdown ? flarePluginCountdown(props.block.atMs, now.value, props.strings) : null));

let timer: ReturnType<typeof setTimeout> | undefined;
function schedule(): void {
  clearTimeout(timer);
  timer = undefined;
  const next = countdown.value?.refreshMs;
  if (next) timer = setTimeout(() => { now.value = flareServerNowMs(); schedule(); }, next);
}
watch(() => [props.block.atMs, props.block.countdown], () => { now.value = flareServerNowMs(); schedule(); }, { immediate: true });
onBeforeUnmount(() => clearTimeout(timer));
</script>

<template>
  <div class="flare-plugin-time">
    <span v-if="block.label" class="flare-plugin-time__label">{{ block.label }}</span>
    <span class="flare-plugin-time__text" data-time-text="true">{{ text }}</span>
    <span
      v-if="countdown"
      class="flare-plugin-time__countdown"
      :class="{ 'is-passed': countdown.refreshMs === null }"
      data-time-countdown="true"
    >{{ countdown.text }}</span>
  </div>
</template>

<style scoped>
.flare-plugin-time { display: flex; flex-wrap: wrap; align-items: baseline; column-gap: var(--flare-size-spacing-sm); row-gap: var(--flare-size-spacing-3xs); min-width: 0; font-size: var(--flare-size-font-size-md); }
.flare-plugin-time__label { color: var(--flare-color-text-secondary); }
.flare-plugin-time__text { color: var(--flare-color-text-primary); font-variant-numeric: tabular-nums; }
.flare-plugin-time__countdown { color: var(--flare-color-warning-text); font-variant-numeric: tabular-nums; }
.flare-plugin-time__countdown.is-passed { color: var(--flare-color-text-tertiary); }
</style>
