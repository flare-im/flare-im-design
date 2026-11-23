<script setup lang="ts">
import { computed, useId } from "vue";
import { useScreenLayout } from "../../shared/screenLayout";
import FlareSettingsRow from "./FlareSettingsRow.vue";
import type { FlareSettingsSection, FlareSettingsItem } from "../../shared/contracts";

const props = withDefaults(
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
const id = useId();
const { detail, sectioned, title: screenTitle } = useScreenLayout();
const repeatedTitle = (section: FlareSettingsSection) => Boolean(screenTitle.value && section.title === screenTitle.value);
const visibleSections = computed(() => props.sections.filter(section => section.items.length > 0 || section.footer?.trim()));
const emit = defineEmits<{
  (e: "toggle", item: FlareSettingsItem, value: boolean): void;
  (e: "select", item: FlareSettingsItem): void;
}>();
</script>

<template>
  <div class="flare-settings" :class="[`flare-settings--${surface}`, { 'is-detail': detail, 'is-sectioned': sectioned }]">
    <div class="flare-settings__sections" :class="{ 'is-multi': surface === 'card' && visibleSections.length > 1 }">
      <div v-for="(section, si) in visibleSections" :key="si" class="flare-settings__section">
        <h2 v-if="section.title && !repeatedTitle(section)" :id="`${id}-section-${si}`" class="flare-settings__title">{{ section.title }}</h2>
        <div v-if="section.items.length" class="flare-settings__group" :role="section.title ? 'group' : undefined" :aria-labelledby="section.title && !repeatedTitle(section) ? `${id}-section-${si}` : undefined" :aria-label="repeatedTitle(section) ? section.title : undefined">
          <FlareSettingsRow
            v-for="item in section.items"
            :key="item.key"
            :item="item"
            @toggle="(i: FlareSettingsItem, v: boolean) => emit('toggle', i, v)"
            @select="(i: FlareSettingsItem) => emit('select', i)"
          />
        </div>
        <p v-if="section.footer" class="flare-settings__footer">{{ section.footer }}</p>
      </div>
    </div>
  </div>
</template>

<style scoped>
.flare-settings { min-width: 0; container: flare-settings / inline-size; padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-md) 0; }
.flare-settings__section { break-inside: avoid; margin: 0 0 var(--flare-size-spacing-lg); }
.flare-settings--flush { padding: 0; }
.flare-settings--flush .flare-settings__section { margin: 0; }
.flare-settings--flush .flare-settings__group {
  border: 0;
  border-radius: 0;
  background: var(--flare-color-bg-primary);
}
.flare-settings__title {
  margin: 0;
  padding: var(--flare-size-spacing-xs) var(--flare-size-spacing-sm) var(--flare-size-spacing-sm);
  font-size: var(--flare-size-font-size-sm);
  font-weight: var(--flare-size-font-weight-medium);
  line-height: var(--flare-size-line-height-normal);
  color: var(--flare-color-text-secondary);
}
.flare-settings__footer {
  margin: 0;
  padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-sm) 0;
  font-size: var(--flare-size-font-size-sm);
  line-height: var(--flare-size-line-height-normal);
  color: var(--flare-color-text-tertiary);
  overflow-wrap: anywhere;
}
/* Match ProfilePanel: quiet groups with one shared edge, no stacked shadows. */
.flare-settings__group {
  border: 1px solid var(--flare-color-border-secondary);
  border-radius: var(--flare-size-radius-lg);
  background: var(--flare-color-bg-elevated);
  overflow: hidden;
}
@container flare-settings (min-width: 640px) {
  .flare-settings__sections.is-multi { columns: 2; column-gap: var(--flare-size-spacing-lg); }
}
.flare-settings.is-detail { padding: 0; }
.flare-settings.is-detail .flare-settings__section { margin-bottom: var(--flare-size-spacing-md); }
.flare-settings.is-detail .flare-settings__sections.is-multi { columns: auto; }
.flare-settings.is-sectioned { padding: 0; }
.flare-settings.is-sectioned .flare-settings__section:last-child { margin-block-end: 0; }
</style>
