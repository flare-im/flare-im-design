<script setup lang="ts">
import { NIcon } from "naive-ui";
import { HappyOutline } from "../../shared/icon-glyphs";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import type { FlareReactionGroup } from "../../shared/contracts";

const props = defineProps<{
  reactions: FlareReactionGroup[];
  /** Hide the trailing "add reaction" affordance. */
  hideAdd?: boolean;
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
  <div v-if="reactions.length || !hideAdd" class="flare-reaction-summary">
    <button
      v-for="group in reactions"
      :key="group.emoji"
      type="button"
      class="flare-reaction-pill"
      :class="{ 'is-self': group.reactedBySelf }"
      :title="tooltip(group)"
      @click="emit('toggle', group.emoji)"
    >
      <span class="flare-reaction-pill__emoji">{{ group.emoji }}</span>
      <span class="flare-reaction-pill__count">{{ group.count }}</span>
    </button>
    <button
      v-if="!hideAdd"
      type="button"
      class="flare-reaction-pill flare-reaction-pill--add"
      :aria-label="t('reaction.add')"
      @click="emit('add')"
    >
      <n-icon aria-hidden="true" :size="15" :component="HappyOutline" />
    </button>
  </div>
</template>

<style scoped>
.flare-reaction-summary {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  margin-top: 6px;
}
.flare-reaction-pill {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  height: 26px;
  padding: 0 9px;
  border-radius: 999px;
  border: 1px solid var(--flare-color-border-primary);
  background: var(--flare-color-message-reaction-background);
  color: var(--flare-color-text-secondary);
  font-size: 13px;
  line-height: 1;
  cursor: pointer;
  transition: transform var(--flare-transition-fast),
    background var(--flare-transition-fast),
    border-color var(--flare-transition-fast);
}
/* Feedback that does not move the hit area: a transform shifts the border box,
   so the bottom 1px a cursor may be resting on leaves the element and hover
   drops — which re-lowers it, which re-enters hover. */
.flare-reaction-pill:hover { background: var(--flare-color-bg-hover); border-color: var(--flare-color-border-hover); }
.flare-reaction-pill:active { transform: scale(0.96); }
.flare-reaction-pill__emoji { font-size: 14px; }
.flare-reaction-pill__count {
  font-variant-numeric: tabular-nums;
  font-weight: 500;
}
.flare-reaction-pill.is-self {
  border-color: var(--flare-color-primary);
  background: var(--flare-color-message-reaction-selected);
  color: var(--flare-color-primary-text);
}
.flare-reaction-pill--add {
  padding: 0 8px;
  color: var(--flare-color-text-tertiary);
}
.flare-reaction-pill--add:hover {
  color: var(--flare-color-primary-text);
  border-color: var(--flare-color-primary);
}
</style>
