<script setup lang="ts">
/**
 * One settings row — the single source of truth for how a `FlareSettingsItem`
 * renders (toggle / value / navigation). Shared by `FlareSettingsList` and
 * `FlareProfilePanel` so the two can't drift apart.
 */
import { NIcon } from "naive-ui";
import { ChevronForwardOutline } from "@vicons/ionicons5";
import type { FlareSettingsItem } from "../../shared/contracts";

defineProps<{ item: FlareSettingsItem }>();
const emit = defineEmits<{
  (e: "toggle", item: FlareSettingsItem, value: boolean): void;
  (e: "select", item: FlareSettingsItem): void;
}>();
</script>

<template>
  <div
    class="flare-settings__row"
    @click="item.kind !== 'toggle' && emit('select', item)"
  >
    <span v-if="item.icon" class="flare-settings__ico">{{ item.icon }}</span>
    <span class="flare-settings__label">{{ item.label }}</span>
    <label
      v-if="item.kind === 'toggle'"
      class="flare-settings__switch"
      :class="{ on: item.value }"
      @click.stop="emit('toggle', item, !item.value)"
    ><span /></label>
    <template v-else>
      <span v-if="item.detail" class="flare-settings__detail">{{ item.detail }}</span>
      <span v-if="item.kind !== 'value'" class="flare-settings__chev"><n-icon :size="18" :component="ChevronForwardOutline" /></span>
    </template>
  </div>
</template>

<style scoped>
.flare-settings__row {
  display: flex; align-items: center; gap: 12px;
  padding: 12px 16px; cursor: pointer;
  background: var(--flare-color-bg-primary);
}
.flare-settings__row + .flare-settings__row { border-top: 1px solid var(--flare-color-border-secondary); }
.flare-settings__ico { font-size: 18px; }
.flare-settings__label { flex: 1; color: var(--flare-color-text-primary); }
.flare-settings__detail { color: var(--flare-color-text-tertiary); font-size: 13px; }
.flare-settings__chev { color: var(--flare-color-text-tertiary); }
.flare-settings__switch {
  width: 42px; height: 24px; border-radius: 999px;
  background: var(--flare-color-bg-disabled); position: relative; transition: 0.2s; cursor: pointer;
}
.flare-settings__switch.on { background: var(--flare-color-primary); }
.flare-settings__switch span {
  position: absolute; top: 2px; left: 2px; width: 20px; height: 20px;
  border-radius: 50%; background: #fff; transition: 0.2s;
}
.flare-settings__switch.on span { transform: translateX(18px); }
</style>
