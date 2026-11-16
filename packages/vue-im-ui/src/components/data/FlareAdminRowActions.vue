<script setup lang="ts">
/** Row operations as text buttons; the ones past `max` collapse into a "more" menu. Hosts keep permission and confirmation ownership. */
import { computed, h } from "vue";
import { NButton, NDropdown, NIcon } from "naive-ui";
import { ChevronDown } from "@lucide/vue";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";
import FlareAdminActions from "./FlareAdminActions.vue";

export type FlareAdminRowAction = {
  key: string;
  label: string;
  danger?: boolean;
  disabled?: boolean;
};
const props = withDefaults(
  defineProps<{ actions: readonly FlareAdminRowAction[]; max?: number }>(),
  { max: 3 },
);
const emit = defineEmits<{ select: [key: string] }>();
const { t } = useFlareI18nOptional();
const inlineCount = computed(() =>
  props.actions.length <= props.max
    ? props.actions.length
    : Math.max(0, props.max - 1),
);
const inline = computed(() => props.actions.slice(0, inlineCount.value));
const overflow = computed(() => props.actions.slice(inlineCount.value));
const menuOptions = computed(() =>
  overflow.value.map((action) => ({
    key: action.key,
    disabled: action.disabled,
    label: () =>
      h(
        "span",
        { class: { "flare-admin-row-actions__danger": action.danger } },
        action.label,
      ),
  })),
);
</script>

<template>
  <FlareAdminActions class="flare-admin-row-actions">
    <NButton
      v-for="action in inline"
      :key="action.key"
      text
      size="small"
      :type="action.danger ? 'error' : 'primary'"
      :class="{ 'flare-admin-row-actions__danger': action.danger }"
      :disabled="action.disabled"
      :data-row-action="action.key"
      @click="emit('select', action.key)"
      >{{ action.label }}</NButton
    >
    <NDropdown
      v-if="overflow.length"
      trigger="click"
      placement="bottom-end"
      :options="menuOptions"
      @select="(key: string) => emit('select', key)"
    >
      <NButton text size="small" type="primary" data-row-action-more>
        {{ t("dataTable.moreActions") }}
        <template #icon
          ><NIcon aria-hidden="true" :component="ChevronDown"
        /></template>
      </NButton>
    </NDropdown>
  </FlareAdminActions>
</template>

<style>
.flare-admin-row-actions__danger {
  color: var(--flare-color-error-text);
}
</style>
