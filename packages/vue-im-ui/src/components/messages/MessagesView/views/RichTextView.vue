<script setup lang="ts">
import { computed } from "vue";
import type { ContentElem } from "../../../../utils/contentElem";
import { pickNestedPayload } from "../../../../utils/contentElem";
import { asRecord, readString } from "../../../../utils/contentData";
import FlareRichTextMessage from "../../standalone/FlareRichTextMessage.vue";

const props = defineProps<{ content: ContentElem; isSelf: boolean }>();

const payload = computed(() => {
  const nested = pickNestedPayload(props.content, "rich_text");
  const nestedRich = asRecord(nested.rich_text ?? nested.richText);
  if (Object.keys(nestedRich).length) return nestedRich;
  return Object.keys(nested).length ? nested : (props.content as Record<string, unknown>);
});

// The document is what the core stores and validates; the sender's Markdown source is not drawn.
const docJson = computed(() => readString(payload.value, "docJson", "doc_json") || null);
const plainText = computed(() => readString(payload.value, "plainText", "plain_text", "text", "body"));
const title = computed(() => readString(payload.value, "title"));
</script>

<template>
  <FlareRichTextMessage :doc-json="docJson" :plain-text="plainText" :title="title" :self="isSelf" selectable />
</template>
