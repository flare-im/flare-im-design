<script setup lang="ts">
// 全屏播放器是一张模态面 —— 栈、滚动锁、焦点陷阱、Escape 和平台返回键都来自共用的
// `useFlareModalSurface`。以前它自己写 `document.body.style.overflow = ''`,不计数
// 也不还原:开在一张面板之上再关掉,面板还开着,背后的页面却又能滚了。
import { computed, ref, watch } from "vue";
import { CloseOutline } from "../../shared/icon-glyphs";
import { NIcon } from "naive-ui";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import { useFlareModalSurface } from "../../shared/useModalSurface";

const props = withDefaults(
  defineProps<{
    show: boolean;
    videoSrc: string;
    poster?: string;
    title?: string;
  }>(),
  { poster: "" },
);
const { t } = useFlareI18n();
const strings = computed(() => ({
  title: props.title ?? t("videoPlayerModal.title"),
}));

const emit = defineEmits<{ "update:show": [value: boolean] }>();

const videoRef = ref<HTMLVideoElement | null>(null);
const surfaceEl = ref<HTMLElement | null>(null);

const displayTitle = computed(() => strings.value.title.trim() || t("videoPlayerModal.title"));

function requestClose(): void {
  emit("update:show", false);
}

const { overlayContainer } = useFlareModalSurface({
  open: () => props.show,
  surface: surfaceEl,
  onRequestClose: requestClose,
});

// 关掉就停下来:留着继续播,声音会从一个看不见的元素里出来。
watch(() => props.show, (open) => { if (!open) videoRef.value?.pause(); });
</script>

<template>
  <Teleport :to="overlayContainer">
    <div v-if="show" ref="surfaceEl" class="video-player-modal" role="dialog" aria-modal="true" tabindex="-1" @click.self="requestClose">
      <header class="video-player-modal__header">
        <strong class="video-player-modal__title">{{ displayTitle }}</strong>
        <button type="button" class="video-player-modal__close" :aria-label="t('common.close')" @click="requestClose">
          <n-icon aria-hidden="true" :component="CloseOutline" />
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
  z-index: var(--flare-z-index-media);
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
