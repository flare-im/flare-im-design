<script setup lang="ts">
import MsgIcon from "./MsgIcon.vue";
export interface FlareVoteOption { text: string; pct?: number | null }
// Presentational — emits `select` with the chosen option + index; the host casts
// the actual vote.
withDefaults(
  defineProps<{ title?: string; options?: FlareVoteOption[]; total?: string; readOnly?: boolean }>(),
  { title: "vote", options: () => [], total: "", readOnly: false },
);
const emit = defineEmits<{ (e: "select", option: FlareVoteOption, index: number): void }>();
function percent(value: number | null | undefined) {
  return typeof value === "number" && Number.isFinite(value) ? Math.min(100, Math.max(0, value)) : null;
}
</script>
<template>
  <div class="fm-vote">
    <div class="vt"><MsgIcon name="poll" :size="16" />{{ title }}</div>
    <component :is="readOnly ? 'div' : 'button'" v-for="(o, i) in options" :key="i" class="opt"
      :type="readOnly ? undefined : 'button'" @click="!readOnly && emit('select', o, i)">
      <div v-if="percent(o.pct) !== null" class="bar" :style="{ width: percent(o.pct) + '%' }" aria-hidden="true" />
      <span class="t">{{ o.text }}</span><span v-if="percent(o.pct) !== null" class="p">{{ percent(o.pct) }}%</span>
    </component>
    <div v-if="total" class="total">{{ total }}</div>
  </div>
</template>
<style scoped>
.fm-vote { display: flex; flex-direction: column; gap: var(--flare-size-spacing-sm); min-width: 0; width: 100%; color: inherit; }
.vt { display: flex; align-items: center; gap: 6px; font-weight: 600; font-size: var(--flare-size-font-size-lg); overflow-wrap: anywhere; }
.opt { position: relative; display: flex; gap: var(--flare-size-spacing-sm); align-items: center; min-height: 48px; padding: var(--flare-size-spacing-xs) var(--flare-size-spacing-sm); border: none; border-radius: var(--flare-size-radius-md); background: color-mix(in srgb, currentColor 8%, transparent); color: inherit; overflow: hidden; text-align: left; }
button.opt { cursor: pointer; }
button.opt:focus-visible { outline: 2px solid currentColor; outline-offset: 2px; }
.bar { position: absolute; left: 0; top: 0; bottom: 0; background: color-mix(in srgb, var(--flare-color-primary) 16%, transparent); }
.t { position: relative; flex: 1; min-width: 0; font-size: var(--flare-size-font-size-md); overflow-wrap: anywhere; }
.p { position: relative; flex: none; font-size: var(--flare-size-font-size-sm); font-variant-numeric: tabular-nums; }
.total { font-size: var(--flare-size-font-size-sm); opacity: 0.8; }
</style>
