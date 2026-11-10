<script setup lang="ts">
import { computed, h, nextTick, ref, watch } from "vue";
import { NMenu, type MenuOption } from "naive-ui";
import FlareGlyph from "../general/FlareGlyph.vue";

export interface FlareAdminWorkspaceNavigationItem {
  key: string;
  label: string;
  disabled?: boolean;
}

export interface FlareAdminWorkspaceNavigationGroup {
  key: string;
  label: string;
  icon?: string;
  disabled?: boolean;
  items: readonly FlareAdminWorkspaceNavigationItem[];
}

/** Presentation only: the host supplies visible destinations and owns routing and permissions. */
const props = withDefaults(defineProps<{
  groups: readonly FlareAdminWorkspaceNavigationGroup[];
  value?: string | null;
  label: string;
  disabled?: boolean;
}>(), { value: null, disabled: false });
const emit = defineEmits<{
  (event: "update:value", value: string): void;
  (event: "change", value: string): void;
}>();
const root = ref<HTMLElement>();
const expandedKeys = ref<string[]>([]);
const selectedGroup = computed(() => props.groups.find((group) => group.items.some((item) => item.key === props.value)));
watch([() => props.value, selectedGroup], () => {
  expandedKeys.value = selectedGroup.value ? [selectedGroup.value.key] : [];
}, { immediate: true });

function groupDisabled(group: FlareAdminWorkspaceNavigationGroup): boolean {
  return props.disabled || !!group.disabled || !group.items.length;
}
const options = computed<MenuOption[]>(() => props.groups.map((group) => ({
  key: group.key,
  label: group.label,
  icon: group.icon ? () => h(FlareGlyph, { icon: group.icon, size: 20 }) : undefined,
  disabled: groupDisabled(group),
  children: group.items.map((item) => ({
    key: item.key,
    label: item.label,
    disabled: groupDisabled(group) || !!item.disabled,
  })),
})));
const visibleKeys = computed(() => props.groups.flatMap((group) => {
  if (groupDisabled(group)) return [];
  return [group.key, ...(expandedKeys.value.includes(group.key)
    ? group.items.filter((item) => !item.disabled).map((item) => item.key) : [])];
}));

function select(value: string | number): void {
  const group = props.groups.find((candidate) => candidate.items.some((item) => item.key === value));
  const item = group?.items.find((candidate) => candidate.key === value);
  if (!group || groupDisabled(group) || !item || item.disabled) return;
  emit("update:value", item.key);
  emit("change", item.key);
}

function toggle(group: FlareAdminWorkspaceNavigationGroup): void {
  if (groupDisabled(group)) return;
  expandedKeys.value = expandedKeys.value.includes(group.key) ? [] : [group.key];
}

async function focus(key: string | undefined): Promise<void> {
  await nextTick();
  if (!key) return;
  Array.from(root.value?.querySelectorAll<HTMLElement>("[data-workspace-key]") ?? [])
    .find((element) => element.dataset.workspaceKey === key)?.focus();
}

function onKeydown(event: KeyboardEvent): void {
  if (!(event.target instanceof HTMLElement)) return;
  const target = event.target.closest<HTMLElement>("[data-workspace-key]");
  const key = target?.dataset.workspaceKey;
  if (!key || target.getAttribute("aria-disabled") === "true") return;
  const group = props.groups.find((candidate) => candidate.key === key);
  const parent = props.groups.find((candidate) => candidate.items.some((item) => item.key === key));
  const index = visibleKeys.value.indexOf(key);
  if (event.key === "Enter" || event.key === " ") {
    if (group) toggle(group);
    else select(key);
  } else if (event.key === "ArrowDown" || event.key === "ArrowUp") {
    const delta = event.key === "ArrowDown" ? 1 : -1;
    void focus(visibleKeys.value[(index + delta + visibleKeys.value.length) % visibleKeys.value.length]);
  } else if (event.key === "Home" || event.key === "End") {
    void focus(event.key === "Home" ? visibleKeys.value[0] : visibleKeys.value.at(-1));
  } else if (event.key === "ArrowRight" && group) {
    if (expandedKeys.value.includes(group.key)) void focus(group.items.find((item) => !item.disabled)?.key);
    else expandedKeys.value = [group.key];
  } else if (event.key === "ArrowLeft" && (group || parent)) {
    if (group) expandedKeys.value = [];
    else void focus(parent?.key);
  } else return;
  event.preventDefault();
  event.stopPropagation();
}

function nodeProps(option: MenuOption) {
  const key = String(option.key);
  const group = props.groups.find((candidate) => candidate.key === key);
  const disabled = props.disabled || !!option.disabled;
  return {
    "data-workspace-key": key,
    title: typeof option.label === "string" ? option.label : undefined,
    "aria-label": typeof option.label === "string" ? option.label : undefined,
    tabindex: disabled ? -1 : 0,
    "aria-disabled": disabled ? "true" as const : undefined,
    "aria-current": !group && key === props.value ? "page" as const : undefined,
    "aria-expanded": group ? (expandedKeys.value.includes(key) ? "true" as const : "false" as const) : undefined,
  };
}
</script>

<template>
  <nav ref="root" class="flare-admin-workspace-navigation" :aria-label="label" @keydown="onKeydown">
    <NMenu
      :options="options"
      :value="value"
      :expanded-keys="expandedKeys"
      :disabled="disabled"
      :node-props="nodeProps"
      :root-indent="12"
      :indent="20"
      :theme-overrides="{ itemHeight: 'var(--flare-size-layout-touch-target)' }"
      accordion
      @update:expanded-keys="expandedKeys = $event.map(String)"
      @update:value="select"
    />
  </nav>
</template>

<style scoped>
.flare-admin-workspace-navigation {
  min-width: 0;
}
.flare-admin-workspace-navigation :deep([data-workspace-key]:focus-visible) {
  outline: 2px solid var(--flare-color-border-selected);
  outline-offset: -2px;
  border-radius: var(--flare-size-radius-md);
}
</style>
