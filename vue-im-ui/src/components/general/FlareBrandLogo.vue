<script setup lang="ts">
import { computed, useId } from "vue";

// Flare 品牌 Logo(通用件,归属 kit)。前倾几何 F,取自品牌色阶。
// variant: gradient = 品牌渐变 squircle + 白 F(中性/浅底、app 图标);
//          plate    = 白 squircle + 品牌渐变 F(品牌色背景上,如登录头)。
// 四端共用同一几何(skewX -9°)。Spec: Brand/BrandLogo。
const props = withDefaults(defineProps<{ size?: number; variant?: "gradient" | "plate" }>(), {
  size: 64,
  variant: "gradient",
});

const gradId = `flare-brand-logo-${useId()}`;
const plate = computed(() => props.variant === "plate");
</script>

<template>
  <div
    class="flare-brand-logo"
    :style="{ width: `${size}px`, height: `${size}px` }"
    aria-label="flare IM"
    role="img"
  >
    <svg viewBox="0 0 100 100" width="100%" height="100%" xmlns="http://www.w3.org/2000/svg">
      <defs>
        <linearGradient :id="gradId" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0" stop-color="var(--flare-color-primary-active, #5B21B6)" />
          <stop offset="0.55" stop-color="var(--flare-color-primary, #7C3AED)" />
          <stop offset="1" stop-color="var(--flare-color-info, #6D5DF6)" />
        </linearGradient>
      </defs>
      <path
        d="M50 3 C 12 3 3 12 3 50 C 3 88 12 97 50 97 C 88 97 97 88 97 50 C 97 12 88 3 50 3 Z"
        :fill="plate ? '#ffffff' : `url(#${gradId})`"
      />
      <g transform="translate(50,51) skewX(-9) translate(-50,-51)" :fill="plate ? `url(#${gradId})` : '#ffffff'">
        <rect x="30" y="26" width="14" height="50" rx="7" />
        <rect x="30" y="26" width="39" height="14" rx="7" />
        <rect x="30" y="46" width="30" height="12.5" rx="6.25" />
      </g>
    </svg>
  </div>
</template>

<style scoped>
.flare-brand-logo {
  display: inline-flex;
  border-radius: 28%;
  overflow: visible;
  box-shadow: 0 8px 20px rgba(0, 0, 0, 0.12);
}
</style>
