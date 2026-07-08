<script setup lang="ts">
import { computed } from "vue";
import { TextOutline } from "@vicons/ionicons5";
import { NIcon } from "naive-ui";
import type { ContentElem } from "../../../../utils/contentElem";
import { getContentDecodedPreview } from "../../../../utils/messagePreview";

const props = defineProps<{
  content: ContentElem;
  isSelf: boolean;
  nestedKey: string;
  fallbackLabel?: string;
}>();

const preview = computed(() => getContentDecodedPreview(props.content) || props.fallbackLabel || "[Message]");
</script>

<template>
  <div class="im-rich-message-card im-rich-message-card--compact im-info-card">
    <header class="im-rich-message-card__header">
      <span class="im-rich-message-card__icon" aria-hidden="true">
      <n-icon :component="TextOutline" />
      </span>
      <div class="im-rich-message-card__main">
        <span class="im-rich-message-card__kicker">{{ nestedKey }}</span>
        <strong class="im-rich-message-card__title">{{ preview }}</strong>
        <p class="im-rich-message-card__subtitle">{{ content.contentType }}</p>
      </div>
    </header>
    <footer class="im-rich-message-card__footer">
      <span>{{ nestedKey }}</span>
      <span>Message card</span>
    </footer>
  </div>
</template>
