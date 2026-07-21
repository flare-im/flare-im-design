<script setup lang="ts">
import { NIcon } from "naive-ui";
import { QrCodeOutline } from "../../shared/icon-glyphs";
import FlareAvatar from "../conversation/FlareAvatar.vue";
import FlareSettingsRow from "./FlareSettingsRow.vue";
import type { FlareUserProfile, FlareSettingsItem } from "../../shared/contracts";

withDefaults(defineProps<{ user: FlareUserProfile; entries?: FlareSettingsItem[] }>(), {
  entries: () =>   [
    { key: "favorites", label: "Favorites", icon: "star" },
    { key: "moments", label: "Moments", icon: "moments" },
    { key: "settings", label: "Settings", icon: "settings" },
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
.flare-profile__id { font-size: 12px; color: rgba(255, 255, 255, 0.62); margin-top: 3px; }
.flare-profile__qr { color: rgba(255, 255, 255, 0.9); font-size: 18px; }
.flare-profile__list { margin-top: 8px; }
</style>
