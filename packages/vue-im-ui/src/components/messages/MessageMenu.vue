<script setup lang="ts">
import { computed, ref, watch } from "vue";
import type { MessageMenuPresentation } from "../../composables/chat/useMessageMenuInteraction";
import type { MessageMenuConfig } from "../../shared/config/messageMenu";
import type { MessageLike } from "../../shared/contracts/messageRow";
import { getMessageText } from "../../utils/messagePreview";
import {
  buildMessageContextSheetModel,
  buildMessageMenuItems,
  resolveMessageMenuAction,
  type MessageMenuExtension,
} from "../../utils/buildMessageMenuOptions";
import FlareBottomSheet from "../general/FlareBottomSheet.vue";
import MessageActionSheet from "./MessageActionSheet.vue";
import FlareActionMenu from "../general/FlareActionMenu.vue";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";

const props = withDefaults(
  defineProps<{
    message: MessageLike;
    currentUserId: string;
    presentation: MessageMenuPresentation;
    enableContextMenu?: boolean;
    suppressMenu?: boolean;
    menuConfig?: MessageMenuConfig;
    dropdownPlacement?: "bottom-start" | "right-start";
    /** Actions the surrounding surface already shows as its own controls. */
    omitActions?: readonly string[];
    /** Host actions (report, translate, ...) listed with the built-in ones; selecting one emits `action`. */
    actions?: readonly MessageMenuExtension[];
  }>(),
  {
    omitActions: () => [],
    actions: () => [],
    enableContextMenu: false,
    suppressMenu: false,
    dropdownPlacement: "bottom-start",
  },
);

const emit = defineEmits<{
  (event: "reply", messageId: string): void;
  (event: "forward", messageId: string): void;
  (event: "multiSelect", messageId: string): void;
  (event: "edit", messageId: string): void;
  (event: "recall", messageId: string): void;
  (event: "resend", clientMsgId: string): void;
  (event: "pin", messageId: string, pinned: boolean, scope: "conversation" | "self"): void;
  (event: "preview", messageId: string): void;
  (event: "mediaAction", messageId: string, action: "download" | "openFolder"): void;
  (event: "delete", messageId: string): void;
  (event: "react", emoji: string): void;
  (event: "mark", messageId: string): void;
  (event: "action", actionId: string, messageId: string): void;
  /** After a copy: `copied` is false when the clipboard refused the text. */
  (event: "copy", messageId: string, copied: boolean): void;
}>();

const menuOpen = ref(false);
const sheetOpen = ref(false);
// The menu and the sheet mount the first time someone opens them. Every message of a timeline
// renders a MessageMenu, so building a popover or drawer per message up front multiplied the
// mount cost of a long conversation by thousands of instances nobody opened.
const menuMounted = ref(false);
const sheetMounted = ref(false);
const anchorRef = ref<HTMLElement | null>(null);
const menuPoint = ref<{ x: number; y: number } | null>(null);
const emojiPanelExpanded = ref(false);
const { t } = useFlareI18n();

const sheetModel = computed(() =>
  buildMessageContextSheetModel(props.message, props.currentUserId, props.menuConfig, t, props.actions),
);
const dropdownItems = computed(() =>
  buildMessageMenuItems(props.message, props.currentUserId, props.menuConfig, t, props.omitActions, props.actions),
);

const useBottomSheet = computed(() => props.presentation === "bottomSheet");

// 面自己按内容撑开,这里只给上限 —— 从前是 naive 抽屉的一个固定高度,内容短了留白、
// 长了被切(表情面板展开那一档尤其明显)。
const sheetMaxHeight = computed(() => {
  if (typeof window === "undefined") return "auto";
  const vh = window.innerHeight;
  const react = sheetModel.value.showReactions ? 72 : 0;
  if (emojiPanelExpanded.value) {
    const emojiPanel = 200;
    return `${Math.min(react + emojiPanel + 20, Math.round(vh * 0.42))}px`;
  }
  const quick = sheetModel.value.quickActions.length > 0 ? 100 : 0;
  const list = sheetModel.value.listActions.length * 54 + 16;
  const px = Math.min(react + quick + list + 24, Math.round(vh * 0.62));
  return `${Math.max(px, 220)}px`;
});

function onEmojiExpanded(expanded: boolean): void {
  emojiPanelExpanded.value = expanded;
}

// 滚动锁、焦点、Escape 和平台返回键都由 FlareBottomSheet 走共用的模态栈 —— 从前这张
// 面是 naive 的底部抽屉:自己锁 documentElement 的 overflow(组件库锁的是 body,两把锁
// 互相看不见),z-index 落在锚定层 2000(比所有模态都高),返回键还得在这里再接一次。
watch(sheetOpen, (open) => {
  if (!open) emojiPanelExpanded.value = false;
});

function dispatch(key: string): void {
  const action = resolveMessageMenuAction(props.message, key);
  if (action.type === "noop") return;
  switch (action.event) {
    case "reply":
      emit("reply", action.payload as string);
      break;
    case "forward":
      emit("forward", action.payload as string);
      break;
    case "multiSelect":
      emit("multiSelect", action.payload as string);
      break;
    case "edit":
      emit("edit", action.payload as string);
      break;
    case "recall":
      emit("recall", action.payload as string);
      break;
    case "resend":
      emit("resend", action.payload as string);
      break;
    case "pin": {
      const p = action.payload as { id: string; pinned: boolean; scope: "conversation" | "self" };
      emit("pin", p.id, p.pinned, p.scope);
      break;
    }
    case "preview":
      emit("preview", action.payload as string);
      break;
    case "mediaAction": {
      const p = action.payload as { id: string; action: "download" | "openFolder" };
      emit("mediaAction", p.id, p.action);
      break;
    }
    case "copy": {
      const id = action.payload as string;
      const text = getMessageText(props.message);
      if (!text || typeof navigator === "undefined" || !navigator.clipboard?.writeText) {
        emit("copy", id, false);
        break;
      }
      navigator.clipboard.writeText(text).then(() => emit("copy", id, true), () => emit("copy", id, false));
      break;
    }
    case "action": {
      const p = action.payload as { id: string; actionId: string };
      emit("action", p.actionId, p.id);
      break;
    }
    case "mark":
      emit("mark", action.payload as string);
      break;
    case "delete":
      emit("delete", action.payload as string);
      break;
    default:
      break;
  }
}

function closeMenus(): void {
  menuOpen.value = false;
  sheetOpen.value = false;
}

function onSelect(key: string): void {
  closeMenus();
  dispatch(key);
}

function onReact(emoji: string): void {
  closeMenus();
  emit("react", emoji);
}

/** Where the dropdown opens: the given point (a right-click), otherwise the bubble's edge for the placement. */
function anchorPoint(): { x: number; y: number } | null {
  const rect = anchorRef.value?.getBoundingClientRect();
  if (!rect) return null;
  return props.dropdownPlacement === "right-start" ? { x: rect.right, y: rect.top } : { x: rect.left, y: rect.bottom };
}

function openMenu(point?: { x: number; y: number }): void {
  if (props.suppressMenu) return;
  if (useBottomSheet.value) {
    sheetMounted.value = true;
    sheetOpen.value = true;
    return;
  }
  menuPoint.value = point ?? anchorPoint();
  menuMounted.value = true;
  menuOpen.value = true;
}

function onContextMenu(event: MouseEvent): void {
  if (!props.enableContextMenu || props.suppressMenu) return;
  event.preventDefault();
  openMenu({ x: event.clientX, y: event.clientY });
}

defineExpose({ openMenu });
</script>

<template>
  <template v-if="suppressMenu">
    <slot />
  </template>
  <template v-else>
    <div ref="anchorRef" class="message-menu-anchor" @contextmenu="onContextMenu">
      <slot />
    </div>
    <FlareBottomSheet
      v-if="useBottomSheet && sheetMounted"
      :open="sheetOpen"
      presentation="sheet"
      :max-height="sheetMaxHeight"
      :title="t('message.menuAria')"
      title-hidden
      @close="sheetOpen = false"
    >
      <MessageActionSheet
        :model="sheetModel"
        :show-grabber="false"
        @action="onSelect"
        @react="onReact"
        @emoji-expanded="onEmojiExpanded"
      />
    </FlareBottomSheet>
    <FlareActionMenu
      v-else-if="!useBottomSheet && menuMounted"
      :open="menuOpen"
      trigger="manual"
      presentation="anchored"
      :x="menuPoint?.x"
      :y="menuPoint?.y"
      :placement="dropdownPlacement"
      :items="dropdownItems"
      :label="t('message.menuAria')"
      @select="onSelect"
      @update:open="menuOpen = $event"
    />
  </template>
</template>
