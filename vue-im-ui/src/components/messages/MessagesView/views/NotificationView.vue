<script setup lang="ts">
import { computed } from "vue";
import type { ContentElem } from "../../../../utils/contentElem";
import { pickNestedPayload } from "../../../../utils/contentElem";
import { asRecord, readString } from "../../../../utils/contentData";
import { getContentDecodedPreview } from "../../../../utils/messagePreview";
import {
  useFlareNotificationResolver,
  type FlareNotificationPayload,
} from "../../../../composables/useNotificationRenderer";

// A host may inject a richer renderer; the dispatcher binds shared view props
// this view doesn't consume, so keep them off the DOM root.
defineOptions({ inheritAttrs: false });

const props = defineProps<{ content: ContentElem; isSelf: boolean; senderName?: string }>();

const nested = computed(() => pickNestedPayload(props.content, "notification"));

const title = computed(() => readString(nested.value, "title"));
const body = computed(
  () => readString(nested.value, "body", "text") || getContentDecodedPreview(props.content),
);

// Normalized payload for host renderers (call-signal tiles, custom cards, …).
const payload = computed<FlareNotificationPayload>(() => {
  const raw = asRecord(nested.value.data ?? (props.content as Record<string, unknown>).data);
  const data: Record<string, string> = {};
  for (const [k, v] of Object.entries(raw)) data[k] = v == null ? "" : String(v);
  return {
    title: title.value,
    body: body.value,
    notificationType: readString(nested.value, "notificationType") || readString(props.content, "notificationType"),
    data,
  };
});

const resolver = useFlareNotificationResolver();
const custom = computed(() => resolver(payload.value));
const hidden = computed(() => custom.value === false);
</script>

<template>
  <component :is="custom" v-if="custom" :payload="payload" />
  <div v-else-if="!hidden" class="im-notification">
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
