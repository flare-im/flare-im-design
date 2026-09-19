<script setup lang="ts">
import { computed, ref } from "vue";
import { NQrCode } from "naive-ui";
import { flareDesignTokens } from "@flare-im/tokens";
import FlareAvatar from "../conversation/FlareAvatar.vue";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";

const props = defineProps<{
  name: string;
  subtitle?: string;
  avatarUrl?: string;
  /** Text to encode (profile link, add-friend token). Without it the card says the code is unavailable. */
  qrPayload?: string;
}>();

const { t } = useFlareI18n();

const payload = computed(() => props.qrPayload?.trim() || "");

// Scanners need dark modules on a light ground in every theme, so the code panel
// always paints the light palette's text-primary on bg-primary.
const modulesColor = flareDesignTokens.colors.text.primary;
const panelColor = flareDesignTokens.colors.bg.primary;

// 4-module quiet zone. The code panel fills the card's content width W and its
// percentage padding is a share of that width: p = 4 modules = 4 (W - 2p) / N
// →  p = 4W / (N + 8).
// N (modules per side) comes from the rendered code; before it is known, the
// smallest symbol (21) gives the widest margin.
const code = ref<InstanceType<typeof NQrCode> | null>(null);
const moduleCount = computed(() => code.value?.svgInfo.numCells ?? 21);
const quietZone = computed(() => `${400 / (moduleCount.value + 8)}%`);
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

    <div
      v-if="payload"
      class="flare-qr-card__code"
      role="img"
      :aria-label="t('qr.code', { name })"
      :style="{ padding: quietZone, background: panelColor }"
    >
      <NQrCode
        ref="code"
        class="flare-qr-card__matrix"
        aria-hidden="true"
        type="svg"
        error-correction-level="M"
        :value="payload"
        :size="200"
        :padding="0"
        :color="modulesColor"
        :background-color="panelColor"
      />
    </div>
    <div v-else class="flare-qr-card__frame flare-qr-card__unavailable">{{ t("qr.unavailable") }}</div>

    <div v-if="payload" class="flare-qr-card__hint">{{ t("qr.scanHint") }}</div>
  </div>
</template>

<style scoped>
.flare-qr-card {
  width: 240px;
  max-width: 100%;
  padding: 18px;
  border-radius: var(--flare-size-radius-xl);
  background: var(--flare-color-bg-primary);
  border: 1px solid var(--flare-color-border-primary);
  box-shadow: var(--flare-shadow-lg);
}
.flare-qr-card__head { display: flex; align-items: center; gap: 12px; }
.flare-qr-card__id { min-width: 0; }
.flare-qr-card__name {
  font-size: 16px;
  font-weight: 600;
  color: var(--flare-color-text-primary);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.flare-qr-card__sub {
  margin-top: 2px;
  font-size: 12px;
  color: var(--flare-color-text-tertiary);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.flare-qr-card__code,
.flare-qr-card__frame {
  box-sizing: border-box;
  margin-top: var(--flare-size-spacing-lg);
  border-radius: var(--flare-size-radius-lg);
}
/* Square by construction: a square code plus the same padding on every side. */
.flare-qr-card__code { display: block; }
/* The encoder sizes itself in px (inline style); the card width decides instead. */
.flare-qr-card__matrix {
  display: block;
  width: 100% !important;
  height: auto !important;
  border-radius: 0;
}
.flare-qr-card__matrix :deep(svg) {
  display: block;
  width: 100%;
  height: auto;
}
.flare-qr-card__frame {
  aspect-ratio: 1 / 1;
  display: grid;
  place-items: center;
  padding: var(--flare-size-spacing-lg);
  background: var(--flare-color-bg-secondary);
  border: 1px solid var(--flare-color-border-primary);
}
.flare-qr-card__unavailable {
  text-align: center;
  font-size: var(--flare-size-font-size-md);
  color: var(--flare-color-text-secondary);
}
.flare-qr-card__hint {
  margin-top: 12px;
  text-align: center;
  font-size: 12px;
  color: var(--flare-color-text-tertiary);
}
</style>
