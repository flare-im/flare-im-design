<script setup lang="ts">
import { computed } from "vue";
import type { ContentElem } from "../../../../utils/contentElem";
import type { MessageMediaDownloadUiState } from "../../MessageBubble.vue";
import { pickNestedPayload } from "../../../../utils/contentElem";
import { formatFileSize, readNumber, readString } from "../../../../utils/contentData";
import { buildMediaResolveRequest, readMediaLocalPath } from "../../../../utils/mediaResolveRequest";
import { useResolvedMediaUrl } from "../../../../composables/useMediaResolver";
import { useFlareI18n } from "../../../../shared/i18n/useFlareI18n";
import FlareFileMessage from "../../standalone/FlareFileMessage.vue";

// Timeline adapter: file payload + the host's download lifecycle → the contract
// body. URL resolution and the media-action wiring stay here; the body only
// renders name / meta / state.
const props = defineProps<{
  content: ContentElem;
  isSelf: boolean;
  messageId?: string;
  mediaAction?: "download" | "openFolder" | null;
  mediaState?: MessageMediaDownloadUiState | null;
}>();

const emit = defineEmits<{
  (event: "media-action", action: "download" | "openFolder"): void;
}>();

const { t } = useFlareI18n();

const payload = computed(() => {
  const nested = pickNestedPayload(props.content, "file");
  return Object.keys(nested).length ? nested : (props.content as Record<string, unknown>);
});

const fileName = computed(() => readString(payload.value, "fileName", "title", "name") || t("mediaMessage.file"));
const fileSize = computed(() => formatFileSize(readNumber(payload.value, 0, "fileSize", "size")));
const fileExt = computed(() => {
  const explicit = readString(payload.value, "ext", "extension");
  if (explicit) return explicit.toUpperCase();
  const match = /\.([a-z0-9]{1,5})$/i.exec(fileName.value);
  return match ? match[1].toUpperCase() : "";
});
const description = computed(() => readString(payload.value, "description"));
const fileRequest = computed(() =>
  buildMediaResolveRequest({
    kind: "file",
    messageId: props.messageId,
    url: readString(payload.value, "url", "localPreviewUrl", "downloadUrl"),
    id: readString(payload.value, "fileId", "id"),
    localPath: readMediaLocalPath(payload.value, payload.value),
    mimeType: readString(payload.value, "mimeType"),
    fileName: fileName.value,
  }),
);
const resolvedFile = useResolvedMediaUrl(fileRequest);

const lifecycle = computed<MessageMediaDownloadUiState>(() => {
  if (props.mediaState) return props.mediaState;
  if (props.mediaAction === "openFolder") return "openFolder";
  return "idle";
});
const state = computed<MessageMediaDownloadUiState | "unavailable">(() => {
  if (lifecycle.value !== "idle") return lifecycle.value;
  if (!props.mediaAction && !resolvedFile.url.value && !resolvedFile.loading.value) return "unavailable";
  return "idle";
});

function onDownload(): void {
  if (!props.mediaAction || state.value === "downloading" || state.value === "downloaded") return;
  emit("media-action", props.mediaAction);
}
// The download affordance exists only when the host resolved a media action.
const downloadListeners = computed(() => (props.mediaAction ? { download: onDownload } : {}));
</script>

<template>
  <div class="im-file" :class="{ 'im-file--self': isSelf }">
    <FlareFileMessage
      embedded
      :name="fileName"
      :size="fileSize"
      :ext="fileExt"
      :description="description"
      :state="state"
      v-on="downloadListeners"
    />
  </div>
</template>

<style scoped>
.im-file {
  display: inline-flex;
  min-width: min(var(--flare-component-media-card-min-width), 100%);
  max-width: min(360px, 72vw);
  color: inherit;
}
</style>
