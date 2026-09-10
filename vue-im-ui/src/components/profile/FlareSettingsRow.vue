<script setup lang="ts">
/**
 * One settings row — the single source of truth for how a `FlareSettingsItem`
 * renders (toggle / value / navigation). Shared by `FlareSettingsList` and
 * `FlareProfilePanel` so the two can't drift apart.
 */
import { NIcon } from "naive-ui";
import { ChevronForwardOutline } from "../../shared/icon-glyphs";
import FlareGlyph from "../general/FlareGlyph.vue";
import type { FlareSettingsItem } from "../../shared/contracts";

const props = defineProps<{ item: FlareSettingsItem }>();
const emit = defineEmits<{
  (e: "toggle", item: FlareSettingsItem, value: boolean): void;
  (e: "select", item: FlareSettingsItem): void;
}>();
function activate() {
  if (props.item.disabled) return;
  if (props.item.kind === 'toggle') emit('toggle', props.item, !props.item.value);
  else emit('select', props.item);
}
</script>

<template>
  <button
    type="button"
    class="flare-settings__row"
    :class="{ 'is-danger': item.danger }"
    :disabled="item.disabled"
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
      <span v-if="item.kind !== 'value'" class="flare-settings__chev"><n-icon :size="18" :component="ChevronForwardOutline" /></span>
    </template>
  </button>
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
.flare-settings__row:hover:not(:disabled) { background: var(--flare-color-bg-hover); }
.flare-settings__row:focus-visible { outline: 2px solid var(--flare-color-primary); outline-offset: -2px; }
.flare-settings__row.is-danger .flare-settings__label { color: var(--flare-color-error); }
.flare-settings__label { flex: 1; min-width: 0; overflow-wrap: anywhere; color: var(--flare-color-text-primary); }
.flare-settings__detail { color: var(--flare-color-text-tertiary); font-size: 13px; }
.flare-settings__badge {
  min-width: 18px; height: 18px; padding: 0 5px;
  display: inline-flex; align-items: center; justify-content: center;
  border-radius: 999px; background: var(--flare-color-error, #ef4444);
  color: #fff; font-size: 11px; font-weight: 700; line-height: 1;
}
.flare-settings__chev { color: var(--flare-color-text-tertiary); }
.flare-settings__switch {
  width: 42px; height: 24px; flex-shrink: 0; border-radius: 999px;
  background: var(--flare-color-bg-disabled); position: relative; transition: 0.2s; cursor: pointer;
}
.flare-settings__switch.on { background: var(--flare-color-primary); }
.flare-settings__switch span {
  position: absolute; top: 2px; left: 2px; width: 20px; height: 20px;
  border-radius: 50%; background: #fff; transition: 0.2s;
}
.flare-settings__switch.on span { transform: translateX(18px); }
</style>
