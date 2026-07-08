<script setup lang="ts">
import { computed } from "vue";
import {
  CloudDoneOutline,
  CloudDownloadOutline,
  DocumentTextOutline,
  FolderOpenOutline,
  RefreshOutline,
} from "@vicons/ionicons5";
import { NIcon } from "naive-ui";
import type { Component } from "vue";
import type { ContentElem } from "../../../../utils/contentElem";
import type { MessageMediaDownloadUiState } from "../../MessageBubble.vue";
import { pickNestedPayload } from "../../../../utils/contentElem";
import { formatFileSize, readNumber, readString } from "../../../../utils/contentData";
import { buildMediaResolveRequest, readMediaLocalPath } from "../../../../utils/mediaResolveRequest";
import { useResolvedMediaUrl } from "../../../../composables/useMediaResolver";

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

const payload = computed(() => {
  const nested = pickNestedPayload(props.content, "file");
  return Object.keys(nested).length ? nested : (props.content as Record<string, unknown>);
});

const fileName = computed(() => readString(payload.value, "fileName", "title") || "文件");
const fileSize = computed(() => formatFileSize(readNumber(payload.value, 0, "fileSize", "size")));
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
const fileUrl = computed(() => resolvedFile.url.value);
const hasPrimaryAction = computed(() => Boolean(props.mediaAction));
const resolvedMediaState = computed<MessageMediaDownloadUiState>(() => {
  if (props.mediaState) return props.mediaState;
  if (props.mediaAction === "openFolder") return "openFolder";
  return "idle";
});
const isDownloading = computed(() => resolvedMediaState.value === "downloading");
const isDownloaded = computed(() => resolvedMediaState.value === "downloaded");
const hasTerminalMediaState = computed(
  () =>
    isDownloading.value ||
    isDownloaded.value ||
    resolvedMediaState.value === "openFolder",
);
const primaryActionIcon = computed<Component>(() =>
  resolvedMediaState.value === "openFolder"
    ? FolderOpenOutline
    : isDownloaded.value
      ? CloudDoneOutline
      : isDownloading.value
        ? RefreshOutline
        : CloudDownloadOutline,
);
const primaryActionTitle = computed(() =>
  resolvedMediaState.value === "openFolder"
    ? "在文件夹中显示"
    : isDownloaded.value
      ? "已下载"
      : isDownloading.value
        ? "下载中"
        : "下载文件",
);
const availabilityText = computed(() => {
  if (isDownloading.value) return "下载中";
  if (isDownloaded.value) return "已下载";
  if (resolvedMediaState.value === "openFolder") return "已保存到本机";
  if (fileSize.value) return fileSize.value;
  if (props.mediaAction === "download") return "文件消息";
  if (resolvedFile.loading.value) return "解析下载地址中";
  return fileUrl.value ? "文件消息" : "暂无下载地址";
});

function onPrimaryAction(): void {
  if (!props.mediaAction || isDownloading.value || isDownloaded.value) return;
  emit("media-action", props.mediaAction);
}
</script>

<template>
  <div
    class="im-file"
    :class="{
      'im-file--self': isSelf,
      'im-file--unavailable': !hasPrimaryAction && !fileUrl && !hasTerminalMediaState,
      [`im-file--${resolvedMediaState}`]: true,
    }"
  >
    <span class="im-file__type-icon" aria-hidden="true">
      <n-icon :component="DocumentTextOutline" />
    </span>
    <div class="im-file__main">
      <strong class="im-file__name">{{ fileName }}</strong>
      <span v-if="description" class="im-file__description">{{ description }}</span>
      <span class="im-file__meta">{{ availabilityText }}</span>
    </div>
    <div class="im-file__actions" role="group" aria-label="文件操作">
      <button
        type="button"
        class="im-file__action"
        :class="`im-file__action--${resolvedMediaState}`"
        :disabled="!hasPrimaryAction || isDownloading || isDownloaded"
        :aria-label="primaryActionTitle"
        @click.stop="onPrimaryAction"
      >
        <n-icon :component="primaryActionIcon" />
      </button>
    </div>
    <span
      v-if="isDownloading"
      class="im-file__progress"
      aria-hidden="true"
    >
      <span />
    </span>
  </div>
</template>

<style scoped>
.im-file {
  position: relative;
  display: flex;
  align-items: flex-start;
  gap: 12px;
  min-width: var(--im-media-card-min-width);
  max-width: min(360px, 72vw);
  color: inherit;
}

.im-file--downloading {
  padding-bottom: 8px;
}

.im-file__type-icon {
  display: inline-flex;
  flex: 0 0 42px;
  align-items: center;
  justify-content: center;
  width: 42px;
  height: 42px;
  border: 1px solid color-mix(in srgb, var(--im-brand-primary, #7c3aed) 20%, transparent);
  border-radius: 12px;
  color: var(--im-brand-primary, #7c3aed);
  background: color-mix(in srgb, var(--im-brand-primary, #7c3aed) 12%, var(--im-bg-surface-alt, #f4f6fb));
}

.im-file__type-icon .n-icon {
  font-size: 25px;
}

.im-file--self .im-file__type-icon {
  border-color: rgba(255, 255, 255, 0.26);
  color: rgba(255, 255, 255, 0.94);
  background: rgba(255, 255, 255, 0.15);
}

.im-file__main {
  min-width: 0;
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 3px;
  padding-top: 1px;
}

.im-file__name {
  display: block;
  overflow: hidden;
  color: inherit;
  font-size: 14px;
  font-weight: 700;
  line-height: 1.35;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.im-file__description {
  display: block;
  max-width: 260px;
  overflow: hidden;
  color: var(--im-text-secondary, #667085);
  font-size: 12px;
  line-height: 1.35;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.im-file__meta {
  display: block;
  color: var(--im-text-tertiary, #8a94a6);
  font-size: 12px;
  line-height: 1.35;
}

.im-file--self .im-file__description,
.im-file--self .im-file__meta {
  color: rgba(255, 255, 255, 0.74);
}

.im-file__actions {
  display: inline-flex;
  flex: 0 0 auto;
  align-items: center;
  justify-content: center;
  padding-top: 1px;
}

.im-file__action {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  width: 42px;
  height: 42px;
  padding: 0;
  border: 0;
  border-radius: 12px;
  color: var(--im-brand-primary, #7c3aed);
  background: color-mix(in srgb, var(--im-brand-primary, #7c3aed) 12%, transparent);
  cursor: pointer;
  transition:
    background-color var(--im-motion-fast, 140ms ease),
    color var(--im-motion-fast, 140ms ease),
    opacity var(--im-motion-fast, 140ms ease),
    transform var(--im-motion-fast, 140ms ease);
}

.im-file__action .n-icon {
  font-size: 28px;
}

.im-file__action:hover:not(:disabled),
.im-file__action:focus-visible {
  background: color-mix(in srgb, var(--im-brand-primary, #7c3aed) 18%, transparent);
  transform: translateY(-1px);
  outline: none;
}

.im-file--self .im-file__action {
  color: rgba(255, 255, 255, 0.95);
  background: rgba(255, 255, 255, 0.15);
}

.im-file--self .im-file__action:hover:not(:disabled),
.im-file--self .im-file__action:focus-visible {
  background: rgba(255, 255, 255, 0.24);
}

.im-file__action--downloading .n-icon {
  animation: im-file-download-spin 900ms linear infinite;
}

.im-file__action--downloaded {
  color: #047857;
  background: color-mix(in srgb, #10b981 16%, transparent);
}

.im-file--self .im-file__action--downloaded {
  color: #dcfce7;
  background: rgba(16, 185, 129, 0.24);
}

.im-file__progress {
  position: absolute;
  right: 54px;
  bottom: 0;
  left: 54px;
  height: 3px;
  overflow: hidden;
  border-radius: var(--im-radius-pill, 999px);
  background: color-mix(in srgb, currentColor 16%, transparent);
}

.im-file__progress span {
  display: block;
  width: 38%;
  height: 100%;
  border-radius: inherit;
  background: currentColor;
  animation: im-file-progress-indeterminate 1.1s ease-in-out infinite;
}

.im-file--unavailable {
  color: color-mix(in srgb, currentColor 72%, transparent);
  cursor: default;
}

.im-file__action:disabled {
  cursor: default;
  opacity: 1;
  transform: none;
}

.im-file__action:disabled:not(.im-file__action--downloading):not(.im-file__action--downloaded) {
  opacity: 0.42;
}

@keyframes im-file-download-spin {
  to {
    transform: rotate(360deg);
  }
}

@keyframes im-file-progress-indeterminate {
  0% {
    transform: translateX(-110%);
  }

  50% {
    transform: translateX(85%);
  }

  100% {
    transform: translateX(240%);
  }
}
</style>
