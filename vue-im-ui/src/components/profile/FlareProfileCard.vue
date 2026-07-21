<script setup lang="ts">
import { computed } from "vue";
import { NIcon } from "naive-ui";
import { CallOutline, ChatbubbleEllipsesOutline, VideocamOutline } from "../../shared/icon-glyphs";
import FlareAvatar from "../conversation/FlareAvatar.vue";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import type { FlareContact } from "../../shared/contracts";

const props = defineProps<{ user: FlareContact }>();
const emit = defineEmits<{
  (e: "message"): void;
  (e: "call"): void;
  (e: "video"): void;
}>();

const { t } = useFlareI18n();
const avatarStatus = computed<"online" | "offline" | "busy">(() => {
  if (props.user.presence === "online") return "online";
  if (props.user.presence === "busy" || props.user.presence === "away") return "busy";
  return "offline";
});
const presenceLabel = computed(() =>
  props.user.presence ? t(`contact.${props.user.presence}`) : "",
);
</script>

<template>
  <div class="flare-profile-card">
    <div class="flare-profile-card__hero">
      <FlareAvatar
        :user-id="user.id"
        :display-name="user.name"
        :avatar-url="user.avatarUrl"
        :size="56"
        show-status
        :status="avatarStatus"
      />
      <div class="flare-profile-card__id">
        <div class="flare-profile-card__name">{{ user.name }}</div>
        <div v-if="presenceLabel" class="flare-profile-card__presence" :class="`is-${user.presence}`">
          <span class="dot" />{{ presenceLabel }}
        </div>
      </div>
    </div>

    <div v-if="user.signature" class="flare-profile-card__sig">{{ user.signature }}</div>
    <div class="flare-profile-card__meta">
      <span class="flare-profile-card__flareid">{{ t("contact.flareId") }} · {{ user.id }}</span>
      <span v-if="user.region"> · {{ user.region }}</span>
    </div>

    <div v-if="user.tags && user.tags.length" class="flare-profile-card__tags">
      <span v-for="tag in user.tags" :key="tag" class="flare-profile-card__tag">{{ tag }}</span>
    </div>

    <div class="flare-profile-card__actions">
      <button type="button" class="is-primary" @click="emit('message')">
        <n-icon :size="17" :component="ChatbubbleEllipsesOutline" />{{ t("contact.message") }}
      </button>
      <button type="button" @click="emit('call')" :aria-label="t('contact.voice')">
        <n-icon :size="17" :component="CallOutline" />
      </button>
      <button type="button" @click="emit('video')" :aria-label="t('contact.video')">
        <n-icon :size="17" :component="VideocamOutline" />
      </button>
    </div>
  </div>
</template>

<style scoped>
.flare-profile-card {
  width: 260px;
  max-width: 100%;
  padding: 16px;
  border-radius: var(--flare-size-radius-xl, 14px);
  background: var(--flare-color-bg-primary, #fff);
  border: 1px solid var(--flare-color-border-primary, #e9e6f1);
  box-shadow: var(--flare-shadow-lg, 0 12px 28px rgba(21, 18, 32, 0.16));
}
.flare-profile-card__hero {
  display: flex;
  align-items: center;
  gap: 12px;
}
.flare-profile-card__id { min-width: 0; }
.flare-profile-card__name {
  font-size: 16px;
  font-weight: 600;
  color: var(--flare-color-text-primary, #15131c);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.flare-profile-card__presence {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  margin-top: 2px;
  font-size: 12px;
  color: var(--flare-color-text-secondary, #6b6780);
}
.flare-profile-card__presence .dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: var(--flare-color-text-tertiary, #a7a2b4);
}
.flare-profile-card__presence.is-online .dot { background: var(--flare-color-success, #22c55e); }
.flare-profile-card__presence.is-busy .dot { background: var(--flare-color-error, #ef4444); }
.flare-profile-card__presence.is-away .dot { background: var(--flare-color-warning, #f59e0b); }
.flare-profile-card__sig {
  margin-top: 12px;
  font-size: 13px;
  color: var(--flare-color-text-secondary, #6b6780);
  line-height: 1.5;
}
.flare-profile-card__meta {
  margin-top: 8px;
  font-size: 12px;
  color: var(--flare-color-text-tertiary, #a7a2b4);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.flare-profile-card__tags {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  margin-top: 10px;
}
.flare-profile-card__tag {
  padding: 2px 9px;
  border-radius: 999px;
  font-size: 11px;
  color: var(--flare-color-primary, #7c3aed);
  background: var(--flare-color-bg-selected, #f1eaff);
}
.flare-profile-card__actions {
  display: flex;
  gap: 8px;
  margin-top: 16px;
}
.flare-profile-card__actions button {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  height: 38px;
  border: none;
  border-radius: var(--flare-size-radius-lg, 10px);
  background: var(--flare-color-bg-secondary, #f6f5fb);
  color: var(--flare-color-text-primary, #15131c);
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  transition: transform var(--flare-transition-fast, 150ms ease), filter var(--flare-transition-fast, 150ms ease);
}
.flare-profile-card__actions button:not(.is-primary) {
  width: 44px;
  flex: 0 0 auto;
}
.flare-profile-card__actions button.is-primary {
  flex: 1;
  background: var(--im-brand-gradient, var(--flare-color-primary, #7c3aed));
  color: #fff;
}
.flare-profile-card__actions button:hover { filter: brightness(0.97); }
.flare-profile-card__actions button:active { transform: scale(0.97); }
</style>
