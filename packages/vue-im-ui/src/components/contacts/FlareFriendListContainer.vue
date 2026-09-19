<script setup lang="ts">
import type { FlareViewState } from "../../shared/contracts/application";
import FlareConversationListContainer from "../conversation/FlareConversationListContainer.vue";

withDefaults(defineProps<{
  state?: FlareViewState<readonly unknown[]>;
  loadingMore?: boolean;
  label?: string;
  /** Label of the retry action shown with an error or offline state. */
  retryLabel?: string;
  /** The container's own words for an empty list; a state's own emptyTitle overrides it. */
  emptyTitle?: string;
}>(), { state: () => ({ status: "ready" }), loadingMore: false, label: "", retryLabel: "", emptyTitle: "" });
const emit = defineEmits<{ (event: "retry"): void; (event: "loadMore"): void }>();
</script>

<template>
  <FlareConversationListContainer :state="state" :loading-more="loadingMore" :label="label" :retry-label="retryLabel" :empty-title="emptyTitle" @retry="emit('retry')" @load-more="emit('loadMore')">
    <template #header><slot name="header" /></template>
    <template #search><slot name="search" /></template>
    <template #filters><slot name="filters" /></template>
    <template #pinned><slot name="favorites" /></template>
    <slot />
    <template #archived><slot name="requests" /></template>
    <template #loadMore><slot name="loadMore" /></template>
    <template #footer><slot name="footer" /></template>
  </FlareConversationListContainer>
</template>

