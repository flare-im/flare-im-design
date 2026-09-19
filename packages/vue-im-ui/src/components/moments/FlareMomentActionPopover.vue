<script setup lang="ts">
import { NIcon } from "naive-ui";
import { HeartOutline, HeartDislikeOutline, ChatbubbleOutline, TrashOutline } from "../../shared/icon-glyphs";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";

defineProps<{ liked?: boolean; canDelete?: boolean }>();
const emit = defineEmits<{
  (e: "like"): void;
  (e: "comment"): void;
  (e: "delete"): void;
}>();
const { t } = useFlareI18n();
</script>

<template>
  <div class="flare-moment-actions" role="group">
    <button type="button" class="flare-moment-actions__btn" @click="emit('like')">
      <n-icon aria-hidden="true" :size="16" :component="liked ? HeartDislikeOutline : HeartOutline" />
      {{ liked ? t("moment.unlike") : t("moment.like") }}
    </button>
    <span class="flare-moment-actions__divider" />
    <button type="button" class="flare-moment-actions__btn" @click="emit('comment')">
      <n-icon aria-hidden="true" :size="16" :component="ChatbubbleOutline" />
      {{ t("moment.comment") }}
    </button>
    <template v-if="canDelete">
      <span class="flare-moment-actions__divider" />
      <button type="button" class="flare-moment-actions__btn is-danger" @click="emit('delete')">
        <n-icon aria-hidden="true" :size="16" :component="TrashOutline" />
        {{ t("moment.delete") }}
      </button>
    </template>
  </div>
</template>

<style scoped>
.flare-moment-actions {
  display: inline-flex;
  align-items: stretch;
  box-sizing: border-box;
  min-height: 36px;
  border: 1px solid var(--flare-color-border-secondary);
  border-radius: var(--flare-size-radius-md);
  background: var(--flare-color-bg-primary);
  box-shadow: var(--flare-shadow-md);
  overflow: hidden;
}
/*
 * Neither `min-width: 0` here nor `max-width: 100%` on the root, and both absences are the fix for
 * FR-164. Two or three short actions with labels that do not wrap have exactly one sensible width —
 * the one their text needs. Told to be narrower, this popover could only lie about it: the
 * max-width clipped 删除 against the root's `overflow: hidden`, and the min-width let the buttons
 * shrink past their own text until 赞 and 评论 were drawn on top of each other. So it takes its
 * width from its content and overhangs a container too small for it, which a host can see and
 * place around; a host that cannot spare the room wants a sheet, not a popover.
 */
.flare-moment-actions__btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: var(--flare-size-spacing-xs);
  padding: 6px 12px;
  border: none;
  background: transparent;
  color: var(--flare-color-text-primary);
  font: inherit;
  font-size: var(--flare-size-font-size-sm);
  cursor: pointer;
  white-space: nowrap;
  transition: background 0.15s ease;
}
.flare-moment-actions__btn:hover { background: var(--flare-color-bg-hover); }
.flare-moment-actions__btn:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: -3px; }
.flare-moment-actions__btn:first-child { border-start-start-radius: inherit; border-end-start-radius: inherit; }
.flare-moment-actions__btn:last-child { border-start-end-radius: inherit; border-end-end-radius: inherit; }
.flare-moment-actions__btn.is-danger { color: var(--flare-color-error-text); }
.flare-moment-actions__btn.is-danger:hover { background: color-mix(in srgb, var(--flare-color-error) 10%, transparent); }
.flare-moment-actions__divider {
  width: 1px;
  flex-shrink: 0;
  margin: 8px 0;
  background: var(--flare-color-border-secondary);
}
@media (pointer: coarse) {
  .flare-moment-actions__btn { min-width: 44px; min-height: 44px; }
}
</style>
