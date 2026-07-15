<script setup lang="ts">
import { computed } from "vue";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";

const props = withDefaults(defineProps<{ count?: number }>(), { count: 0 });

const { t } = useFlareI18n();
const label = computed(() =>
  props.count > 0 ? t("timeline.unreadCount", { count: props.count }) : t("timeline.newMessages"),
);
</script>

<template>
  <div class="flare-unread-divider" role="separator" :aria-label="label">
    <span class="flare-unread-divider__line" />
    <span class="flare-unread-divider__label">{{ label }}</span>
    <span class="flare-unread-divider__line" />
  </div>
</template>

<style scoped>
.flare-unread-divider {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 8px 16px;
}
.flare-unread-divider__line {
  flex: 1;
  height: 1px;
  background: color-mix(in srgb, var(--flare-color-primary, #7c3aed) 24%, transparent);
}
.flare-unread-divider__label {
  flex: 0 0 auto;
  font-size: 12px;
  font-weight: 500;
  color: var(--flare-color-primary, #7c3aed);
  letter-spacing: 0.02em;
}
</style>
