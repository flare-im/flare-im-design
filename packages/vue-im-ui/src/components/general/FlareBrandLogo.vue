<script setup lang="ts">
import { computed, useId } from "vue";

// IM 品牌标识（通用件，归属 kit），沿用品牌色阶和圆角底板。
// variant: gradient = 品牌渐变底板 + 白色 IM；plate = 白底板 + 渐变 IM。
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
    aria-label="IM"
    role="img"
  >
    <svg viewBox="0 0 100 100" width="100%" height="100%" xmlns="http://www.w3.org/2000/svg">
      <defs>
        <linearGradient :id="gradId" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0" stop-color="var(--flare-color-primary-active)" />
          <stop offset="0.55" stop-color="var(--flare-color-primary)" />
          <stop offset="1" stop-color="var(--flare-color-info)" />
        </linearGradient>
      </defs>
      <path
        d="M50 3 C 12 3 3 12 3 50 C 3 88 12 97 50 97 C 88 97 97 88 97 50 C 97 12 88 3 50 3 Z"
        :fill="plate ? '#ffffff' : `url(#${gradId})`"
      />
      <g transform="translate(50,51) skewX(-9) translate(-50,-51)" :fill="plate ? `url(#${gradId})` : '#ffffff'">
        <path d="M22 27H32V75H22ZM40 75V27H50L60 48L70 27H80V75H70V48L60 65L50 48V75Z" />
      </g>
    </svg>
  </div>
</template>

<style scoped>
.flare-brand-logo {
  display: inline-flex;
  border-radius: 28%;
  overflow: visible;
  box-shadow: var(--flare-component-brand-logo-shadow);
}
</style>
