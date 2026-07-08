<script setup lang="ts">
import { computed } from "vue";
import type { ContentElem } from "../../../../utils/contentElem";
import { pickNestedPayload } from "../../../../utils/contentElem";
import { asRecord, readString } from "../../../../utils/contentData";
import { isMarkdown } from "../../../../utils/markdown";
import MarkdownPreview from "../../../message-preview/MarkdownPreview.vue";
import PlainTextEmojiRich from "../../../shared/PlainTextEmojiRich.vue";

const props = defineProps<{ content: ContentElem; isSelf: boolean }>();

const payload = computed(() => {
  const nested = pickNestedPayload(props.content, "rich_text");
  const nestedRich = asRecord(nested.rich_text ?? nested.richText);
  if (Object.keys(nestedRich).length) return nestedRich;
  return Object.keys(nested).length ? nested : (props.content as Record<string, unknown>);
});

const title = computed(() => readString(payload.value, "title"));
const plainText = computed(() => readString(payload.value, "plainText", "plain_text", "text", "body"));
const sourceAttributes = computed(() =>
  asRecord(
    payload.value.sourcePayload
      ?? payload.value.source_payload
      ?? payload.value.sourceAttributes
      ?? payload.value.source_attributes,
  ),
);
const sourceMarkdown = computed(() => readString(sourceAttributes.value, "markdown", "md"));
const renderText = computed(() => sourceMarkdown.value || plainText.value || title.value);
const useMarkdown = computed(() => Boolean(sourceMarkdown.value) || isMarkdown(renderText.value));
const showBody = computed(() => Boolean(renderText.value));
</script>

<template>
  <div v-if="showBody" class="im-rich-text">
    <MarkdownPreview v-if="useMarkdown" :content="renderText" :show-stats="false" />
    <PlainTextEmojiRich v-else :text="renderText" />
  </div>
</template>

<style scoped>
.im-rich-text {
  color: inherit;
  font-size: 14px;
  line-height: 1.5;
  overflow-wrap: anywhere;
}

.im-rich-text :deep(.markdown-preview) {
  margin: 0;
}

.im-rich-text :deep(.markdown-preview__body) {
  color: inherit;
  font-size: 14px;
  line-height: 1.52;
}

.im-rich-text :deep(.markdown-preview__body > :first-child) {
  margin-top: 0;
}

.im-rich-text :deep(.markdown-preview__body > :last-child) {
  margin-bottom: 0;
}

.im-rich-text :deep(.markdown-preview__body h1),
.im-rich-text :deep(.markdown-preview__body h2),
.im-rich-text :deep(.markdown-preview__body h3),
.im-rich-text :deep(.markdown-preview__body h4),
.im-rich-text :deep(.markdown-preview__body h5),
.im-rich-text :deep(.markdown-preview__body h6) {
  margin: 0.15em 0 0.42em;
  color: inherit;
  font-weight: 750;
  line-height: 1.28;
}

.im-rich-text :deep(.markdown-preview__body h1) {
  font-size: 1.18em;
}

.im-rich-text :deep(.markdown-preview__body h2) {
  font-size: 1.12em;
}

.im-rich-text :deep(.markdown-preview__body h3),
.im-rich-text :deep(.markdown-preview__body h4),
.im-rich-text :deep(.markdown-preview__body h5),
.im-rich-text :deep(.markdown-preview__body h6) {
  font-size: 1.04em;
}

.im-rich-text :deep(.markdown-preview__body p),
.im-rich-text :deep(.markdown-preview__body ul),
.im-rich-text :deep(.markdown-preview__body ol),
.im-rich-text :deep(.markdown-preview__body blockquote),
.im-rich-text :deep(.markdown-preview__body pre) {
  margin: 0.42em 0;
}

.im-rich-text :deep(.markdown-preview__body ul),
.im-rich-text :deep(.markdown-preview__body ol) {
  padding-left: 1.3em;
}

.im-rich-text :deep(.markdown-preview__body a) {
  color: inherit;
  font-weight: 650;
  text-decoration: none;
  border-bottom: 1px solid color-mix(in srgb, currentColor 42%, transparent);
}

.im-rich-text :deep(.markdown-preview__body blockquote) {
  padding: 5px 9px;
  border-left-color: color-mix(in srgb, currentColor 42%, transparent);
  color: color-mix(in srgb, currentColor 82%, transparent);
  background: color-mix(in srgb, currentColor 8%, transparent);
}

.im-rich-text :deep(.markdown-preview__body code) {
  color: inherit;
  background: color-mix(in srgb, currentColor 10%, transparent);
}

.im-rich-text :deep(.markdown-preview__body pre) {
  background: color-mix(in srgb, currentColor 8%, transparent);
}

.im-rich-text :deep(.markdown-preview__body img) {
  margin: 7px 0;
  border-color: color-mix(in srgb, currentColor 18%, transparent);
}
</style>
