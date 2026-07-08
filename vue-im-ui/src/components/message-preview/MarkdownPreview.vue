<script setup lang="ts">
import { computed } from "vue";
import { countWords, estimateReadingTime, renderMarkdown } from "../../utils/markdown";

const props = withDefaults(
  defineProps<{
    content: string;
    showStats?: boolean;
  }>(),
  { showStats: true },
);

const renderedContent = computed(() => (props.content ? renderMarkdown(props.content) : ""));
const wordCount = computed(() => countWords(props.content));
const readingTime = computed(() => estimateReadingTime(props.content));
</script>

<template>
  <section class="markdown-preview">
    <header v-if="showStats && content" class="markdown-preview__header">
      <span>{{ wordCount }} chars</span>
      <span>~{{ readingTime }} min</span>
    </header>
    <div v-if="content" class="markdown-preview__body" v-html="renderedContent" />
    <p v-else class="markdown-preview__empty">No Markdown content</p>
  </section>
</template>

<style scoped>
.markdown-preview__header {
  display: flex;
  gap: 12px;
  margin-bottom: 10px;
  color: var(--im-text-tertiary);
  font-size: 12px;
}

.markdown-preview__body {
  font-size: 14px;
  line-height: 1.6;
  color: var(--im-text-primary);
  word-break: break-word;
}

.markdown-preview__body :deep(h1),
.markdown-preview__body :deep(h2),
.markdown-preview__body :deep(h3) {
  margin: 0.65em 0 0.38em;
  color: var(--im-text-primary);
  font-weight: 700;
  line-height: 1.25;
}

.markdown-preview__body :deep(h1) {
  font-size: 1.32em;
}

.markdown-preview__body :deep(h2) {
  font-size: 1.18em;
}

.markdown-preview__body :deep(h3) {
  font-size: 1.06em;
}

.markdown-preview__body :deep(p),
.markdown-preview__body :deep(ul),
.markdown-preview__body :deep(ol),
.markdown-preview__body :deep(blockquote),
.markdown-preview__body :deep(pre),
.markdown-preview__body :deep(table) {
  margin: 0.52em 0;
}

.markdown-preview__body :deep(ul),
.markdown-preview__body :deep(ol) {
  padding-left: 1.45em;
}

.markdown-preview__body :deep(li + li) {
  margin-top: 0.18em;
}

.markdown-preview__body :deep(a) {
  color: var(--im-primary, var(--im-brand-primary));
  font-weight: 600;
  text-decoration: none;
  border-bottom: 1px solid color-mix(in srgb, currentColor 32%, transparent);
}

.markdown-preview__body :deep(a:hover) {
  border-bottom-color: currentColor;
}

.markdown-preview__body :deep(blockquote) {
  padding: 6px 10px;
  border-left: 3px solid color-mix(in srgb, var(--im-primary, #7c3aed) 46%, transparent);
  border-radius: 0 7px 7px 0;
  color: var(--im-text-secondary);
  background: color-mix(in srgb, var(--im-primary, #7c3aed) 6%, var(--im-bg-surface-alt, #f4f6fb));
}

.markdown-preview__body :deep(pre) {
  padding: 10px;
  border-radius: 8px;
  background: var(--im-bg-surface-alt);
  overflow-x: auto;
}

.markdown-preview__body :deep(code) {
  padding: 0.1em 0.32em;
  border-radius: 5px;
  color: color-mix(in srgb, var(--im-primary, #7c3aed) 76%, var(--im-text-primary));
  background: color-mix(in srgb, var(--im-primary, #7c3aed) 7%, var(--im-bg-surface-alt, #f4f6fb));
  font-size: 0.92em;
}

.markdown-preview__body :deep(pre code) {
  padding: 0;
  color: inherit;
  background: transparent;
}

.markdown-preview__body :deep(img) {
  display: block;
  max-width: 100%;
  max-height: min(260px, 38dvh);
  margin: 8px 0;
  border: 1px solid color-mix(in srgb, var(--im-border, #d7dce5) 54%, transparent);
  border-radius: 8px;
  object-fit: cover;
}

.markdown-preview__body :deep(table) {
  display: block;
  width: 100%;
  overflow-x: auto;
  border-collapse: collapse;
}

.markdown-preview__body :deep(th),
.markdown-preview__body :deep(td) {
  padding: 5px 7px;
  border: 1px solid color-mix(in srgb, var(--im-border, #d7dce5) 70%, transparent);
}

.markdown-preview__body :deep(th) {
  background: color-mix(in srgb, var(--im-bg-surface-alt, #f4f6fb) 74%, var(--im-bg-surface, #fff));
  font-weight: 700;
}

.markdown-preview__empty {
  color: var(--im-text-tertiary);
  font-size: 13px;
}
</style>
