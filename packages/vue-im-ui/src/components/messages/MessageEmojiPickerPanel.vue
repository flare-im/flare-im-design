<script setup lang="ts">
import { ChevronDownOutline } from "../../shared/icon-glyphs";
import { NIcon } from "naive-ui";
import { MESSAGE_EXTENDED_REACTIONS } from "../../shared/constants/messageReactions";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";

const { t } = useFlareI18n();

defineProps<{
  quickReactions?: readonly string[];
  extendedReactions?: readonly string[];
}>();

const emit = defineEmits<{
  (event: "select", emoji: string): void;
  (event: "collapse"): void;
}>();
</script>

<template>
  <section class="msg-ctx-emoji-panel" :aria-label="t('messageEmojiPickerPanel.title')">
    <header class="msg-ctx-emoji-panel__header">
      <h3 class="msg-ctx-emoji-panel__title">{{ t("messageEmojiPickerPanel.title") }}</h3>
      <button type="button" class="msg-ctx-emoji-panel__collapse" @click="emit('collapse')">
        <span>{{ t("messageEmojiPickerPanel.collapse") }}</span>
        <n-icon aria-hidden="true" :component="ChevronDownOutline" />
      </button>
    </header>

    <div class="msg-ctx-emoji-panel__grid" role="listbox">
      <button
        v-for="emoji in extendedReactions ?? MESSAGE_EXTENDED_REACTIONS"
        :key="emoji"
        type="button"
        class="msg-ctx-emoji-panel__cell"
        role="option"
        :aria-label="t('messageEmojiPickerPanel.emojiOption', { emoji })"
        @click="emit('select', emoji)"
      >
        {{ emoji }}
      </button>
    </div>
  </section>
</template>
