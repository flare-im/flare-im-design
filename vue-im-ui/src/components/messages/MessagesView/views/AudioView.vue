<script setup lang="ts">
import { computed, onBeforeUnmount, ref } from "vue";
import { MicOutline, PauseOutline, PlayOutline } from "@vicons/ionicons5";
import { NIcon } from "naive-ui";
import type { ContentElem } from "../../../../utils/contentElem";
import { pickNestedPayload } from "../../../../utils/contentElem";
import { asRecord, readNumber, readString } from "../../../../utils/contentData";
import { buildMediaResolveRequest, readMediaLocalPath } from "../../../../utils/mediaResolveRequest";
import { useResolvedMediaUrl } from "../../../../composables/useMediaResolver";

const props = defineProps<{ content: ContentElem; isSelf: boolean; messageId?: string }>();

const payload = computed(() => {
  const nested = pickNestedPayload(props.content, "audio");
  return Object.keys(nested).length ? nested : (props.content as Record<string, unknown>);
});

const source = computed(() => asRecord(payload.value.source));
const audioRef = ref<HTMLAudioElement | null>(null);
const isPlaying = ref(false);
const currentSeconds = ref(0);
const loadedDurationSeconds = ref(0);
const playbackError = ref(false);

const payloadDurationSeconds = computed(() => {
  const ms = readNumber(payload.value, 0, "durationMs", "duration_ms", "durationMillis", "duration_millis");
  if (ms > 0) return Math.max(1, Math.round(ms / 1000));
  const seconds = readNumber(payload.value, 0, "durationSeconds", "duration_seconds", "duration");
  return seconds > 0 ? Math.max(1, Math.round(seconds)) : 0;
});

const durationSeconds = computed(() => loadedDurationSeconds.value || payloadDurationSeconds.value);
const sourceId = computed(() =>
  readString(
    payload.value,
    "audioId",
    "fileId",
    "mediaId",
    "id",
    "uuid",
  ) || readString(source.value, "audioId", "fileId", "mediaId", "id", "uuid"),
);
const sourceDirectUrl = computed(() =>
  readString(
    payload.value,
    "url",
    "mediaUrl",
    "media_url",
    "downloadUrl",
    "download_url",
    "previewUrl",
    "preview_url",
    "src",
  ) || readString(source.value, "url", "mediaUrl", "media_url", "downloadUrl", "download_url"),
);
const sourceRequest = computed(() =>
  buildMediaResolveRequest({
    kind: "audio",
    messageId: props.messageId,
    url: sourceDirectUrl.value,
    id: sourceId.value,
    localPath: readMediaLocalPath(source.value, payload.value),
    mimeType: readString(source.value, "mimeType") || readString(payload.value, "mimeType"),
    fileName: readString(source.value, "fileName", "name", "title") || readString(payload.value, "fileName", "name", "title"),
  }),
);
const resolvedAudio = useResolvedMediaUrl(sourceRequest);
const audioUrl = computed(() => resolvedAudio.url.value);
const progressPercent = computed(() => {
  if (!durationSeconds.value) return 0;
  return Math.min(100, Math.max(0, (currentSeconds.value / durationSeconds.value) * 100));
});
const playbackLabel = computed(() => {
  if (!durationSeconds.value) return audioUrl.value ? "Voice" : "Voice not playable";
  if (isPlaying.value || currentSeconds.value > 0) {
    return `${formatTime(currentSeconds.value)} / ${formatTime(durationSeconds.value)}`;
  }
  return formatTime(durationSeconds.value);
});

function formatTime(seconds: number): string {
  const safe = Math.max(0, Math.round(seconds));
  const min = Math.floor(safe / 60);
  const sec = safe % 60;
  return `${min}:${sec.toString().padStart(2, "0")}`;
}

async function togglePlay(): Promise<void> {
  const node = audioRef.value;
  if (!node || !audioUrl.value) return;
  playbackError.value = false;
  if (isPlaying.value) {
    node.pause();
    return;
  }
  try {
    await node.play();
  } catch {
    playbackError.value = true;
    isPlaying.value = false;
  }
}

function onLoadedMetadata(): void {
  const duration = audioRef.value?.duration ?? 0;
  loadedDurationSeconds.value = Number.isFinite(duration) ? Math.max(0, duration) : 0;
}

function onTimeUpdate(): void {
  const current = audioRef.value?.currentTime ?? 0;
  currentSeconds.value = Number.isFinite(current) ? current : 0;
}

function onSeek(event: Event): void {
  const node = audioRef.value;
  if (!node || !durationSeconds.value) return;
  const value = Number((event.target as HTMLInputElement).value);
  const next = Math.max(0, Math.min(100, value));
  node.currentTime = (next / 100) * durationSeconds.value;
  currentSeconds.value = node.currentTime;
}

function onEnded(): void {
  isPlaying.value = false;
  currentSeconds.value = 0;
}

onBeforeUnmount(() => {
  audioRef.value?.pause();
});
</script>

<template>
  <div
    class="im-audio"
    :class="{
      'im-audio--playing': isPlaying,
      'im-audio--disabled': !audioUrl,
    }"
  >
    <button
      type="button"
      class="im-audio__play"
      :disabled="!audioUrl"
      :aria-label="isPlaying ? 'Pause' : 'Play'"
      @click="togglePlay"
    >
      <n-icon :component="!audioUrl ? MicOutline : isPlaying ? PauseOutline : PlayOutline" />
    </button>
    <div class="im-audio__body">
      <div class="im-audio__meta">
        <strong>Voice message</strong>
        <span>{{ playbackLabel }}</span>
      </div>
      <div class="im-audio__track" :style="{ '--im-audio-progress': `${progressPercent}%` }">
        <div class="im-audio__wave" aria-hidden="true">
          <span /><span /><span /><span /><span /><span /><span /><span />
        </div>
        <input
          v-if="audioUrl"
          class="im-audio__seek"
          type="range"
          min="0"
          max="100"
          step="1"
          :value="progressPercent"
          aria-label="Voice progress"
          @input="onSeek"
        />
      </div>
      <p v-if="playbackError" class="im-audio__error">Audio can't be played right now</p>
    </div>
    <audio
      v-if="audioUrl"
      ref="audioRef"
      :src="audioUrl"
      preload="metadata"
      class="im-audio__player"
      @loadedmetadata="onLoadedMetadata"
      @timeupdate="onTimeUpdate"
      @play="isPlaying = true"
      @pause="isPlaying = false"
      @ended="onEnded"
      @error="playbackError = true"
    />
  </div>
</template>

<style scoped>
.im-audio {
  display: grid;
  grid-template-columns: 34px minmax(112px, 1fr);
  align-items: center;
  gap: 9px;
  min-width: min(228px, 100%);
  color: inherit;
}

.im-audio__play {
  display: grid;
  place-items: center;
  width: 34px;
  height: 34px;
  padding: 0;
  border: 1px solid color-mix(in srgb, currentColor 18%, transparent);
  border-radius: 999px;
  color: currentColor;
  background: color-mix(in srgb, currentColor 9%, transparent);
  cursor: pointer;
  line-height: 1;
  transition:
    transform var(--im-motion-fast, 140ms ease),
    background var(--im-motion-fast, 140ms ease);
}

.im-audio__play:hover,
.im-audio__play:focus-visible {
  background: color-mix(in srgb, currentColor 14%, transparent);
  outline: none;
}

.im-audio__play:active {
  transform: scale(0.96);
}

.im-audio__play:disabled {
  cursor: not-allowed;
  opacity: 0.6;
}

.im-audio__play .n-icon {
  font-size: 18px;
}

.im-audio__body {
  display: grid;
  gap: 5px;
  min-width: 0;
}

.im-audio__meta {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  gap: 10px;
  min-width: 0;
}

.im-audio__meta strong {
  overflow: hidden;
  color: inherit;
  font-size: 13px;
  font-weight: 700;
  line-height: 1.25;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.im-audio__meta span {
  flex: 0 0 auto;
  color: color-mix(in srgb, currentColor 62%, transparent);
  font-size: 11px;
  font-weight: 700;
}

.im-audio__wave {
  position: relative;
  display: flex;
  gap: 3px;
  align-items: center;
  height: 20px;
  min-width: 0;
  overflow: hidden;
}

.im-audio__wave span {
  width: 3px;
  border-radius: 999px;
  background: currentColor;
  opacity: 0.48;
  transition: opacity var(--im-motion-fast, 140ms ease);
}

.im-audio__wave span:nth-child(1) { height: 8px; }
.im-audio__wave span:nth-child(2) { height: 13px; }
.im-audio__wave span:nth-child(3) { height: 18px; }
.im-audio__wave span:nth-child(4) { height: 11px; }
.im-audio__wave span:nth-child(5) { height: 16px; }
.im-audio__wave span:nth-child(6) { height: 20px; }
.im-audio__wave span:nth-child(7) { height: 12px; }
.im-audio__wave span:nth-child(8) { height: 15px; }

.im-audio--playing .im-audio__wave span {
  opacity: 0.8;
}

.im-audio__track {
  position: relative;
  min-width: 0;
}

.im-audio__track::before {
  position: absolute;
  right: 0;
  bottom: 1px;
  left: 0;
  height: 3px;
  border-radius: 999px;
  background: color-mix(in srgb, currentColor 13%, transparent);
  content: "";
}

.im-audio__track::after {
  position: absolute;
  bottom: 1px;
  left: 0;
  width: var(--im-audio-progress, 0%);
  height: 3px;
  border-radius: 999px;
  background: currentColor;
  content: "";
  opacity: 0.62;
  transition: width 120ms linear;
}

.im-audio__seek {
  position: absolute;
  inset: 0;
  width: 100%;
  opacity: 0;
  cursor: pointer;
}

.im-audio__error {
  margin: 0;
  color: var(--im-danger, var(--flare-color-error, #ef4444));
  font-size: 11px;
  line-height: 1.25;
}

.im-audio__player {
  display: none;
}
</style>
