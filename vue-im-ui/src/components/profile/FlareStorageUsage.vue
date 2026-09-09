<script setup lang="ts">
// Storage management — the "storage space" section of the settings page.
// The host measures the categories and says which ones it can clear; this
// component only shows the snapshot and dispatches the intent. Clearing is
// irreversible, so the button carries danger colour + icon, but the second
// confirmation is NOT here: the host wraps `clear` in DangerConfirm.
// A category whose size the host has not measured reads "未知", never 0 B.
import { computed } from "vue";
import { NIcon } from "naive-ui";
import {
  AlertCircleOutline,
  CloseOutline,
  DocumentOutline,
  RefreshOutline,
  TrashOutline,
} from "../../shared/icon-glyphs";
import {
  canClearStorage,
  formatBytes,
  storageShare,
  storageTotals,
  type StorageCategory,
} from "../../shared/contracts/storage-usage";

const props = withDefaults(
  defineProps<{
    /** Per-category snapshot; `id` must be stable and is echoed in every event. */
    categories: StorageCategory[];
    /** Host-measured overall footprint; omitted, the component sums what it knows. */
    totalBytes?: number | null;
    /** Free space left on the device, when the host can read it. */
    deviceFreeBytes?: number | null;
    /** First measurement in flight — renders a skeleton, never a fake empty list. */
    loading?: boolean;
    /** Whole-snapshot failure; already-known categories stay on screen. */
    error?: string;
    /** BCP-47 tag threaded through to formatBytes; sizes read the same in every locale. */
    locale?: string;
    title?: string;
    unknownText?: string;
    atLeastText?: string;
    clearText?: string;
    clearingText?: string;
    totalText?: string;
    deviceFreeText?: string;
    reloadText?: string;
    retryText?: string;
    dismissErrorText?: string;
    loadingText?: string;
    emptyText?: string;
    /** `{count}` is replaced with the category's file count. */
    fileCountText?: string;
  }>(),
  {
    totalBytes: null,
    deviceFreeBytes: null,
    loading: false,
    error: "",
    locale: undefined,
    title: "存储空间",
    unknownText: "未知",
    atLeastText: "至少",
    clearText: "清理",
    clearingText: "清理中",
    totalText: "总计",
    deviceFreeText: "可用空间",
    reloadText: "重新统计",
    retryText: "失败重试",
    dismissErrorText: "忽略此错误",
    loadingText: "正在统计存储占用",
    emptyText: "没有可统计的存储分类",
    fileCountText: "{count} 个文件",
  },
);

const emit = defineEmits<{
  (event: "clear", categoryId: string): void;
  (event: "reload"): void;
  /** `null` dismisses the whole-snapshot error; a string dismisses that category's. */
  (event: "dismissError", categoryId: string | null): void;
}>();

const totals = computed(() => storageTotals(props.categories, props.totalBytes));

/** The sum is only a floor when the component computed it and something is unmeasured. */
const totalIsFloor = computed(
  () => totals.value.hasUnknown && !(typeof props.totalBytes === "number" && Number.isFinite(props.totalBytes) && props.totalBytes >= 0),
);

function sizeText(bytes: number | null | undefined): string {
  return formatBytes(bytes, props.locale) ?? props.unknownText;
}
const totalValueText = computed(() => {
  const text = sizeText(totals.value.total);
  return totalIsFloor.value ? `${props.atLeastText} ${text}` : text;
});
const deviceFreeLabel = computed(() => formatBytes(props.deviceFreeBytes, props.locale));

function fileCountLabel(count: number | undefined): string | null {
  if (typeof count !== "number" || !Number.isFinite(count) || count < 0) return null;
  return props.fileCountText.replace("{count}", String(Math.round(count)));
}

const rows = computed(() =>
  props.categories.map((category) => ({
    category,
    size: sizeText(category.bytes),
    share: storageShare(category.bytes, totals.value.total),
    files: fileCountLabel(category.fileCount),
    canClear: canClearStorage(category),
    busy: category.busy === true,
    error: category.error ?? null,
  })),
);

/** Skeleton only stands in for a first measurement — never for a real empty list. */
const showSkeleton = computed(() => props.loading && props.categories.length === 0);
const showEmpty = computed(() => !props.loading && !props.error && props.categories.length === 0);

function clear(id: string, busy: boolean, canClear: boolean): void {
  if (busy || !canClear) return;
  emit("clear", id);
}
</script>

<template>
  <section class="flare-storage" :aria-label="title">
    <header class="flare-storage__head">
      <div class="flare-storage__headline">
        <h3 class="flare-storage__title">{{ title }}</h3>
        <p class="flare-storage__totals">
          <span class="flare-storage__total">{{ totalText }} {{ totalValueText }}</span>
          <span v-if="deviceFreeLabel" class="flare-storage__free">
            · {{ deviceFreeText }} {{ deviceFreeLabel }}
          </span>
        </p>
      </div>
      <button
        type="button"
        class="flare-storage__btn"
        :disabled="loading"
        @click="emit('reload')"
      >
        <n-icon :size="14" :component="RefreshOutline" aria-hidden="true" />
        <span>{{ reloadText }}</span>
      </button>
    </header>

    <p v-if="loading" class="flare-storage__loading" role="status">
      <span class="flare-storage__spinner" aria-hidden="true" />
      <span>{{ loadingText }}</span>
    </p>

    <div v-if="error" class="flare-storage__error flare-storage__error--global" role="alert">
      <n-icon :size="14" :component="AlertCircleOutline" class="flare-storage__error-icon" aria-hidden="true" />
      <span class="flare-storage__error-text">{{ error }}</span>
      <button type="button" class="flare-storage__btn" :disabled="loading" @click="emit('reload')">
        <n-icon :size="14" :component="RefreshOutline" aria-hidden="true" />
        <span>{{ reloadText }}</span>
      </button>
      <button
        type="button"
        class="flare-storage__btn flare-storage__btn--icon"
        :aria-label="dismissErrorText"
        :title="dismissErrorText"
        @click="emit('dismissError', null)"
      >
        <n-icon :size="14" :component="CloseOutline" aria-hidden="true" />
      </button>
    </div>

    <ul v-if="showSkeleton" class="flare-storage__rows" aria-hidden="true">
      <li v-for="n in 3" :key="n" class="flare-storage__row flare-storage__row--skeleton">
        <span class="flare-storage__ghost flare-storage__ghost--label" />
        <span class="flare-storage__ghost flare-storage__ghost--bar" />
      </li>
    </ul>

    <p v-else-if="showEmpty" class="flare-storage__empty" role="status">{{ emptyText }}</p>

    <ul v-else class="flare-storage__rows">
      <li
        v-for="row in rows"
        :key="row.category.id"
        class="flare-storage__row"
        :class="{ 'flare-storage__row--failed': !!row.error }"
        :aria-busy="row.busy || undefined"
      >
        <div class="flare-storage__main">
          <span class="flare-storage__icon" aria-hidden="true">
            <n-icon :size="18" :component="DocumentOutline" />
          </span>
          <div class="flare-storage__text">
            <span class="flare-storage__label">{{ row.category.label }}</span>
            <span class="flare-storage__meta">
              <span class="flare-storage__size">{{ row.size }}</span>
              <span v-if="row.files" class="flare-storage__files">· {{ row.files }}</span>
            </span>
          </div>

          <span v-if="row.busy" class="flare-storage__busy" role="status">
            <span class="flare-storage__spinner" aria-hidden="true" />
            <span>{{ clearingText }}</span>
          </span>
          <button
            v-else-if="row.canClear"
            type="button"
            class="flare-storage__clear"
            :aria-label="`${clearText} ${row.category.label}`"
            @click="clear(row.category.id, row.busy, row.canClear)"
          >
            <n-icon :size="14" :component="TrashOutline" aria-hidden="true" />
            <span>{{ clearText }}</span>
          </button>
        </div>

        <div v-if="row.share !== null" class="flare-storage__bar" aria-hidden="true">
          <span class="flare-storage__bar-fill" :style="{ width: `${Math.round(row.share * 100)}%` }" />
        </div>

        <div v-if="row.error" class="flare-storage__error" role="alert">
          <n-icon :size="14" :component="AlertCircleOutline" class="flare-storage__error-icon" aria-hidden="true" />
          <span class="flare-storage__error-text">{{ row.error }}</span>
          <button
            v-if="row.canClear"
            type="button"
            class="flare-storage__btn"
            :disabled="row.busy"
            @click="clear(row.category.id, row.busy, row.canClear)"
          >
            <n-icon :size="14" :component="RefreshOutline" aria-hidden="true" />
            <span>{{ retryText }}</span>
          </button>
          <button
            type="button"
            class="flare-storage__btn flare-storage__btn--icon"
            :aria-label="dismissErrorText"
            :title="dismissErrorText"
            @click="emit('dismissError', row.category.id)"
          >
            <n-icon :size="14" :component="CloseOutline" aria-hidden="true" />
          </button>
        </div>
      </li>
    </ul>
  </section>
</template>

<style scoped>
.flare-storage {
  display: grid;
  gap: var(--flare-size-spacing-sm, 8px);
  min-width: 0;
  padding: var(--flare-size-spacing-md, 12px);
  border-radius: var(--flare-size-radius-lg, 10px);
  border: 1px solid var(--flare-color-border-primary);
  background: var(--flare-color-bg-primary);
  color: var(--flare-color-text-primary);
}
.flare-storage__head {
  display: flex;
  align-items: flex-start;
  justify-content: space-between;
  gap: var(--flare-size-spacing-sm, 8px);
  flex-wrap: wrap;
}
.flare-storage__headline { display: grid; gap: 2px; min-width: 0; }
.flare-storage__title {
  margin: 0;
  font-size: var(--flare-size-font-size-lg, 14px);
  font-weight: 600;
}
.flare-storage__totals {
  margin: 0;
  font-size: var(--flare-size-font-size-sm, 12px);
  color: var(--flare-color-text-secondary);
  overflow-wrap: anywhere;
}
.flare-storage__total { font-weight: 500; }
.flare-storage__free { color: var(--flare-color-text-tertiary); }
.flare-storage__loading,
.flare-storage__busy {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  margin: 0;
  font-size: var(--flare-size-font-size-sm, 12px);
  color: var(--flare-color-text-tertiary);
  flex: none;
}
.flare-storage__spinner {
  width: 14px;
  height: 14px;
  border-radius: 50%;
  border: 2px solid currentColor;
  border-right-color: transparent;
  animation: flare-storage-spin 0.8s linear infinite;
  flex: none;
}
@keyframes flare-storage-spin { to { transform: rotate(360deg); } }
@media (prefers-reduced-motion: reduce) { .flare-storage__spinner { animation-duration: 2s; } }
.flare-storage__rows {
  list-style: none;
  margin: 0;
  padding: 0;
  display: grid;
  gap: var(--flare-size-spacing-xs, 4px);
}
.flare-storage__row {
  display: grid;
  gap: var(--flare-size-spacing-xs, 4px);
  padding: var(--flare-size-spacing-sm, 8px) 0;
  border-bottom: 1px solid var(--flare-color-border-secondary);
}
.flare-storage__row:last-child { border-bottom: none; }
.flare-storage__main {
  display: flex;
  align-items: center;
  gap: var(--flare-size-spacing-md, 12px);
  min-height: var(--flare-size-layout-touch-target, 48px);
  min-width: 0;
}
.flare-storage__icon {
  display: grid;
  place-items: center;
  width: 32px;
  height: 32px;
  flex: none;
  border-radius: var(--flare-size-radius-full, 999px);
  color: var(--flare-color-primary);
  background: color-mix(in srgb, var(--flare-color-primary) 10%, var(--flare-color-bg-primary));
}
.flare-storage__text { display: grid; gap: 2px; min-width: 0; flex: 1 1 auto; }
.flare-storage__label {
  font-size: var(--flare-size-font-size-lg, 14px);
  font-weight: 500;
  overflow-wrap: anywhere;
}
.flare-storage__meta {
  display: flex;
  gap: 5px;
  flex-wrap: wrap;
  font-size: var(--flare-size-font-size-sm, 12px);
  color: var(--flare-color-text-secondary);
}
.flare-storage__files { color: var(--flare-color-text-tertiary); }
.flare-storage__bar {
  height: 4px;
  border-radius: var(--flare-size-radius-full, 999px);
  background: var(--flare-color-bg-secondary);
  overflow: hidden;
  margin-inline-start: 44px;
}
.flare-storage__bar-fill {
  display: block;
  height: 100%;
  min-width: 2px;
  border-radius: inherit;
  background: var(--flare-color-primary);
}
.flare-storage__empty {
  margin: 0;
  padding: var(--flare-size-spacing-md, 12px) 0;
  font-size: var(--flare-size-font-size-md, 13px);
  color: var(--flare-color-text-secondary);
  text-align: center;
}
.flare-storage__row--skeleton {
  display: grid;
  gap: 6px;
  min-height: var(--flare-size-layout-touch-target, 48px);
  align-content: center;
}
.flare-storage__ghost {
  display: block;
  border-radius: var(--flare-size-radius-sm, 6px);
  background: var(--flare-color-bg-secondary);
  animation: flare-storage-pulse 1.4s ease-in-out infinite;
}
.flare-storage__ghost--label { width: 40%; height: 14px; }
.flare-storage__ghost--bar { width: 100%; height: 8px; }
@keyframes flare-storage-pulse { 50% { opacity: 0.55; } }
@media (prefers-reduced-motion: reduce) { .flare-storage__ghost { animation: none; } }
.flare-storage__clear {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  flex: none;
  min-height: 40px;
  padding: 0 10px;
  border: 1px solid color-mix(in srgb, var(--flare-color-error) 40%, transparent);
  border-radius: var(--flare-size-radius-md, 8px);
  background: color-mix(in srgb, var(--flare-color-error) 8%, var(--flare-color-bg-primary));
  color: var(--flare-color-error);
  font: inherit;
  font-size: var(--flare-size-font-size-md, 13px);
  cursor: pointer;
}
@media (pointer: coarse) {
  .flare-storage__clear { min-height: var(--flare-size-layout-touch-target, 48px); }
}
.flare-storage__clear:focus-visible,
.flare-storage__btn:focus-visible {
  outline: 2px solid var(--flare-color-focus-ring, var(--flare-color-primary));
  outline-offset: 2px;
}
.flare-storage__error {
  display: flex;
  align-items: center;
  gap: 6px;
  flex-wrap: wrap;
  margin-inline-start: 44px;
  padding: 6px 8px;
  border-radius: var(--flare-size-radius-sm, 6px);
  background: color-mix(in srgb, var(--flare-color-error) 8%, var(--flare-color-bg-primary));
}
.flare-storage__error--global { margin-inline-start: 0; }
.flare-storage__error-icon { color: var(--flare-color-error); flex: none; }
.flare-storage__error-text {
  font-size: var(--flare-size-font-size-sm, 12px);
  color: var(--flare-color-error);
  min-width: 0;
  overflow-wrap: anywhere;
  flex: 1 1 auto;
}
.flare-storage__btn {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  min-height: 32px;
  padding: 0 8px;
  border: none;
  border-radius: var(--flare-size-radius-sm, 6px);
  background: var(--flare-color-bg-secondary);
  color: var(--flare-color-text-primary);
  font: inherit;
  font-size: var(--flare-size-font-size-sm, 12px);
  cursor: pointer;
  flex: none;
}
.flare-storage__btn:disabled { opacity: 0.5; cursor: progress; }
.flare-storage__btn--icon { padding: 0 6px; }
</style>
