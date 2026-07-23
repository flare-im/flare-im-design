<script setup lang="ts">
import { computed } from "vue";
import { NIcon } from "naive-ui";
import { QrCodeOutline, ChevronForwardOutline } from "../../shared/icon-glyphs";
import FlareAvatar from "../conversation/FlareAvatar.vue";
import FlareSettingsRow from "./FlareSettingsRow.vue";
import type {
  FlareUserProfile,
  FlareSettingsItem,
  FlareSettingsSection,
} from "../../shared/contracts";

const props = withDefaults(
  defineProps<{
    user: FlareUserProfile;
    entries?: FlareSettingsItem[];
    /** Grouped rows (iOS-style cards). Overrides `entries` when provided. */
    sections?: FlareSettingsSection[];
    /** Placeholder shown in the header when the user has no signature yet. */
    signaturePlaceholder?: string;
  }>(),
  {
    entries: () => [
      { key: "favorites", label: "Favorites", icon: "star" },
      { key: "moments", label: "Moments", icon: "moments" },
      { key: "settings", label: "Settings", icon: "settings" },
    ],
    sections: undefined,
    signaturePlaceholder: "",
  },
);
const emit = defineEmits<{
  (e: "edit"): void;
  (e: "qr"): void;
  (e: "action", item: FlareSettingsItem): void;
  (e: "toggle", item: FlareSettingsItem, value: boolean): void;
  (e: "logout"): void;
}>();

// Normalize to grouped sections so the template has one render path.
const groups = computed<FlareSettingsSection[]>(() =>
  props.sections ?? [{ items: props.entries }],
);
</script>

<template>
  <div class="flare-profile">
    <div class="flare-profile__hdr" @click="emit('edit')">
      <FlareAvatar :user-id="user.id" :display-name="user.name" :avatar-url="user.avatarUrl" :size="56" />
      <div class="flare-profile__meta">
        <div class="flare-profile__name">{{ user.name }}</div>
        <div v-if="user.signature" class="flare-profile__sig">{{ user.signature }}</div>
        <div v-else-if="signaturePlaceholder" class="flare-profile__sig is-placeholder">{{ signaturePlaceholder }}</div>
        <div v-if="user.flareId" class="flare-profile__id">Flare ID: {{ user.flareId }}</div>
      </div>
      <button type="button" class="flare-profile__qr" @click.stop="emit('qr')">
        <n-icon :size="20" :component="QrCodeOutline" />
      </button>
      <span class="flare-profile__chev"><n-icon :size="18" :component="ChevronForwardOutline" /></span>
    </div>
    <!-- Shared with FlareSettingsList: renders kind (toggle/value/navigation) + detail. -->
    <div v-for="(group, gi) in groups" :key="gi" class="flare-profile__list">
      <FlareSettingsRow
        v-for="e in group.items"
        :key="e.key"
        :item="e"
        @select="(i: FlareSettingsItem) => emit('action', i)"
        @toggle="(i: FlareSettingsItem, v: boolean) => emit('toggle', i, v)"
      />
    </div>
  </div>
</template>

<style scoped>
.flare-profile { width: 100%; }
.flare-profile__hdr {
  display: flex; align-items: center; gap: 14px;
  padding: 26px 16px 24px; cursor: pointer;
  position: relative; overflow: hidden;
  /* Aurora glow header — a violet light source, white text over it. */
  background:
    radial-gradient(120% 150% at 6% -30%, rgba(196, 181, 253, 0.5), transparent 52%),
    radial-gradient(95% 130% at 102% -10%, rgba(124, 58, 237, 0.6), transparent 55%),
    linear-gradient(150deg, #3b1f7a 0%, #7c3aed 62%, #8b5cf6 100%);
}
.flare-profile__hdr :deep(.im-avatar),
.flare-profile__hdr :deep(.flare-avatar) {
  box-shadow: 0 0 0 3px rgba(255, 255, 255, 0.22), 0 6px 16px rgba(0, 0, 0, 0.28);
}
.flare-profile__meta { flex: 1; min-width: 0; }
.flare-profile__name { font-size: 18px; font-weight: 700; color: #fff; }
.flare-profile__sig {
  font-size: 13px; color: rgba(255, 255, 255, 0.82); margin-top: 3px;
  overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
}
.flare-profile__sig.is-placeholder { color: rgba(255, 255, 255, 0.62); font-style: italic; }
.flare-profile__id { font-size: 12px; color: rgba(255, 255, 255, 0.62); margin-top: 3px; }
.flare-profile__qr {
  display: inline-flex; align-items: center; justify-content: center;
  width: 34px; height: 34px; border: none; border-radius: 50%;
  color: rgba(255, 255, 255, 0.92); background: rgba(255, 255, 255, 0.14);
  cursor: pointer; transition: background 0.15s ease;
}
.flare-profile__qr:hover { background: rgba(255, 255, 255, 0.24); }
.flare-profile__chev { color: rgba(255, 255, 255, 0.7); display: inline-flex; margin-left: -4px; }
.flare-profile__list {
  margin: 14px 12px 0;
  border-radius: var(--flare-size-radius-xl, 14px);
  background: var(--flare-color-bg-elevated, #fff);
  box-shadow: var(--flare-shadow-card);
  overflow: hidden;
}
.flare-profile__list + .flare-profile__list { margin-top: 12px; }
.flare-profile__list :deep(.flare-settings__row) { background: transparent; }
</style>
