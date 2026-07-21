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
          <n-icon :size="16" :component="CheckmarkOutline" />
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
  border-radius: var(--flare-size-radius-xl, 14px);
  background: var(--flare-color-bg-primary, #fff);
  border: 1px solid var(--flare-color-border-primary, #e9e6f1);
  box-shadow: var(--flare-shadow-lg, 0 12px 28px rgba(21, 18, 32, 0.16));
}
.flare-wallpaper__title {
  font-size: 13px;
  font-weight: 600;
  color: var(--flare-color-text-secondary, #6b6780);
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
  border-radius: var(--flare-size-radius-lg, 10px);
  cursor: pointer;
  padding: 0;
  background-size: cover;
  background-position: center;
  box-shadow: inset 0 0 0 1px rgba(17, 19, 24, 0.06);
  transition: transform var(--flare-transition-fast, 150ms ease), border-color var(--flare-transition-fast, 150ms ease);
}
.flare-wallpaper__swatch:hover { transform: translateY(-2px); }
.flare-wallpaper__swatch.is-selected { border-color: var(--flare-color-primary, #7c3aed); }
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
  background: var(--flare-color-primary, #7c3aed);
  box-shadow: 0 2px 6px rgba(21, 18, 32, 0.28);
}
</style>
