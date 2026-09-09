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
import FlareEmptyState from "../general/FlareEmptyState.vue";
import FlareSkeleton from "../general/FlareSkeleton.vue";
import FlareStatusBanner from "../general/FlareStatusBanner.vue";
import { flareLayout } from "../../design-system/theme/layout-policy";
import {
  paneRender,
  paneRetryVisible,
  paneSkeletonVariant,
  workspaceBannerActionVisible,
  workspaceBannerTone,
  workspaceBannerVisible,
  type WorkspaceBanner,
  type WorkspacePaneKey,
  type WorkspacePaneState,
} from "../../shared/contracts/conversation-workspace";

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
    listWidth: flareLayout.leftPanel,
    detailWidth: flareLayout.rightPanel,
    hideMobileBar: false,
    backLabel: "Back",
    listState: () => ({ status: "ready" }),
    chatState: () => ({ status: "ready" }),
    detailState: () => ({ status: "ready" }),
    listEmptyText: "暂无会话",
    chatEmptyText: "选择一个会话开始聊天",
    detailEmptyText: "暂无详情",
    listFailureText: "会话列表加载失败",
    chatFailureText: "消息加载失败",
    detailFailureText: "详情加载失败",
    listLoadingText: "正在加载会话列表",
    chatLoadingText: "正在加载消息",
    detailLoadingText: "正在加载详情",
  },
);

const emit = defineEmits<{
  (e: "paneChange", pane: WorkspacePaneKey): void;
  (e: "retry", pane: WorkspacePaneKey): void;
  (e: "bannerAction"): void;
}>();

// A recovery button appears only when the host bound the matching listener.
const instance = getCurrentInstance();
const hasRetry = computed(() => !!instance?.vnode.props?.onRetry);
const hasBannerAction = computed(() => !!instance?.vnode.props?.onBannerAction);

const listRender = computed(() => paneRender(props.listState));
const chatRender = computed(() => paneRender(props.chatState));
const detailRender = computed(() => paneRender(props.detailState));

const listRetry = computed(() => paneRetryVisible(props.listState, hasRetry.value));
const chatRetry = computed(() => paneRetryVisible(props.chatState, hasRetry.value));
const detailRetry = computed(() => paneRetryVisible(props.detailState, hasRetry.value));

function text(value: string | undefined, fallback: string): string {
  return value && value.trim().length > 0 ? value : fallback;
}
const listMessage = computed(() => props.listState.message);
const chatMessage = computed(() => props.chatState.message);
const detailMessage = computed(() => props.detailState.message);

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
        :back-label="backLabel"
        @pane-change="emit('paneChange', $event)"
      >
        <template #list>
          <div class="flare-workspace__pane">
            <slot v-if="listRender === 'content'" name="list" />
            <div v-else-if="listRender === 'skeleton'" class="flare-workspace__loading" role="status" aria-live="polite">
              <span class="flare-workspace__sr">{{ listLoadingText }}</span>
              <FlareSkeleton :variant="listSkeleton" :rows="6" />
            </div>
            <FlareEmptyState
              v-else-if="listRender === 'empty'"
              class="flare-workspace__empty"
              icon="chats"
              :title="text(listMessage, listEmptyText)"
            />
            <div v-else class="flare-workspace__failure" role="alert">
              <FlareStatusBanner
                tone="danger"
                :dot="true"
                :text="text(listMessage, listFailureText)"
                :action-text="listRetry ? listState.actionLabel : undefined"
                @action="emit('retry', 'list')"
              />
            </div>
          </div>
        </template>

        <template #chat>
          <div class="flare-workspace__pane">
            <slot v-if="chatRender === 'content'" name="chat" />
            <div v-else-if="chatRender === 'skeleton'" class="flare-workspace__loading" role="status" aria-live="polite">
              <span class="flare-workspace__sr">{{ chatLoadingText }}</span>
              <FlareSkeleton :variant="chatSkeleton" :rows="5" />
            </div>
            <FlareEmptyState
              v-else-if="chatRender === 'empty'"
              class="flare-workspace__empty"
              icon="comment"
              :title="text(chatMessage, chatEmptyText)"
            />
            <div v-else class="flare-workspace__failure" role="alert">
              <FlareStatusBanner
                tone="danger"
                :dot="true"
                :text="text(chatMessage, chatFailureText)"
                :action-text="chatRetry ? chatState.actionLabel : undefined"
                @action="emit('retry', 'chat')"
              />
            </div>
          </div>
        </template>

        <template #detail>
          <div class="flare-workspace__pane">
            <slot v-if="detailRender === 'content'" name="detail" />
            <div v-else-if="detailRender === 'skeleton'" class="flare-workspace__loading" role="status" aria-live="polite">
              <span class="flare-workspace__sr">{{ detailLoadingText }}</span>
              <FlareSkeleton :variant="detailSkeleton" :rows="1" />
            </div>
            <FlareEmptyState
              v-else-if="detailRender === 'empty'"
              class="flare-workspace__empty"
              icon="info"
              :title="text(detailMessage, detailEmptyText)"
            />
            <div v-else class="flare-workspace__failure" role="alert">
              <FlareStatusBanner
                tone="danger"
                :dot="true"
                :text="text(detailMessage, detailFailureText)"
                :action-text="detailRetry ? detailState.actionLabel : undefined"
                @action="emit('retry', 'detail')"
              />
            </div>
          </div>
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
  padding: var(--flare-size-spacing-sm, 8px);
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
  padding: var(--flare-size-spacing-lg, 16px);
}
.flare-workspace__empty {
  flex: 1;
  min-height: 0;
  justify-content: center;
  overflow-y: auto;
}
.flare-workspace__failure {
  flex: none;
  padding: var(--flare-size-spacing-lg, 16px);
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
