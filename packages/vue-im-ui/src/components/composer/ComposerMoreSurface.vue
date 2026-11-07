<script setup lang="ts">
import { computed, ref, watch, type Component } from "vue";
import { NIcon } from "naive-ui";
import { CloseOutline } from "../../shared/icon-glyphs";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import type { FlareComposerAction } from "../../shared/contracts/composer";
import FlareComposerActionPanel, { type FlareComposerPanelFormFactor } from "./FlareComposerActionPanel.vue";

// The "+" surface of the composer: the shared ComposerActionPanel grid (which pages on a
// phone and scrolls on a desktop) plus the niceties around it (search, an explicit close).
// The composer hands over labelled actions, so the search reads the label the tile shows.
type LabelledAction = FlareComposerAction<string | Component> & { label: string };
const props = defineProps<{
  actions: ReadonlyArray<LabelledAction>;
  formFactor?: FlareComposerPanelFormFactor;
  searchVisible?: boolean;
  titleVisible?: boolean;
  closeVisible?: boolean;
}>();
const emit = defineEmits<{ (event: "select", action: FlareComposerAction<string | Component>): void; (event: "close"): void }>();
const { t } = useFlareI18n();

const query = ref("");
const filtered = computed(() => props.actions.filter((action) => action.label.toLocaleLowerCase().includes(query.value.toLocaleLowerCase())));
watch(() => props.searchVisible, (visible) => { if (!visible) query.value = ""; });
</script>

<template>
  <section class="composer-surface composer-more-surface" :aria-label="t('composer.more')">
    <header v-if="searchVisible || titleVisible || closeVisible" class="composer-more-header">
      <input v-if="searchVisible" v-model="query" class="composer-panel-search" :placeholder="t('composer.searchActions')" :aria-label="t('composer.searchActions')" />
      <span v-else-if="titleVisible">{{ t('composer.more') }}</span>
      <button v-if="closeVisible" type="button" class="composer-more-close" :aria-label="t('composer.closePanel')" @click="emit('close')"><n-icon aria-hidden="true" :component="CloseOutline" /></button>
    </header>
    <FlareComposerActionPanel v-if="filtered.length" class="composer-more-grid" :actions="filtered" :columns="4" :form-factor="formFactor ?? 'desktop'" @action="emit('select', $event)" />
    <p v-else role="status">{{ t('composer.noResults') }}</p>
  </section>
</template>

<style scoped>
.composer-more-header { display: flex; align-items: center; justify-content: space-between; min-height: var(--flare-size-layout-control-height-sm); }
.composer-panel-search {
  width: calc(100% - var(--flare-size-layout-control-height-md));
  height: var(--flare-size-layout-control-height-sm);
  padding: 0 var(--flare-size-spacing-sm);
  border: 0;
  border-bottom: 1px solid var(--studio-divider, var(--flare-color-border-secondary));
  color: inherit;
  background: transparent;
  font: inherit;
}
.composer-more-close { border: 0; color: var(--flare-color-text-secondary); background: transparent; cursor: pointer; width: 36px; height: 36px; display: grid; place-items: center; }
.composer-more-grid { --flare-action-panel-gap: var(--flare-size-spacing-sm); --flare-action-panel-row: 68px; padding: var(--flare-size-spacing-sm) 0 0; background: transparent; }
.composer-more-grid :deep(.flare-action-panel__ico) { width: 36px; height: 36px; border-radius: var(--flare-size-radius-md, 8px); background: var(--studio-surface-subtle, var(--flare-color-bg-secondary)); font-size: 18px; }
.composer-more-grid :deep(.flare-action-panel__tile) { min-height: 68px; padding: var(--flare-size-spacing-xs); color: var(--flare-color-text-secondary); }
p { margin: var(--flare-size-spacing-sm) 0 0; color: var(--flare-color-text-tertiary); font-size: var(--flare-size-font-size-sm); }
.composer-more-grid :deep(.flare-action-panel__dots span) { background: var(--studio-border, var(--flare-color-border-primary)); }
.composer-more-grid :deep(.flare-action-panel__dots [aria-current] span) { background: var(--studio-accent, var(--flare-color-primary)); }
.composer-panel-search:focus-visible,
.composer-more-close:focus-visible { outline: 2px solid var(--studio-focus, var(--flare-color-border-selected)); outline-offset: -2px; }
</style>
