<script setup lang="ts">
import { computed, ref, watch, type Component } from "vue";
import { NIcon } from "naive-ui";
import { CloseOutline } from "../../shared/icon-glyphs";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import type { FlareComposerAction } from "../../shared/contracts/composer";
import FlareComposerActionPanel from "./FlareComposerActionPanel.vue";

const PAGE_SIZE = 8;

// The "+" surface of the composer: the shared ComposerActionPanel grid plus the
// desktop niceties around it (search, paging, an explicit close).
const props = defineProps<{
  actions: ReadonlyArray<FlareComposerAction<string | Component>>;
  searchVisible?: boolean;
  titleVisible?: boolean;
  closeVisible?: boolean;
}>();
const emit = defineEmits<{ (event: "select", action: FlareComposerAction<string | Component>): void; (event: "close"): void }>();
const { t } = useFlareI18n();

const query = ref("");
const page = ref(0);
const filtered = computed(() => props.actions.filter((action) => action.label.toLocaleLowerCase().includes(query.value.toLocaleLowerCase())));
const pages = computed(() => Math.ceil(filtered.value.length / PAGE_SIZE));
const pageActions = computed(() => filtered.value.slice(page.value * PAGE_SIZE, page.value * PAGE_SIZE + PAGE_SIZE));
watch([query, () => props.actions], () => { page.value = 0; });
watch(() => props.searchVisible, (visible) => { if (!visible) query.value = ""; });
</script>

<template>
  <section class="composer-surface composer-more-surface" :aria-label="t('composer.more')">
    <header v-if="searchVisible || titleVisible || closeVisible" class="composer-more-header">
      <input v-if="searchVisible" v-model="query" class="composer-panel-search" :placeholder="t('composer.searchActions')" :aria-label="t('composer.searchActions')" />
      <span v-else-if="titleVisible">{{ t('composer.more') }}</span>
      <button v-if="closeVisible" type="button" class="composer-more-close" :aria-label="t('composer.closePanel')" @click="emit('close')"><n-icon aria-hidden="true" :component="CloseOutline" /></button>
    </header>
    <FlareComposerActionPanel v-if="pageActions.length" class="composer-more-grid" :actions="pageActions" :columns="4" @action="emit('select', $event)" />
    <p v-else role="status">{{ t('composer.noResults') }}</p>
    <nav v-if="pages > 1" class="composer-pages">
      <button v-for="p in pages" :key="p" type="button" :aria-label="t('composer.page', { page: p })" :aria-current="page === p - 1 ? 'page' : undefined" @click="page = p - 1"><span /></button>
    </nav>
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
.composer-more-grid { padding: var(--flare-size-spacing-sm) 0 0; gap: var(--flare-size-spacing-sm); background: transparent; }
.composer-more-grid :deep(.flare-action-panel__ico) { width: 36px; height: 36px; border-radius: var(--flare-size-radius-md, 8px); background: var(--studio-surface-subtle, var(--flare-color-bg-secondary)); font-size: 18px; }
.composer-more-grid :deep(.flare-action-panel__tile) { min-height: 68px; padding: var(--flare-size-spacing-xs); color: var(--flare-color-text-secondary); }
p { margin: var(--flare-size-spacing-sm) 0 0; color: var(--flare-color-text-tertiary); font-size: var(--flare-size-font-size-sm); }
.composer-pages { display: flex; justify-content: center; height: var(--flare-size-icon-size-lg); }
.composer-pages button { width: 28px; height: var(--flare-size-icon-size-lg); padding: var(--flare-size-spacing-sm); border: 0; background: transparent; cursor: pointer; }
.composer-pages span { display: block; width: 5px; height: 5px; border-radius: var(--flare-size-radius-full, 999px); background: var(--studio-border, var(--flare-color-border-primary)); }
.composer-pages [aria-current] span { width: 12px; background: var(--studio-accent, var(--flare-color-primary)); }
.composer-panel-search:focus-visible,
.composer-more-close:focus-visible,
.composer-pages button:focus-visible { outline: 2px solid var(--studio-focus, var(--flare-color-border-selected)); outline-offset: -2px; }
</style>
