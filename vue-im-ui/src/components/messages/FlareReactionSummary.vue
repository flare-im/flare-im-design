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
      <n-icon :size="15" :component="HappyOutline" />
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
  border: 1px solid var(--flare-color-border-primary, #e9e6f1);
  background: var(--flare-color-bg-secondary, #f6f5fb);
  color: var(--flare-color-text-secondary, #6b6780);
  font-size: 13px;
  line-height: 1;
  cursor: pointer;
  transition: transform var(--flare-transition-fast, 150ms ease),
    background var(--flare-transition-fast, 150ms ease),
    border-color var(--flare-transition-fast, 150ms ease);
}
.flare-reaction-pill:hover { transform: translateY(-1px); }
.flare-reaction-pill:active { transform: scale(0.96); }
.flare-reaction-pill__emoji { font-size: 14px; }
.flare-reaction-pill__count {
  font-variant-numeric: tabular-nums;
  font-weight: 500;
}
.flare-reaction-pill.is-self {
  border-color: var(--flare-color-primary, #7c3aed);
  background: var(--flare-color-bg-selected, #f1eaff);
  color: var(--flare-color-primary, #7c3aed);
}
.flare-reaction-pill--add {
  padding: 0 8px;
  color: var(--flare-color-text-tertiary, #a7a2b4);
}
.flare-reaction-pill--add:hover {
  color: var(--flare-color-primary, #7c3aed);
  border-color: var(--flare-color-primary, #7c3aed);
}
</style>
