<script setup lang="ts">
import { ref } from "vue";
import type { DropdownOption } from "naive-ui";
import { NButton, NDropdown, NIcon } from "naive-ui";
import {
  ChatbubbleOutline,
  EllipsisHorizontalOutline,
  ThumbsUpOutline,
} from "@vicons/ionicons5";
import type { MessageLike } from "../../shared/contracts/messageRow";
import type { MessageMenuConfig } from "../../shared/config/messageMenu";
import MessageMenu from "./MessageMenu.vue";
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
    <n-dropdown
      trigger="click"
      :options="reactionOptions"
      placement="bottom-start"
      @select="(key: string) => emit('reactionSelect', key)"
    >
      <n-button text class="im-bar-btn" :aria-label="t('message.reactAria')">
        <n-icon :size="18" :component="ThumbsUpOutline" />
      </n-button>
    </n-dropdown>
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
  background: var(--im-bg-card, #eef1f6);
}
</style>
