<script setup lang="ts">
import { computed, getCurrentInstance } from "vue";
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
const instance = getCurrentInstance();
// Message, voice and video appear only when the host handles them, as on FlareContactDetail.
const handles = (listener: "onMessage" | "onCall" | "onVideo"): boolean => Boolean(instance?.vnode.props?.[listener]);
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
    <div v-if="user.flareId || user.region" class="flare-profile-card__meta">
      <span v-if="user.flareId" class="flare-profile-card__flareid">{{ t("contact.flareId") }} · {{ user.flareId }}</span>
      <span v-if="user.flareId && user.region"> · </span>
      <span v-if="user.region">{{ user.region }}</span>
    </div>

    <div v-if="user.tags && user.tags.length" class="flare-profile-card__tags">
      <span v-for="tag in user.tags" :key="tag" class="flare-profile-card__tag">{{ tag }}</span>
    </div>

    <div v-if="handles('onMessage') || handles('onCall') || handles('onVideo')" class="flare-profile-card__actions">
      <button v-if="handles('onMessage')" type="button" class="is-primary" @click="emit('message')">
        <n-icon aria-hidden="true" :size="17" :component="ChatbubbleEllipsesOutline" />{{ t("contact.message") }}
      </button>
      <button v-if="handles('onCall')" type="button" @click="emit('call')" :aria-label="t('contact.voice')">
        <n-icon aria-hidden="true" :size="17" :component="CallOutline" />
      </button>
      <button v-if="handles('onVideo')" type="button" @click="emit('video')" :aria-label="t('contact.video')">
        <n-icon aria-hidden="true" :size="17" :component="VideocamOutline" />
      </button>
    </div>
  </div>
</template>

<style scoped>
.flare-profile-card {
  width: 260px;
  max-width: 100%;
  padding: 16px;
  border-radius: var(--flare-size-radius-xl);
  background: var(--flare-color-bg-primary);
  border: 1px solid var(--flare-color-border-primary);
  box-shadow: var(--flare-shadow-lg);
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
  color: var(--flare-color-text-primary);
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
  color: var(--flare-color-text-secondary);
}
.flare-profile-card__presence .dot {
  width: 6px;
  height: 6px;
  border-radius: 50%;
  background: var(--flare-color-text-tertiary);
}
.flare-profile-card__presence.is-online .dot { background: var(--flare-color-success); }
.flare-profile-card__presence.is-busy .dot { background: var(--flare-color-error); }
.flare-profile-card__presence.is-away .dot { background: var(--flare-color-warning); }
.flare-profile-card__sig {
  margin-top: 12px;
  font-size: 13px;
  color: var(--flare-color-text-secondary);
  line-height: 1.5;
}
.flare-profile-card__meta {
  margin-top: 8px;
  font-size: 12px;
  color: var(--flare-color-text-tertiary);
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
  color: var(--flare-color-primary-text);
  background: var(--flare-color-bg-selected);
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
  border-radius: var(--flare-size-radius-lg);
  background: var(--flare-color-bg-secondary);
  color: var(--flare-color-text-primary);
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  transition: transform var(--flare-transition-fast), filter var(--flare-transition-fast);
}
.flare-profile-card__actions button:not(.is-primary) {
  width: 44px;
  flex: 0 0 auto;
}
.flare-profile-card__actions button.is-primary {
  flex: 1;
  background: var(--flare-component-brand-primary);
  color: #fff;
}
.flare-profile-card__actions button:hover { filter: brightness(0.97); }
.flare-profile-card__actions button:active { transform: scale(0.97); }
</style>
