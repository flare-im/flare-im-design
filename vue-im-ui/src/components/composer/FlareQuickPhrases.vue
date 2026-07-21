<script setup lang="ts">
import { ref, computed } from "vue";
import { NIcon } from "naive-ui";
import { FlashOutline, CreateOutline } from "../../shared/icon-glyphs";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import type { FlareQuickPhraseGroup } from "../../shared/contracts";

const props = defineProps<{
  groups: FlareQuickPhraseGroup[];
  /** Show the "manage phrases" footer control. */
  manageable?: boolean;
}>();
const emit = defineEmits<{
  (e: "select", text: string): void;
  (e: "manage"): void;
}>();

const { t } = useFlareI18n();
const activeKey = ref(props.groups[0]?.key ?? "");
const activeGroup = computed(
  () => props.groups.find((g) => g.key === activeKey.value) ?? props.groups[0],
);
</script>

<template>
  <div class="flare-quick-phrases">
    <header class="flare-quick-phrases__head">
      <div class="flare-quick-phrases__title">
        <n-icon :size="15" :component="FlashOutline" />
        {{ t("quickPhrase.title") }}
      </div>
      <button
        v-if="manageable"
        type="button"
        class="flare-quick-phrases__manage"
        @click="emit('manage')"
      >
        <n-icon :size="15" :component="CreateOutline" />
        {{ t("quickPhrase.manage") }}
      </button>
    </header>

    <div v-if="groups.length > 1" class="flare-quick-phrases__tabs" role="tablist">
      <button
        v-for="g in groups"
        :key="g.key"
        type="button"
        role="tab"
        class="flare-quick-phrases__tab"
        :class="{ 'is-active': g.key === activeGroup?.key }"
        :aria-selected="g.key === activeGroup?.key"
        @click="activeKey = g.key"
      >
        {{ g.title }}
      </button>
    </div>

    <ul class="flare-quick-phrases__list">
      <li v-for="p in activeGroup?.phrases ?? []" :key="p.id">
        <button type="button" class="flare-quick-phrases__item" @click="emit('select', p.text)">
          {{ p.text }}
        </button>
      </li>
    </ul>
  </div>
</template>

<style scoped>
.flare-quick-phrases {
  width: 320px;
  max-width: 100%;
  display: flex;
  flex-direction: column;
  border-radius: var(--flare-size-radius-xl, 14px);
  background: var(--flare-color-bg-primary, #fff);
  border: 1px solid var(--flare-color-border-primary, #e9e6f1);
  box-shadow: var(--flare-shadow-lg, 0 12px 28px rgba(21, 18, 32, 0.16));
  overflow: hidden;
}
.flare-quick-phrases__head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 14px 8px;
}
.flare-quick-phrases__title {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  font-size: 14px;
  font-weight: 600;
  color: var(--flare-color-text-primary, #15131c);
}
.flare-quick-phrases__manage {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  border: none;
  background: transparent;
  color: var(--flare-color-primary, #7c3aed);
  font-size: 12px;
  cursor: pointer;
}
.flare-quick-phrases__tabs {
  display: flex;
  gap: 4px;
  padding: 0 12px 8px;
  overflow-x: auto;
}
.flare-quick-phrases__tab {
  flex: 0 0 auto;
  padding: 5px 12px;
  border: none;
  border-radius: 999px;
  background: var(--flare-color-bg-secondary, #f6f5fb);
  color: var(--flare-color-text-secondary, #6b6780);
  font-size: 12px;
  cursor: pointer;
  transition: background var(--flare-transition-fast, 150ms ease), color var(--flare-transition-fast, 150ms ease);
}
.flare-quick-phrases__tab.is-active {
  background: var(--flare-color-bg-selected, #f1eaff);
  color: var(--flare-color-primary, #7c3aed);
  font-weight: 500;
}
.flare-quick-phrases__list {
  list-style: none;
  margin: 0;
  padding: 0 8px 10px;
  max-height: 260px;
  overflow-y: auto;
}
.flare-quick-phrases__item {
  width: 100%;
  text-align: left;
  padding: 10px 12px;
  border: none;
  border-radius: var(--flare-size-radius-lg, 10px);
  background: transparent;
  color: var(--flare-color-text-primary, #15131c);
  font-size: 14px;
  line-height: 1.45;
  cursor: pointer;
  transition: background var(--flare-transition-fast, 150ms ease);
}
.flare-quick-phrases__item:hover { background: var(--flare-color-bg-secondary, #f6f5fb); }
</style>
