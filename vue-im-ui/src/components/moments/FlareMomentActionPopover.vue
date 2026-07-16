<script setup lang="ts">
import { NIcon } from "naive-ui";
import { HeartOutline, HeartDislikeOutline, ChatbubbleOutline } from "@vicons/ionicons5";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";

defineProps<{ liked?: boolean }>();
const emit = defineEmits<{
  (e: "like"): void;
  (e: "comment"): void;
}>();
const { t } = useFlareI18n();
</script>

<template>
  <div class="flare-moment-actions" role="menu">
    <button type="button" class="flare-moment-actions__btn" @click="emit('like')">
      <n-icon :size="16" :component="liked ? HeartDislikeOutline : HeartOutline" />
      {{ liked ? t("moment.unlike") : t("moment.like") }}
    </button>
    <span class="flare-moment-actions__divider" />
    <button type="button" class="flare-moment-actions__btn" @click="emit('comment')">
      <n-icon :size="16" :component="ChatbubbleOutline" />
      {{ t("moment.comment") }}
    </button>
  </div>
</template>

<style scoped>
.flare-moment-actions {
  display: inline-flex;
  align-items: stretch;
  height: 34px;
  border-radius: 8px;
  background: #2c2b33;
  box-shadow: 0 6px 18px rgba(21, 18, 32, 0.28);
  overflow: hidden;
}
.flare-moment-actions__btn {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  padding: 0 14px;
  border: none;
  background: transparent;
  color: #f2f0f7;
  font-size: 13px;
  cursor: pointer;
  white-space: nowrap;
  transition: background 0.15s ease;
}
.flare-moment-actions__btn:hover { background: rgba(255, 255, 255, 0.08); }
.flare-moment-actions__divider {
  width: 1px;
  margin: 8px 0;
  background: rgba(255, 255, 255, 0.16);
}
</style>
