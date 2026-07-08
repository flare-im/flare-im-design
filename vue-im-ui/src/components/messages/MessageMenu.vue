<script setup lang="ts">
import { computed, ref, watch } from "vue";
import { NDrawer, NDrawerContent, NDropdown } from "naive-ui";
import type { MessageMenuPresentation } from "../../composables/chat/useMessageMenuInteraction";
import type { MessageMenuConfig } from "../../shared/config/messageMenu";
import type { MessageLike } from "../../shared/contracts/messageRow";
import { getMessageText } from "../../utils/messagePreview";
import {
  buildMessageContextSheetModel,
  buildMessageMenuDropdownOptions,
  resolveMessageMenuAction,
} from "../../utils/buildMessageMenuOptions";
import MessageContextMenuSheet from "./MessageContextMenuSheet.vue";
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
  }>(),
  {
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
}>();

const menuOpen = ref(false);
const sheetOpen = ref(false);
const emojiPanelExpanded = ref(false);
const { t } = useFlareI18n();

const sheetModel = computed(() =>
  buildMessageContextSheetModel(props.message, props.currentUserId, props.menuConfig, t),
);
const dropdownOptions = computed(() =>
  buildMessageMenuDropdownOptions(props.message, props.currentUserId, props.menuConfig, t),
);

const useBottomSheet = computed(() => props.presentation === "bottomSheet");

const sheetHeight = computed(() => {
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
      const text = getMessageText(props.message);
      if (text && typeof navigator !== "undefined" && navigator.clipboard?.writeText) {
        void navigator.clipboard.writeText(text);
      }
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
  if (key.startsWith("__menu_")) return;
  closeMenus();
  dispatch(key);
}

function onReact(emoji: string): void {
  closeMenus();
  emit("react", emoji);
}

function openMenu(): void {
  if (props.suppressMenu) return;
  if (useBottomSheet.value) {
    sheetOpen.value = true;
    return;
  }
  menuOpen.value = true;
}

function onContextMenu(event: MouseEvent): void {
  if (!props.enableContextMenu || props.suppressMenu) return;
  event.preventDefault();
  openMenu();
}

defineExpose({ openMenu });
</script>

<template>
  <template v-if="suppressMenu">
    <slot />
  </template>
  <template v-else-if="useBottomSheet">
    <div class="message-menu-anchor" @contextmenu="onContextMenu">
      <slot />
    </div>
    <n-drawer
      v-model:show="sheetOpen"
      placement="bottom"
      :height="sheetHeight"
      class="message-menu-drawer mobile-sheet"
    >
      <n-drawer-content :native-scrollbar="false" class="message-menu-drawer-content">
        <MessageContextMenuSheet
          :model="sheetModel"
          @select="onSelect"
          @react="onReact"
          @emoji-expanded="onEmojiExpanded"
        />
      </n-drawer-content>
    </n-drawer>
  </template>
  <n-dropdown
    v-else
    :show="menuOpen"
    trigger="manual"
    :placement="dropdownPlacement"
    :options="dropdownOptions"
    :menu-props="() => ({ class: 'message-menu-dropdown' })"
    @select="onSelect"
    @clickoutside="menuOpen = false"
  >
    <div class="message-menu-anchor" @contextmenu="onContextMenu">
      <slot />
    </div>
  </n-dropdown>
</template>
