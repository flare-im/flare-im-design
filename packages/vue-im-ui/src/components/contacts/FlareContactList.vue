<script setup lang="ts">
import { computed, getCurrentInstance, ref, useId } from "vue";
import FlareContactItem from "./FlareContactItem.vue";
import FlareAvatar from "../conversation/FlareAvatar.vue";
import FlareIcon from "../general/FlareIcon.vue";
import FlareEmptyState from "../general/FlareEmptyState.vue";
import type { FlareContact } from "../../shared/contracts";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";
import { compareContactIndexLetters, compareContactNames, contactIndexLetter } from "../../utils/contactIndex";

const props = withDefaults(
  defineProps<{
    items: readonly FlareContact[];
    indexed?: boolean;
    loading?: boolean;
    /** Picker mode: every row carries a checkbox and a tap emits `toggleSelect` instead of `select`. */
    selectable?: boolean;
    /** Ids of the checked rows in picker mode. */
    selectedIds?: readonly string[];
    /** Selected identities across all filtered pages, for removable selection chips. selectedIds stays authoritative. */
    selectedItems?: readonly FlareContact[];
    /** 右边那一栏正在显示的那个人。两栏布局下左列要看得出对应关系（同会话列表的 activeId）。 */
    activeId?: string;
  }>(),
  { indexed: true, loading: false, selectable: false, selectedIds: () => [], selectedItems: () => [], activeId: "" },
);
const emit = defineEmits<{
  (e: "select", c: FlareContact): void;
  (e: "toggleSelect", id: string): void;
  /** ArrowUp on the first row lets a host return to its search field. */
  (e: "focusSearch"): void;
}>();
const { t } = useFlareI18nOptional();

// Rows are buttons only when the host handles `select` (see FlareContactItem).
const instance = getCurrentInstance();
const canSelect = computed(() => Boolean(instance?.vnode.props?.onSelect));
const checked = computed(() => new Set(props.selectedIds));
const chosen = computed(() => props.selectable ? props.selectedItems.filter((item, index, all) => checked.value.has(item.id) && all.findIndex(other => other.id === item.id) === index) : []);

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

function rowControls(): HTMLElement[] {
  return Array.from(scroller.value?.querySelectorAll<HTMLElement>(
    'button.flare-contact-item__main, .flare-contact-item__main button[role="checkbox"]',
  ) ?? []).filter((element) => !element.matches(':disabled, [aria-disabled="true"]'));
}
function focusControl(control: HTMLElement | undefined): boolean {
  if (!control) return false;
  control.focus({ preventScroll: true });
  control.scrollIntoView({ block: "nearest" });
  return true;
}
/** Move focus without opening a profile or changing a picker selection. */
function focusFirst(): boolean { return focusControl(rowControls()[0]); }
function focusLast(): boolean { return focusControl(rowControls().at(-1)); }
function focusContact(id: string): boolean {
  return focusControl(rowControls().find((control) => control.closest<HTMLElement>("[data-contact-id]")?.dataset.contactId === id));
}
function onKeydown(event: KeyboardEvent): void {
  if (event.isComposing || event.altKey || event.ctrlKey || event.metaKey || event.shiftKey) return;
  const controls = rowControls();
  const index = controls.indexOf(event.target as HTMLElement);
  // Trailing actions, index buttons and selection chips keep their own keyboard behavior.
  if (index < 0 || !["ArrowDown", "ArrowUp", "Home", "End"].includes(event.key)) return;
  event.preventDefault();
  event.stopPropagation();
  if (event.key === "Home") focusFirst();
  else if (event.key === "End") focusLast();
  else if (event.key === "ArrowUp" && index === 0) emit("focusSearch");
  else focusControl(controls[Math.max(0, Math.min(controls.length - 1, index + (event.key === "ArrowDown" ? 1 : -1)))]);
}
defineExpose({ focusFirst, focusLast, focusContact });
</script>

<template>
  <div class="flare-contact-list" :aria-busy="loading" :class="{ 'is-indexed': indexed && groups.length > 1, 'has-selection': chosen.length > 0 }">
    <div v-if="chosen.length" class="flare-contact-list__chosen" role="group" :aria-label="t('contactPicker.selectedCount', { count: chosen.length })">
      <button v-for="person in chosen" :key="person.id" type="button" class="flare-contact-list__chip" :aria-label="t('contactPicker.removeSelection', { name: person.name })" :title="person.name" @click="emit('toggleSelect', person.id)">
        <FlareAvatar :user-id="person.id" :display-name="person.name" :avatar-url="person.avatarUrl" :size="24" />
        <span>{{ person.name }}</span><FlareIcon name="close" size="sm" />
      </button>
    </div>
    <!-- A directory can be empty for a reason only the host knows — a filter, a permission, an
         invitation to add someone. Without the slot the kit's own line is what everyone gets. -->
    <FlareEmptyState v-if="!items.length && loading" loading :title="t('common.loading')" />
    <slot v-else-if="!items.length" name="empty">
      <FlareEmptyState icon="people" :title="t('contact.empty')" />
    </slot>
    <div v-else ref="scroller" class="flare-contact-list__scroll" @keydown="onKeydown">
      <div v-for="[l, people] in groups" :key="l" role="group" :aria-labelledby="`${groupIdPrefix}-${l === '#' ? 'other' : l}`">
        <div :id="`${groupIdPrefix}-${l === '#' ? 'other' : l}`" class="flare-contact-list__head" :data-index-letter="l">{{ l }}</div>
        <FlareContactItem
          v-for="p in people"
          :key="p.id"
          :item="p"
          :data-contact-id="p.id"
          :selectable="selectable"
          :selected="selectable && checked.has(p.id)"
          :current="!selectable && Boolean(activeId) && p.id === activeId"
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
.flare-contact-list__scroll { height: 100%; overflow-y: auto; scrollbar-width: thin; scrollbar-color: var(--flare-color-border-primary) transparent; }
.flare-contact-list.has-selection { display: flex; flex-direction: column; min-height: 0; }
.flare-contact-list.has-selection .flare-contact-list__scroll { flex: 1; height: auto; min-height: 0; }
.flare-contact-list__chosen { display: flex; flex: none; align-items: center; gap: var(--flare-size-spacing-sm); padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-md); overflow-x: auto; scrollbar-width: none; border-bottom: 1px solid var(--flare-color-border-secondary); }
.flare-contact-list__chosen::-webkit-scrollbar { display: none; }
.flare-contact-list__chip { position: relative; display: inline-flex; flex: none; align-items: center; gap: var(--flare-size-spacing-xs); min-height: var(--flare-size-layout-control-height-sm); max-width: 180px; padding: var(--flare-size-spacing-3xs) var(--flare-size-spacing-sm) var(--flare-size-spacing-3xs) var(--flare-size-spacing-3xs); border: 1px solid var(--flare-color-border-secondary); border-radius: var(--flare-size-radius-full); background: var(--flare-color-bg-selected); color: var(--flare-color-text-primary); font: inherit; font-size: var(--flare-size-font-size-sm); cursor: pointer; }
.flare-contact-list__chip > span { min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.flare-contact-list__chip:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: 2px; }
@media (pointer: coarse) { .flare-contact-list__chip::after { content: ""; position: absolute; inset-inline: 0; top: 50%; transform: translateY(-50%); height: var(--flare-size-layout-touch-target); } }

.flare-contact-list.is-indexed .flare-contact-list__scroll { padding-inline-end: var(--flare-size-spacing-lg); box-sizing: border-box; }
.flare-contact-list__head {
  position: sticky;
  top: 0;
  padding: 4px var(--flare-size-spacing-2md);
  font-size: 12px;
  font-weight: 600;
  color: var(--flare-color-text-tertiary);
  background: var(--flare-color-bg-secondary);
}
.flare-contact-list__idx {
  position: absolute;
  inset-inline-end: 2px;
  top: 50%;
  transform: translateY(-50%);
  display: flex;
  flex-direction: column;
  gap: 2px;
  font-size: var(--flare-size-font-size-2xs);
  font-weight: 600;
  color: var(--flare-color-primary-text);
}
.flare-contact-list__idx button { min-width: 20px; min-height: 16px; padding: 0 2px; border: 0; background: transparent; color: inherit; font: inherit; line-height: 16px; cursor: pointer; }
.flare-contact-list__idx button:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: 0; border-radius: var(--flare-size-radius-sm); }
</style>
