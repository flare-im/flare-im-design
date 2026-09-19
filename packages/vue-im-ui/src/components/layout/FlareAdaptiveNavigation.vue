<script setup lang="ts">
import { computed, nextTick, ref } from "vue";
import {
  resolveNavigationPresentation,
  type FlareApplicationResponsiveMode,
  type FlareNavigationGroup,
  type FlareNavigationItem,
  type FlareNavigationPresentation,
} from "../../shared/contracts/application";
import FlareGlyph from "../general/FlareGlyph.vue";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";

const props = withDefaults(defineProps<{
  groups: readonly FlareNavigationGroup[];
  activeId: string;
  responsiveMode: FlareApplicationResponsiveMode;
  presentation?: FlareNavigationPresentation;
  label?: string;
}>(), { label: "" });

const emit = defineEmits<{ (event: "navigate", id: string): void }>();
const { t } = useFlareI18nOptional();

/**
 * The kit's own default entries carry English labels in the data contract
 * (FLARE_DEFAULT_IM_NAVIGATION / FLARE_DEFAULT_CONTACT_NAVIGATION), so they are translated here,
 * at render time, the way ConversationHeader translates its default action labels: an item whose
 * label is still the default for its id reads from the strings table, and a host's own wording is
 * left alone. The three native kits build their defaults from the strings table instead, which
 * arrives at the same words.
 */
const DEFAULT_NAVIGATION_LABELS: Record<string, string> = {
  chats: "Chats",
  contacts: "Contacts",
  profile: "Profile",
  friends: "Friends",
  groups: "Groups",
  newFriends: "New Friends",
  favorites: "Favorites",
};

function itemLabel(item: FlareNavigationItem): string {
  return item.label === DEFAULT_NAVIGATION_LABELS[item.id] ? t(`navigation.${item.id}`) : item.label;
}
const visibleGroups = computed(() => props.groups.map((group) => ({
  ...group,
  items: group.items.filter((item) => item.visible !== false),
})).filter((group) => group.items.length));
const items = computed(() => visibleGroups.value.flatMap((group) => group.items));
const resolvedPresentation = computed(() => props.presentation ?? resolveNavigationPresentation(props.responsiveMode));
const buttons = ref<HTMLButtonElement[]>([]);

function badgeText(item: FlareNavigationItem): string {
  if (!item.badge) return "";
  if (item.badge.kind === "dot") return "";
  if (item.badge.kind === "mention") return item.badge.label ?? "@";
  const count = Math.max(0, item.badge.count ?? 0);
  return count > 99 ? "99+" : String(count);
}

function badgeLabel(item: FlareNavigationItem): string | undefined {
  if (!item.badge) return undefined;
  return item.badge.label || item.accessibilityLabel || itemLabel(item);
}

async function moveFocus(current: number, delta: number): Promise<void> {
  const candidates = items.value.map((item, index) => ({ item, index })).filter(({ item }) => !item.disabled);
  if (!candidates.length) return;
  const at = Math.max(0, candidates.findIndex(({ index }) => index === current));
  const next = candidates[(at + delta + candidates.length) % candidates.length].index;
  await nextTick();
  buttons.value[next]?.focus();
}

function onKeydown(event: KeyboardEvent, index: number): void {
  const vertical = resolvedPresentation.value !== "bottom";
  const previous = vertical ? event.key === "ArrowUp" : event.key === "ArrowLeft";
  const next = vertical ? event.key === "ArrowDown" : event.key === "ArrowRight";
  if (previous || next) {
    event.preventDefault();
    void moveFocus(index, previous ? -1 : 1);
  } else if (event.key === "Home" || event.key === "End") {
    event.preventDefault();
    const target = event.key === "Home" ? buttons.value.find((button) => !button.disabled) : [...buttons.value].reverse().find((button) => !button.disabled);
    target?.focus();
  }
}
</script>

<template>
  <nav class="flare-adaptive-navigation" :data-presentation="resolvedPresentation" :aria-label="label || undefined">
    <div
      v-for="(group, groupIndex) in visibleGroups"
      :key="group.id"
      class="flare-adaptive-navigation__group"
      :class="{ 'is-trailing': visibleGroups.length > 1 && groupIndex === visibleGroups.length - 1 }"
      role="group"
      :aria-label="group.label || undefined"
    >
      <span v-if="group.label && resolvedPresentation === 'expandedSidebar'" class="flare-adaptive-navigation__group-label">{{ group.label }}</span>
      <button
        v-for="item in group.items"
        :key="item.id"
        :ref="(element) => { if (element) buttons[items.indexOf(item)] = element as HTMLButtonElement }"
        type="button"
        class="flare-adaptive-navigation__item"
        :class="{ 'is-active': item.id === activeId }"
        :disabled="item.disabled"
        :aria-current="item.id === activeId ? 'page' : undefined"
        :aria-label="item.accessibilityLabel || itemLabel(item)"
        :title="resolvedPresentation === 'rail' ? itemLabel(item) : undefined"
        @click="emit('navigate', item.id)"
        @keydown="onKeydown($event, items.indexOf(item))"
      >
        <span class="flare-adaptive-navigation__icon">
          <FlareGlyph :icon="item.icon || 'comment'" :size="resolvedPresentation === 'rail' ? 24 : 20" />
          <span
            v-if="item.badge"
            class="flare-adaptive-navigation__badge"
            :data-kind="item.badge.kind"
            :aria-label="badgeLabel(item)"
          >{{ badgeText(item) }}</span>
        </span>
        <span class="flare-adaptive-navigation__label">{{ itemLabel(item) }}</span>
      </button>
    </div>
  </nav>
</template>

<style scoped>
.flare-adaptive-navigation {
  display: flex;
  gap: var(--flare-size-spacing-xs);
  height: 100%;
  box-sizing: border-box;
  color: var(--flare-color-text-secondary);
  background: var(--flare-color-bg-secondary);
}
.flare-adaptive-navigation:not([data-presentation="bottom"]) {
  flex-direction: column;
  width: var(--flare-size-layout-navigation-rail-width);
  padding: var(--flare-size-spacing-lg) var(--flare-size-spacing-xs) var(--flare-size-spacing-md);
  border-inline-end: 1px solid var(--flare-color-border-primary);
}
.flare-adaptive-navigation[data-presentation="rail"] { gap: var(--flare-size-spacing-md); background: var(--flare-color-bg-secondary); }
.flare-adaptive-navigation[data-presentation="sidebar"],
.flare-adaptive-navigation[data-presentation="expandedSidebar"] { width: var(--flare-size-layout-primary-pane-min-width); padding-inline: var(--flare-size-spacing-sm); }
.flare-adaptive-navigation[data-presentation="expandedSidebar"] { width: var(--flare-size-layout-primary-pane-default-width); }
.flare-adaptive-navigation[data-presentation="bottom"] {
  flex-direction: row;
  width: 100%;
  height: auto;
  padding: var(--flare-size-spacing-xs) max(var(--flare-size-spacing-xs), env(safe-area-inset-right)) max(var(--flare-size-spacing-xs), env(safe-area-inset-bottom)) max(var(--flare-size-spacing-xs), env(safe-area-inset-left));
  overflow-x: auto;
  border-top: 1px solid var(--flare-color-border-primary);
  background: var(--flare-color-bg-primary);
}
.flare-adaptive-navigation__group { display: flex; flex-direction: column; gap: var(--flare-size-spacing-xs); width: 100%; min-width: 0; }
.flare-adaptive-navigation[data-presentation="bottom"] .flare-adaptive-navigation__group { display: contents; }
.flare-adaptive-navigation[data-presentation="rail"] .flare-adaptive-navigation__group.is-trailing { margin-block-start: auto; }
.flare-adaptive-navigation__group-label { padding: var(--flare-size-spacing-md) var(--flare-size-spacing-sm) var(--flare-size-spacing-xs); color: var(--flare-color-text-tertiary); font-size: var(--flare-size-font-size-xs); font-weight: 600; }
.flare-adaptive-navigation__item {
  position: relative;
  display: flex;
  flex: none;
  align-items: center;
  justify-content: flex-start;
  gap: var(--flare-size-spacing-sm);
  min-width: var(--flare-size-layout-touch-target);
  min-height: var(--flare-size-layout-touch-target);
  padding: var(--flare-size-spacing-sm);
  border: 0;
  border-radius: var(--flare-size-radius-md);
  color: inherit;
  background: transparent;
  cursor: pointer;
  font: inherit;
  text-align: start;
}
.flare-adaptive-navigation[data-presentation="rail"] .flare-adaptive-navigation__item {
  align-self: center;
  flex-direction: column;
  justify-content: center;
  gap: var(--flare-size-spacing-xs);
  width: calc(var(--flare-size-layout-navigation-rail-width) - var(--flare-size-spacing-sm));
  height: 60px;
  padding: 0;
}
.flare-adaptive-navigation[data-presentation="bottom"] .flare-adaptive-navigation__item {
  flex: 1 1 var(--flare-size-layout-touch-target);
  min-width: var(--flare-size-layout-touch-target);
  flex-direction: column;
  gap: 2px;
  padding-block: var(--flare-size-spacing-xs);
  padding-inline: 2px;
}
.flare-adaptive-navigation__item:hover:not(:disabled) { background: var(--flare-color-bg-hover); }
.flare-adaptive-navigation__item.is-active { color: var(--flare-color-primary-text); background: var(--flare-color-bg-selected); }
.flare-adaptive-navigation__item:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: -2px; }
.flare-adaptive-navigation__item:disabled { opacity: var(--flare-opacity-disabled); cursor: not-allowed; }
.flare-adaptive-navigation__icon { position: relative; display: inline-flex; align-items: center; justify-content: center; width: var(--flare-size-icon-size-lg); height: var(--flare-size-icon-size-lg); }
.flare-adaptive-navigation__badge { position: absolute; inset-block-start: -7px; inset-inline-end: -11px; min-width: var(--flare-size-icon-size-sm); height: var(--flare-size-icon-size-sm); padding-inline: var(--flare-size-spacing-xs); box-sizing: border-box; border-radius: var(--flare-size-radius-full); color: white; background: var(--flare-color-error); font-size: 10px; line-height: var(--flare-size-icon-size-sm); text-align: center; }
.flare-adaptive-navigation__badge[data-kind="dot"] { inset-block-start: -2px; inset-inline-end: calc(-1 * var(--flare-size-spacing-xs)); min-width: var(--flare-size-spacing-sm); width: var(--flare-size-spacing-sm); height: var(--flare-size-spacing-sm); padding: 0; }
.flare-adaptive-navigation__badge[data-kind="mention"] { background: var(--flare-color-important); }
.flare-adaptive-navigation__label { min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; font-size: var(--flare-size-font-size-sm); }
.flare-adaptive-navigation[data-presentation="rail"] .flare-adaptive-navigation__label {
  display: block;
  max-width: 100%;
  color: var(--flare-color-text-secondary);
  font-size: var(--flare-size-font-size-sm);
  line-height: 1.2;
}
.flare-adaptive-navigation[data-presentation="rail"] .flare-adaptive-navigation__item.is-active .flare-adaptive-navigation__label {
  color: var(--flare-color-primary-text);
  font-weight: 600;
}
@media (prefers-reduced-motion: reduce) {
  .flare-adaptive-navigation__item { transition: none; }
}
</style>
