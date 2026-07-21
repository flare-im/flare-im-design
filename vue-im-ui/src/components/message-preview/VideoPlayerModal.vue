<script setup lang="ts">
import { computed, onBeforeUnmount, ref, watch } from "vue";
import { CloseOutline } from "../../shared/icon-glyphs";
import { NIcon } from "naive-ui";

const props = withDefaults(
  defineProps<{
    show: boolean;
    videoSrc: string;
    poster?: string;
    title?: string;
  }>(),
  { poster: "", title: "Video preview" },
);

const emit = defineEmits<{ "update:show": [value: boolean] }>();

const videoRef = ref<HTMLVideoElement | null>(null);

const displayTitle = computed(() => props.title.trim() || "Video preview");

function requestClose(): void {
  emit("update:show", false);
}

function onGlobalKeydown(event: KeyboardEvent): void {
  if (!props.show) return;
  if (event.key === "Escape") {
    event.preventDefault();
    requestClose();
  }
}

watch(
  () => props.show,
  (open) => {
    if (typeof document === "undefined") return;
    if (open) {
      document.addEventListener("keydown", onGlobalKeydown);
      document.body.style.overflow = "hidden";
    } else {
      document.removeEventListener("keydown", onGlobalKeydown);
      document.body.style.overflow = "";
      videoRef.value?.pause();
    }
  },
);

onBeforeUnmount(() => {
  if (typeof document === "undefined") return;
  document.removeEventListener("keydown", onGlobalKeydown);
  document.body.style.overflow = "";
});
</script>

<template>
  <Teleport to="body">
    <div v-if="show" class="video-player-modal" role="dialog" aria-modal="true" @click.self="requestClose">
      <header class="video-player-modal__header">
        <strong class="video-player-modal__title">{{ displayTitle }}</strong>
        <button type="button" class="video-player-modal__close" aria-label="Close" @click="requestClose">
          <n-icon :component="CloseOutline" />
        </button>
      </header>
      <div class="video-player-modal__body" @click.stop>
        <video
          v-if="videoSrc.trim()"
          ref="videoRef"
          class="video-player-modal__video"
          :src="videoSrc"
          :poster="poster || undefined"
          controls
          playsinline
          preload="metadata"
        />
        <div v-else class="video-player-modal__empty">Can't play: missing video URL</div>
      </div>
    </div>
  </Teleport>
</template>

<style scoped>
.video-player-modal {
  position: fixed;
  inset: 0;
  z-index: 10000;
  display: flex;
  flex-direction: column;
  background: rgba(0, 0, 0, 0.88);
  padding: 16px;
  box-sizing: border-box;
}

.video-player-modal__header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  color: #fff;
}

.video-player-modal__title {
  font-size: 15px;
  font-weight: 600;
}

.video-player-modal__close {
  display: grid;
  place-items: center;
  width: 36px;
  height: 36px;
  border: 0;
  border-radius: 8px;
  background: rgba(255, 255, 255, 0.08);
  color: #fff;
  cursor: pointer;
}

.video-player-modal__body {
  flex: 1;
  min-height: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  margin-top: 12px;
}

.video-player-modal__video {
  width: min(100%, 960px);
  max-height: calc(100vh - 96px);
  border-radius: 8px;
  background: #000;
}

.video-player-modal__empty {
  color: rgba(255, 255, 255, 0.9);
  font-size: 14px;
}
</style>
