<script setup lang="ts">
/**
 * The drawn menu of FlareActionMenu, shared by its anchored and sheet presentations:
 * a named `role="menu"` whose items take focus in turn (arrow keys, Home, End), with
 * separators where the action group changes. An unavailable action stays in place,
 * announced as disabled with its reason. Internal — hosts use FlareActionMenu.
 */
import { computed, nextTick, onMounted, ref, type Component } from "vue";
import { NIcon } from "naive-ui";
import FlareIcon from "./FlareIcon.vue";
import { flareIcons, type FlareIconName } from "../../shared/icons";
import { actionMenuEntries, type FlareActionItem } from "../../shared/contracts/action-menu";

type MenuAction = FlareActionItem<string | Component>;

const props = defineProps<{
  items: readonly MenuAction[];
  label: string;
  menuId?: string;
  presentation: "anchored" | "sheet";
}>();
const emit = defineEmits<{
  (e: "select", id: string): void;
  /** Escape: the menu closes and focus returns to its trigger. */
  (e: "escape"): void;
  /** Tab: the menu closes and focus moves on. */
  (e: "tab"): void;
}>();

const root = ref<HTMLElement | null>(null);
const entries = computed(() => actionMenuEntries(props.items));

function glyphName(icon: MenuAction["icon"]): FlareIconName | null {
  return typeof icon === "string" && icon in flareIcons ? (icon as FlareIconName) : null;
}
function glyphComponent(icon: MenuAction["icon"]): Component | null {
  return icon && typeof icon !== "string" ? icon : null;
}
// Labels line up when any item has an icon, so an item without one keeps the icon column.
const iconColumn = computed(() => entries.value.some((entry) => entry.kind === "item" && (glyphName(entry.item.icon) || glyphComponent(entry.item.icon))));

function itemElements(): HTMLElement[] {
  return root.value ? Array.from(root.value.querySelectorAll<HTMLElement>("[data-action-menu-item]")) : [];
}

function focusAt(index: number): void {
  const elements = itemElements();
  if (elements.length) elements[(index + elements.length) % elements.length]?.focus();
}

function onKeydown(event: KeyboardEvent): void {
  const elements = itemElements();
  const current = elements.indexOf(document.activeElement as HTMLElement);
  switch (event.key) {
    case "ArrowDown":
      event.preventDefault();
      focusAt(current + 1);
      break;
    case "ArrowUp":
      event.preventDefault();
      focusAt(current < 0 ? elements.length - 1 : current - 1);
      break;
    case "Home":
      event.preventDefault();
      focusAt(0);
      break;
    case "End":
      event.preventDefault();
      focusAt(elements.length - 1);
      break;
    case "Escape":
      event.preventDefault();
      event.stopPropagation();
      emit("escape");
      break;
    case "Tab":
      emit("tab");
      break;
  }
}

function choose(item: MenuAction): void {
  if (item.enabled !== false) emit("select", item.id);
}

onMounted(() => {
  void nextTick(() => {
    const elements = itemElements();
    const first = elements.find((element) => element.getAttribute("aria-disabled") !== "true") ?? elements[0];
    first?.focus({ preventScroll: true });
  });
});
</script>

<template>
  <div
    :id="menuId"
    ref="root"
    role="menu"
    :aria-label="label"
    class="flare-action-menu"
    :class="`flare-action-menu--${presentation}`"
    @keydown="onKeydown"
  >
    <template v-for="entry in entries" :key="entry.kind === 'item' ? entry.item.id : entry.key">
      <div v-if="entry.kind === 'separator'" role="separator" class="flare-action-menu__separator" />
      <button
        v-else
        type="button"
        tabindex="-1"
        data-action-menu-item
        class="flare-action-menu__item"
        :class="{ 'is-danger': entry.item.danger, 'is-disabled': entry.item.enabled === false }"
        :role="entry.item.pressed === undefined ? 'menuitem' : 'menuitemcheckbox'"
        :aria-checked="entry.item.pressed === undefined ? undefined : entry.item.pressed"
        :aria-disabled="entry.item.enabled === false ? true : undefined"
        :aria-label="entry.item.accessibilityLabel"
        :data-action-id="entry.item.id"
        @click="choose(entry.item)"
      >
        <span v-if="iconColumn" class="flare-action-menu__icon">
          <FlareIcon v-if="glyphName(entry.item.icon)" :name="glyphName(entry.item.icon)!" />
          <n-icon v-else-if="glyphComponent(entry.item.icon)" aria-hidden="true" :component="glyphComponent(entry.item.icon)!" />
        </span>
        <span class="flare-action-menu__text">
          <span class="flare-action-menu__label">{{ entry.item.label }}</span>
          <span v-if="entry.item.enabled === false && entry.item.disabledReason" class="flare-action-menu__reason">{{ entry.item.disabledReason }}</span>
        </span>
        <span v-if="entry.item.badge" class="flare-action-menu__badge">{{ entry.item.badge }}</span>
        <span v-if="entry.item.pressed" class="flare-action-menu__check">
          <FlareIcon name="check" />
        </span>
      </button>
    </template>
  </div>
</template>

<style scoped>
.flare-action-menu {
  display: flex;
  flex-direction: column;
  box-sizing: border-box;
  outline: none;
}
.flare-action-menu--anchored {
  min-width: 12em;
  max-width: min(22em, calc(100vw - 2 * var(--flare-size-spacing-lg)));
  max-height: min(32em, calc(100vh - 2 * var(--flare-size-spacing-lg)));
  overflow-y: auto;
  padding: var(--flare-size-spacing-xs);
  border: 1px solid var(--flare-color-border-primary);
  border-radius: var(--flare-size-radius-lg);
  background: var(--flare-color-bg-elevated);
  box-shadow: var(--flare-shadow-lg);
}
.flare-action-menu--sheet {
  padding-bottom: var(--flare-size-spacing-sm);
}
.flare-action-menu__item {
  display: flex;
  align-items: center;
  gap: var(--flare-size-spacing-sm);
  width: 100%;
  min-height: var(--flare-size-layout-control-height-md);
  box-sizing: border-box;
  padding: var(--flare-size-spacing-xs) var(--flare-size-spacing-md);
  border: 0;
  border-radius: var(--flare-size-radius-md);
  background: transparent;
  color: var(--flare-color-text-primary);
  font: inherit;
  font-size: var(--flare-size-font-size-lg);
  line-height: 1.35;
  text-align: start;
  overflow-wrap: anywhere;
  cursor: pointer;
}
.flare-action-menu--sheet .flare-action-menu__item {
  min-height: var(--flare-size-layout-touch-target);
  padding-inline: var(--flare-size-spacing-lg);
  border-radius: 0;
}
@media (pointer: coarse) {
  .flare-action-menu__item {
    min-height: var(--flare-size-layout-touch-target);
  }
}
@media (hover: hover) {
  .flare-action-menu__item:not(.is-disabled):hover {
    background: var(--flare-color-bg-hover);
  }
}
.flare-action-menu__item:focus-visible {
  outline: 2px solid var(--flare-color-border-selected);
  outline-offset: -2px;
}
.flare-action-menu__item.is-danger {
  color: var(--flare-color-error-text);
}
.flare-action-menu__item.is-disabled {
  color: var(--flare-color-text-disabled);
  cursor: not-allowed;
}
.flare-action-menu__icon {
  display: grid;
  flex: 0 0 auto;
  place-items: center;
  width: var(--flare-size-icon-size-md);
  height: var(--flare-size-icon-size-md);
  color: var(--flare-color-text-secondary);
  font-size: var(--flare-size-icon-size-md);
}
.flare-action-menu__item.is-danger .flare-action-menu__icon,
.flare-action-menu__item.is-disabled .flare-action-menu__icon {
  color: inherit;
}
.flare-action-menu__text {
  display: flex;
  flex: 1 1 auto;
  flex-direction: column;
  min-width: 0;
}
.flare-action-menu__reason {
  color: var(--flare-color-text-tertiary);
  font-size: var(--flare-size-font-size-sm);
}
.flare-action-menu__badge {
  flex: 0 0 auto;
  color: var(--flare-color-text-secondary);
  font-size: var(--flare-size-font-size-sm);
  font-variant-numeric: tabular-nums;
}
.flare-action-menu__check {
  display: grid;
  flex: 0 0 auto;
  place-items: center;
  color: var(--flare-color-primary-text);
}
.flare-action-menu__separator {
  flex: 0 0 auto;
  height: 1px;
  margin: var(--flare-size-spacing-xs) var(--flare-size-spacing-sm);
  background: var(--flare-color-border-primary);
}
.flare-action-menu--sheet .flare-action-menu__separator {
  margin-inline: var(--flare-size-spacing-lg);
}
</style>
