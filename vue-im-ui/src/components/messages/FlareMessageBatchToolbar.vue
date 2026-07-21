<script setup lang="ts">
import { computed } from "vue";
import { NIcon } from "naive-ui";
import {
  CheckmarkDoneOutline,
  CloseOutline,
  LibraryOutline,
  ShareSocialOutline,
  TrashOutline,
} from "../../shared/icon-glyphs";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";

const props = defineProps<{
  count: number;
  total: number;
  busy?: boolean;
}>();
const emit = defineEmits<{
  (e: "selectAll"): void;
  (e: "forwardEach"): void;
  (e: "forwardMerged"): void;
  (e: "delete"): void;
  (e: "exit"): void;
}>();

const { t } = useFlareI18n();
const disabled = computed(() => props.busy || props.count === 0);
</script>

<template>
  <div class="flare-batch-toolbar" role="toolbar" :aria-label="t('batch.title')">
    <div class="flare-batch-toolbar__meta">
      <strong>{{ count }}</strong>
      <span>/ {{ total }} · {{ t("batch.selected") }}</span>
    </div>
    <div class="flare-batch-toolbar__actions">
      <button
        type="button"
        class="flare-batch-btn"
        :disabled="busy || total === 0"
        @click="emit('selectAll')"
      >
        <n-icon :size="16" :component="CheckmarkDoneOutline" />
        <span>{{ t("batch.selectAll") }}</span>
      </button>
      <button type="button" class="flare-batch-btn" :disabled="disabled" @click="emit('forwardEach')">
        <n-icon :size="16" :component="ShareSocialOutline" />
        <span>{{ t("batch.forwardEach") }}</span>
      </button>
      <button
        type="button"
        class="flare-batch-btn"
        :disabled="busy || count < 2"
        @click="emit('forwardMerged')"
      >
        <n-icon :size="16" :component="LibraryOutline" />
        <span>{{ t("batch.forwardMerged") }}</span>
      </button>
      <button
        type="button"
        class="flare-batch-btn flare-batch-btn--danger"
        :disabled="disabled"
        @click="emit('delete')"
      >
        <n-icon :size="16" :component="TrashOutline" />
        <span>{{ t("batch.delete") }}</span>
      </button>
      <button
        type="button"
        class="flare-batch-btn flare-batch-btn--icon"
        :disabled="busy"
        :aria-label="t('batch.exit')"
        @click="emit('exit')"
      >
        <n-icon :size="18" :component="CloseOutline" />
      </button>
    </div>
  </div>
</template>

<style scoped>
.flare-batch-toolbar {
  display: flex;
  align-items: center;
  gap: 14px;
  flex-wrap: wrap;
  padding: 10px 14px;
  border-radius: var(--flare-size-radius-lg, 12px);
  background: var(--flare-color-bg-primary, #fff);
  border: 1px solid var(--flare-color-border-primary, #e9e6f1);
  box-shadow: var(--flare-shadow-md, 0 6px 18px rgba(21, 18, 32, 0.1));
}
.flare-batch-toolbar__meta {
  display: inline-flex;
  align-items: baseline;
  gap: 5px;
  font-size: 13px;
  color: var(--flare-color-text-secondary, #6b6780);
}
.flare-batch-toolbar__meta strong {
  font-size: 16px;
  color: var(--flare-color-primary, #7c3aed);
  font-variant-numeric: tabular-nums;
}
.flare-batch-toolbar__actions {
  display: flex;
  align-items: center;
  gap: 6px;
  flex-wrap: wrap;
  margin-left: auto;
}
.flare-batch-btn {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  height: 32px;
  padding: 0 10px;
  border: none;
  border-radius: var(--flare-size-radius-md, 8px);
  background: var(--flare-color-bg-secondary, #f6f5fb);
  color: var(--flare-color-text-primary, #15131c);
  font-size: 13px;
  cursor: pointer;
  transition: filter var(--flare-transition-fast, 150ms ease), transform var(--flare-transition-fast, 150ms ease);
}
.flare-batch-btn:hover:not(:disabled) { filter: brightness(0.97); }
.flare-batch-btn:active:not(:disabled) { transform: scale(0.97); }
.flare-batch-btn:disabled { opacity: 0.45; cursor: not-allowed; }
.flare-batch-btn--danger { color: var(--flare-color-error, #ef4444); }
.flare-batch-btn--icon { padding: 0 8px; }
</style>
