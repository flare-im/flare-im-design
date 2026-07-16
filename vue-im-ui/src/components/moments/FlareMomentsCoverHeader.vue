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
        <FlareAvatar :user-id="userId" :display-name="name" :avatar-url="avatarUrl" :size="64" />
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
  background-image: linear-gradient(135deg, #6d5bd0, #b48bf0);
  background-size: cover;
  background-position: center;
  position: relative;
}
.flare-moments-cover__hint {
  position: absolute;
  right: 14px;
  bottom: 40px;
  font-size: 12px;
  color: rgba(255, 255, 255, 0.85);
}
.flare-moments-cover__id {
  display: flex;
  align-items: flex-end;
  justify-content: flex-end;
  gap: 12px;
  padding: 0 16px;
  margin-top: -30px;
  position: relative;
}
.flare-moments-cover__text {
  text-align: right;
  padding-bottom: 6px;
  min-width: 0;
}
.flare-moments-cover__name {
  font-size: 17px;
  font-weight: 700;
  color: #fff;
  text-shadow: 0 1px 4px rgba(0, 0, 0, 0.35);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.flare-moments-cover__sig {
  margin-top: 4px;
  font-size: 12px;
  color: var(--flare-color-text-secondary, #6b6780);
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
