<script setup lang="ts">
import FlareAvatar from "../conversation/FlareAvatar.vue";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";

defineProps<{
  userId: string;
  name: string;
  coverUrl?: string;
  avatarUrl?: string;
  signature?: string;
}>();
const emit = defineEmits<{
  (e: "editCover"): void;
  (e: "avatar"): void;
}>();
const { t } = useFlareI18n();
</script>

<template>
  <header class="flare-moments-cover">
    <button
      type="button"
      class="flare-moments-cover__photo"
      :style="coverUrl ? { backgroundImage: `url(${coverUrl})` } : undefined"
      :aria-label="t('moment.editCover')"
      @click="emit('editCover')"
    >
      <span v-if="!coverUrl" class="flare-moments-cover__hint">{{ t("moment.editCover") }}</span>
    </button>

    <div class="flare-moments-cover__id">
      <div class="flare-moments-cover__text">
        <div class="flare-moments-cover__name">{{ name }}</div>
        <div v-if="signature" class="flare-moments-cover__sig">{{ signature }}</div>
      </div>
      <button type="button" class="flare-moments-cover__avatar" @click="emit('avatar')">
        <FlareAvatar :user-id="userId" :display-name="name" :avatar-url="avatarUrl" :size="66" />
      </button>
    </div>
  </header>
</template>

<style scoped>
.flare-moments-cover { position: relative; padding-bottom: 20px; }
.flare-moments-cover__photo {
  display: block;
  width: 100%;
  height: 240px;
  border: none;
  padding: 0;
  cursor: pointer;
  background-color: var(--flare-color-bg-tertiary, #ece9f3);
  /* Aurora: a violet light source rather than a flat gradient. Only shows when
     the user has no cover photo (an inline background-image overrides it). */
  background-image:
    radial-gradient(120% 100% at 12% -10%, rgba(196, 181, 253, 0.6), transparent 55%),
    radial-gradient(90% 90% at 105% 15%, rgba(124, 58, 237, 0.65), transparent 55%),
    linear-gradient(160deg, #3b1f7a 0%, #7c3aed 55%, #a78bfa 100%);
  background-size: cover;
  background-position: center;
  position: relative;
}
/* Bottom scrim so the name + avatar stay legible over any cover image. */
.flare-moments-cover__photo::after {
  content: "";
  position: absolute;
  inset: 0;
  background: linear-gradient(to bottom, transparent 45%, rgba(15, 12, 25, 0.42));
  pointer-events: none;
}
.flare-moments-cover__hint {
  position: absolute;
  z-index: 1;
  right: 14px;
  top: 14px;
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 5px 11px;
  border-radius: 999px;
  background: rgba(15, 12, 25, 0.32);
  backdrop-filter: blur(6px);
  font-size: 12px;
  color: rgba(255, 255, 255, 0.92);
  transition: background 0.15s ease;
}
.flare-moments-cover__hint:hover { background: rgba(15, 12, 25, 0.48); }
/* Name + avatar sit OVER the cover's lower scrim (white text stays legible on
   any cover), with the avatar overhanging the cover's bottom edge. */
.flare-moments-cover__id {
  display: flex;
  align-items: flex-end;
  justify-content: flex-end;
  gap: 14px;
  padding: 0 16px;
  margin-top: -62px;
  position: relative;
  z-index: 1;
}
.flare-moments-cover__text {
  text-align: right;
  padding-bottom: 20px;
  min-width: 0;
}
.flare-moments-cover__name {
  font-size: 18px;
  font-weight: 700;
  color: #fff;
  text-shadow: 0 1px 6px rgba(0, 0, 0, 0.45);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.flare-moments-cover__sig {
  margin-top: 5px;
  font-size: 12.5px;
  color: rgba(255, 255, 255, 0.88);
  text-shadow: 0 1px 4px rgba(0, 0, 0, 0.4);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.flare-moments-cover__avatar {
  flex: 0 0 auto;
  border: 3px solid var(--flare-color-bg-primary, #fff);
  border-radius: 14px;
  padding: 0;
  background: none;
  cursor: pointer;
  overflow: hidden;
  box-shadow: 0 4px 14px rgba(21, 18, 32, 0.2);
  line-height: 0;
}
.flare-moments-cover__avatar :deep(.im-avatar) { border-radius: 11px; }
</style>
