<script setup lang="ts">
/** Compact Naive selection surface; never grants, fetches, expands bundles or owns a save. */
import { computed, ref } from "vue";
import {
  NButton,
  NCheckbox,
  NEmpty,
  NInput,
  NRadioButton,
  NRadioGroup,
  NSelect,
  NTag,
} from "naive-ui";
import { ChevronDown, ChevronRight } from "@lucide/vue";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";
import FlareAdminHelp from "./FlareAdminHelp.vue";
import {
  filterPermissionWorkbench,
  permissionWorkbenchChanges,
  permissionWorkbenchItems,
  togglePermissionWorkbench,
  type FlarePermissionFilter,
  type FlarePermissionGroup,
} from "./permission-workbench";
const props = withDefaults(
  defineProps<{
    groups: readonly FlarePermissionGroup[];
    baselineKeys?: readonly string[];
    disabled?: boolean;
    height?: string;
    label?: string;
  }>(),
  { baselineKeys: () => [], disabled: false, height: "480px" },
);
const checkedKeys = defineModel<string[]>("checkedKeys", { default: () => [] });
const emit = defineEmits<{ reset: [] }>();
const { t } = useFlareI18nOptional();
const query = ref(""),
  mode = ref<FlarePermissionFilter>("all"),
  active = ref("");
const open = ref(new Set<string>());
const checked = computed(() => new Set(checkedKeys.value));
const items = computed(() => permissionWorkbenchItems(props.groups));
const changes = computed(() =>
  permissionWorkbenchChanges(
    props.groups,
    checkedKeys.value,
    props.baselineKeys,
  ),
);
const added = computed(
  () => changes.value.filter((entry) => entry.added).length,
);
const removed = computed(() => changes.value.length - added.value);
const totals = computed(() => ({
  menus: items.value.filter(
    (item) => item.kind === "menu" && checked.value.has(item.key),
  ).length,
  buttons: items.value.filter(
    (item) => item.kind === "button" && checked.value.has(item.key),
  ).length,
}));
const filtered = computed(() =>
  filterPermissionWorkbench(
    props.groups,
    query.value,
    mode.value,
    checkedKeys.value,
    props.baselineKeys,
  ),
);
const group = computed(
  () =>
    filtered.value.find((entry) => entry.key === active.value) ??
    filtered.value[0],
);
const groupOptions = computed(() =>
  filtered.value.map((entry) => ({ value: entry.key, label: entry.label })),
);
function count(key: string) {
  const source = props.groups.find((entry) => entry.key === key);
  return source
    ? permissionWorkbenchItems([source]).filter((item) =>
        checked.value.has(item.key),
      ).length
    : 0;
}
function toggle(key: string, value: boolean) {
  if (!props.disabled)
    checkedKeys.value = togglePermissionWorkbench(
      props.groups,
      checkedKeys.value,
      key,
      value,
    );
}
function isOpen(key: string) {
  return !!query.value.trim() || mode.value !== "all" || open.value.has(key);
}
function fold(key: string) {
  const next = new Set(open.value);
  if (next.has(key)) next.delete(key);
  else next.add(key);
  open.value = next;
}
</script>
<template>
  <section
    class="flare-permission-workbench"
    :style="{ height }"
    :aria-label="label || t('permissionWorkbench.label')"
  >
    <header class="flare-permission-workbench__toolbar">
      <FlareAdminHelp v-if="$slots.help" :label="t('permissionWorkbench.help')"
        ><slot name="help"
      /></FlareAdminHelp>
      <NInput
        v-model:value="query"
        size="small"
        clearable
        class="flare-permission-workbench__search"
        :placeholder="t('permissionWorkbench.search')"
        :input-props="{ 'aria-label': t('permissionWorkbench.search') }"
      />
      <NRadioGroup
        v-model:value="mode"
        size="small"
        :aria-label="t('permissionWorkbench.filter')"
      >
        <NRadioButton value="all">{{
          t("permissionWorkbench.all")
        }}</NRadioButton>
        <NRadioButton value="selected">{{
          t("permissionWorkbench.selected")
        }}</NRadioButton>
        <NRadioButton value="changed">{{
          t("permissionWorkbench.changed")
        }}</NRadioButton>
      </NRadioGroup>
      <NButton
        size="small"
        :disabled="disabled || !changes.length"
        @click="emit('reset')"
        >{{ t("permissionWorkbench.reset") }}</NButton
      >
    </header>
    <div class="flare-permission-workbench__status" aria-live="polite">
      <span>{{ t("permissionWorkbench.total", totals) }}</span>
      <span>{{ t("permissionWorkbench.delta", { added, removed }) }}</span>
    </div>
    <div
      v-if="filtered.length"
      class="flare-permission-workbench__mobile-groups"
    >
      <NSelect
        :value="group?.key"
        :options="groupOptions"
        size="small"
        :aria-label="t('permissionWorkbench.groups')"
        @update:value="active = $event"
      />
    </div>
    <div class="flare-permission-workbench__body">
      <nav
        class="flare-permission-workbench__groups"
        :aria-label="t('permissionWorkbench.groups')"
      >
        <NButton
          v-for="entry in filtered"
          :key="entry.key"
          size="small"
          block
          :type="group?.key === entry.key ? 'primary' : 'default'"
          :quaternary="group?.key !== entry.key"
          :aria-current="group?.key === entry.key ? 'true' : undefined"
          @click="active = entry.key"
        >
          {{ entry.label }}
          <span class="flare-permission-workbench__count">{{
            count(entry.key)
          }}</span>
        </NButton>
      </nav>
      <div class="flare-permission-workbench__menus" :aria-label="group?.label">
        <NEmpty v-if="!group" :description="t('permissionWorkbench.empty')" />
        <section
          v-for="menu in group?.menus || []"
          :key="menu.key"
          class="flare-permission-workbench__menu"
        >
          <div class="flare-permission-workbench__menu-row">
            <NCheckbox
              :checked="checked.has(menu.key)"
              :disabled="disabled || menu.disabled"
              :aria-disabled="!!(disabled || menu.disabled)"
              @update:checked="toggle(menu.key, $event)"
              >{{ menu.label }}</NCheckbox
            >
            <NButton
              v-if="menu.actions.length"
              size="small"
              quaternary
              :aria-expanded="isOpen(menu.key)"
              :aria-label="
                t('permissionWorkbench.actions', { name: menu.label })
              "
              @click="fold(menu.key)"
            >
              {{
                t("permissionWorkbench.buttonCount", {
                  count: menu.actions.length,
                })
              }}
              <ChevronDown
                v-if="isOpen(menu.key)"
                :size="14"
                aria-hidden="true"
              /><ChevronRight v-else :size="14" aria-hidden="true" />
            </NButton>
          </div>
          <div
            v-if="menu.actions.length && isOpen(menu.key)"
            class="flare-permission-workbench__actions"
          >
            <NCheckbox
              v-for="action in menu.actions"
              :key="action.key"
              :checked="checked.has(action.key)"
              :disabled="disabled || menu.disabled || action.disabled"
              :aria-disabled="!!(disabled || menu.disabled || action.disabled)"
              @update:checked="toggle(action.key, $event)"
              >{{ action.label }}</NCheckbox
            >
          </div>
        </section>
      </div>
      <aside
        class="flare-permission-workbench__summary"
        :aria-label="t('permissionWorkbench.changed')"
      >
        <h3>{{ t("permissionWorkbench.changed") }}</h3>
        <NEmpty
          v-if="!changes.length"
          size="small"
          :description="t('permissionWorkbench.unchanged')"
        />
        <ul v-else>
          <li v-for="change in changes" :key="change.key">
            <NTag size="small" :type="change.added ? 'success' : 'warning'">{{
              t(
                change.added
                  ? "permissionWorkbench.added"
                  : "permissionWorkbench.removed",
              )
            }}</NTag>
            <span
              >{{ change.label }}<small>{{ change.context }}</small></span
            >
          </li>
        </ul>
      </aside>
    </div>
  </section>
</template>
<style scoped>
.flare-permission-workbench {
  display: flex;
  flex-direction: column;
  min-width: 0;
  min-height: 0;
  max-height: 65dvh;
  border: 1px solid var(--flare-color-border-secondary);
  border-radius: var(--flare-size-radius-md);
  overflow: hidden;
}
.flare-permission-workbench__toolbar {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 8px;
  padding: 12px;
}
.flare-permission-workbench__search {
  flex: 1 1 220px;
  min-width: 0;
}
.flare-permission-workbench__status {
  display: flex;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 8px;
  padding: 0 12px 8px;
  font-size: var(--flare-size-font-size-sm);
  color: var(--flare-color-text-secondary);
}
.flare-permission-workbench__body {
  display: grid;
  grid-template-columns: 148px minmax(0, 1fr) 190px;
  flex: 1;
  min-height: 0;
  border-top: 1px solid var(--flare-color-border-secondary);
}
.flare-permission-workbench__groups,
.flare-permission-workbench__menus,
.flare-permission-workbench__summary {
  min-width: 0;
  min-height: 0;
  overflow: auto;
  overscroll-behavior: contain;
}
.flare-permission-workbench__groups {
  padding: 8px;
  border-right: 1px solid var(--flare-color-border-secondary);
}
.flare-permission-workbench__groups :deep(.n-button) {
  margin-bottom: 4px;
}
.flare-permission-workbench__count {
  margin-inline-start: 8px;
  font-variant-numeric: tabular-nums;
}
.flare-permission-workbench__menu {
  border-bottom: 1px solid var(--flare-color-border-secondary);
}
.flare-permission-workbench__menu-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 8px;
  padding: 8px 12px;
  min-width: 0;
}
.flare-permission-workbench__menu-row :deep(.n-checkbox) {
  min-width: 0;
}
.flare-permission-workbench__menu-row :deep(.n-button) {
  flex: none;
}
.flare-permission-workbench__actions {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(min(100%, 170px), 1fr));
  gap: 12px;
  padding: 4px 12px 12px;
}
.flare-permission-workbench :deep(.n-checkbox__label) {
  white-space: normal;
  overflow-wrap: anywhere;
}
.flare-permission-workbench__summary {
  padding: 12px;
  border-left: 1px solid var(--flare-color-border-secondary);
}
.flare-permission-workbench__summary h3 {
  margin: 0 0 12px;
  font-size: var(--flare-size-font-size-sm);
}
.flare-permission-workbench__summary ul {
  list-style: none;
  margin: 0;
  padding: 0;
}
.flare-permission-workbench__summary li {
  display: flex;
  align-items: flex-start;
  gap: 8px;
  margin-bottom: 12px;
  overflow-wrap: anywhere;
  font-size: var(--flare-size-font-size-sm);
}
.flare-permission-workbench__summary small {
  display: block;
  margin-top: 4px;
  color: var(--flare-color-text-secondary);
}
.flare-permission-workbench__mobile-groups {
  display: none;
}
.flare-permission-workbench__menus :deep(.n-empty) {
  padding: 24px 12px;
}
@media (max-width: 760px) {
  .flare-permission-workbench__body {
    grid-template-columns: minmax(0, 1fr);
  }
  .flare-permission-workbench__groups,
  .flare-permission-workbench__summary {
    display: none;
  }
  .flare-permission-workbench__mobile-groups {
    display: block;
    padding: 0 12px 8px;
  }
  .flare-permission-workbench__toolbar {
    padding: 8px 12px;
  }
}
</style>
