<script setup lang="ts">
/**
 * A tag — a short status or category label on a table row or a detail line: frozen, in review,
 * text / image, owner. `tone` says what the state means (danger for blocked, success for active);
 * the words carry the meaning and the colour only repeats it, so a tag reads the same to someone
 * who cannot tell the tones apart, and a screen reader reads just the words.
 *
 * It is not a control: no hover, no focus, no click. A filter a person toggles is FilterTabs; an
 * action is a Button. Every tone writes its tone's text colour on a 6% tint of the same tone mixed
 * into the primary surface, which keeps 4.5:1 in every brand and both modes (asserted by the tests,
 * lowest 4.64:1 for light warning; at 8% the painted light warning tag is 4.49:1, which axe caught).
 */
import type { FlareTone } from "../../shared/contracts/tone";

withDefaults(
  defineProps<{
    /** The words. Short: a state or a category, not a sentence. */
    label: string;
    /** What the state means. `neutral` (the default) is a category with no judgement. */
    tone?: FlareTone;
    /** A leading dot, for a live state (online, running) rather than a category. */
    dot?: boolean;
    /** Draw the label in the monospaced face — an identifier, a code, a version. */
    monospace?: boolean;
  }>(),
  { tone: "neutral", dot: false, monospace: false },
);
</script>

<template>
  <span class="flare-tag" :class="[`flare-tag--${tone}`, { 'is-monospace': monospace }]" :data-tone="tone">
    <span v-if="dot" class="flare-tag__dot" aria-hidden="true" />
    <span class="flare-tag__label">{{ label }}</span>
  </span>
</template>

<style scoped>
.flare-tag {
  display: inline-flex;
  align-items: center;
  gap: var(--flare-size-spacing-xs);
  max-width: 100%;
  min-width: 0;
  padding: 0 var(--flare-size-spacing-2xs);
  box-sizing: border-box;
  border-radius: var(--flare-size-radius-sm);
  color: var(--flare-tag-ink);
  background: var(--flare-tag-surface);
  /* A hairline of the ink gives the tag its edge on any surface (a white row, a grey panel) without
     touching the words' contrast; forced colours replace it with a real border below. */
  box-shadow: inset 0 0 0 1px color-mix(in srgb, var(--flare-tag-ink) 18%, transparent);
  font-size: var(--flare-text-caption-font-size);
  font-weight: var(--flare-size-font-weight-medium);
  line-height: var(--flare-text-caption-line-height);
  vertical-align: middle;
  white-space: nowrap;
}
.flare-tag--neutral {
  --flare-tag-ink: var(--flare-color-text-secondary);
  --flare-tag-surface: var(--flare-color-bg-tertiary);
}
.flare-tag--info {
  --flare-tag-ink: var(--flare-color-info-text);
  --flare-tag-surface: color-mix(in srgb, var(--flare-color-info) 6%, var(--flare-color-bg-primary));
}
.flare-tag--success {
  --flare-tag-ink: var(--flare-color-success-text);
  --flare-tag-surface: color-mix(in srgb, var(--flare-color-success) 6%, var(--flare-color-bg-primary));
}
.flare-tag--warning {
  --flare-tag-ink: var(--flare-color-warning-text);
  --flare-tag-surface: color-mix(in srgb, var(--flare-color-warning) 6%, var(--flare-color-bg-primary));
}
.flare-tag--danger {
  --flare-tag-ink: var(--flare-color-error-text);
  --flare-tag-surface: color-mix(in srgb, var(--flare-color-error) 6%, var(--flare-color-bg-primary));
}
.flare-tag__dot {
  flex: none;
  width: var(--flare-size-spacing-2xs);
  height: var(--flare-size-spacing-2xs);
  border-radius: var(--flare-size-radius-full);
  background: currentColor;
}
.flare-tag__label {
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
}
.flare-tag.is-monospace .flare-tag__label {
  font-family: var(--flare-component-font-family-mono);
  font-weight: var(--flare-size-font-weight-regular);
}
@media (forced-colors: active) {
  .flare-tag { border: 1px solid CanvasText; }
}
</style>
