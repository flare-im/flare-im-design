<script setup lang="ts">
import { computed, ref, watch } from "vue";
import type { DropdownOption } from "naive-ui";
import { NButton, NIcon, NPopover } from "naive-ui";
import {
  ChatbubbleOutline,
  EllipsisHorizontalOutline,
  ThumbsUpOutline,
} from "@vicons/ionicons5";
import type { MessageLike } from "../../shared/contracts/messageRow";
import type { MessageMenuConfig } from "../../shared/config/messageMenu";
import MessageMenu from "./MessageMenu.vue";
import MessageEmojiPickerPanel from "./MessageEmojiPickerPanel.vue";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";

const props = withDefaults(
  defineProps<{
    message: MessageLike;
    currentUserId: string;
    reactionOptions: DropdownOption[];
    menuConfig?: MessageMenuConfig;
    /** PC：工具条贴在气泡侧面，便于鼠标移入 */
    beside?: boolean;
  }>(),
  { beside: false },
);

const emit = defineEmits<{
  (event: "quickReply"): void;
  (event: "reactionSelect", emoji: string): void;
  (event: "reply", messageId: string): void;
  (event: "forward", messageId: string): void;
  (event: "multiSelect", messageId: string): void;
  (event: "edit", messageId: string): void;
  (event: "recall", messageId: string): void;
  (event: "pin", messageId: string, pinned: boolean, scope: "conversation" | "self"): void;
  (event: "preview", messageId: string): void;
  (event: "mediaAction", messageId: string, action: "download" | "openFolder"): void;
  (event: "delete", messageId: string): void;
}>();

const menuRef = ref<InstanceType<typeof MessageMenu> | null>(null);
const { t } = useFlareI18n();

// Quick reactions come through as naive DropdownOptions (key = emoji); the popover
// wants the raw emoji, plus a "more" affordance that opens the full picker — so PC
// hover reaches the same extended emoji set the mobile long-press sheet does.
const quickReactions = computed(() => props.reactionOptions.map((o) => String(o.key)));
const reactShow = ref(false);
const emojiExpanded = ref(false);

watch(reactShow, (open) => {
  if (!open) emojiExpanded.value = false;
});

function pickReaction(emoji: string): void {
  emit("reactionSelect", emoji);
  reactShow.value = false;
}

function openMoreMenu(): void {
  menuRef.value?.openMenu();
}
</script>

<template>
  <div
    class="im-floating-bar"
    :class="{ 'im-floating-bar--beside-bubble': beside }"
    role="toolbar"
    :aria-label="t('message.toolbarAria')"
  >
    <n-popover
      v-model:show="reactShow"
      trigger="click"
      placement="top-start"
      :show-arrow="false"
      raw
      class="im-react-popover"
    >
      <template #trigger>
        <n-button text class="im-bar-btn" :aria-label="t('message.reactAria')">
          <n-icon :size="18" :component="ThumbsUpOutline" />
        </n-button>
      </template>
      <MessageEmojiPickerPanel
        v-if="emojiExpanded"
        @select="pickReaction"
        @collapse="emojiExpanded = false"
      />
      <div v-else class="im-react-quick" role="listbox">
        <button
          v-for="emoji in quickReactions"
          :key="emoji"
          type="button"
          class="im-react-quick__cell"
          :aria-label="`Emoji ${emoji}`"
          @click="pickReaction(emoji)"
        >
          {{ emoji }}
        </button>
        <button
          type="button"
          class="im-react-quick__cell im-react-quick__more"
          :aria-label="t('message.moreAria')"
          @click="emojiExpanded = true"
        >
          <n-icon :size="18" :component="EllipsisHorizontalOutline" />
        </button>
      </div>
    </n-popover>
    <n-button text class="im-bar-btn" :aria-label="t('message.replyAria')" @click="emit('quickReply')">
      <n-icon :size="18" :component="ChatbubbleOutline" />
    </n-button>
    <MessageMenu
      ref="menuRef"
      presentation="dropdown"
      :message="message"
      :current-user-id="currentUserId"
      :menu-config="menuConfig"
      dropdown-placement="bottom-start"
      @reply="(id: string) => emit('reply', id)"
      @forward="(id: string) => emit('forward', id)"
      @multi-select="(id: string) => emit('multiSelect', id)"
      @edit="(id: string) => emit('edit', id)"
      @recall="(id: string) => emit('recall', id)"
      @pin="(id: string, pinned: boolean, scope: 'conversation' | 'self') => emit('pin', id, pinned, scope)"
      @preview="(id: string) => emit('preview', id)"
      @media-action="(id: string, action: 'download' | 'openFolder') => emit('mediaAction', id, action)"
      @delete="(id: string) => emit('delete', id)"
    >
      <n-button text class="im-bar-btn" :aria-label="t('message.moreAria')" @click.stop="openMoreMenu">
        <n-icon :size="18" :component="EllipsisHorizontalOutline" />
      </n-button>
    </MessageMenu>
  </div>
</template>

<style scoped>
.im-floating-bar {
  display: inline-flex;
  align-items: center;
  gap: 2px;
  padding: 4px 6px;
  border-radius: 999px;
  background: var(--im-bg-surface);
  border: 1px solid var(--im-border-subtle);
  box-shadow: var(--im-shadow-panel);
}

.im-floating-bar--beside-bubble {
  border-radius: var(--im-radius-md, 8px);
  padding: 2px;
  box-shadow: var(--im-shadow-panel);
}

.im-floating-bar--beside-bubble .im-bar-btn {
  border-radius: 6px;
  min-height: 30px;
}

.im-bar-btn {
  width: 32px;
  height: 32px;
  padding: 0;
}

.im-bar-btn:hover {
  color: var(--im-primary) !important;
  background: var(--im-bg-card, var(--flare-color-bg-hover, #eef1f6));
}

/* Reaction popover — quick row that expands to the full picker. */
.im-react-quick {
  display: flex;
  align-items: center;
  gap: 2px;
  padding: 6px;
  border-radius: 12px;
  background: var(--im-bg-surface, var(--flare-color-bg-primary, #fff));
  border: 1px solid var(--im-border-subtle, var(--flare-color-border-primary, #e9e6f1));
  box-shadow: var(--im-shadow-floating, 0 8px 24px rgba(21, 18, 32, 0.12));
}

.im-react-quick__cell {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 34px;
  height: 34px;
  border: 0;
  border-radius: 9px;
  background: transparent;
  font-size: 20px;
  line-height: 1;
  cursor: pointer;
  transition: background var(--im-motion-fast, 150ms ease), transform var(--im-motion-fast, 150ms ease);
}

.im-react-quick__cell:hover {
  background: var(--im-bg-card, var(--flare-color-bg-hover, #f1eef8));
  transform: translateY(-1px) scale(1.06);
}

.im-react-quick__more {
  color: var(--im-text-secondary, var(--flare-color-text-secondary, #6b6780));
}
</style>
