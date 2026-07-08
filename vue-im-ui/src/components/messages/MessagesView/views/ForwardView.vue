<script setup lang="ts">
import { computed } from "vue";
import { DocumentTextOutline } from "@vicons/ionicons5";
import { NIcon } from "naive-ui";
import type { ContentElem } from "../../../../utils/contentElem";
import { pickNestedPayload } from "../../../../utils/contentElem";
import { asRecord, readArray, readString } from "../../../../utils/contentData";

const props = defineProps<{ content: ContentElem; isSelf: boolean }>();

const payload = computed(() => {
  const nested = pickNestedPayload(props.content, "forward");
  return Object.keys(nested).length ? nested : (props.content as Record<string, unknown>);
});

const title = computed(() => readString(payload.value, "title") || "Forwarded message");
const items = computed(() => readArray(payload.value, "items"));
const summary = computed(() => {
  if (items.value.length > 1) return `${items.value.length} messages`;
  if (items.value.length === 1) {
    const first = asRecord(items.value[0]);
    return readString(first, "plainText", "text") || "1 message";
  }
  return readString(payload.value, "plainText") || "Forwarded content";
});
</script>

<template>
  <div class="im-forward">
    <n-icon :component="DocumentTextOutline" />
    <div>
      <strong>{{ title }}</strong>
      <span>{{ summary }}</span>
    </div>
  </div>
</template>

<style scoped>
.im-forward {
  display: flex;
  align-items: center;
  gap: 10px;
  min-width: var(--im-media-card-min-width);
}

.im-forward span {
  display: block;
  font-size: 12px;
  color: var(--im-text-secondary);
}
</style>
