<script setup lang="ts">
import { computed, h, nextTick, ref, watch } from "vue";
import { NSelect, NButton, NAvatar, NText, type SelectOption } from "naive-ui";

export interface FlareAdminEntityOption extends SelectOption {
  value: string;
  label: string;
  title?: string;
  description?: string;
  disabled?: boolean;
}
const props = withDefaults(
  defineProps<{
    value?: string;
    values?: string[];
    multiple?: boolean;
    clearable?: boolean;
    /** Keep true for host searches; false filters a complete local directory. */
    remote?: boolean;
    options: FlareAdminEntityOption[];
    label: string;
    placeholder: string;
    emptyText: string;
    error?: string;
    loading?: boolean;
    disabled?: boolean;
    hasMore?: boolean;
    moreText: string;
    retryText: string;
    max?: number;
    selectionSummary?: boolean;
    selectedText?: string;
    manageText?: string;
    collapseText?: string;
    clearText?: string;
    removeText?: string;
  }>(),
  { value: "", multiple: false, clearable: true, remote: true, max: 200 },
);
const emit = defineEmits<{
  "update:value": [string];
  "update:values": [string[]];
  search: [string];
  open: [];
  more: [];
  retry: [];
}>();
const selected = computed(() =>
  props.multiple ? (props.values ?? []) : props.value || null,
);
const expanded = ref(false),
  menuOpen = ref(false);
const summary = ref<HTMLElement | null>(null);
function remove(id: string) {
  if (props.disabled) return;
  select((props.values ?? []).filter((value) => value !== id));
  void nextTick(() => {
    if (!props.disabled) summary.value?.focus({ preventScroll: true });
  });
}
function manageSelection() {
  if (props.disabled) return;
  menuOpen.value = false;
  expanded.value = !expanded.value;
}
function showMenu(show: boolean) {
  menuOpen.value = show && !props.disabled;
  if (menuOpen.value) emit("open");
}
function onKeydown(event: KeyboardEvent) {
  if (event.key === "Escape" && menuOpen.value) {
    event.preventDefault();
    event.stopPropagation();
    menuOpen.value = false;
  }
}
const selectedOptions = computed(() =>
  (props.values ?? [])
    .map((id) => props.options.find((o) => o.value === id))
    .filter((o): o is FlareAdminEntityOption => !!o),
);
const choiceOptions = computed(() =>
  props.options.map((option) =>
    props.multiple &&
    (props.values?.length ?? 0) >= props.max &&
    !props.values?.includes(option.value)
      ? { ...option, disabled: true }
      : option,
  ),
);
watch(
  () => [props.disabled, props.values?.length],
  () => {
    if (props.disabled || !props.values?.length) expanded.value = false;
    if (props.disabled) menuOpen.value = false;
  },
);
function renderLabel(option: SelectOption, selected: boolean) {
  const item = option as FlareAdminEntityOption;
  if (!item.title) return item.label;
  if (selected)
    return h(
      "span",
      { title: item.label, class: "flare-admin-entity-select__selected-label" },
      item.title,
    );
  return h(
    "div",
    { class: "flare-admin-entity-select__option", title: item.label },
    [
      h(
        NAvatar,
        { size: 28, round: true, "aria-hidden": true },
        () => Array.from(item.title!)[0],
      ),
      h("div", { class: "flare-admin-entity-select__identity" }, [
        h("div", { class: "flare-admin-entity-select__name" }, item.title),
        item.description
          ? h(
              "div",
              { class: "flare-admin-entity-select__description" },
              item.description,
            )
          : null,
      ]),
    ],
  );
}
const EntityLabel = (props: { option: FlareAdminEntityOption }) =>
  renderLabel(props.option, false);
function select(value: string | number | Array<string | number> | null) {
  if (props.disabled || (value === null && !props.clearable)) return;
  const available = new Set(
    props.options.filter((o) => !o.disabled).map((o) => o.value),
  );
  // An unavailable persisted value may be retained while removing another tag;
  // it must never be introduced as a new selection.
  const retained = new Set(props.values ?? []);
  if (props.multiple) {
    if (value !== null && !Array.isArray(value)) return;
    const ids = value === null ? [] : value;
    if (
      (ids.length <= props.max ||
        (ids.length < retained.size &&
          ids.every((id) => retained.has(String(id))))) &&
      ids.every(
        (id) =>
          typeof id === "string" && (available.has(id) || retained.has(id)),
      )
    ) {
      emit("update:values", [...new Set(ids as string[])]);
    }
  } else if (
    value === null ||
    (typeof value === "string" && available.has(value))
  ) {
    emit("update:value", value ?? "");
  }
}
</script>
<template>
  <div class="flare-admin-entity-select" @keydown.capture="onKeydown">
    <div
      v-if="multiple && selectionSummary"
      ref="summary"
      class="flare-admin-entity-select__summary"
      role="group"
      :aria-label="selectedText"
      tabindex="-1"
    >
      <NText
        depth="3"
        :type="(values?.length ?? 0) > max ? 'warning' : undefined"
        role="status"
        >{{ selectedText }}</NText
      >
      <div
        v-if="clearable && values?.length"
        class="flare-admin-entity-select__summary-actions"
      >
        <NButton
          size="small"
          text
          type="primary"
          :disabled="disabled"
          :aria-expanded="expanded"
          @click="manageSelection"
          >{{ expanded ? collapseText : manageText }}</NButton
        >
        <NButton
          size="small"
          text
          :disabled="disabled"
          @click="
            menuOpen = false;
            select(null);
          "
          >{{ clearText }}</NButton
        >
      </div>
    </div>
    <NSelect
      :show="menuOpen"
      :value="selected"
      :multiple="multiple"
      :options="choiceOptions"
      :loading="loading"
      :disabled="disabled"
      :placeholder="placeholder"
      :aria-label="label"
      :input-props="{ 'aria-label': label, 'aria-invalid': !!error }"
      :status="error ? 'error' : undefined"
      :max="multiple ? max : undefined"
      :max-tag-count="'responsive'"
      :render-label="renderLabel"
      :reset-menu-on-options-change="false"
      :consistent-menu-width="true"
      size="small"
      filterable
      :remote="remote"
      :clearable="clearable"
      @search="emit('search', $event)"
      @update:value="select"
      @update:show="showMenu"
    >
      <template #empty>{{ error || emptyText }}</template>
      <template v-if="hasMore || error" #action>
        <NButton
          v-if="error"
          size="small"
          text
          :disabled="disabled || loading"
          @click="emit('retry')"
          >{{ retryText }}</NButton
        >
        <NButton
          v-else
          size="small"
          text
          :loading="loading"
          :disabled="disabled || loading"
          @click="emit('more')"
          >{{ moreText }}</NButton
        >
      </template>
    </NSelect>
    <template v-if="multiple && selectionSummary">
      <div
        v-if="expanded && selectedOptions.length"
        class="flare-admin-entity-select__members"
        role="list"
        :aria-label="selectedText"
      >
        <div v-for="item in selectedOptions" :key="item.value" role="listitem">
          <div class="flare-admin-entity-select__member-info">
            <EntityLabel :option="item" />
          </div>
          <NButton
            size="small"
            text
            :disabled="disabled"
            :aria-label="`${removeText} ${item.title || item.label}`"
            @click="remove(item.value)"
            >{{ removeText }}</NButton
          >
        </div>
      </div>
    </template>
    <div v-if="error" class="flare-admin-entity-select__error" role="status">
      {{ error }}
    </div>
  </div>
</template>
<style scoped>
.flare-admin-entity-select {
  min-width: 0;
  width: 100%;
  max-width: 100%;
}
.flare-admin-entity-select__error {
  color: var(--flare-color-error-text);
  font-size: 12px;
  overflow-wrap: anywhere;
  margin-top: var(--flare-size-spacing-xs, 4px);
}
.flare-admin-entity-select__option {
  display: flex;
  align-items: center;
  gap: var(--flare-size-spacing-sm, 8px);
  min-width: 0;
  padding-block: var(--flare-size-spacing-xs, 4px);
}
.flare-admin-entity-select__identity {
  min-width: 0;
  flex: 1;
}
.flare-admin-entity-select__name,
.flare-admin-entity-select__description,
.flare-admin-entity-select__selected-label {
  display: block;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.flare-admin-entity-select__description {
  color: var(--flare-color-text-secondary);
  font-size: var(--flare-size-font-size-xs, 11px);
}
.flare-admin-entity-select__summary {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  justify-content: space-between;
  gap: var(--flare-size-spacing-xs, 4px) var(--flare-size-spacing-sm, 8px);
  margin-bottom: var(--flare-size-spacing-xs, 4px);
  font-size: var(--flare-size-font-size-xs, 11px);
}
.flare-admin-entity-select__summary-actions,
.flare-admin-entity-select__members {
  display: flex;
  flex-wrap: wrap;
  gap: var(--flare-size-spacing-sm, 8px);
  min-width: 0;
}
.flare-admin-entity-select__members {
  flex-direction: column;
  flex-wrap: nowrap;
  max-height: 128px;
  overflow: auto;
  padding-block: var(--flare-size-spacing-xs, 4px);
}
.flare-admin-entity-select__members > div {
  display: flex;
  align-items: center;
  gap: var(--flare-size-spacing-xs, 4px);
  min-width: 0;
  max-width: 100%;
  width: 100%;
}
.flare-admin-entity-select__member-info {
  flex: 1;
  min-width: 0;
}
</style>
