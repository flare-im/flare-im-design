<script setup lang="ts">
import { NIcon } from "naive-ui";
import { CheckmarkOutline } from "../../shared/icon-glyphs";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import type { FlareWallpaperOption } from "../../shared/contracts";

defineProps<{
  options: FlareWallpaperOption[];
  selectedId?: string;
}>();
const emit = defineEmits<{ (e: "select", id: string): void }>();

const { t } = useFlareI18n();
</script>

<template>
  <div class="flare-wallpaper">
    <div class="flare-wallpaper__title">{{ t("wallpaper.title") }}</div>
    <div class="flare-wallpaper__grid">
      <button
        v-for="opt in options"
        :key="opt.id"
        type="button"
        class="flare-wallpaper__swatch"
        :class="{ 'is-selected': opt.id === selectedId }"
        :style="opt.imageUrl ? { backgroundImage: `url(${opt.imageUrl})` } : { background: opt.color || 'var(--flare-color-bg-secondary)' }"
        :aria-label="opt.label || opt.id"
        :aria-pressed="opt.id === selectedId"
        @click="emit('select', opt.id)"
      >
        <span v-if="opt.id === selectedId" class="flare-wallpaper__check">
          <n-icon aria-hidden="true" :size="16" :component="CheckmarkOutline" />
        </span>
      </button>
    </div>
  </div>
</template>

<style scoped>
.flare-wallpaper {
  width: 300px;
  max-width: 100%;
  padding: 14px;
  border-radius: var(--flare-size-radius-xl);
  background: var(--flare-color-bg-primary);
  border: 1px solid var(--flare-color-border-primary);
  box-shadow: var(--flare-shadow-lg);
}
.flare-wallpaper__title {
  font-size: 13px;
  font-weight: 600;
  color: var(--flare-color-text-secondary);
  margin-bottom: 12px;
}
.flare-wallpaper__grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 10px;
}
.flare-wallpaper__swatch {
  position: relative;
  aspect-ratio: 3 / 4;
  border: 2px solid transparent;
  border-radius: var(--flare-size-radius-lg);
  cursor: pointer;
  padding: 0;
  background-size: cover;
  background-position: center;
  box-shadow: inset 0 0 0 1px rgba(17, 19, 24, 0.06);
  transition: border-color var(--flare-transition-fast);
}
.flare-wallpaper__swatch:hover:not(.is-selected) { border-color: var(--flare-color-border-hover); }
.flare-wallpaper__swatch.is-selected { border-color: var(--flare-color-primary); }
.flare-wallpaper__check {
  position: absolute;
  right: 4px;
  bottom: 4px;
  width: 22px;
  height: 22px;
  border-radius: 50%;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  color: #fff;
  background: var(--flare-color-primary);
  box-shadow: 0 2px 6px rgba(21, 18, 32, 0.28);
}
</style>
