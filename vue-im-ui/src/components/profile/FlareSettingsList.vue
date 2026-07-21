<script setup lang="ts">
import FlareSettingsRow from "./FlareSettingsRow.vue";
import type { FlareSettingsSection, FlareSettingsItem } from "../../shared/contracts";

defineProps<{ sections: FlareSettingsSection[] }>();
const emit = defineEmits<{
  (e: "toggle", item: FlareSettingsItem, value: boolean): void;
  (e: "select", item: FlareSettingsItem): void;
}>();
</script>

<template>
  <div class="flare-settings">
    <div v-for="(section, si) in sections" :key="si" class="flare-settings__section">
      <div v-if="section.title" class="flare-settings__title">{{ section.title }}</div>
      <div class="flare-settings__group">
        <FlareSettingsRow
          v-for="item in section.items"
          :key="item.key"
          :item="item"
          @toggle="(i: FlareSettingsItem, v: boolean) => emit('toggle', i, v)"
          @select="(i: FlareSettingsItem) => emit('select', i)"
        />
      </div>
    </div>
  </div>
</template>

<style scoped>
.flare-settings { padding-top: 8px; }
.flare-settings__section { margin: 0 12px 18px; }
.flare-settings__title {
  padding: 4px 8px 8px; font-size: 12px; letter-spacing: 0.02em;
  color: var(--flare-color-text-tertiary);
}
/* iOS-style grouped card — rows float together on one elevated surface. */
.flare-settings__group {
  border-radius: var(--flare-size-radius-xl, 14px);
  background: var(--flare-color-bg-elevated, #fff);
  box-shadow: var(--flare-shadow-card);
  overflow: hidden;
}
.flare-settings__group :deep(.flare-settings__row) { background: transparent; }
</style>
