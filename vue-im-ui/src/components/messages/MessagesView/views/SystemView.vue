<script setup lang="ts">
import { computed } from "vue";
import type { ContentElem } from "../../../../utils/contentElem";
import { pickNestedPayload } from "../../../../utils/contentElem";
import { readString } from "../../../../utils/contentData";
import { getContentDecodedPreview } from "../../../../utils/messagePreview";

const props = defineProps<{ content: ContentElem; isSelf: boolean; senderName?: string }>();

const body = computed(() => {
  const nested = pickNestedPayload(props.content, "system");
  return readString(nested, "body", "text") || getContentDecodedPreview(props.content);
});
</script>

<template>
  <div class="im-system">{{ body }}</div>
</template>

<style scoped>
.im-system {
  text-align: center;
  font-size: 12px;
  color: var(--im-text-tertiary);
}
</style>
