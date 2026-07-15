<script setup lang="ts">
import { computed } from "vue";
import FlareAvatar from "../conversation/FlareAvatar.vue";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";

const props = defineProps<{
  name: string;
  subtitle?: string;
  avatarUrl?: string;
  /** Data/URL of the actual QR bitmap. When absent, a decorative frame is shown. */
  qrImageUrl?: string;
}>();

const { t } = useFlareI18n();

/** Deterministic decorative matrix (NOT a scannable code) keyed off the name. */
const dots = computed(() => {
  const n = 11;
  const seed = [...props.name].reduce((a, c) => a + c.charCodeAt(0), 7);
  const cells: { x: number; y: number }[] = [];
  for (let y = 0; y < n; y++) {
    for (let x = 0; x < n; x++) {
      // leave the three finder corners clear
      const corner =
        (x < 3 && y < 3) || (x > n - 4 && y < 3) || (x < 3 && y > n - 4);
      if (corner) continue;
      if (((x * 31 + y * 17 + seed) % 5) === 0) cells.push({ x, y });
    }
  }
  return { n, cells };
});
</script>

<template>
  <div class="flare-qr-card">
    <div class="flare-qr-card__head">
      <FlareAvatar :user-id="name" :display-name="name" :avatar-url="avatarUrl" :size="44" />
      <div class="flare-qr-card__id">
        <div class="flare-qr-card__name">{{ name }}</div>
        <div v-if="subtitle" class="flare-qr-card__sub">{{ subtitle }}</div>
      </div>
    </div>

    <div class="flare-qr-card__frame">
      <img v-if="qrImageUrl" :src="qrImageUrl" alt="" class="flare-qr-card__img" />
      <svg
        v-else
        class="flare-qr-card__svg"
        :viewBox="`0 0 ${dots.n} ${dots.n}`"
        role="img"
        :aria-label="t('qr.decorative')"
      >
        <g fill="currentColor">
          <rect
            v-for="(c, i) in dots.cells"
            :key="i"
            :x="c.x + 0.12"
            :y="c.y + 0.12"
            width="0.76"
            height="0.76"
            rx="0.16"
          />
        </g>
        <g fill="none" stroke="currentColor" stroke-width="0.6">
          <rect x="0.3" y="0.3" width="2.4" height="2.4" rx="0.5" />
          <rect :x="dots.n - 2.7" y="0.3" width="2.4" height="2.4" rx="0.5" />
          <rect x="0.3" :y="dots.n - 2.7" width="2.4" height="2.4" rx="0.5" />
        </g>
        <g fill="currentColor">
          <rect x="1.1" y="1.1" width="0.8" height="0.8" rx="0.2" />
          <rect :x="dots.n - 1.9" y="1.1" width="0.8" height="0.8" rx="0.2" />
          <rect x="1.1" :y="dots.n - 1.9" width="0.8" height="0.8" rx="0.2" />
        </g>
      </svg>
    </div>

    <div class="flare-qr-card__hint">{{ t("qr.scanHint") }}</div>
  </div>
</template>

<style scoped>
.flare-qr-card {
  width: 240px;
  max-width: 100%;
  padding: 18px;
  border-radius: var(--flare-size-radius-xl, 16px);
  background: var(--flare-color-bg-primary, #fff);
  border: 1px solid var(--flare-color-border-primary, #e9e6f1);
  box-shadow: var(--flare-shadow-lg, 0 12px 28px rgba(21, 18, 32, 0.16));
}
.flare-qr-card__head { display: flex; align-items: center; gap: 12px; }
.flare-qr-card__id { min-width: 0; }
.flare-qr-card__name {
  font-size: 16px;
  font-weight: 600;
  color: var(--flare-color-text-primary, #15131c);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.flare-qr-card__sub {
  margin-top: 2px;
  font-size: 12px;
  color: var(--flare-color-text-tertiary, #a7a2b4);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.flare-qr-card__frame {
  margin-top: 16px;
  aspect-ratio: 1 / 1;
  display: grid;
  place-items: center;
  padding: 14px;
  border-radius: var(--flare-size-radius-lg, 12px);
  background: var(--flare-color-bg-secondary, #f6f5fb);
  border: 1px solid var(--flare-color-border-primary, #e9e6f1);
}
.flare-qr-card__img { width: 100%; height: 100%; object-fit: contain; }
.flare-qr-card__svg { width: 100%; height: 100%; color: var(--flare-color-text-primary, #15131c); }
.flare-qr-card__hint {
  margin-top: 12px;
  text-align: center;
  font-size: 12px;
  color: var(--flare-color-text-tertiary, #a7a2b4);
}
</style>
