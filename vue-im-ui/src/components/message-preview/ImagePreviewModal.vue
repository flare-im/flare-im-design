<template>
  <Teleport to="body">
    <div
      v-if="show"
      class="image-preview-modal"
      role="dialog"
      aria-modal="true"
      @click.self="requestClose"
    >
      <div class="image-preview-modal__toolbar">
        <div class="image-preview-modal__toolbar-left">
          <button
            type="button"
            class="image-preview-modal__icon-btn"
            title="Zoom out"
            aria-label="Zoom out"
            :disabled="!canTransform"
            @click="zoomOut"
          >
            <n-icon :size="20" :component="RemoveOutline" />
          </button>
          <span class="image-preview-modal__zoom-label" aria-live="polite">{{ zoomPercentLabel }}</span>
          <button
            type="button"
            class="image-preview-modal__icon-btn"
            title="Zoom in"
            aria-label="Zoom in"
            :disabled="!canTransform"
            @click="zoomIn"
          >
            <n-icon :size="20" :component="AddOutline" />
          </button>
          <button
            type="button"
            class="image-preview-modal__icon-btn image-preview-modal__icon-btn--text"
            title="Actual size (100%)"
            aria-label="Actual size"
            :disabled="!canTransform"
            @click="actualSize"
          >
            1:1
          </button>
          <button
            type="button"
            class="image-preview-modal__icon-btn"
            title="Reset zoom & rotation"
            aria-label="Reset view"
            :disabled="!canTransform"
            @click="resetView"
          >
            <n-icon :size="20" :component="ContractOutline" />
          </button>
          <button
            type="button"
            class="image-preview-modal__icon-btn"
            title="Rotate 90°"
            aria-label="Rotate"
            :disabled="!canTransform"
            @click="rotateCw"
          >
            <n-icon :size="20" :component="SyncOutline" />
          </button>
        </div>
        <div class="image-preview-modal__toolbar-right">
          <button
            v-if="primaryActionIcon"
            type="button"
            class="image-preview-modal__icon-btn"
            :disabled="primaryActionDisabled"
            :title="primaryActionTitle"
            :aria-label="primaryActionTitle"
            @click="emitPrimary"
          >
            <n-icon :size="22" :component="primaryActionIcon" />
          </button>
          <button type="button" class="image-preview-modal__icon-btn" aria-label="Close" @click="requestClose">
            <span class="image-preview-modal__close-x" aria-hidden="true">×</span>
          </button>
        </div>
      </div>

      <div class="image-preview-modal__body" @click.stop>
        <div v-if="loading" class="image-preview-modal__state">Loading…</div>
        <div v-else-if="!imageSrc.trim()" class="image-preview-modal__state">Can't display image</div>
        <div v-else class="image-preview-modal__stage">
          <div v-if="downloading" class="image-preview-modal__progress" role="status" aria-live="polite">
            <span class="image-preview-modal__progress-label">{{ progressLabel }}</span>
            <div
              class="image-preview-modal__track"
              :class="{ 'is-indeterminate': progressIndeterminate }"
              role="progressbar"
              :aria-valuenow="progressIndeterminate ? undefined : progressPct"
              aria-valuemin="0"
              aria-valuemax="100"
            >
              <div
                class="image-preview-modal__fill"
                :style="progressIndeterminate ? undefined : { width: `${progressPct}%` }"
              />
            </div>
          </div>
          <div
            ref="viewportRef"
            class="image-preview-modal__viewport"
            tabindex="-1"
            @wheel.prevent="onWheel"
          >
            <div class="image-preview-modal__transform" :style="transformStyle">
              <img :src="imageSrc" :alt="alt" draggable="false" class="image-preview-modal__img" />
            </div>
          </div>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup lang="ts">
import { computed, onBeforeUnmount, ref, watch } from 'vue';
import { NIcon } from 'naive-ui';
import type { Component } from 'vue';
import { AddOutline, ContractOutline, RemoveOutline, SyncOutline } from '@vicons/ionicons5';

const ZOOM_STEP = 1.15;

const props = withDefaults(
  defineProps<{
    show: boolean;
    imageSrc: string;
    loading?: boolean;
    alt?: string;
    /** 下载 / 在文件夹中显示 */
    primaryActionIcon?: Component;
    primaryActionTitle?: string;
    primaryActionDisabled?: boolean;
    downloading?: boolean;
    progressLabel?: string;
    progressPct?: number;
    progressIndeterminate?: boolean;
    zoomMin?: number;
    zoomMax?: number;
  }>(),
  {
    loading: false,
    alt: '',
    primaryActionTitle: '',
    primaryActionDisabled: false,
    downloading: false,
    progressLabel: '',
    progressPct: 0,
    progressIndeterminate: false,
    zoomMin: 0.1,
    zoomMax: 8,
  },
);

const emit = defineEmits<{
  'update:show': [value: boolean];
  'primary-action': [];
}>();

const scale = ref(1);
const rotateDeg = ref(0);
const viewportRef = ref<HTMLElement | null>(null);

const canTransform = computed(
  () => props.show && !props.loading && Boolean(props.imageSrc.trim()),
);

const zoomPercentLabel = computed(() => `${Math.round(scale.value * 100)}%`);

const transformStyle = computed(() => ({
  transform: `rotate(${rotateDeg.value}deg) scale(${scale.value})`,
  transformOrigin: 'center center',
}));

function clampScale(v: number): number {
  const lo = props.zoomMin;
  const hi = props.zoomMax;
  return Math.min(hi, Math.max(lo, v));
}

function zoomIn() {
  scale.value = clampScale(scale.value * ZOOM_STEP);
}

function zoomOut() {
  scale.value = clampScale(scale.value / ZOOM_STEP);
}

function actualSize() {
  scale.value = 1;
}

function resetView() {
  scale.value = 1;
  rotateDeg.value = 0;
  viewportRef.value?.scrollTo({ left: 0, top: 0 });
}

function rotateCw() {
  rotateDeg.value = (rotateDeg.value + 90) % 360;
}

function onWheel(e: WheelEvent) {
  if (!canTransform.value) return;
  const delta = e.deltaY;
  if (delta > 0) {
    scale.value = clampScale(scale.value / ZOOM_STEP ** 0.35);
  } else if (delta < 0) {
    scale.value = clampScale(scale.value * ZOOM_STEP ** 0.35);
  }
}

function requestClose() {
  emit('update:show', false);
}

function emitPrimary() {
  emit('primary-action');
}

function onGlobalKeydown(e: KeyboardEvent) {
  if (!props.show) return;
  if (e.key === 'Escape') {
    e.preventDefault();
    requestClose();
    return;
  }
  if (!canTransform.value) return;
  if (e.key === '+' || e.key === '=') {
    e.preventDefault();
    zoomIn();
  } else if (e.key === '-' || e.key === '_') {
    e.preventDefault();
    zoomOut();
  } else   if (e.key === '0' && (e.metaKey || e.ctrlKey)) {
    e.preventDefault();
    actualSize();
  }
}

watch(
  () => props.show,
  (open) => {
    if (typeof document === 'undefined') return;
    if (open) {
      document.addEventListener('keydown', onGlobalKeydown);
      document.body.style.overflow = 'hidden';
    } else {
      document.removeEventListener('keydown', onGlobalKeydown);
      document.body.style.overflow = '';
    }
  },
);

watch(
  () => props.imageSrc,
  () => {
    scale.value = 1;
    rotateDeg.value = 0;
    viewportRef.value?.scrollTo({ left: 0, top: 0 });
  },
);

onBeforeUnmount(() => {
  if (typeof document === 'undefined') return;
  document.removeEventListener('keydown', onGlobalKeydown);
  document.body.style.overflow = '';
});
</script>

<style scoped>
.image-preview-modal {
  position: fixed;
  inset: 0;
  z-index: 10000;
  display: flex;
  flex-direction: column;
  background: rgba(0, 0, 0, 0.85);
  padding: 52px 16px 20px;
  box-sizing: border-box;
}

.image-preview-modal__toolbar {
  position: absolute;
  top: 10px;
  left: 12px;
  right: 12px;
  z-index: 3;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  flex-wrap: wrap;
  pointer-events: none;
}

.image-preview-modal__toolbar-left,
.image-preview-modal__toolbar-right {
  display: flex;
  align-items: center;
  gap: 2px;
  pointer-events: auto;
}

.image-preview-modal__zoom-label {
  min-width: 3rem;
  text-align: center;
  font-size: 13px;
  font-variant-numeric: tabular-nums;
  color: rgba(255, 255, 255, 0.88);
  user-select: none;
}

.image-preview-modal__icon-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  min-width: 36px;
  min-height: 36px;
  padding: 6px;
  border: none;
  border-radius: 8px;
  background: transparent;
  color: rgba(255, 255, 255, 0.92);
  cursor: pointer;
  transition: background 0.15s ease;
}

.image-preview-modal__icon-btn--text {
  font-size: 12px;
  font-weight: 600;
  font-variant-numeric: tabular-nums;
  letter-spacing: 0;
}

.image-preview-modal__icon-btn:hover:not(:disabled) {
  background: rgba(255, 255, 255, 0.12);
}

.image-preview-modal__icon-btn:disabled {
  opacity: 0.35;
  cursor: not-allowed;
}

.image-preview-modal__close-x {
  font-size: 26px;
  line-height: 1;
  font-weight: 300;
}

.image-preview-modal__body {
  flex: 1;
  min-height: 0;
  display: flex;
  align-items: center;
  justify-content: center;
}

.image-preview-modal__state {
  color: rgba(255, 255, 255, 0.9);
  font-size: 14px;
  padding: 24px;
}

.image-preview-modal__stage {
  position: relative;
  width: 100%;
  height: 100%;
  min-height: 0;
  display: flex;
  align-items: center;
  justify-content: center;
}

.image-preview-modal__progress {
  position: absolute;
  top: 8px;
  right: 8px;
  z-index: 2;
  width: min(200px, calc(100% - 24px));
  padding: 8px 10px;
  border-radius: 10px;
  background: rgba(0, 0, 0, 0.55);
  backdrop-filter: blur(6px);
  pointer-events: none;
  box-sizing: border-box;
}

.image-preview-modal__progress-label {
  display: block;
  font-size: 11px;
  line-height: 1.3;
  color: rgba(255, 255, 255, 0.92);
  font-variant-numeric: tabular-nums;
  margin-bottom: 6px;
}

.image-preview-modal__track {
  width: 100%;
  height: 4px;
  border-radius: 2px;
  background: rgba(255, 255, 255, 0.2);
  overflow: hidden;
}

.image-preview-modal__fill {
  height: 100%;
  border-radius: 2px;
  background: rgba(126, 184, 255, 0.95);
  transition: width 0.12s ease-out;
}

.image-preview-modal__track.is-indeterminate .image-preview-modal__fill {
  width: 40% !important;
  animation: image-preview-indeterminate 1s ease-in-out infinite;
}

@keyframes image-preview-indeterminate {
  0% {
    transform: translateX(-100%);
  }
  100% {
    transform: translateX(350%);
  }
}

.image-preview-modal__viewport {
  overflow: auto;
  max-width: 100%;
  max-height: 100%;
  width: 100%;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  outline: none;
}

.image-preview-modal__transform {
  flex-shrink: 0;
}

.image-preview-modal__img {
  display: block;
  max-width: min(100vw - 64px, 100%);
  max-height: calc(100vh - 120px);
  width: auto;
  height: auto;
  object-fit: contain;
  border-radius: 4px;
  vertical-align: top;
  user-select: none;
}
</style>
