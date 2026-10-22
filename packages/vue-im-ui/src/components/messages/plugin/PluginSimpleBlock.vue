<script setup lang="ts">
import FlareTag from "../../general/FlareTag.vue";
import type {
  FlarePluginDividerBlock,
  FlarePluginFieldsBlock,
  FlarePluginNoteBlock,
  FlarePluginProgressBlock,
  FlarePluginStatusBlock,
} from "../../../shared/contracts/plugin-ui";

// The blocks without state of their own: fields (label/value rows), status (a kit Tag), progress (a bar
// and value/total), divider and note (a tinted line in the *Text tone).
defineProps<{ block: FlarePluginFieldsBlock | FlarePluginStatusBlock | FlarePluginProgressBlock | FlarePluginDividerBlock | FlarePluginNoteBlock }>();
const clamp = (n: number) => Math.min(100, Math.max(0, n));
</script>

<template>
  <dl v-if="block.kind === 'fields'" class="flare-plugin-fields">
    <div v-for="(field, index) in block.fields" :key="index" class="flare-plugin-fields__row">
      <dt>{{ field.label }}</dt>
      <dd>{{ field.value }}</dd>
    </div>
  </dl>
  <div v-else-if="block.kind === 'status'" class="flare-plugin-status">
    <span v-if="block.label" class="flare-plugin-status__label">{{ block.label }}</span>
    <FlareTag :label="block.text" :tone="block.tone" :data-status-tone="block.tone" />
  </div>
  <div v-else-if="block.kind === 'progress'" class="flare-plugin-progress">
    <div class="flare-plugin-progress__head">
      <span v-if="block.label" class="flare-plugin-progress__label">{{ block.label }}</span>
      <span class="flare-plugin-progress__value" data-progress-text="true">{{ block.value }}/{{ block.total }}</span>
    </div>
    <div
      class="flare-plugin-progress__track"
      role="progressbar"
      :aria-label="block.label"
      :aria-valuenow="block.value"
      aria-valuemin="0"
      :aria-valuemax="block.total"
      :aria-valuetext="`${block.value}/${block.total}`"
    >
      <span class="flare-plugin-progress__fill" :style="{ width: `${clamp(block.percent)}%` }" data-progress-fill="true" />
    </div>
  </div>
  <hr v-else-if="block.kind === 'divider'" class="flare-plugin-divider" />
  <p v-else-if="block.kind === 'note'" class="flare-plugin-note" :class="`is-${block.tone ?? 'neutral'}`" :data-note-tone="block.tone ?? 'neutral'">{{ block.text }}</p>
</template>

<style scoped>
.flare-plugin-fields { display: grid; gap: var(--flare-size-spacing-xs); margin: 0; font-size: var(--flare-size-font-size-md); }
.flare-plugin-fields__row { display: grid; grid-template-columns: minmax(4em, 1fr) minmax(0, 2fr); gap: var(--flare-size-spacing-md); }
.flare-plugin-fields dt { color: var(--flare-color-text-secondary); }
.flare-plugin-fields dd { margin: 0; color: var(--flare-color-text-primary); overflow-wrap: anywhere; }
.flare-plugin-status { display: flex; align-items: center; gap: var(--flare-size-spacing-sm); min-width: 0; font-size: var(--flare-size-font-size-md); }
.flare-plugin-status__label { color: var(--flare-color-text-secondary); }
.flare-plugin-progress { display: grid; gap: var(--flare-size-spacing-xs); min-width: 0; font-size: var(--flare-size-font-size-md); }
.flare-plugin-progress__head { display: flex; justify-content: space-between; gap: var(--flare-size-spacing-sm); }
.flare-plugin-progress__label { color: var(--flare-color-text-secondary); }
.flare-plugin-progress__value { color: var(--flare-color-text-primary); font-variant-numeric: tabular-nums; }
.flare-plugin-progress__track { height: var(--flare-size-spacing-2xs); overflow: hidden; border-radius: var(--flare-size-radius-full); background: var(--flare-color-bg-tertiary); }
.flare-plugin-progress__fill { display: block; height: 100%; border-radius: inherit; background: var(--flare-color-primary); transition: width var(--flare-component-motion-fast); }
.flare-plugin-divider { width: 100%; margin: 0; border: 0; border-top: 1px solid var(--flare-color-border-secondary); }
.flare-plugin-note {
  margin: 0;
  padding: var(--flare-size-spacing-xs) var(--flare-size-spacing-sm);
  border-radius: var(--flare-size-radius-md);
  font-size: var(--flare-size-font-size-md);
  overflow-wrap: anywhere;
  color: var(--flare-plugin-note-ink);
  background: var(--flare-plugin-note-surface);
}
.flare-plugin-note.is-neutral { --flare-plugin-note-ink: var(--flare-color-text-secondary); --flare-plugin-note-surface: var(--flare-color-bg-tertiary); }
.flare-plugin-note.is-info { --flare-plugin-note-ink: var(--flare-color-info-text); --flare-plugin-note-surface: color-mix(in srgb, var(--flare-color-info) 6%, var(--flare-color-bg-primary)); }
.flare-plugin-note.is-success { --flare-plugin-note-ink: var(--flare-color-success-text); --flare-plugin-note-surface: color-mix(in srgb, var(--flare-color-success) 6%, var(--flare-color-bg-primary)); }
.flare-plugin-note.is-warning { --flare-plugin-note-ink: var(--flare-color-warning-text); --flare-plugin-note-surface: color-mix(in srgb, var(--flare-color-warning) 6%, var(--flare-color-bg-primary)); }
.flare-plugin-note.is-danger { --flare-plugin-note-ink: var(--flare-color-error-text); --flare-plugin-note-surface: color-mix(in srgb, var(--flare-color-error) 6%, var(--flare-color-bg-primary)); }
@media (prefers-reduced-motion: reduce) {
  .flare-plugin-progress__fill { transition: none; }
}
@media (forced-colors: active) {
  .flare-plugin-note { border: 1px solid CanvasText; }
}
</style>
