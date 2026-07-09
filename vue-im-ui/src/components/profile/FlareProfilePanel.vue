<script setup lang="ts">
import FlareAvatar from "../conversation/FlareAvatar.vue";
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
  (e: "logout"): void;
}>();
</script>

<template>
  <div class="flare-profile">
    <div class="flare-profile__hdr" @click="emit('edit')">
      <FlareAvatar :user-id="user.id" :display-name="user.name" :avatar-url="user.avatarUrl" :size="56" />
      <div class="flare-profile__meta">
        <div class="flare-profile__name">{{ user.name }}</div>
        <div v-if="user.flareId" class="flare-profile__id">Flare ID: {{ user.flareId }}</div>
      </div>
      <span class="flare-profile__qr">▦</span>
    </div>
    <div class="flare-profile__list">
      <div
        v-for="e in entries"
        :key="e.key"
        class="flare-profile__row"
        @click="emit('action', e)"
      >
        <span v-if="e.icon" class="flare-profile__ico">{{ e.icon }}</span>
        <span class="flare-profile__label">{{ e.label }}</span>
        <span class="flare-profile__chev">›</span>
      </div>
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
.flare-profile__meta { flex: 1; }
.flare-profile__name { font-size: 18px; font-weight: 600; color: var(--flare-color-text-primary); }
.flare-profile__id { font-size: 12px; color: var(--flare-color-text-tertiary); margin-top: 2px; }
.flare-profile__qr { color: var(--flare-color-text-tertiary); font-size: 18px; }
.flare-profile__list { margin-top: 8px; }
.flare-profile__row {
  display: flex; align-items: center; gap: 12px;
  padding: 13px 16px; cursor: pointer;
}
.flare-profile__row + .flare-profile__row { border-top: 1px solid var(--flare-color-border-secondary); }
.flare-profile__ico { font-size: 18px; }
.flare-profile__label { flex: 1; color: var(--flare-color-text-primary); }
.flare-profile__chev { color: var(--flare-color-text-tertiary); }
</style>
