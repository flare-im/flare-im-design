<script setup lang="ts">
import { computed } from "vue";
import { NIcon } from "naive-ui";
import {
  BanOutline,
  CallOutline,
  ChatbubbleEllipsesOutline,
  CreateOutline,
  TrashOutline,
  VideocamOutline,
} from "../../shared/icon-glyphs";
import FlareAvatar from "../conversation/FlareAvatar.vue";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import type { FlareContact } from "../../shared/contracts";

const props = defineProps<{ contact: FlareContact }>();
const emit = defineEmits<{
  (e: "message"): void;
  (e: "call"): void;
  (e: "video"): void;
  (e: "edit"): void;
  (e: "remove"): void;
  (e: "block"): void;
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

const infoRows = computed(() =>
  [
    { key: "flareId", label: t("contact.flareId"), value: props.contact.id },
    { key: "remark", label: t("contact.remark"), value: props.contact.remark },
    { key: "region", label: t("contact.region"), value: props.contact.region },
    { key: "phone", label: t("contact.phone"), value: props.contact.phone },
  ].filter((r) => r.value),
);
</script>

<template>
  <div class="flare-contact-detail">
    <FlareAvatar
      :user-id="contact.id"
      :display-name="contact.name"
      :avatar-url="contact.avatarUrl"
      :size="88"
      show-status
      :status="avatarStatus"
    />
    <div class="flare-contact-detail__name">{{ contact.name }}</div>
    <div v-if="presenceLabel" class="flare-contact-detail__presence" :class="`is-${contact.presence}`">
      <span class="dot" />{{ presenceLabel }}
    </div>
    <div v-if="contact.signature" class="flare-contact-detail__sig">{{ contact.signature }}</div>

    <div v-if="contact.tags && contact.tags.length" class="flare-contact-detail__tags">
      <span v-for="tag in contact.tags" :key="tag" class="flare-contact-detail__tag">{{ tag }}</span>
    </div>

    <div class="flare-contact-detail__actions">
      <button type="button" class="is-primary" @click="emit('message')">
        <n-icon :size="18" :component="ChatbubbleEllipsesOutline" />{{ t("contact.message") }}
      </button>
      <button type="button" @click="emit('call')">
        <n-icon :size="18" :component="CallOutline" />{{ t("contact.voice") }}
      </button>
      <button type="button" @click="emit('video')">
        <n-icon :size="18" :component="VideocamOutline" />{{ t("contact.video") }}
      </button>
    </div>

    <div v-if="infoRows.length" class="flare-contact-detail__card">
      <div v-for="row in infoRows" :key="row.key" class="flare-contact-detail__row">
        <span class="flare-contact-detail__row-label">{{ row.label }}</span>
        <span class="flare-contact-detail__row-value">{{ row.value }}</span>
      </div>
    </div>

    <div class="flare-contact-detail__secondary">
      <button type="button" @click="emit('edit')">
        <n-icon :size="16" :component="CreateOutline" />{{ t("contact.edit") }}
      </button>
      <button type="button" @click="emit('block')">
        <n-icon :size="16" :component="BanOutline" />{{ t("contact.block") }}
      </button>
      <button type="button" class="is-danger" @click="emit('remove')">
        <n-icon :size="16" :component="TrashOutline" />{{ t("contact.remove") }}
      </button>
    </div>
  </div>
</template>

<style scoped>
.flare-contact-detail {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
  padding: 28px 16px;
}
.flare-contact-detail__name {
  font-size: 20px;
  font-weight: 600;
  color: var(--flare-color-text-primary);
  margin-top: 10px;
}
.flare-contact-detail__presence {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  font-size: 12px;
  color: var(--flare-color-text-secondary);
}
.flare-contact-detail__presence .dot {
  width: 7px;
  height: 7px;
  border-radius: 50%;
  background: var(--flare-color-text-tertiary);
}
.flare-contact-detail__presence.is-online .dot { background: var(--flare-color-success, #22c55e); }
.flare-contact-detail__presence.is-busy .dot { background: var(--flare-color-error, #ef4444); }
.flare-contact-detail__presence.is-away .dot { background: var(--flare-color-warning, #f59e0b); }
.flare-contact-detail__sig {
  font-size: 14px;
  color: var(--flare-color-text-tertiary);
  text-align: center;
}
.flare-contact-detail__tags {
  display: flex;
  flex-wrap: wrap;
  justify-content: center;
  gap: 6px;
  margin-top: 2px;
}
.flare-contact-detail__tag {
  padding: 3px 10px;
  border-radius: 999px;
  font-size: 12px;
  color: var(--flare-color-primary);
  background: var(--flare-color-bg-selected, #f1eaff);
}
.flare-contact-detail__actions {
  display: flex;
  gap: 10px;
  margin-top: 20px;
  width: 100%;
}
.flare-contact-detail__actions button {
  flex: 1;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  padding: 10px;
  border-radius: var(--flare-size-radius-lg, 10px);
  border: none;
  background: var(--flare-color-bg-secondary);
  color: var(--flare-color-text-primary);
  font-size: 13px;
  font-weight: 500;
  cursor: pointer;
  transition: transform var(--flare-transition-fast, 150ms ease), filter var(--flare-transition-fast, 150ms ease);
}
.flare-contact-detail__actions button:hover { filter: brightness(0.97); }
.flare-contact-detail__actions button:active { transform: scale(0.97); }
.flare-contact-detail__actions button.is-primary {
  background: var(--im-brand-gradient, var(--flare-color-primary));
  color: #fff;
}
.flare-contact-detail__card {
  width: 100%;
  margin-top: 18px;
  border-radius: var(--flare-size-radius-xl, 14px);
  background: var(--flare-color-bg-secondary);
  overflow: hidden;
}
.flare-contact-detail__row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  padding: 12px 16px;
  font-size: 13px;
}
.flare-contact-detail__row + .flare-contact-detail__row {
  border-top: 1px solid var(--flare-color-border-secondary);
}
.flare-contact-detail__row-label { color: var(--flare-color-text-tertiary); }
.flare-contact-detail__row-value {
  color: var(--flare-color-text-primary);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  max-width: 60%;
  text-align: right;
}
.flare-contact-detail__secondary {
  display: flex;
  gap: 8px;
  margin-top: 16px;
  width: 100%;
}
.flare-contact-detail__secondary button {
  flex: 1;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 5px;
  padding: 9px;
  border-radius: var(--flare-size-radius-md, 8px);
  border: 1px solid var(--flare-color-border-primary);
  background: transparent;
  color: var(--flare-color-text-secondary);
  font-size: 12px;
  cursor: pointer;
  transition: background var(--flare-transition-fast, 150ms ease);
}
.flare-contact-detail__secondary button:hover { background: var(--flare-color-bg-hover); }
.flare-contact-detail__secondary button.is-danger {
  color: var(--flare-color-error, #ef4444);
  border-color: color-mix(in srgb, var(--flare-color-error, #ef4444) 30%, transparent);
}
</style>
