<script setup lang="ts">
import { ChevronDownOutline } from "@vicons/ionicons5";
import { NIcon } from "naive-ui";
import { MESSAGE_EXTENDED_REACTIONS } from "../../shared/constants/messageReactions";

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
  <section class="msg-ctx-emoji-panel" aria-label="Choose emoji">
    <header class="msg-ctx-emoji-panel__header">
      <h3 class="msg-ctx-emoji-panel__title">Choose emoji</h3>
      <button type="button" class="msg-ctx-emoji-panel__collapse" @click="emit('collapse')">
        <span>Collapse</span>
        <n-icon :component="ChevronDownOutline" />
      </button>
    </header>

    <div class="msg-ctx-emoji-panel__grid" role="listbox">
      <button
        v-for="emoji in extendedReactions ?? MESSAGE_EXTENDED_REACTIONS"
        :key="emoji"
        type="button"
        class="msg-ctx-emoji-panel__cell"
        role="option"
        :aria-label="`Emoji ${emoji}`"
        @click="emit('select', emoji)"
      >
        {{ emoji }}
      </button>
    </div>
  </section>
</template>
