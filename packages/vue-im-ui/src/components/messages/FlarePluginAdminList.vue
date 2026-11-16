<script setup lang="ts">
import { computed, useSlots } from "vue";
import PluginRowsBlock from "./plugin/PluginRowsBlock.vue";
import PluginSimpleBlock from "./plugin/PluginSimpleBlock.vue";
import PluginTextBlock from "./plugin/PluginTextBlock.vue";
import type { FlareAdminPagination } from "../data/admin-list";
import type {
  FlarePluginAction,
  FlarePluginBlock,
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
  /** Explanations drawn in the list's "?" help popover. */
  help?: readonly FlarePluginBlock[];
  /** Warnings drawn in the list notice, two lines each with an expand key. */
  notices?: readonly FlarePluginBlock[];
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
// A host's own help / notice slots stay; the declared blocks follow them.
const passthrough = computed(() => Object.keys(slots).filter((name) => name !== "help" && name !== "notice"));
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
    <template v-for="name in passthrough" :key="name" #[name]
      ><slot :name="name"
    /></template>
    <template v-if="slots.help || help?.length" #help>
      <slot name="help" />
      <template v-for="(block, index) in help ?? []" :key="index">
        <PluginTextBlock v-if="block.kind === 'text'" :block="block" />
        <PluginSimpleBlock v-else-if="block.kind === 'note'" :block="block" />
      </template>
    </template>
    <template v-if="slots.notice || notices?.length" #notice>
      <slot name="notice" />
      <template v-for="(block, index) in notices ?? []" :key="index">
        <PluginSimpleBlock v-if="block.kind === 'note'" :block="block" :clamp="2" />
        <PluginTextBlock v-else-if="block.kind === 'text'" :block="block" :clamp="2" />
      </template>
    </template>
  </PluginRowsBlock>
</template>
