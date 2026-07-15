<script setup lang="ts">
import { NIcon } from "naive-ui";
import { QrCodeOutline } from "@vicons/ionicons5";
import FlareAvatar from "../conversation/FlareAvatar.vue";
import FlareSettingsRow from "./FlareSettingsRow.vue";
import type { FlareUserProfile, FlareSettingsItem } from "../../shared/contracts";

withDefaults(defineProps<{ user: FlareUserProfile; entries?: FlareSettingsItem[] }>(), {
  entries: () =>   [
    { key: "favorites", label: "Favorites", icon: "⭐" },
    { key: "moments", label: "Moments", icon: "🖼️" },
    { key: "settings", label: "Settings", icon: "⚙️" },
  ],
});
const emit = defineEmits<{
  (e: "edit"): void;
  (e: "action", item: FlareSettingsItem): void;
  (e: "toggle", item: FlareSettingsItem, value: boolean): void;
  (e: "logout"): void;
}>();
</script>

<template>
  <div class="flare-profile">
    <div class="flare-profile__hdr" @click="emit('edit')">
      <FlareAvatar :user-id="user.id" :display-name="user.name" :avatar-url="user.avatarUrl" :size="56" />
      <div class="flare-profile__meta">
        <div class="flare-profile__name">{{ user.name }}</div>
        <div v-if="user.signature" class="flare-profile__sig">{{ user.signature }}</div>
        <div v-if="user.flareId" class="flare-profile__id">Flare ID: {{ user.flareId }}</div>
      </div>
      <span class="flare-profile__qr"><n-icon :size="20" :component="QrCodeOutline" /></span>
    </div>
    <div class="flare-profile__list">
      <!-- Shared with FlareSettingsList: renders kind (toggle/value/navigation) + detail. -->
      <FlareSettingsRow
        v-for="e in entries"
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
  padding: 20px 16px; cursor: pointer;
  background: var(--flare-color-bg-selected);
}
.flare-profile__meta { flex: 1; min-width: 0; }
.flare-profile__name { font-size: 18px; font-weight: 600; color: var(--flare-color-text-primary); }
.flare-profile__sig {
  font-size: 13px; color: var(--flare-color-text-secondary); margin-top: 2px;
  overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
}
.flare-profile__id { font-size: 12px; color: var(--flare-color-text-tertiary); margin-top: 2px; }
.flare-profile__qr { color: var(--flare-color-text-tertiary); font-size: 18px; }
.flare-profile__list { margin-top: 8px; }
</style>
