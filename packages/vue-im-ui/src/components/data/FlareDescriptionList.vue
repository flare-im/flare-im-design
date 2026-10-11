<script setup lang="ts">
/**
 * A description list — the facts of one record as label / value lines: a user's ids and dates in a
 * detail drawer, a message's sender, sequence and status, an application's contact. The host owns
 * the record and formats each value; the list lays the lines out, says "not set" for an empty one
 * (a dash on screen, never a blank or a "null"), and offers a copy key on the lines that hold an
 * identifier.
 *
 * It is a real `<dl>`: one `<dt>` and one `<dd>` per line, grouped in a `<div>`. The columns are the
 * list's own business, measured against its container, so the same list reads as two columns in a
 * wide drawer and as one on a phone without the host asking which.
 */
import { computed } from "vue";
import FlareIconButton from "../general/FlareIconButton.vue";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";
import { flareIcons } from "../../shared/icons";
import {
  descriptionColumns,
  descriptionIsEmpty,
  descriptionSpan,
  descriptionText,
  type FlareDescriptionItem,
  type FlareDescriptionLabelPlacement,
} from "./description-list";

const props = withDefaults(
  defineProps<{
    /** The lines, in reading order. */
    items: readonly FlareDescriptionItem[];
    /** Columns on a wide container (1–4). Under 480px of its own width the list is one column. */
    columns?: number;
    /** `start` puts each label beside its value; `top` puts it above. */
    labelPlacement?: FlareDescriptionLabelPlacement;
    /** Names the list as a group, when a page holds more than one. */
    label?: string;
    /** `plain` sits inside a surface the host already drew; `card` draws its own. */
    appearance?: "plain" | "card";
  }>(),
  { columns: 2, labelPlacement: "start", label: undefined, appearance: "plain" },
);
const emit = defineEmits<{
  /** After a copy key: `copied` is false when the clipboard refused the text. */
  (e: "copy", key: string, copied: boolean): void;
}>();

const { t } = useFlareI18nOptional();
const cols = computed(() => descriptionColumns(props.columns));
const style = computed(() => ({ "--flare-description-list-columns": String(cols.value) }));

function copyable(item: FlareDescriptionItem): boolean {
  return Boolean(item.copyable) && !descriptionIsEmpty(item.value);
}

function copy(item: FlareDescriptionItem): void {
  const text = descriptionText(item.value);
  if (!text || typeof navigator === "undefined" || !navigator.clipboard?.writeText) {
    emit("copy", item.key, false);
    return;
  }
  navigator.clipboard.writeText(text).then(
    () => emit("copy", item.key, true),
    () => emit("copy", item.key, false),
  );
}
</script>

<template>
  <div
    class="flare-description-list"
    :class="[`flare-description-list--${appearance}`, `flare-description-list--label-${labelPlacement}`]"
    :role="label ? 'group' : undefined"
    :aria-label="label || undefined"
    :style="style"
  >
    <dl class="flare-description-list__grid">
      <div
        v-for="item in items"
        :key="item.key"
        class="flare-description-list__item"
        :style="{ '--flare-description-list-span': String(descriptionSpan(item, cols)) }"
      >
        <dt class="flare-description-list__label">{{ item.label }}</dt>
        <dd class="flare-description-list__value">
          <span class="flare-description-list__text" :class="{ 'is-monospace': item.monospace }">
            <slot :name="`item-${item.key}`" :item="item" :value="item.value">
              <template v-if="descriptionIsEmpty(item.value)">
                <span class="flare-description-list__empty" aria-hidden="true">—</span>
                <span class="flare-description-list__spoken">{{ t("descriptionList.empty") }}</span>
              </template>
              <template v-else>{{ descriptionText(item.value) }}</template>
            </slot>
          </span>
          <FlareIconButton
            v-if="copyable(item)"
            class="flare-description-list__copy"
            :icon="flareIcons.copy"
            :ariaLabel="t('descriptionList.copy', { label: item.label })"
            size="sm"
            shape="square"
            @click="copy(item)"
          />
        </dd>
      </div>
    </dl>
  </div>
</template>

<style scoped>
.flare-description-list {
  min-width: 0;
  box-sizing: border-box;
  color: var(--flare-color-text-primary);
  container-type: inline-size;
  container-name: flare-description-list;
}
.flare-description-list--card {
  padding: var(--flare-size-spacing-lg);
  border: 1px solid var(--flare-color-border-secondary);
  border-radius: var(--flare-size-radius-card);
  background: var(--flare-color-bg-primary);
}
.flare-description-list__grid {
  display: grid;
  grid-template-columns: repeat(var(--flare-description-list-columns), minmax(0, 1fr));
  gap: var(--flare-size-spacing-md) var(--flare-size-spacing-2xl);
  margin: 0;
}
.flare-description-list__item {
  display: grid;
  grid-column: span var(--flare-description-list-span);
  align-content: start;
  gap: var(--flare-size-spacing-3xs);
  min-width: 0;
}
.flare-description-list--label-start .flare-description-list__item {
  grid-template-columns: minmax(0, var(--flare-component-description-list-label-width)) minmax(0, 1fr);
  align-items: baseline;
  column-gap: var(--flare-size-spacing-md);
}
.flare-description-list__label {
  min-width: 0;
  margin: 0;
  color: var(--flare-color-text-secondary);
  font-size: var(--flare-text-caption-font-size);
  line-height: var(--flare-text-body-line-height);
  overflow-wrap: anywhere;
}
.flare-description-list__value {
  position: relative;
  display: flex;
  align-items: baseline;
  gap: var(--flare-size-spacing-xs);
  min-width: 0;
  margin: 0;
  font-size: var(--flare-text-body-font-size);
  line-height: var(--flare-text-body-line-height);
}
.flare-description-list__text {
  min-width: 0;
  overflow-wrap: anywhere;
  white-space: pre-line;
}
.flare-description-list__text.is-monospace { font-family: var(--flare-component-font-family-mono); }
.flare-description-list__empty { color: var(--flare-color-text-tertiary); }
/* The key sits on the value's first line and does not make the line taller than its text needs. */
.flare-description-list__copy {
  flex: none;
  align-self: center;
  margin-block: calc(var(--flare-size-spacing-sm) * -1);
}
/* Heard, not seen: the dash is the sighted half of "not set". */
.flare-description-list__spoken {
  position: absolute;
  width: 1px;
  height: 1px;
  margin: -1px;
  padding: 0;
  overflow: hidden;
  clip-path: inset(50%);
  white-space: nowrap;
  border: 0;
}
/* The list asks its own container, not the window: a drawer on a desktop can be phone-narrow. */
@container flare-description-list (max-width: 479px) {
  .flare-description-list__grid { grid-template-columns: minmax(0, 1fr); }
  .flare-description-list__item { grid-column: auto; }
}
@container flare-description-list (max-width: 319px) {
  .flare-description-list--label-start .flare-description-list__item { grid-template-columns: minmax(0, 1fr); }
}
</style>
