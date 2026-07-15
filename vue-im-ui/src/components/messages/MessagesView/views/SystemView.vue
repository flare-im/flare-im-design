<script setup lang="ts">
import { computed } from "vue";
import type { ContentElem } from "../../../../utils/contentElem";
import { pickNestedPayload } from "../../../../utils/contentElem";
import { readString } from "../../../../utils/contentData";
import { displayTextFromStoredPreview, getContentDecodedPreview } from "../../../../utils/messagePreview";

const props = defineProps<{
  content: ContentElem;
  isSelf: boolean;
  senderName?: string;
  messageExtra?: Record<string, unknown>;
}>();

const body = computed(() => {
  const nested = pickNestedPayload(props.content, "system");
  const direct = readString(nested, "body", "text");
  if (direct) return direct;
  // Core social system events (friendship_established / group.created / member_joined…) carry their
  // human-readable text only in the message's stored preview token
  // (`{ k: "im.preview.system", a: { fb } }`, exposed as `message.textPreview`), not in the content
  // elem. Resolve it before the generic "系统消息" fallback.
  const raw = props.messageExtra?.textPreview;
  const fromPreview = typeof raw === "string" ? displayTextFromStoredPreview(raw) : "";
  return fromPreview || getContentDecodedPreview(props.content);
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
