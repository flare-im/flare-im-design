<script setup lang="ts">
import { computed } from "vue";
import type { ContentElem } from "../../../../utils/contentElem";
import { pickNestedPayload } from "../../../../utils/contentElem";
import { readString } from "../../../../utils/contentData";
import { getContentDecodedPreview } from "../../../../utils/messagePreview";

const props = defineProps<{ content: ContentElem; isSelf: boolean; senderName?: string }>();

const title = computed(() => readString(pickNestedPayload(props.content, "notification"), "title"));
const body = computed(() => {
  const nested = pickNestedPayload(props.content, "notification");
  return readString(nested, "body", "text") || getContentDecodedPreview(props.content);
});
</script>

<template>
  <div class="im-notification">
    <strong v-if="senderName || title">{{ senderName || title }}</strong>
    <span>{{ body }}</span>
  </div>
</template>

<style scoped>
.im-notification {
  text-align: center;
  font-size: 12px;
  color: var(--im-text-tertiary);
}

.im-notification strong {
  display: block;
  margin-bottom: 4px;
  color: var(--im-text-secondary);
}
</style>
