<script setup lang="ts">
/**
 * An ordered admin list the operator rearranges: drag a row by its handle, press
 * Alt+↑ / Alt+↓ on the handle, or pick 上移 / 下移 / 移到最前 from the row menu. Every
 * move emits the whole reordered list (`update:items`) and is announced politely
 * with the row's new position. Presentation only: the host owns the data, what a
 * row shows (`item` slot) and the controls at its end (`trailing` slot), and
 * whether the order is saved.
 */
import { computed, nextTick, ref } from "vue";
import { NIcon } from "naive-ui";
import FlareActionMenu from "../general/FlareActionMenu.vue";
import { EllipsisHorizontal, ReorderTwoOutline } from "../../shared/icon-glyphs";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import type { FlareActionItem } from "../../shared/contracts/action-menu";

export interface FlareAdminSortableItem {
  id: string;
  /** Names the row in the handle, the row menu and the announcement. */
  label: string;
}

const props = withDefaults(
  defineProps<{
    items: readonly FlareAdminSortableItem[];
    /** The list's accessible name. */
    label: string;
    /** Read-only: no handle, no menu, no drag. */
    disabled?: boolean;
  }>(),
  { disabled: false },
);
const emit = defineEmits<{ (e: "update:items", items: FlareAdminSortableItem[]): void }>();
defineSlots<{
  item?(props: { item: FlareAdminSortableItem; index: number }): unknown;
  trailing?(props: { item: FlareAdminSortableItem; index: number }): unknown;
}>();
const { t } = useFlareI18n();

const root = ref<HTMLElement | null>(null);
const announcement = ref("");
const dragging = ref<string | null>(null);
const dropTarget = ref<string | null>(null);
const count = computed(() => props.items.length);

function move(from: number, to: number): void {
  if (props.disabled || from === to || from < 0 || to < 0 || from >= count.value || to >= count.value) return;
  const next = [...props.items];
  const [moved] = next.splice(from, 1);
  next.splice(to, 0, moved!);
  emit("update:items", next);
  announcement.value = t("sortableList.moved", { label: moved!.label, position: to + 1, count: next.length });
  // The handle keeps focus as its row travels, so the next Alt+↑/↓ moves the same row.
  void nextTick(() => {
    root.value?.querySelector<HTMLElement>(`[data-sortable-handle="${CSS.escape(moved!.id)}"]`)?.focus();
  });
}
function onKeydown(event: KeyboardEvent, index: number): void {
  if (!event.altKey || (event.key !== "ArrowUp" && event.key !== "ArrowDown")) return;
  event.preventDefault();
  move(index, event.key === "ArrowUp" ? index - 1 : index + 1);
}
function menuItems(index: number): FlareActionItem[] {
  return [
    { id: "up", label: t("sortableList.moveUp"), enabled: index > 0 },
    { id: "down", label: t("sortableList.moveDown"), enabled: index < count.value - 1 },
    { id: "top", label: t("sortableList.moveToTop"), enabled: index > 0 },
  ];
}
function onMenu(id: string, index: number): void {
  move(index, id === "up" ? index - 1 : id === "down" ? index + 1 : 0);
}

function onDragStart(event: DragEvent, item: FlareAdminSortableItem): void {
  if (props.disabled) return event.preventDefault();
  dragging.value = item.id;
  event.dataTransfer?.setData("text/plain", item.id);
  if (event.dataTransfer) event.dataTransfer.effectAllowed = "move";
}
function onDragOver(event: DragEvent, item: FlareAdminSortableItem): void {
  if (!dragging.value) return;
  event.preventDefault();
  dropTarget.value = item.id;
}
function onDrop(event: DragEvent, index: number): void {
  event.preventDefault();
  const from = props.items.findIndex((item) => item.id === dragging.value);
  endDrag();
  move(from, index);
}
function endDrag(): void {
  dragging.value = null;
  dropTarget.value = null;
}
</script>

<template>
  <div ref="root" class="flare-admin-sortable">
    <p v-if="!disabled" class="flare-admin-sortable__hint">{{ t("sortableList.hint") }}</p>
    <ol class="flare-admin-sortable__list" :aria-label="label">
      <li
        v-for="(item, index) in items"
        :key="item.id"
        class="flare-admin-sortable__row"
        :class="{
          'is-dragging': dragging === item.id,
          'is-drop-target': dropTarget === item.id && dragging !== item.id,
        }"
        :data-sortable-id="item.id"
        :draggable="!disabled"
        @dragstart="onDragStart($event, item)"
        @dragover="onDragOver($event, item)"
        @dragleave="dropTarget === item.id && (dropTarget = null)"
        @drop="onDrop($event, index)"
        @dragend="endDrag"
      >
        <button
          v-if="!disabled"
          type="button"
          class="flare-admin-sortable__handle"
          :data-sortable-handle="item.id"
          :aria-label="t('sortableList.handle', { label: item.label })"
          @keydown="onKeydown($event, index)"
        >
          <n-icon aria-hidden="true" :size="18" :component="ReorderTwoOutline" />
        </button>
        <div class="flare-admin-sortable__content">
          <slot name="item" :item="item" :index="index">{{ item.label }}</slot>
        </div>
        <div v-if="$slots.trailing" class="flare-admin-sortable__trailing">
          <slot name="trailing" :item="item" :index="index" />
        </div>
        <FlareActionMenu
          v-if="!disabled"
          :items="menuItems(index)"
          :label="t('sortableList.actions', { label: item.label })"
          placement="bottom-end"
          @select="onMenu($event, index)"
        >
          <button type="button" class="flare-admin-sortable__menu" :aria-label="t('sortableList.actions', { label: item.label })">
            <n-icon aria-hidden="true" :size="18" :component="EllipsisHorizontal" />
          </button>
        </FlareActionMenu>
      </li>
    </ol>
    <p class="flare-admin-sortable__live" aria-live="polite" role="status">{{ announcement }}</p>
  </div>
</template>

<style scoped>
.flare-admin-sortable__hint {
  margin: 0 0 var(--flare-size-spacing-xs);
  color: var(--flare-color-text-tertiary);
  font-size: var(--flare-size-font-size-xs);
}
.flare-admin-sortable__list {
  margin: 0;
  padding: 0;
  list-style: none;
  border: 1px solid var(--flare-color-border-secondary);
  border-radius: var(--flare-size-radius-md);
  background: var(--flare-color-bg-primary);
}
.flare-admin-sortable__row {
  display: flex;
  align-items: center;
  gap: var(--flare-size-spacing-sm);
  min-height: var(--flare-size-layout-control-height-lg);
  padding: var(--flare-size-spacing-xs) var(--flare-size-spacing-sm);
  border-top: 1px solid var(--flare-color-border-secondary);
  transition: background-color 150ms ease;
}
.flare-admin-sortable__row:first-child { border-top: 0; }
.flare-admin-sortable__row.is-dragging { opacity: var(--flare-opacity-disabled); }
.flare-admin-sortable__row.is-drop-target { box-shadow: inset 0 2px 0 var(--flare-color-primary); }
.flare-admin-sortable__handle,
.flare-admin-sortable__menu {
  display: grid;
  place-items: center;
  flex-shrink: 0;
  width: var(--flare-size-layout-control-height-sm);
  height: var(--flare-size-layout-control-height-sm);
  padding: 0;
  border: 0;
  border-radius: var(--flare-size-radius-sm);
  color: var(--flare-color-text-tertiary);
  background: transparent;
}
.flare-admin-sortable__handle { cursor: grab; }
.flare-admin-sortable__menu { cursor: pointer; }
.flare-admin-sortable__handle:hover,
.flare-admin-sortable__menu:hover { color: var(--flare-color-text-primary); background: var(--flare-color-bg-secondary); }
.flare-admin-sortable__handle:focus-visible,
.flare-admin-sortable__menu:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: 0; }
.flare-admin-sortable__content { flex: 1; min-width: 0; }
.flare-admin-sortable__trailing { display: flex; align-items: center; gap: var(--flare-size-spacing-sm); flex-shrink: 0; }
.flare-admin-sortable__live {
  position: absolute;
  width: 1px;
  height: 1px;
  margin: -1px;
  overflow: hidden;
  clip: rect(0 0 0 0);
  white-space: nowrap;
}
@media (prefers-reduced-motion: reduce) {
  .flare-admin-sortable__row { transition: none; }
}
</style>
