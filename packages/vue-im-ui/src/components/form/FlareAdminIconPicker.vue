<script lang="ts">
import type { Component } from "vue";
export interface FlareAdminIconOption {
  value: string;
  label: string;
  component: Component;
  keywords?: readonly string[];
}
</script>
<script setup lang="ts">
import { computed, ref, toRaw } from "vue";
import { NButton, NEmpty, NIcon, NInput, NPopover } from "naive-ui";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";
const props = defineProps<{
  options: readonly FlareAdminIconOption[];
  disabled?: boolean;
  label?: string;
}>();
const value = defineModel<string | null>({ default: null });
const { t } = useFlareI18nOptional();
const open = ref(false),
  search = ref("");
const selected = computed(() =>
  props.options.find((o) => o.value === value.value),
);
const shown = computed(() =>
  props.options.filter((o) =>
    [o.label, o.value, ...(o.keywords ?? [])]
      .join(" ")
      .toLowerCase()
      .includes(search.value.trim().toLowerCase()),
  ),
);
function choose(key: string | null) {
  if (props.disabled) return;
  value.value = key;
  open.value = false;
}
</script>
<template>
  <NPopover
    :show="open && !disabled"
    trigger="click"
    placement="bottom-start"
    :show-arrow="false"
    @update:show="
      (v) => {
        open = v;
        if (v) search = '';
      }
    "
  >
    <template #trigger
      ><NButton
        size="small"
        :disabled="disabled"
        :aria-label="label || t('iconPicker.choose')"
        aria-haspopup="dialog"
        :aria-expanded="open && !disabled"
      >
        <template v-if="selected" #icon
          ><NIcon :component="toRaw(selected.component)" /></template
        >{{ selected?.label || t("iconPicker.default") }}
      </NButton></template
    >
    <section
      class="flare-admin-icon-picker"
      role="dialog"
      :aria-label="label || t('iconPicker.choose')"
      @keydown.esc.stop.prevent="open = false"
    >
      <NInput
        v-model:value="search"
        clearable
        :placeholder="t('iconPicker.search')"
        :input-props="{ 'aria-label': t('iconPicker.search') }"
      />
      <NButton size="small" @click="choose(null)">{{
        t("iconPicker.default")
      }}</NButton>
      <div v-if="shown.length" class="flare-admin-icon-picker__grid">
        <NButton
          v-for="option in shown"
          :key="option.value"
          :aria-label="option.label"
          :aria-pressed="option.value === value"
          :type="option.value === value ? 'primary' : 'default'"
          class="flare-admin-icon-picker__option"
          @click="choose(option.value)"
        >
          <NIcon :component="toRaw(option.component)" :size="22" /><span>{{
            option.label
          }}</span>
        </NButton>
      </div>
      <NEmpty v-else :description="t('iconPicker.empty')" />
    </section>
  </NPopover>
</template>
<style scoped>
.flare-admin-icon-picker {
  display: grid;
  gap: var(--flare-size-spacing-sm);
  width: min(360px, calc(100vw - 64px));
}
.flare-admin-icon-picker__grid {
  display: grid;
  grid-template-columns: repeat(4, minmax(0, 1fr));
  gap: var(--flare-size-spacing-xs);
  max-height: 300px;
  overflow-y: auto;
  overscroll-behavior: contain;
}
.flare-admin-icon-picker__option {
  height: auto;
  min-height: 56px;
  padding: var(--flare-size-spacing-xs);
}
.flare-admin-icon-picker__option :deep(.n-button__content) {
  display: flex;
  flex-direction: column;
  gap: var(--flare-size-spacing-2xs);
  white-space: normal;
  overflow-wrap: anywhere;
  font-size: var(--flare-size-font-size-xs);
}
</style>
