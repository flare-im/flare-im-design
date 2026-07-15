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
      <FlareSettingsRow
        v-for="item in section.items"
        :key="item.key"
        :item="item"
        @toggle="(i: FlareSettingsItem, v: boolean) => emit('toggle', i, v)"
        @select="(i: FlareSettingsItem) => emit('select', i)"
      />
    </div>
  </div>
</template>

<style scoped>
.flare-settings__section { margin-bottom: 16px; }
.flare-settings__title {
  padding: 8px 16px 4px; font-size: 12px; color: var(--flare-color-text-tertiary);
}
</style>
