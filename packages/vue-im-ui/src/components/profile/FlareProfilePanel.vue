<script setup lang="ts">
import { computed, getCurrentInstance } from "vue";
import { NIcon } from "naive-ui";
import { QrCodeOutline, ChevronForwardOutline } from "../../shared/icon-glyphs";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";
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
    entries: undefined,
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

const { t } = useFlareI18nOptional();
const instance = getCurrentInstance();
// The identity opens the editor and the QR button exists only when the host handles them.
const handles = (listener: "onEdit" | "onQr"): boolean => Boolean(instance?.vnode.props?.[listener]);

// Normalize to grouped sections so the template has one render path.
const groups = computed<FlareSettingsSection[]>(() =>
  props.sections ?? [{
    items: props.entries ?? [
      { key: "favorites", label: t("profilePanel.favorites"), icon: "star" },
      { key: "moments", label: t("profilePanel.moments"), icon: "moments" },
      { key: "settings", label: t("profilePanel.settings"), icon: "settings" },
    ],
  }],
);
</script>

<template>
  <div class="flare-profile">
    <!-- The identity row and the QR button are siblings: a button inside a clickable header could not be reached or named on its own. -->
    <div class="flare-profile__hdr">
      <component
        :is="handles('onEdit') ? 'button' : 'div'"
        :type="handles('onEdit') ? 'button' : undefined"
        class="flare-profile__identity"
        :class="{ 'is-interactive': handles('onEdit'), 'has-qr': handles('onQr') }"
        :aria-label="handles('onEdit') ? t('profilePanel.editProfile', { name: user.name }) : undefined"
        @click="handles('onEdit') && emit('edit')"
      >
        <FlareAvatar :user-id="user.id" :display-name="user.name" :avatar-url="user.avatarUrl" :size="56" />
        <span class="flare-profile__meta">
          <span class="flare-profile__name">{{ user.name }}</span>
          <span v-if="user.signature" class="flare-profile__sig">{{ user.signature }}</span>
          <span v-else-if="signaturePlaceholder" class="flare-profile__sig is-placeholder">{{ signaturePlaceholder }}</span>
          <span v-if="user.flareId" class="flare-profile__id">Flare ID: {{ user.flareId }}</span>
        </span>
        <span v-if="handles('onEdit')" class="flare-profile__chev"><n-icon aria-hidden="true" :size="18" :component="ChevronForwardOutline" /></span>
      </component>
      <button v-if="handles('onQr')" type="button" class="flare-profile__qr" :aria-label="t('qr.open')" @click="emit('qr')">
        <n-icon aria-hidden="true" :size="20" :component="QrCodeOutline" />
      </button>
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
/* A quiet identity card in the same surface as the lists below it: the profile is content, not a banner. */
.flare-profile__hdr {
  position: relative;
  margin: 12px 12px 0;
  border-radius: var(--flare-size-radius-xl);
  background: var(--flare-color-bg-elevated);
  box-shadow: var(--flare-shadow-card);
  overflow: hidden;
}
.flare-profile__identity {
  display: flex; align-items: center; gap: 14px;
  width: 100%; min-height: 88px;
  padding: 16px;
  border: 0; background: transparent; color: inherit; font: inherit; text-align: start;
}
/* Room for the chevron and, when present, the QR button that sit over the row's end. */
.flare-profile__identity.is-interactive { padding-right: 44px; cursor: pointer; }
.flare-profile__identity.has-qr { padding-right: 84px; }
.flare-profile__identity.is-interactive:hover { background: var(--flare-color-bg-hover); }
.flare-profile__identity:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: -2px; }
.flare-profile__meta { display: flex; flex-direction: column; flex: 1; min-width: 0; }
.flare-profile__name { font-size: 18px; font-weight: 700; color: var(--flare-color-text-primary); }
.flare-profile__sig {
  margin-top: 3px; font-size: var(--flare-size-font-size-md); color: var(--flare-color-text-secondary);
  overflow: hidden; text-overflow: ellipsis; white-space: nowrap;
}
.flare-profile__sig.is-placeholder { color: var(--flare-color-text-tertiary); }
.flare-profile__id { margin-top: 3px; font-size: var(--flare-size-font-size-sm); color: var(--flare-color-text-tertiary); }
.flare-profile__chev {
  position: absolute; top: 50%; right: 14px; transform: translateY(-50%);
  display: inline-flex; color: var(--flare-color-text-tertiary); pointer-events: none;
}
.flare-profile__qr {
  position: absolute; top: 50%; right: 38px; transform: translateY(-50%);
  display: inline-flex; align-items: center; justify-content: center;
  width: 40px; height: 40px; border: none; border-radius: 50%;
  color: var(--flare-color-text-secondary); background: transparent;
  cursor: pointer; transition: background var(--flare-transition-fast), color var(--flare-transition-fast);
}
.flare-profile__qr:hover { color: var(--flare-color-text-primary); background: var(--flare-color-bg-hover); }
.flare-profile__qr:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: 2px; }
.flare-profile__list {
  margin: 14px 12px 0;
  border-radius: var(--flare-size-radius-xl);
  background: var(--flare-color-bg-elevated);
  box-shadow: var(--flare-shadow-card);
  overflow: hidden;
}
.flare-profile__list + .flare-profile__list { margin-top: 12px; }
.flare-profile__list :deep(.flare-settings__row) { background: transparent; }
@media (prefers-reduced-motion: reduce) { .flare-profile__qr { transition: none; } }
</style>
