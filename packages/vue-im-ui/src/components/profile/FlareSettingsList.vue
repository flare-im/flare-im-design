<script setup lang="ts">
import FlareSettingsRow from "./FlareSettingsRow.vue";
import type { FlareSettingsSection, FlareSettingsItem } from "../../shared/contracts";

withDefaults(
  defineProps<{
    sections: FlareSettingsSection[];
    /**
     * 行是通栏还是浮在一张内缩的卡上。
     *
     * `card`（默认）是设置页那种分组卡。`flush` 给的是「这些行和它下面的长列表
     * 是同一份列表」的场合 —— 比如通讯录顶部的功能入口，下面接着字母索引：
     * 入口用内缩卡、索引和联系人行通栏，同一屏上就出现了两套槽宽。
     */
    surface?: "card" | "flush";
  }>(),
  { surface: "card" },
);
const emit = defineEmits<{
  (e: "toggle", item: FlareSettingsItem, value: boolean): void;
  (e: "select", item: FlareSettingsItem): void;
}>();
</script>

<template>
  <div class="flare-settings" :class="`flare-settings--${surface}`">
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
.flare-settings--flush { padding-top: 0; }
.flare-settings--flush .flare-settings__section { margin: 0; }
.flare-settings--flush .flare-settings__group {
  border-radius: 0;
  box-shadow: none;
  background: var(--flare-color-bg-primary);
}
.flare-settings__title {
  padding: 4px 8px 8px; font-size: 12px; letter-spacing: 0.02em;
  color: var(--flare-color-text-tertiary);
}
/* iOS-style grouped card — rows float together on one elevated surface. */
.flare-settings__group {
  border-radius: var(--flare-size-radius-xl);
  background: var(--flare-color-bg-elevated);
  box-shadow: var(--flare-shadow-card);
  overflow: hidden;
}
.flare-settings__group :deep(.flare-settings__row) { background: transparent; }
</style>
