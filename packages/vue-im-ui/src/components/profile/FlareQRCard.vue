<script setup lang="ts">
import { computed } from "vue";
import FlareAvatar from "../conversation/FlareAvatar.vue";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import FlareQrMatrix from "./FlareQrMatrix.vue";

const props = defineProps<{
  name: string;
  subtitle?: string;
  avatarUrl?: string;
  /** Text to encode (profile link, add-friend token). Without it the card says the code is unavailable. */
  qrPayload?: string;
  hint?: string;
}>();

const { t } = useFlareI18n();

const payload = computed(() => props.qrPayload?.trim() || "");
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

    <FlareQrMatrix
      v-if="payload"
      class="flare-qr-card__code"
      :label="t('qr.code', { name })"
      :payload="payload"
    />
    <div v-else class="flare-qr-card__frame flare-qr-card__unavailable">{{ t("qr.unavailable") }}</div>

    <div v-if="payload" class="flare-qr-card__hint">{{ hint ?? t("qr.scanHint") }}</div>
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
