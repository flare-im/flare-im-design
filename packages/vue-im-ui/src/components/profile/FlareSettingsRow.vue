<script setup lang="ts">
/**
 * One settings row — the single source of truth for how a `FlareSettingsItem`
 * renders (navigation / toggle / action / value). Shared by `FlareSettingsList` and
 * `FlareProfilePanel` so the two can't drift apart. A `value` row is read-only
 * information, not a control: it renders no button and ignores clicks.
 */
import { computed } from "vue";
import { NIcon } from "naive-ui";
import { ChevronForwardOutline } from "../../shared/icon-glyphs";
import FlareGlyph from "../general/FlareGlyph.vue";
import type { FlareSettingsItem } from "../../shared/contracts";

const props = defineProps<{ item: FlareSettingsItem }>();
const emit = defineEmits<{
  (e: "toggle", item: FlareSettingsItem, value: boolean): void;
  (e: "select", item: FlareSettingsItem): void;
}>();
/**
 * A long value (a group announcement, a signature) goes on its own lines under the label; beside the
 * label it squeezed the label to one character per line.
 */
const STACK_AFTER_CHARACTERS = 16;
const stacked = computed(() => props.item.kind !== "toggle" && Array.from(props.item.detail ?? "").length > STACK_AFTER_CHARACTERS);
const readOnly = computed(() => props.item.kind === "value");
/** Only rows that open something carry a chevron; in-place actions and values do not. */
const chevron = computed(() => (props.item.kind ?? "navigation") === "navigation");
function activate() {
  if (props.item.disabled || readOnly.value) return;
  if (props.item.kind === 'toggle') emit('toggle', props.item, !props.item.value);
  else emit('select', props.item);
}
</script>

<template>
  <component
    :is="readOnly ? 'div' : 'button'"
    :type="readOnly ? undefined : 'button'"
    class="flare-settings__row"
    :class="{ 'is-danger': item.danger, 'is-stacked': stacked, 'is-static': readOnly }"
    :disabled="readOnly ? undefined : item.disabled"
    :role="item.kind === 'toggle' ? 'switch' : undefined"
    :aria-checked="item.kind === 'toggle' ? !!item.value : undefined"
    @click="activate"
  >
    <span v-if="item.icon || $slots.icon" class="flare-settings__ico"><slot name="icon"><FlareGlyph v-if="item.icon" :icon="item.icon" :size="18" /></slot></span>
    <span class="flare-settings__label">{{ item.label }}</span>
    <span
      v-if="item.kind === 'toggle'"
      class="flare-settings__switch"
      :class="{ on: item.value }"
      aria-hidden="true"
    ><span /></span>
    <template v-else>
      <span v-if="item.badge" class="flare-settings__badge">{{ item.badge > 99 ? "99+" : item.badge }}</span>
      <span v-if="item.detail" class="flare-settings__detail">{{ item.detail }}</span>
      <span v-if="chevron" class="flare-settings__chev"><n-icon aria-hidden="true" :size="18" :component="ChevronForwardOutline" /></span>
    </template>
  </component>
</template>

<style scoped>
.flare-settings__row {
  display: flex; align-items: center; gap: 12px;
  width: 100%; min-height: 48px; border: 0; text-align: start; font: inherit;
  padding: 12px 16px; cursor: pointer;
  background: var(--flare-color-bg-primary);
}
.flare-settings__row + .flare-settings__row { border-top: 1px solid var(--flare-color-border-secondary); }
.flare-settings__ico { font-size: 18px; width: 20px; flex-shrink: 0; display: inline-flex; }
.flare-settings__ico :deep(svg) { width: 20px; height: 20px; }
.flare-settings__row:disabled { opacity: .45; cursor: not-allowed; }
.flare-settings__row:hover:not(:disabled):not(.is-static) { background: var(--flare-color-bg-hover); }
.flare-settings__row.is-static { cursor: default; }
.flare-settings__row:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: -2px; }
.flare-settings__row.is-danger .flare-settings__label { color: var(--flare-color-error-text); }
.flare-settings__label { flex: 1; min-width: 0; overflow-wrap: anywhere; color: var(--flare-color-text-primary); font-size: var(--flare-size-font-size-lg); }
.flare-settings__detail { flex: 0 1 auto; min-width: 0; max-width: 60%; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; color: var(--flare-color-text-tertiary); font-size: var(--flare-size-font-size-md); }
.flare-settings__row.is-stacked {
  display: grid;
  grid-template-columns: auto minmax(0, 1fr) auto auto;
  grid-template-areas: "ico label badge chev" "ico detail detail detail";
  align-items: center;
  row-gap: 4px;
}
.flare-settings__row.is-stacked .flare-settings__ico { grid-area: ico; align-self: start; padding-top: 2px; }
.flare-settings__row.is-stacked .flare-settings__label { grid-area: label; }
.flare-settings__row.is-stacked .flare-settings__badge { grid-area: badge; }
.flare-settings__row.is-stacked .flare-settings__chev { grid-area: chev; }
.flare-settings__row.is-stacked .flare-settings__detail {
  grid-area: detail;
  max-width: none;
  display: -webkit-box;
  -webkit-box-orient: vertical;
  -webkit-line-clamp: 3;
  white-space: normal;
  overflow-wrap: anywhere;
  line-height: 1.5;
  color: var(--flare-color-text-secondary);
}
.flare-settings__badge {
  min-width: 18px; height: 18px; padding: 0 5px;
  display: inline-flex; align-items: center; justify-content: center;
  border-radius: 999px; background: var(--flare-color-error);
  color: #fff; font-size: 11px; font-weight: 700; line-height: 1;
}
.flare-settings__chev { color: var(--flare-color-text-tertiary); }
.flare-settings__switch {
  width: 42px; height: 24px; flex-shrink: 0; border-radius: 999px;
  background: var(--flare-color-border-hover); position: relative; transition: 0.2s; cursor: pointer;
}
.flare-settings__switch.on { background: var(--flare-color-primary); }
.flare-settings__switch span {
  position: absolute; top: 2px; left: 2px; width: 20px; height: 20px;
  border-radius: 50%; background: #fff; transition: 0.2s;
}
.flare-settings__switch.on span { transform: translateX(18px); }
</style>
