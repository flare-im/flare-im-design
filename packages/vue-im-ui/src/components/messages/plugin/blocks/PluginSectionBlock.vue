<script setup lang="ts">
import FlareIcon from "../../../general/FlareIcon.vue";
import { useFlareI18nOptional } from "../../../../shared/i18n/useFlareI18n";
import type { FlarePluginSectionBlock } from "../../../../shared/contracts/plugin-ui";

// A section's heading (vocabulary 2): its label and, when it has one, the key that folds the blocks under it. The
// children are drawn by PluginView right after the heading, so they keep the view's forms, choices and actions;
// they are hidden while `collapsed`. A section without a label has no heading and is never folded.
defineProps<{ block: FlarePluginSectionBlock; collapsed: boolean; controls?: string }>();
const emit = defineEmits<{ toggle: [] }>();
const { t } = useFlareI18nOptional();
</script>

<template>
  <div v-if="block.label" class="flare-plugin-section">
    <h3 class="flare-plugin-section__label">{{ block.label }}</h3>
    <button
      type="button"
      class="flare-plugin-section__toggle"
      :aria-expanded="!collapsed"
      :aria-controls="controls"
      data-section-toggle="true"
      @click="emit('toggle')"
    >
      <span>{{ collapsed ? t("pluginView.expand") : t("pluginView.collapse") }}</span>
      <FlareIcon :name="collapsed ? 'chevron-down' : 'chevron-up'" :size="14" aria-hidden="true" />
    </button>
  </div>
</template>

<style scoped>
.flare-plugin-section {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: var(--flare-size-spacing-sm);
  min-width: 0;
  padding-block-start: var(--flare-size-spacing-xs);
}
.flare-plugin-section__label {
  min-width: 0;
  margin: 0;
  font-size: var(--flare-size-font-size-md);
  font-weight: var(--flare-size-font-weight-semibold);
  color: var(--flare-color-text-primary);
  overflow-wrap: anywhere;
}
.flare-plugin-section__toggle {
  position: relative;
  flex: none;
  display: inline-flex;
  align-items: center;
  gap: var(--flare-size-spacing-3xs);
  padding: var(--flare-size-spacing-3xs) var(--flare-size-spacing-2xs);
  border: 0;
  border-radius: var(--flare-size-radius-sm);
  background: transparent;
  color: var(--flare-color-text-secondary);
  font-size: var(--flare-size-font-size-sm);
  cursor: pointer;
}
.flare-plugin-section__toggle::after {
  content: "";
  position: absolute;
  top: 50%;
  left: 50%;
  width: max(100%, var(--flare-size-layout-touch-target));
  height: var(--flare-size-layout-touch-target);
  transform: translate(-50%, -50%);
}
@media (hover: hover) {
  .flare-plugin-section__toggle:hover { background: var(--flare-color-bg-hover); color: var(--flare-color-text-primary); }
}
.flare-plugin-section__toggle:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: 2px; }
</style>
