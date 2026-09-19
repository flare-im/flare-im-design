<script setup lang="ts">
import { computed } from "vue";
import type { ContentElem } from "../../../../utils/contentElem";
import { textBodyFromContent } from "../../../../utils/contentElem";
import { textMentionSpans } from "../../../../utils/textMentions";
import FlareTextMessage from "../../standalone/FlareTextMessage.vue";

const props = defineProps<{ content: ContentElem; isSelf: boolean; messageExtra?: Record<string, unknown> }>();
const text = computed(() => textBodyFromContent(props.content));
const mentions = computed(() =>
  textMentionSpans(props.content, text.value, String(props.messageExtra?.currentUserId ?? "")),
);
</script>

<template>
  <FlareTextMessage :text="text" :self="isSelf" :mentions="mentions" selectable />
</template>
