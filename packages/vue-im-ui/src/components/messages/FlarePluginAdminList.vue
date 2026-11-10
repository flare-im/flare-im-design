<script setup lang="ts">
import { useSlots } from "vue";
import PluginRowsBlock from "./plugin/PluginRowsBlock.vue";
import type { FlareAdminPagination } from "../data/admin-list";
import type {
  FlarePluginAction,
  FlarePluginRow,
  FlarePluginRowsBlock,
  FlarePluginStrings,
} from "../../shared/contracts/plugin-ui";

/** Plugin row declarations composed through the same operational list as ordinary admin pages. */
defineProps<{
  block: FlarePluginRowsBlock;
  strings: FlarePluginStrings;
  label?: string;
  loading?: boolean;
  busy?: boolean;
  disabled?: boolean;
  busyActionId?: string;
  busyRow?: string | null;
  error?: string;
  filtersInvalid?: boolean;
  pagination?: FlareAdminPagination;
}>();
const emit = defineEmits<{
  search: [];
  reset: [];
  "update:pagination": [value: FlareAdminPagination];
  rowAction: [action: FlarePluginAction, row: FlarePluginRow, input: unknown];
  openRow: [row: FlarePluginRow];
  loadMore: [cursor: string];
}>();
const visibleColumnKeys = defineModel<string[] | null>("visibleColumnKeys", {
  default: null,
});
const slots = useSlots();
</script>

<template>
  <PluginRowsBlock
    :block="block"
    :strings="strings"
    :admin-label="label"
    layout="admin-list"
    :loading="loading"
    :busy="!!(busy || disabled || loading)"
    :disabled="disabled"
    :busy-action-id="busyActionId"
    :busy-row="busyRow"
    :error="error"
    :filters-invalid="filtersInvalid"
    :pagination="pagination"
    v-model:visible-column-keys="visibleColumnKeys"
    @search="emit('search')"
    @reset="emit('reset')"
    @update:pagination="emit('update:pagination', $event)"
    @row-action="(action, row, input) => emit('rowAction', action, row, input)"
    @open-row="emit('openRow', $event)"
    @load-more="emit('loadMore', $event)"
  >
    <template v-for="(_, name) in slots" :key="name" #[name]
      ><slot :name="name"
    /></template>
  </PluginRowsBlock>
</template>
