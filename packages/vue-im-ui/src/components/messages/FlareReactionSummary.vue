<script setup lang="ts">
import { NIcon } from "naive-ui";
import { HappyOutline } from "../../shared/icon-glyphs";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import type { FlareReactionGroup } from "../../shared/contracts";

defineProps<{
  reactions: FlareReactionGroup[];
  /** Hide the trailing "add reaction" affordance. */
  hideAdd?: boolean;
  /** Render counts without toggle controls. */
  readOnly?: boolean;
}>();
const emit = defineEmits<{
  (e: "toggle", emoji: string): void;
  (e: "add"): void;
}>();

const { t } = useFlareI18n();

function tooltip(group: FlareReactionGroup): string {
  if (!group.users || group.users.length === 0) return "";
  return group.users.join("、");
}
</script>

<template>
  <div v-if="reactions.length || (!hideAdd && !readOnly)" class="flare-reaction-summary">
    <component
      :is="readOnly ? 'span' : 'button'"
      v-for="group in reactions"
      :key="group.emoji"
      :type="readOnly ? undefined : 'button'"
      class="flare-reaction-pill"
      :class="{ 'is-self': group.reactedBySelf }"
      :aria-pressed="readOnly ? undefined : Boolean(group.reactedBySelf)"
      :title="tooltip(group)"
      v-on="readOnly ? {} : { click: (event: MouseEvent) => { event.stopPropagation(); emit('toggle', group.emoji); } }"
    >{{ group.emoji }} {{ group.count }}</component>
    <button
      v-if="!hideAdd && !readOnly"
      type="button"
      class="flare-reaction-pill flare-reaction-pill--add"
      :aria-label="t('reaction.add')"
      @click="emit('add')"
    >
      <n-icon aria-hidden="true" :size="15" :component="HappyOutline" />
    </button>
    <slot name="trailing" />
  </div>
</template>

<style scoped>
.flare-reaction-summary {
  --flare-reaction-pill-height: 22px;
  display: flex;
  flex-wrap: wrap;
  align-items: flex-start;
  gap: var(--flare-size-spacing-xs);
}

.flare-reaction-pill {
  --reaction-fill: var(--flare-color-message-reaction-background);
  --reaction-touch-inset: 0px;
  position: relative;
  isolation: isolate;
  box-sizing: border-box;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-height: var(--flare-reaction-pill-height);
  min-width: var(--flare-reaction-pill-height);
  padding: 0 var(--flare-size-spacing-sm) var(--reaction-touch-inset);
  border: 0;
  background: transparent;
  color: var(--flare-color-text-secondary);
  font: inherit;
  font-size: var(--flare-size-font-size-sm);
  font-variant-numeric: tabular-nums;
  font-weight: var(--flare-size-font-weight-medium);
  white-space: pre;
}

/* The pill sits at the top of its own touch slot so every hit area stays
   inside its layout box, even next to a timestamp or another line of pills. */
.flare-reaction-pill::before {
  content: "";
  position: absolute;
  z-index: -1;
  inset: 0 0 var(--reaction-touch-inset);
  border-radius: var(--flare-size-radius-full);
  background: var(--reaction-fill);
}
button.flare-reaction-pill { cursor: pointer; }
button.flare-reaction-pill:hover:not(.is-self) { --reaction-fill: var(--flare-color-bg-hover); }
button.flare-reaction-pill:focus-visible {
  outline: 2px solid var(--flare-color-border-selected);
  outline-offset: 1px;
  border-radius: var(--flare-size-radius-full);
}
.flare-reaction-pill.is-self {
  --reaction-fill: var(--flare-color-message-reaction-selected);
  color: var(--flare-color-primary-text);
}
.flare-reaction-pill--add { color: var(--flare-color-text-tertiary); }
.flare-reaction-pill--add:hover { color: var(--flare-color-primary-text); }

@media (pointer: coarse) {
  button.flare-reaction-pill {
    --reaction-touch-inset: calc(var(--flare-size-layout-touch-target-min) - var(--flare-reaction-pill-height));
    min-width: var(--flare-size-layout-touch-target-min);
    min-height: var(--flare-size-layout-touch-target-min);
  }
}
@media (forced-colors: active) {
  .flare-reaction-pill::before { outline: 1px solid CanvasText; }
  .flare-reaction-pill.is-self::before { outline-color: Highlight; }
}
</style>
