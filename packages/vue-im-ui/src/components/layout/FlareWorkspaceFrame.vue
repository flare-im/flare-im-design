<script setup lang="ts">
import { computed, getCurrentInstance } from "vue";
import { flareLayout } from "../../design-system/theme/layout-tokens";
import type {
  FlareLayoutChange,
  FlareWorkspacePane,
  FlareWorkspaceState,
} from "../../shared/contracts/application";
import {
  workspaceBannerActionVisible,
  workspaceBannerTone,
  workspaceBannerVisible,
  type WorkspacePaneState,
} from "../../shared/contracts/conversation-workspace";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";
import FlareStatusBanner from "../general/FlareStatusBanner.vue";
import FlareAppLayout from "./FlareAppLayout.vue";
import WorkspacePane from "./WorkspacePane.vue";

const props = withDefaults(defineProps<{
  state?: FlareWorkspaceState;
  hasDetail?: boolean;
  label?: string;
  primaryWidth?: number;
  detailWidth?: number;
}>(), {
  state: () => ({}),
  hasDetail: false,
  label: "",
  primaryWidth: flareLayout.primaryPaneDefaultWidth,
  detailWidth: flareLayout.detailPaneDefaultWidth,
});

const emit = defineEmits<{
  (event: "paneChange", pane: FlareWorkspacePane): void;
  (event: "retry", pane: FlareWorkspacePane): void;
  (event: "emptyAction", pane: FlareWorkspacePane): void;
  (event: "bannerAction"): void;
  /** Forwarded from the layout: the presentation actually in use. See FlareAppLayout. */
  (event: "layoutChange", layout: FlareLayoutChange): void;
}>();
const instance = getCurrentInstance();
const hasRetry = computed(() => Boolean(instance?.vnode.props?.onRetry));
const hasBannerAction = computed(() => Boolean(instance?.vnode.props?.onBannerAction));
const hasEmptyAction = computed(() => Boolean(instance?.vnode.props?.onEmptyAction));

// Generic defaults: this frame carries contacts, settings, search and media, so
// its fallback text cannot talk about conversations.
// Optional: the frame is mounted standalone in previews and by hosts that own
// their own provider — a missing one must not throw and blank the workspace.
const { t } = useFlareI18nOptional();
const defaults = computed(() => ({
  loading: t("workspaceFrame.loading"),
  empty: t("workspaceFrame.empty"),
  failure: t("workspaceFrame.failure"),
}));
const activePane = computed(() => props.state.activePane ?? "content");
const bannerVisible = computed(() => workspaceBannerVisible(props.state.banner));
const bannerActionVisible = computed(() => workspaceBannerActionVisible(props.state.banner, hasBannerAction.value));

function stateFor(pane: FlareWorkspacePane): WorkspacePaneState {
  return props.state[pane] ?? { status: "ready" };
}

function activate(pane: FlareWorkspacePane): void {
  emit("paneChange", pane);
}
</script>

<template>
  <section class="flare-workspace-frame" :aria-label="label || undefined">
    <FlareStatusBanner
      v-if="bannerVisible"
      class="flare-workspace-frame__banner"
      :text="state.banner?.message || ''"
      :tone="workspaceBannerTone(state.banner?.tone)"
      :action-text="bannerActionVisible ? state.banner?.actionLabel : undefined"
      @action="emit('bannerAction')"
    />
    <FlareAppLayout
      class="flare-workspace-frame__layout"
      :active-pane="activePane"
      :has-detail="hasDetail"
      :primary-width="primaryWidth"
      :detail-width="detailWidth"
      :label="label"
      @layout-change="emit('layoutChange', $event)"
    >
      <template #primary>
        <WorkspacePane
          class="flare-workspace-frame__pane"
          :state="stateFor('primary')"
          skeleton="conversation"
          :skeleton-rows="6"
          empty-icon="folder"
          :empty-text="defaults.empty"
          :failure-text="defaults.failure"
          :loading-text="defaults.loading"
          :has-retry="hasRetry"
          :has-empty-action="hasEmptyAction"
          @focusin="activate('primary')"
          @retry="emit('retry', 'primary')"
          @empty-action="emit('emptyAction', 'primary')"
        >
          <slot name="primary" />
        </WorkspacePane>
      </template>
      <template #content>
        <WorkspacePane
          class="flare-workspace-frame__pane"
          :state="stateFor('content')"
          skeleton="message"
          :skeleton-rows="5"
          empty-icon="comment"
          :empty-text="defaults.empty"
          :failure-text="defaults.failure"
          :loading-text="defaults.loading"
          :has-retry="hasRetry"
          :has-empty-action="hasEmptyAction"
          @focusin="activate('content')"
          @retry="emit('retry', 'content')"
          @empty-action="emit('emptyAction', 'content')"
        >
          <slot />
        </WorkspacePane>
      </template>
      <template #detail>
        <WorkspacePane
          class="flare-workspace-frame__pane"
          :state="stateFor('detail')"
          skeleton="profile"
          :skeleton-rows="1"
          empty-icon="info"
          :empty-text="defaults.empty"
          :failure-text="defaults.failure"
          :loading-text="defaults.loading"
          :has-retry="hasRetry"
          :has-empty-action="hasEmptyAction"
          @focusin="activate('detail')"
          @retry="emit('retry', 'detail')"
          @empty-action="emit('emptyAction', 'detail')"
        >
          <slot name="detail" />
        </WorkspacePane>
      </template>
      <template #overlay><slot name="overlay" /></template>
      <template #floating><slot name="floating" /></template>
      <template #command><slot name="command" /></template>
    </FlareAppLayout>
  </section>
</template>

<style scoped>
.flare-workspace-frame { display: flex; flex-direction: column; width: 100%; height: 100%; min-width: 0; min-height: 0; overflow: hidden; background: var(--flare-color-bg-primary); }
.flare-workspace-frame__banner { flex: none; border-bottom: 1px solid var(--flare-color-border-primary); }
.flare-workspace-frame__layout { flex: 1; }
.flare-workspace-frame__pane { width: 100%; height: 100%; min-width: 0; min-height: 0; overflow: auto; }
.flare-workspace-frame__pane > :deep(.flare-skeleton),
.flare-workspace-frame__pane > :deep(.flare-empty-state),
.flare-workspace-frame__pane > :deep(.flare-status-banner) { margin: var(--flare-size-spacing-lg); }
</style>

