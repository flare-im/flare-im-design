<script setup lang="ts">
// The conversation workspace: FlareResponsiveLayout plus ONE place where every
// pane resolves loading / empty / failure. Hosts stop re-writing a skeleton, an
// empty card and an error card per app and per pane.
//
// It owns no data and performs no side effect: pane content stays in the
// list / chat / detail slots, splitting and breakpoints stay in
// FlareResponsiveLayout, recovery stays with the host via `retry`.
import { computed, getCurrentInstance } from "vue";
import FlareResponsiveLayout from "./FlareResponsiveLayout.vue";
import WorkspacePane from "./WorkspacePane.vue";
import FlareStatusBanner from "../general/FlareStatusBanner.vue";
import { flareLayout } from "../../design-system/theme/layout-tokens";
import type { FlareLayoutChange } from "../../shared/contracts/application";
import {
  paneSkeletonVariant,
  workspaceBannerActionVisible,
  workspaceBannerTone,
  workspaceBannerVisible,
  type WorkspaceBanner,
  type WorkspacePaneKey,
  type WorkspacePaneState,
} from "../../shared/contracts/conversation-workspace";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";

const props = withDefaults(
  defineProps<{
    /** Foreground pane when collapsed to one column. Forwarded verbatim. */
    activePane?: WorkspacePaneKey;
    /** Whether a detail pane exists (enables the third column). Forwarded verbatim. */
    hasDetail?: boolean;
    listWidth?: number;
    detailWidth?: number;
    hideMobileBar?: boolean;
    backLabel?: string;
    /** Per-pane status. Independent: a failing timeline never degrades a loaded inbox. */
    listState?: WorkspacePaneState;
    chatState?: WorkspacePaneState;
    detailState?: WorkspacePaneState;
    /** Cross-pane notice (offline / reconnecting / session expired), above all three panes. */
    banner?: WorkspaceBanner;
    listEmptyText?: string;
    chatEmptyText?: string;
    detailEmptyText?: string;
    listFailureText?: string;
    chatFailureText?: string;
    detailFailureText?: string;
    /** Screen-reader text announced while the pane skeleton shows. */
    listLoadingText?: string;
    chatLoadingText?: string;
    detailLoadingText?: string;
  }>(),
  {
    activePane: "list",
    hasDetail: false,
    listWidth: flareLayout.primaryPaneDefaultWidth,
    detailWidth: flareLayout.detailPaneDefaultWidth,
    hideMobileBar: false,
    listState: () => ({ status: "ready" }),
    chatState: () => ({ status: "ready" }),
    detailState: () => ({ status: "ready" }),
  },
);
const { t } = useFlareI18n();
const strings = computed(() => ({
  backLabel: props.backLabel ?? t("conversationWorkspace.back"),
  listEmptyText: props.listEmptyText ?? t("conversationWorkspace.listEmpty"),
  chatEmptyText: props.chatEmptyText ?? t("conversationWorkspace.chatEmpty"),
  detailEmptyText: props.detailEmptyText ?? t("conversationWorkspace.detailEmpty"),
  listFailureText: props.listFailureText ?? t("conversationWorkspace.listFailure"),
  chatFailureText: props.chatFailureText ?? t("conversationWorkspace.chatFailure"),
  detailFailureText: props.detailFailureText ?? t("conversationWorkspace.detailFailure"),
  listLoadingText: props.listLoadingText ?? t("conversationWorkspace.listLoading"),
  chatLoadingText: props.chatLoadingText ?? t("conversationWorkspace.chatLoading"),
  detailLoadingText: props.detailLoadingText ?? t("conversationWorkspace.detailLoading"),
}));

const emit = defineEmits<{
  (e: "paneChange", pane: WorkspacePaneKey): void;
  (e: "retry", pane: WorkspacePaneKey): void;
  (e: "emptyAction", pane: WorkspacePaneKey): void;
  (e: "bannerAction"): void;
  /** Forwarded from FlareResponsiveLayout: the panes in use once the width is known. */
  (e: "layoutChange", layout: FlareLayoutChange): void;
}>();

// A recovery button appears only when the host bound the matching listener.
const instance = getCurrentInstance();
const hasRetry = computed(() => !!instance?.vnode.props?.onRetry);
const hasBannerAction = computed(() => !!instance?.vnode.props?.onBannerAction);
const hasEmptyAction = computed(() => !!instance?.vnode.props?.onEmptyAction);

const bannerVisible = computed(() => workspaceBannerVisible(props.banner));
const bannerActionVisible = computed(() => workspaceBannerActionVisible(props.banner, hasBannerAction.value));
const bannerText = computed(() => props.banner?.message ?? "");
const bannerTone = computed(() => workspaceBannerTone(props.banner?.tone));
const bannerActionLabel = computed(() => props.banner?.actionLabel);

const listSkeleton = paneSkeletonVariant("list");
const chatSkeleton = paneSkeletonVariant("chat");
const detailSkeleton = paneSkeletonVariant("detail");
</script>

<template>
  <div class="flare-workspace">
    <div v-if="bannerVisible" class="flare-workspace__banner">
      <FlareStatusBanner
        :text="bannerText"
        :tone="bannerTone"
        :action-text="bannerActionVisible ? bannerActionLabel : undefined"
        @action="emit('bannerAction')"
      />
    </div>

    <div class="flare-workspace__body">
      <FlareResponsiveLayout
        :has-detail="hasDetail"
        :active-pane="activePane"
        :list-width="listWidth"
        :detail-width="detailWidth"
        :hide-mobile-bar="hideMobileBar"
        :back-label="strings.backLabel"
        @pane-change="emit('paneChange', $event)"
        @layout-change="emit('layoutChange', $event)"
      >
        <template #list>
          <WorkspacePane
            class="flare-workspace__pane"
            :state="listState"
            :skeleton="listSkeleton"
            :skeleton-rows="6"
            empty-icon="chats"
            :empty-text="strings.listEmptyText"
            :failure-text="strings.listFailureText"
            :loading-text="strings.listLoadingText"
            :has-retry="hasRetry"
            :has-empty-action="hasEmptyAction"
            @retry="emit('retry', 'list')"
            @empty-action="emit('emptyAction', 'list')"
          >
            <slot name="list" />
          </WorkspacePane>
        </template>

        <template #chat>
          <WorkspacePane
            class="flare-workspace__pane"
            :state="chatState"
            :skeleton="chatSkeleton"
            :skeleton-rows="5"
            empty-icon="comment"
            :empty-text="strings.chatEmptyText"
            :failure-text="strings.chatFailureText"
            :loading-text="strings.chatLoadingText"
            :has-retry="hasRetry"
            :has-empty-action="hasEmptyAction"
            @retry="emit('retry', 'chat')"
            @empty-action="emit('emptyAction', 'chat')"
          >
            <slot name="chat" />
          </WorkspacePane>
        </template>

        <template #detail>
          <WorkspacePane
            class="flare-workspace__pane"
            :state="detailState"
            :skeleton="detailSkeleton"
            :skeleton-rows="1"
            empty-icon="info"
            :empty-text="strings.detailEmptyText"
            :failure-text="strings.detailFailureText"
            :loading-text="strings.detailLoadingText"
            :has-retry="hasRetry"
            :has-empty-action="hasEmptyAction"
            @retry="emit('retry', 'detail')"
            @empty-action="emit('emptyAction', 'detail')"
          >
            <slot name="detail" />
          </WorkspacePane>
        </template>
      </FlareResponsiveLayout>
    </div>
  </div>
</template>

<style scoped>
.flare-workspace {
  display: flex;
  flex-direction: column;
  width: 100%;
  height: 100%;
  min-width: 0;
  min-height: 0;
  color: var(--flare-color-text-primary);
  background: var(--flare-color-bg-primary);
}
.flare-workspace__banner {
  flex: none;
  padding: var(--flare-size-spacing-sm);
  border-bottom: 1px solid var(--flare-color-border-primary);
}
.flare-workspace__body {
  flex: 1;
  min-width: 0;
  min-height: 0;
}
.flare-workspace__pane {
  display: flex;
  flex-direction: column;
  width: 100%;
  height: 100%;
  min-width: 0;
  min-height: 0;
}
.flare-workspace__loading {
  flex: 1;
  min-height: 0;
  overflow: hidden;
  padding: var(--flare-size-spacing-lg);
}
.flare-workspace__empty {
  flex: 1;
  min-height: 0;
  justify-content: center;
  overflow-y: auto;
}
.flare-workspace__failure {
  flex: none;
  padding: var(--flare-size-spacing-lg);
  overflow-wrap: anywhere;
}
.flare-workspace__sr {
  position: absolute;
  width: 1px;
  height: 1px;
  padding: 0;
  margin: -1px;
  overflow: hidden;
  clip: rect(0 0 0 0);
  white-space: nowrap;
  border: 0;
}
</style>
