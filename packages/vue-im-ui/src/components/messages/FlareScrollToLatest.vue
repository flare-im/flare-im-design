<script setup lang="ts">
import { computed } from "vue";
import { NIcon } from "naive-ui";
import { ArrowDownOutline } from "../../shared/icon-glyphs";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";

const props = withDefaults(defineProps<{ count?: number }>(), { count: 0 });
defineEmits<{ (e: "click"): void }>();

const { t } = useFlareI18nOptional();
const badge = computed(() => (props.count > 99 ? "99+" : String(props.count)));
</script>

<template>
  <button
    type="button"
    class="flare-scroll-latest"
    :class="{ 'has-count': count > 0 }"
    :aria-label="count > 0 ? t('timeline.unreadCount', { count }) : t('timeline.backToLatest')"
    @click="$emit('click')"
  >
    <span v-if="count > 0" class="flare-scroll-latest__count">{{ badge }}</span>
    <span class="flare-scroll-latest__icon"><n-icon aria-hidden="true" :size="20" :component="ArrowDownOutline" /></span>
  </button>
</template>

<style scoped>
.flare-scroll-latest {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 6px 6px 6px 12px;
  border: 1px solid var(--flare-color-border-primary);
  border-radius: 999px;
  background: var(--flare-color-bg-primary);
  box-shadow: var(--flare-shadow-md);
  color: var(--flare-color-text-secondary);
  cursor: pointer;
  transition:
    transform var(--flare-transition-fast),
    box-shadow var(--flare-transition-fast);
}
.flare-scroll-latest:not(.has-count) {
  padding: 8px;
}
.flare-scroll-latest:hover {
  box-shadow: var(--flare-shadow-lg);
}
.flare-scroll-latest:active {
  transform: translateY(0) scale(0.96);
}
.flare-scroll-latest__count {
  font-size: 13px;
  font-weight: 600;
  color: var(--flare-color-primary-text);
}
.flare-scroll-latest__icon {
  display: grid;
  place-items: center;
  width: 30px;
  height: 30px;
  border-radius: 50%;
  color: #fff;
  background: var(--flare-component-brand-primary);
}
</style>
