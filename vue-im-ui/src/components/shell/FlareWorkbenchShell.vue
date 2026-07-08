<script setup lang="ts">
import { computed } from "vue";
import {
  ChatbubbleEllipsesOutline,
  InformationCircleOutline,
  LogOutOutline,
} from "@vicons/ionicons5";
import { NDrawer, NDrawerContent, NIcon, NModal } from "naive-ui";
import {
  workbenchShellClass,
  type FlareWorkbenchShellMode,
} from "../../shared/contracts/workbench";
import { useViewport } from "../../composables/useViewport";

const props = withDefaults(
  defineProps<{
    mode?: FlareWorkbenchShellMode;
    brandLabel?: string;
    moreTitle?: string;
    moreSheetHeight?: string;
    moreActionCount?: number;
    messageUnreadCount?: number;
    chatSearchTitle?: string;
    sdkBuildTitle?: string;
    previewTitle?: string;
    previewPreset?: "card" | "dialog";
  }>(),
  {
    mode: "conversations",
    brandLabel: "F",
    moreTitle: "更多",
    moreActionCount: 2,
    messageUnreadCount: 0,
    chatSearchTitle: "搜索消息",
    sdkBuildTitle: "SDK 消息类型",
    previewTitle: "消息预览",
    previewPreset: "card",
  },
);

const moreOpen = defineModel<boolean>("moreOpen", { default: false });
const chatSearchOpen = defineModel<boolean>("chatSearchOpen", { default: false });
const sdkBuildOpen = defineModel<boolean>("sdkBuildOpen", { default: false });
const previewOpen = defineModel<boolean>("previewOpen", { default: false });

const emit = defineEmits<{
  (event: "navigate-messages"): void;
  (event: "navigate-lab"): void;
  (event: "logout"): void;
}>();

const { isDesktop } = useViewport();

const shellClass = computed(() => workbenchShellClass(props.mode));
const messagesNavActive = computed(() => props.mode === "conversations" || props.mode === "chat");
const labNavActive = computed(() => props.mode === "lab");
const showConversationPanel = computed(() => props.mode !== "lab");
const showDetails = computed(() => props.mode === "conversations" || props.mode === "chat");
const messageUnread = computed(() => Math.max(0, Math.floor(Number(props.messageUnreadCount) || 0)));
const messageUnreadLabel = computed(() => (messageUnread.value > 99 ? "99+" : String(messageUnread.value)));

const sheetPlacement = computed(() => (isDesktop.value ? "right" : "bottom"));
const sheetWidth = computed(() => (isDesktop.value ? 440 : undefined));
const tallSheetHeight = computed(() => (isDesktop.value ? undefined : "70vh"));
const sheetDrawerClass = computed(() =>
  isDesktop.value ? "mobile-sheet workbench-sheet--side" : "mobile-sheet",
);
const chatSearchDrawerClass = computed(() => [sheetDrawerClass.value, "workbench-search-sheet"]);

const resolvedMoreSheetHeight = computed(() => {
  if (props.moreSheetHeight) return props.moreSheetHeight;
  if (isDesktop.value) return undefined;
  const grabberAndTitle = 48;
  const accountCard = props.mode === "conversations" ? 88 : 0;
  const listTop = 10;
  const rowHeight = 48;
  const rowGap = 6;
  const actions =
    props.moreActionCount * rowHeight + Math.max(0, props.moreActionCount - 1) * rowGap + listTop;
  const edge = 10;
  const total = grabberAndTitle + accountCard + actions + edge;
  const maxPx =
    typeof window !== "undefined" ? Math.round(window.innerHeight * 0.5) : 400;
  return `${Math.min(total, maxPx)}px`;
});
</script>

<template>
  <main class="flutter-shell workbench-shell" :class="shellClass">
    <nav class="workbench-rail" aria-label="flare IM 工作台导航">
      <button
        type="button"
        class="workbench-rail__brand"
        title="flare IM"
        @click="emit('navigate-messages')"
      >
        {{ brandLabel }}
      </button>
      <button
        type="button"
        class="workbench-rail__item"
        :class="{ 'workbench-rail__item--active': messagesNavActive }"
        title="消息"
        @click="emit('navigate-messages')"
      >
        <n-icon :component="ChatbubbleEllipsesOutline" />
        <span v-if="messageUnread" class="workbench-rail__badge">{{ messageUnreadLabel }}</span>
      </button>
      <button
        type="button"
        class="workbench-rail__item"
        :class="{ 'workbench-rail__item--active': labNavActive }"
        title="SDK 能力中心"
        @click="emit('navigate-lab')"
      >
        <n-icon :component="InformationCircleOutline" />
      </button>
      <span class="workbench-rail__spacer" />
      <button type="button" class="workbench-rail__item" title="退出登录" @click="emit('logout')">
        <n-icon :component="LogOutOutline" />
      </button>
    </nav>

    <slot v-if="showConversationPanel" name="conversation" />
    <slot name="main" />

    <aside v-if="showDetails" class="workbench-details">
      <slot name="details" />
    </aside>

    <n-drawer
      v-model:show="moreOpen"
      :placement="sheetPlacement"
      :class="[sheetDrawerClass, 'workbench-more-sheet']"
      :width="sheetWidth"
      :height="resolvedMoreSheetHeight"
    >
      <n-drawer-content
        :title="moreTitle"
        :class="[sheetDrawerClass, 'workbench-more-sheet__content']"
      >
        <slot name="more" />
      </n-drawer-content>
    </n-drawer>

    <n-drawer
      v-model:show="chatSearchOpen"
      :placement="sheetPlacement"
      :class="chatSearchDrawerClass"
      :width="sheetWidth"
      :height="tallSheetHeight"
    >
      <n-drawer-content :title="chatSearchTitle" :class="chatSearchDrawerClass">
        <slot name="chat-search" />
      </n-drawer-content>
    </n-drawer>

    <n-drawer
      v-model:show="sdkBuildOpen"
      :placement="sheetPlacement"
      :class="sheetDrawerClass"
      :width="sheetWidth"
      :height="tallSheetHeight"
    >
      <n-drawer-content :title="sdkBuildTitle" :class="sheetDrawerClass">
        <slot name="sdk-build" />
      </n-drawer-content>
    </n-drawer>

    <n-modal
      v-model:show="previewOpen"
      :preset="previewPreset"
      class="preview-card"
      :title="previewTitle"
    >
      <slot name="preview" />
    </n-modal>
  </main>
</template>
