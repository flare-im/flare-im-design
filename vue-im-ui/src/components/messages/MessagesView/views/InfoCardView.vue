<script setup lang="ts">
import { computed } from "vue";
import { TextOutline } from "../../../../shared/icon-glyphs";
import { NIcon } from "naive-ui";
import type { ContentElem } from "../../../../utils/contentElem";
import { pickNestedPayload } from "../../../../utils/contentElem";
import { readString } from "../../../../utils/contentData";
import { getContentDecodedPreview } from "../../../../utils/messagePreview";

const props = defineProps<{
  content: ContentElem;
  isSelf: boolean;
  nestedKey: string;
  fallbackLabel?: string;
}>();

const nested = computed(() => pickNestedPayload(props.content, props.nestedKey));

// `getContentDecodedPreview` already surfaces the meaningful field per type
// (thread → threadTitle, custom → description); a secondary line shows any
// distinct hint/subtitle the payload carries.
const title = computed(
  () => getContentDecodedPreview(props.content) || props.fallbackLabel || props.nestedKey,
);
const subtitle = computed(() => {
  const line = readString(nested.value, "hint", "subtitle", "description", "type");
  return line && line !== title.value ? line : "";
});
</script>

<template>
  <div class="im-rich-message-card im-rich-message-card--compact im-info-card">
    <header class="im-rich-message-card__header">
      <span class="im-rich-message-card__icon" aria-hidden="true">
        <n-icon :component="TextOutline" />
      </span>
      <div class="im-rich-message-card__main">
        <span class="im-rich-message-card__kicker">{{ nestedKey }}</span>
        <strong class="im-rich-message-card__title">{{ title }}</strong>
        <p v-if="subtitle" class="im-rich-message-card__subtitle">{{ subtitle }}</p>
      </div>
    </header>
  </div>
</template>
