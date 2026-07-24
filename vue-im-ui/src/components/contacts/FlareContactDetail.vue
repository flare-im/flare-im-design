<script setup lang="ts">
/**
 * Contact profile — hero (avatar / name / presence / star chip), a 3-up action
 * row (message / voice / video), a 资料 settings card (Flare ID / remark /
 * description / favorite toggle), and a danger zone (block / remove). Purely
 * presentational: it renders state from props and emits intents; the host owns
 * the edit sheets and the SDK writes.
 */
import { computed } from "vue";
import { NIcon } from "naive-ui";
import {
  CallOutline,
  ChatbubbleEllipsesOutline,
  VideocamOutline,
} from "../../shared/icon-glyphs";
import FlareAvatar from "../conversation/FlareAvatar.vue";
import FlareSettingsList from "../profile/FlareSettingsList.vue";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import type {
  FlareContact,
  FlareSettingsItem,
  FlareSettingsSection,
} from "../../shared/contracts";

const props = defineProps<{
  contact: FlareContact;
  /** Whether the viewer has starred (favorited) this contact. */
  starred?: boolean;
  /** Free-text description the viewer set for this contact. */
  description?: string;
}>();
const emit = defineEmits<{
  (e: "message"): void;
  (e: "call"): void;
  (e: "video"): void;
  /** Edit the remark (备注). */
  (e: "edit"): void;
  /** Edit the description (描述). */
  (e: "editDescription"): void;
  (e: "toggleStar", value: boolean): void;
  (e: "block"): void;
  (e: "remove"): void;
}>();

const { t } = useFlareI18n();

const avatarStatus = computed<"online" | "offline" | "busy">(() => {
  if (props.contact.presence === "online") return "online";
  if (props.contact.presence === "busy" || props.contact.presence === "away") return "busy";
  return "offline";
});
const presenceLabel = computed(() =>
  props.contact.presence ? t(`contact.${props.contact.presence}`) : "",
);

const sections = computed<FlareSettingsSection[]>(() => [
  {
    title: t("contact.info"),
    items: [
      { key: "flareId", label: t("contact.flareId"), icon: "info", kind: "value", detail: props.contact.id },
      { key: "remark", label: t("contact.remark"), icon: "edit", kind: "value", detail: props.contact.remark || t("contact.notSet") },
      { key: "description", label: t("contact.description"), icon: "comment", kind: "value", detail: props.description || t("contact.notSet") },
      { key: "star", label: t("contact.star"), icon: "star", kind: "toggle", value: props.starred ?? false },
    ],
  },
]);

function onSelect(item: FlareSettingsItem) {
  if (item.key === "remark") emit("edit");
  else if (item.key === "description") emit("editDescription");
}
function onToggle(item: FlareSettingsItem, value: boolean) {
  if (item.key === "star") emit("toggleStar", value);
}
</script>

<template>
  <div class="flare-contact-detail">
    <div class="flare-contact-detail__hero">
      <FlareAvatar
        :user-id="contact.id"
        :display-name="contact.name"
        :avatar-url="contact.avatarUrl"
        :size="76"
        show-status
        :status="avatarStatus"
      />
      <div class="flare-contact-detail__name">{{ contact.name }}</div>
      <div v-if="presenceLabel" class="flare-contact-detail__presence" :class="`is-${contact.presence}`">
        <span class="dot" />{{ presenceLabel }}
      </div>
      <div v-if="contact.signature" class="flare-contact-detail__sig">{{ contact.signature }}</div>
      <span v-if="starred" class="flare-contact-detail__star">★ {{ t("contact.star") }}</span>
    </div>

    <div class="flare-contact-detail__actions">
      <button type="button" class="is-primary" @click="emit('message')">
        <n-icon :size="20" :component="ChatbubbleEllipsesOutline" /><span>{{ t("contact.message") }}</span>
      </button>
      <button type="button" @click="emit('call')">
        <n-icon :size="20" :component="CallOutline" /><span>{{ t("contact.voice") }}</span>
      </button>
      <button type="button" @click="emit('video')">
        <n-icon :size="20" :component="VideocamOutline" /><span>{{ t("contact.video") }}</span>
      </button>
    </div>

    <FlareSettingsList class="flare-contact-detail__card" :sections="sections" @select="onSelect" @toggle="onToggle" />

    <div class="flare-contact-detail__foot">
      <button type="button" @click="emit('block')">{{ t("contact.block") }}</button>
      <button type="button" class="is-danger" @click="emit('remove')">{{ t("contact.remove") }}</button>
    </div>
  </div>
</template>

<style scoped>
.flare-contact-detail { display: flex; flex-direction: column; }
.flare-contact-detail__hero { display: flex; flex-direction: column; align-items: center; gap: 8px; padding: 24px 16px 10px; }
.flare-contact-detail__name { font-size: 20px; font-weight: 700; letter-spacing: -0.01em; color: var(--flare-color-text-primary); }
.flare-contact-detail__presence { display: inline-flex; align-items: center; gap: 6px; font-size: 12px; color: var(--flare-color-text-secondary); }
.flare-contact-detail__presence .dot { width: 7px; height: 7px; border-radius: 50%; background: var(--flare-color-text-tertiary); }
.flare-contact-detail__presence.is-online .dot { background: var(--flare-color-success, #22c55e); }
.flare-contact-detail__presence.is-busy .dot { background: var(--flare-color-error, #ef4444); }
.flare-contact-detail__presence.is-away .dot { background: var(--flare-color-warning, #f59e0b); }
.flare-contact-detail__sig { font-size: 13px; color: var(--flare-color-text-secondary); text-align: center; }
.flare-contact-detail__star {
  padding: 2px 10px; border-radius: 999px; font-size: 12px; font-weight: 600;
  color: var(--flare-color-primary); background: var(--flare-color-bg-selected, color-mix(in srgb, var(--flare-color-primary) 12%, transparent));
}

.flare-contact-detail__actions { display: flex; gap: 10px; padding: 6px 16px 4px; }
.flare-contact-detail__actions button {
  flex: 1; display: flex; flex-direction: column; align-items: center; gap: 6px;
  padding: 12px 4px; border: none; border-radius: var(--flare-size-radius-lg, 14px);
  background: var(--flare-color-bg-primary, #fff); box-shadow: var(--flare-shadow-soft, 0 1px 2px rgba(20, 19, 28, 0.06));
  color: var(--flare-color-text-secondary); font-size: 13px; font-weight: 500; cursor: pointer;
  transition: transform var(--flare-transition-fast, 150ms ease), filter var(--flare-transition-fast, 150ms ease);
}
.flare-contact-detail__actions button:active { transform: scale(0.97); }
.flare-contact-detail__actions button.is-primary {
  color: #fff; background: var(--im-brand-gradient, var(--flare-color-primary));
  box-shadow: 0 8px 20px -8px color-mix(in srgb, var(--flare-color-primary) 60%, transparent);
}

.flare-contact-detail__card { margin-top: 8px; }

.flare-contact-detail__foot { display: flex; flex-direction: column; gap: 10px; padding: 16px; }
.flare-contact-detail__foot button {
  width: 100%; padding: 12px; border-radius: var(--flare-size-radius-lg, 12px);
  border: 1px solid var(--flare-color-border-primary); background: var(--flare-color-bg-primary, #fff);
  color: var(--flare-color-text-primary); font-size: 15px; font-weight: 500; cursor: pointer;
  transition: filter var(--flare-transition-fast, 150ms ease);
}
.flare-contact-detail__foot button:active { filter: brightness(0.97); }
.flare-contact-detail__foot button.is-danger {
  border: none; color: #fff; background: var(--flare-color-error, #ef4444);
}
</style>
