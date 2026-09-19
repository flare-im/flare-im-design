<script setup lang="ts">
// One pane's four outcomes, in one place: host content, a skeleton while it
// loads, an explanation when it is empty, a reason plus recovery when it failed.
//
// Private part. Both FlareConversationWorkspace and FlareWorkspaceFrame render
// their three panes through it, so the inbox and a settings surface fail the
// same way instead of two dialects of "something went wrong".
import { computed } from "vue";
import FlareEmptyState from "../general/FlareEmptyState.vue";
import FlareSkeleton from "../general/FlareSkeleton.vue";
import FlareStatusBanner from "../general/FlareStatusBanner.vue";
import {
  paneEmptyActionVisible,
  paneRender,
  paneRetryVisible,
  type WorkspacePaneState,
} from "../../shared/contracts/conversation-workspace";

const props = withDefaults(
  defineProps<{
    state?: WorkspacePaneState;
    /** Skeleton shape: rows for a list, bubbles for a timeline, a card for details. */
    skeleton?: "conversation" | "message" | "profile";
    skeletonRows?: number;
    /** Icon of the empty explanation. */
    emptyIcon?: string;
    /** Fallback texts when the host state carries none. */
    emptyText?: string;
    failureText?: string;
    /** Announced to a screen reader while the skeleton shows. */
    loadingText?: string;
    /** The host bound a retry handler (a failure may offer a button). */
    hasRetry?: boolean;
    /** The host bound an empty-state handler (an empty pane may offer a next step). */
    hasEmptyAction?: boolean;
  }>(),
  {
    state: () => ({ status: "ready" }),
    skeleton: "conversation",
    skeletonRows: 6,
    emptyIcon: "folder",
    emptyText: "",
    failureText: "",
    loadingText: "",
    hasRetry: false,
    hasEmptyAction: false,
  },
);

const emit = defineEmits<{ (e: "retry"): void; (e: "emptyAction"): void }>();

const render = computed(() => paneRender(props.state));
const retryVisible = computed(() => paneRetryVisible(props.state, props.hasRetry));
const emptyActionVisible = computed(() => paneEmptyActionVisible(props.state, props.hasEmptyAction));

/** Host text wins; the kit's default only fills a blank. */
function text(value: string | undefined, fallback: string): string {
  return value && value.trim().length > 0 ? value : fallback;
}
const message = computed(() => props.state.message);
</script>

<template>
  <div class="flare-workspace-pane">
    <slot v-if="render === 'content'" />

    <div v-else-if="render === 'skeleton'" class="flare-workspace-pane__loading" role="status" aria-live="polite">
      <span v-if="loadingText" class="flare-workspace-pane__sr">{{ loadingText }}</span>
      <FlareSkeleton :variant="skeleton" :rows="skeletonRows" />
    </div>

    <FlareEmptyState
      v-else-if="render === 'empty'"
      class="flare-workspace-pane__empty"
      :icon="emptyIcon"
      :title="text(message, emptyText)"
      :description="state.description"
      :action-text="emptyActionVisible ? state.actionLabel : undefined"
      @action="emit('emptyAction')"
    />

    <div v-else class="flare-workspace-pane__failure" role="alert">
      <FlareStatusBanner
        tone="danger"
        :dot="true"
        :text="text(message, failureText)"
        :action-text="retryVisible ? state.actionLabel : undefined"
        @action="emit('retry')"
      />
    </div>
  </div>
</template>

<style scoped>
.flare-workspace-pane {
  display: flex;
  flex-direction: column;
  min-width: 0;
  min-height: 0;
  height: 100%;
}
.flare-workspace-pane__loading,
.flare-workspace-pane__empty,
.flare-workspace-pane__failure {
  flex: 1;
  min-height: 0;
}
.flare-workspace-pane__loading {
  padding: var(--flare-size-spacing-md);
  overflow: hidden;
}
.flare-workspace-pane__failure {
  display: flex;
  align-items: flex-start;
  padding: var(--flare-size-spacing-md);
}
/* Announced, never drawn: the skeleton already carries the visual. */
.flare-workspace-pane__sr {
  position: absolute;
  width: 1px;
  height: 1px;
  margin: -1px;
  padding: 0;
  overflow: hidden;
  clip-path: inset(50%);
  white-space: nowrap;
}
</style>
