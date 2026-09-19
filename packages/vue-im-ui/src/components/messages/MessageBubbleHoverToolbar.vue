<script setup lang="ts">
import { computed, ref, watch } from "vue";
import type { DropdownOption } from "naive-ui";
import { NButton, NIcon, NPopover } from "naive-ui";
import { flareIcons } from "../../shared/icons";
import type { MessageLike } from "../../shared/contracts/messageRow";
import { isMessageMenuActionEnabled, mergeMessageMenuConfig, type MessageMenuConfig } from "../../shared/config/messageMenu";
import { buildMessageMenuContext, buildMessageMenuItems, type MessageMenuExtension } from "../../utils/buildMessageMenuOptions";
import MessageMenu from "./MessageMenu.vue";
import MessageEmojiPickerPanel from "./MessageEmojiPickerPanel.vue";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";

const props = withDefaults(
  defineProps<{
    message: MessageLike;
    currentUserId: string;
    reactionOptions: DropdownOption[];
    menuConfig?: MessageMenuConfig;
    actions?: readonly MessageMenuExtension[];
    /** PC：工具条贴在气泡侧面，便于鼠标移入 */
    beside?: boolean;
    /** Whether the buttons are in the Tab sequence; a message list turns this on only while focus is inside the message. */
    focusable?: boolean;
  }>(),
  { beside: false, actions: () => [], focusable: true },
);

const emit = defineEmits<{
  (event: "quickReply"): void;
  (event: "reactionSelect", emoji: string): void;
  (event: "reply", messageId: string): void;
  (event: "forward", messageId: string): void;
  (event: "multiSelect", messageId: string): void;
  (event: "edit", messageId: string): void;
  (event: "recall", messageId: string): void;
  (event: "resend", messageId: string): void;
  (event: "pin", messageId: string, pinned: boolean, scope: "conversation" | "self"): void;
  (event: "mark", messageId: string): void;
  (event: "preview", messageId: string): void;
  (event: "mediaAction", messageId: string, action: "download" | "openFolder"): void;
  (event: "delete", messageId: string): void;
  (event: "action", actionId: string, messageId: string): void;
  (event: "copy", messageId: string, copied: boolean): void;
}>();

const menuRef = ref<InstanceType<typeof MessageMenu> | null>(null);
const { t } = useFlareI18n();

// Each control is shown only when its intent is enabled for this message — the same
// rule as the menu, so a host without a reaction or reply handler gets no dead button.
const merged = computed(() => mergeMessageMenuConfig(props.menuConfig));
const context = computed(() => buildMessageMenuContext(props.message, props.currentUserId));
const canReact = computed(() => isMessageMenuActionEnabled(merged.value, "react", context.value));
const canReply = computed(() => isMessageMenuActionEnabled(merged.value, "reply", context.value));
const hasMoreActions = computed(
  () => buildMessageMenuItems(props.message, props.currentUserId, props.menuConfig, t, ["reply"], props.actions).length > 0,
);

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
    v-if="canReact || canReply || hasMoreActions"
    class="im-floating-bar"
    :class="{ 'im-floating-bar--beside-bubble': beside }"
    role="toolbar"
    :aria-label="t('message.toolbarAria')"
  >
    <n-popover
      v-if="canReact"
      v-model:show="reactShow"
      trigger="click"
      placement="top-start"
      :show-arrow="false"
      raw
      class="im-react-popover"
    >
      <template #trigger>
        <n-button text class="im-bar-btn" :focusable="focusable" :aria-label="t('message.reactAria')">
          <n-icon aria-hidden="true" :size="18" :component="flareIcons.reaction" />
        </n-button>
      </template>
      <MessageEmojiPickerPanel
        v-if="emojiExpanded"
        @select="pickReaction"
        @collapse="emojiExpanded = false"
      />
      <div v-else class="im-react-quick" role="group" :aria-label="t('message.reactAria')">
        <button
          v-for="emoji in quickReactions"
          :key="emoji"
          type="button"
          class="im-react-quick__cell"
          :aria-label="t('messageEmojiPickerPanel.emojiOption', { emoji })"
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
          <n-icon aria-hidden="true" :size="18" :component="flareIcons.more" />
        </button>
      </div>
    </n-popover>
    <n-button v-if="canReply" text class="im-bar-btn" :focusable="focusable" :aria-label="t('message.replyAria')" @click="emit('quickReply')">
      <n-icon aria-hidden="true" :size="18" :component="flareIcons.reply" />
    </n-button>
    <MessageMenu
      v-if="hasMoreActions"
      ref="menuRef"
      presentation="dropdown"
      :omit-actions="['reply']"
      :message="message"
      :current-user-id="currentUserId"
      :menu-config="menuConfig"
      :actions="actions"
      dropdown-placement="bottom-start"
      @reply="(id: string) => emit('reply', id)"
      @forward="(id: string) => emit('forward', id)"
      @multi-select="(id: string) => emit('multiSelect', id)"
      @edit="(id: string) => emit('edit', id)"
      @recall="(id: string) => emit('recall', id)"
      @resend="(id: string) => emit('resend', id)"
      @pin="(id: string, pinned: boolean, scope: 'conversation' | 'self') => emit('pin', id, pinned, scope)"
      @mark="(id: string) => emit('mark', id)"
      @preview="(id: string) => emit('preview', id)"
      @media-action="(id: string, action: 'download' | 'openFolder') => emit('mediaAction', id, action)"
      @delete="(id: string) => emit('delete', id)"
      @action="(actionId: string, id: string) => emit('action', actionId, id)"
      @copy="(id: string, copied: boolean) => emit('copy', id, copied)"
    >
      <n-button text class="im-bar-btn" :focusable="focusable" :aria-label="t('message.moreAria')" @click.stop="openMoreMenu">
        <n-icon aria-hidden="true" :size="18" :component="flareIcons.more" />
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
  background: var(--flare-color-bg-primary);
  border: 1px solid var(--flare-color-border-secondary);
  box-shadow: var(--flare-component-shadow-panel);
}

.im-floating-bar--beside-bubble {
  border-radius: var(--flare-component-radius-md);
  padding: 2px;
  box-shadow: var(--flare-component-shadow-panel);
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
  color: var(--flare-color-primary-text) !important;
  background: var(--flare-color-bg-tertiary);
}

/* Reaction popover — quick row that expands to the full picker. */
.im-react-quick {
  display: flex;
  align-items: center;
  gap: 2px;
  padding: 6px;
  border-radius: 12px;
  background: var(--flare-color-bg-primary);
  border: 1px solid var(--flare-color-border-secondary);
  box-shadow: var(--flare-component-shadow-floating);
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
  transition: background var(--flare-component-motion-fast), transform var(--flare-component-motion-fast);
}

.im-react-quick__cell:hover {
  background: var(--flare-color-bg-tertiary);
  /* Grow in place: scale keeps the cursor inside, a lift would not. */
  transform: scale(1.06);
}

.im-react-quick__more {
  color: var(--flare-color-text-secondary);
}
</style>
