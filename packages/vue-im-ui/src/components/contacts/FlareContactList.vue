<script setup lang="ts">
import { computed, getCurrentInstance, ref, useId } from "vue";
import FlareContactItem from "./FlareContactItem.vue";
import FlareEmptyState from "../general/FlareEmptyState.vue";
import type { FlareContact } from "../../shared/contracts";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";
import { compareContactIndexLetters, compareContactNames, contactIndexLetter } from "../../utils/contactIndex";

const props = withDefaults(
  defineProps<{
    items: FlareContact[];
    indexed?: boolean;
    loading?: boolean;
    /** Picker mode: every row carries a checkbox and a tap emits `toggleSelect` instead of `select`. */
    selectable?: boolean;
    /** Ids of the checked rows in picker mode. */
    selectedIds?: readonly string[];
  }>(),
  { indexed: true, loading: false, selectable: false, selectedIds: () => [] },
);
const emit = defineEmits<{
  (e: "select", c: FlareContact): void;
  (e: "toggleSelect", id: string): void;
}>();
const { t } = useFlareI18nOptional();

// Rows are buttons only when the host handles `select` (see FlareContactItem).
const instance = getCurrentInstance();
const canSelect = computed(() => Boolean(instance?.vnode.props?.onSelect));
const checked = computed(() => new Set(props.selectedIds));

// Groups by index letter (Chinese names by pinyin initial), A to Z then "#", names in pinyin order.
const groups = computed<[string, FlareContact[]][]>(() => {
  const map = new Map<string, FlareContact[]>();
  for (const c of props.items) {
    const l = contactIndexLetter(c.name, c.indexKey);
    (map.get(l) ?? map.set(l, []).get(l)!).push(c);
  }
  return [...map.entries()]
    .sort((a, b) => compareContactIndexLetters(a[0], b[0]))
    .map(([l, people]) => [l, [...people].sort((a, b) => compareContactNames(a.name, b.name))]);
});
// Jump targets belong to this list, so two lists on one page never jump into each other.
const groupIdPrefix = `flare-contact-group-${useId()}`;
const scroller = ref<HTMLElement | null>(null);
function jump(l: string) {
  scroller.value?.querySelector<HTMLElement>(`[data-index-letter="${l}"]`)?.scrollIntoView({ behavior: "smooth", block: "start" });
}
</script>

<template>
  <div class="flare-contact-list">
    <!-- A directory can be empty for a reason only the host knows — a filter, a permission, an
         invitation to add someone. Without the slot the kit's own line is what everyone gets. -->
    <slot v-if="!items.length && !loading" name="empty">
      <FlareEmptyState icon="people" :title="t('contact.empty')" />
    </slot>
    <div v-else ref="scroller" class="flare-contact-list__scroll">
      <div v-for="[l, people] in groups" :key="l" role="group" :aria-labelledby="`${groupIdPrefix}-${l === '#' ? 'other' : l}`">
        <div :id="`${groupIdPrefix}-${l === '#' ? 'other' : l}`" class="flare-contact-list__head" :data-index-letter="l">{{ l }}</div>
        <FlareContactItem
          v-for="p in people"
          :key="p.id"
          :item="p"
          :selectable="selectable"
          :selected="selectable && checked.has(p.id)"
          :onSelect="canSelect ? () => emit('select', p) : undefined"
          @toggle-select="emit('toggleSelect', p.id)"
        >
          <template v-if="$slots.trailing" #trailing><slot name="trailing" :item="p" /></template>
        </FlareContactItem>
      </div>
    </div>
    <nav v-if="indexed && groups.length > 1" class="flare-contact-list__idx" :aria-label="t('contact.index')">
      <button v-for="[l] in groups" :key="l" type="button" :aria-label="t('contact.jumpTo', { letter: l })" @click="jump(l)">{{ l }}</button>
    </nav>
  </div>
</template>

<style scoped>
.flare-contact-list { position: relative; height: 100%; }
.flare-contact-list__scroll { height: 100%; overflow-y: auto; }
.flare-contact-list__head {
  position: sticky;
  top: 0;
  padding: 4px 14px;
  font-size: 12px;
  font-weight: 600;
  color: var(--flare-color-text-tertiary);
  background: var(--flare-color-bg-secondary);
}
.flare-contact-list__idx {
  position: absolute;
  right: 2px;
  top: 50%;
  transform: translateY(-50%);
  display: flex;
  flex-direction: column;
  gap: 2px;
  font-size: 10px;
  font-weight: 600;
  color: var(--flare-color-primary-text);
}
.flare-contact-list__idx button { min-width: 20px; min-height: 16px; padding: 0 2px; border: 0; background: transparent; color: inherit; font: inherit; line-height: 16px; cursor: pointer; }
.flare-contact-list__idx button:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: 0; border-radius: var(--flare-size-radius-sm); }
</style>
