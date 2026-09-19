<script setup lang="ts">
import { computed } from "vue";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
// Reply strip — a composable composer part shown above the input when replying
// (or, with `tone="edit"`, while editing a sent message). Left rail + label/sender
// + summary + cancel. Labels default to the strings provider.
const props = withDefaults(
  defineProps<{ senderName: string; summary: string; label?: string; cancelLabel?: string; tone?: "default" | "warn" | "edit" }>(),
  { tone: "default" },
);
const { t } = useFlareI18n();
const strings = computed(() => ({
  label: props.label ?? t("composerReplyStrip.label"),
  cancelLabel: props.cancelLabel ?? t("composerReplyStrip.cancel"),
}));
const emit = defineEmits<{ (e: "cancel"): void }>();
</script>

<template>
  <div class="flare-reply" :class="`flare-reply--${tone}`">
    <div class="body">
      <div class="who">{{ strings.label }} {{ senderName }}</div>
      <div class="sum">{{ summary }}</div>
    </div>
    <button type="button" class="x" :aria-label="strings.cancelLabel" :title="strings.cancelLabel" @click="emit('cancel')">
      <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="currentColor"
        stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
        <path d="M6 6l12 12M18 6L6 18" />
      </svg>
    </button>
  </div>
</template>

<style scoped>
.flare-reply {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 6px 8px;
  border-radius: var(--flare-size-radius-md);
  background: var(--flare-color-message-reply-background);
  border-left: 3px solid var(--flare-color-message-reply-border);
}
.body { flex: 1; min-width: 0; }
/* 回复条上的发信人用“文字版”品牌色：边框色 #8B5CF6 当文字只有 3.98:1。 */
.who { font-size: 11px; line-height: 16px; font-weight: 600; color: var(--flare-color-primary-text); }
.sum {
  font-size: 12px;
  line-height: 18px;
  color: var(--flare-color-text-secondary);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.flare-reply--warn { border-left-color: var(--flare-color-warning); background: color-mix(in srgb, var(--flare-color-warning) 8%, var(--flare-color-bg-primary)); }
.flare-reply--warn .who,
.flare-reply--edit .who { color: var(--flare-color-warning-text); }
.flare-reply--edit { border-left-color: var(--flare-color-warning); background: color-mix(in srgb, var(--flare-color-warning) 6%, var(--flare-color-bg-primary)); }
.x {
  flex: none;
  display: grid;
  place-items: center;
  width: var(--flare-size-layout-touch-target, 48px);
  height: var(--flare-size-layout-touch-target, 48px);
  margin: -8px -8px -8px 0;
  border: none;
  border-radius: var(--flare-size-radius-sm);
  background: none;
  padding: 0;
  color: var(--flare-color-text-tertiary);
  cursor: pointer;
}
.x:hover { color: var(--flare-color-text-primary); background: var(--flare-color-bg-hover); }
.x:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: -2px; }
</style>
