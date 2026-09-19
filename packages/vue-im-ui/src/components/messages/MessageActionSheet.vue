<script setup lang="ts">
import { computed, ref } from "vue";
import {
  EllipsisHorizontalOutline,
} from "../../shared/icon-glyphs";
import { NIcon } from "naive-ui";
import type { MessageContextSheetModel, MessageMenuSheetItem } from "../../utils/buildMessageMenuOptions";
import { messageMenuGlyph } from "../../utils/messageMenuIcons";
import { MESSAGE_QUICK_REACTIONS } from "../../shared/constants/messageReactions";
import MessageEmojiPickerPanel from "./MessageEmojiPickerPanel.vue";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";

const props = withDefaults(defineProps<{
  model: MessageContextSheetModel;
  /** Disable when the containing sheet already supplies its own handle. */
  showGrabber?: boolean;
}>(), { showGrabber: true });

// The message long-press action sheet — reaction strip, quick actions, grouped
// list, expandable emoji panel. Spec: Message/MessageActionSheet. Owns no
// positioning: the host (MessageMenu) places it in a bottom sheet.
const emit = defineEmits<{
  (event: "action", key: string): void;
  (event: "react", emoji: string): void;
  (event: "emoji-expanded", expanded: boolean): void;
}>();

const emojiPanelOpen = ref(false);
const { t } = useFlareI18n();

function setEmojiPanelOpen(open: boolean): void {
  emojiPanelOpen.value = open;
  emit("emoji-expanded", open);
}

const quickReactions = MESSAGE_QUICK_REACTIONS;

function iconFor(item: MessageMenuSheetItem) {
  return messageMenuGlyph(item.icon) ?? null;
}

const showQuickGrid = computed(() => props.model.quickActions.length > 0);

function onReaction(emoji: string): void {
  setEmojiPanelOpen(false);
  emit("react", emoji);
}

function onAction(key: string): void {
  emit("action", key);
}
</script>

<template>
  <div class="msg-ctx-sheet" :class="{ 'msg-ctx-sheet--emoji-only': emojiPanelOpen }" role="menu">
    <div v-if="showGrabber" class="msg-ctx-sheet__grabber" aria-hidden="true" />

    <section v-if="model.showReactions" class="msg-ctx-sheet__block msg-ctx-sheet__reactions" :aria-label="t('messageMenu.reactionsAria')">
      <button
        v-for="emoji in quickReactions"
        :key="emoji"
        type="button"
        class="msg-ctx-sheet__reaction-btn"
        @click="onReaction(emoji)"
      >
        {{ emoji }}
      </button>
      <button
        type="button"
        class="msg-ctx-sheet__reaction-btn msg-ctx-sheet__reaction-btn--more"
        :aria-label="t('messageMenu.moreEmojiAria')"
        @click="setEmojiPanelOpen(!emojiPanelOpen)"
      >
        <n-icon aria-hidden="true" :component="EllipsisHorizontalOutline" />
      </button>
    </section>

    <MessageEmojiPickerPanel
      v-if="model.showReactions && emojiPanelOpen"
      @select="onReaction"
      @collapse="setEmojiPanelOpen(false)"
    />

    <section
      v-if="!emojiPanelOpen && showQuickGrid"
      class="msg-ctx-sheet__block msg-ctx-sheet__quick"
      :aria-label="t('messageMenu.quickActionsAria')"
    >
      <button
        v-for="item in model.quickActions"
        :key="item.key"
        type="button"
        class="msg-ctx-sheet__quick-btn"
        :class="{ 'msg-ctx-sheet__quick-btn--danger': item.danger }"
        :disabled="item.disabled"
        @click="onAction(item.key)"
      >
        <span class="msg-ctx-sheet__quick-icon" aria-hidden="true">
          <n-icon aria-hidden="true" v-if="iconFor(item)" :component="iconFor(item)!" />
        </span>
        <span class="msg-ctx-sheet__quick-label">{{ item.label }}</span>
      </button>
    </section>

    <section
      v-if="!emojiPanelOpen && model.listActions.length"
      class="msg-ctx-sheet__block msg-ctx-sheet__list"
      :aria-label="t('messageMenu.moreActionsAria')"
    >
      <button
        v-for="item in model.listActions"
        :key="item.key"
        type="button"
        class="msg-ctx-sheet__list-row"
        :class="{ 'msg-ctx-sheet__list-row--danger': item.danger }"
        :disabled="item.disabled"
        @click="onAction(item.key)"
      >
        <span class="msg-ctx-sheet__list-icon" aria-hidden="true">
          <n-icon aria-hidden="true" v-if="iconFor(item)" :component="iconFor(item)!" />
        </span>
        <span class="msg-ctx-sheet__list-label">{{ item.label }}</span>
      </button>
    </section>
  </div>
</template>
