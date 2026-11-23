<script setup lang="ts">
import { computed, getCurrentInstance, useId } from "vue";
import { NIcon } from "naive-ui";
import { QrCodeOutline, ChevronForwardOutline } from "../../shared/icon-glyphs";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";
import { useScreenLayout } from "../../shared/screenLayout";
import FlareAvatar from "../conversation/FlareAvatar.vue";
import FlareIconButton from "../general/FlareIconButton.vue";
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
    /** Accessible destination name when the identity opens an overview rather than editing. */
    identityActionLabel?: string;
    /** Sidebar keeps identity fixed while compact destinations scroll inside the available height. */
    layout?: "page" | "sidebar";
    /** Hide the identity when the account overview already renders it beside the navigation. */
    showIdentity?: boolean;
  }>(),
  {
    entries: undefined,
    sections: undefined,
    signaturePlaceholder: "",
    layout: "page",
    showIdentity: true,
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
const { detail, title } = useScreenLayout();
const instance = getCurrentInstance();
// The host owns the identity destination; the QR button remains a separate intent.
const handles = (listener: "onEdit" | "onQr"): boolean => Boolean(instance?.vnode.props?.[listener]);
/** Names each titled card after its title (`aria-labelledby`). */
const sectionId = `flare-profile-section-${useId()}`;

// Normalize to grouped sections so the template has one render path.
const groups = computed<FlareSettingsSection[]>(() =>
  (props.sections ?? [{
    items: props.entries ?? [
      { key: "favorites", label: t("profilePanel.favorites"), icon: "star" },
      { key: "moments", label: t("profilePanel.moments"), icon: "moments" },
      { key: "settings", label: t("profilePanel.settings"), icon: "settings" },
    ],
  }]).filter(group => group.items.length > 0),
);
</script>

<template>
  <div class="flare-profile" :class="{ 'flare-profile--sidebar': layout === 'sidebar', 'is-detail': detail }">
    <!-- The identity row and the QR button are siblings: a button inside a clickable header could not be reached or named on its own. -->
    <div v-if="showIdentity" class="flare-profile__hdr">
      <component
        :is="handles('onEdit') ? 'button' : 'div'"
        :type="handles('onEdit') ? 'button' : undefined"
        class="flare-profile__identity"
        :class="{ 'is-interactive': handles('onEdit') }"
        :aria-label="handles('onEdit') ? (identityActionLabel || t('profilePanel.editProfile', { name: user.name })) : undefined"
        :aria-describedby="handles('onEdit') ? `${sectionId}-identity` : undefined"
        :aria-hidden="handles('onEdit') ? undefined : true"
        @click="handles('onEdit') && emit('edit')"
      />
        <span class="flare-profile__avatar" aria-hidden="true">
          <FlareAvatar :user-id="user.id" :display-name="user.name" :avatar-url="user.avatarUrl" :size="48" />
        </span>
        <span :id="`${sectionId}-identity`" class="flare-profile__meta">
          <span class="flare-profile__name" :title="user.name">{{ user.name }}</span>
          <span v-if="user.flareId" class="flare-profile__id" :title="`Flare ID: ${user.flareId}`">Flare ID: {{ user.flareId }}</span>
          <span v-if="user.signature" class="flare-profile__sig" :title="user.signature">{{ user.signature }}</span>
          <span v-else-if="signaturePlaceholder" class="flare-profile__sig is-placeholder">{{ signaturePlaceholder }}</span>
        </span>
        <span v-if="handles('onEdit') || handles('onQr')" class="flare-profile__tail">
          <FlareIconButton v-if="handles('onQr')" class="flare-profile__qr" :icon="QrCodeOutline" size="md" shape="square" :ariaLabel="t('qr.open')" @click="emit('qr')" />
          <n-icon v-if="handles('onEdit')" aria-hidden="true" size="var(--flare-size-icon-size-sm)" :component="ChevronForwardOutline" />
        </span>
    </div>
    <!-- Shared with FlareSettingsList: renders kind (toggle/value/navigation) + detail. A section's title sits above its
         card and its footer under it, in the settings list's own section styles; a titled card is a group named by it. -->
    <div
      v-if="groups.length"
      class="flare-profile__sections"
      :role="layout === 'sidebar' ? 'navigation' : undefined"
      :aria-labelledby="layout === 'sidebar' && showIdentity ? `${sectionId}-identity` : undefined"
      :aria-label="layout === 'sidebar' && !showIdentity ? title : undefined"
    >
    <section v-for="(group, gi) in groups" :key="gi" class="flare-profile__section">
      <h2 v-if="group.title" :id="`${sectionId}-${gi}`" class="flare-profile__section-title">{{ group.title }}</h2>
      <div
        class="flare-profile__list"
        :class="{ 'is-titled': Boolean(group.title) }"
        :role="group.title ? 'group' : undefined"
        :aria-labelledby="group.title ? `${sectionId}-${gi}` : undefined"
      >
        <FlareSettingsRow
          v-for="e in group.items"
          :key="e.key"
          :item="e"
          @select="(i: FlareSettingsItem) => emit('action', i)"
          @toggle="(i: FlareSettingsItem, v: boolean) => emit('toggle', i, v)"
        />
      </div>
      <p v-if="group.footer" class="flare-profile__section-footer">{{ group.footer }}</p>
    </section>
    </div>
  </div>
</template>

<style scoped>
.flare-profile {
  width: 100%; min-width: 0; box-sizing: border-box;
  padding: var(--flare-size-spacing-md);
  container: flare-profile / inline-size;
}
.flare-profile.is-detail { padding: 0; }
/* A quiet identity card in the same surface as the lists below it: the profile is content, not a banner. */
.flare-profile__hdr {
  position: relative;
  display: grid; grid-template-columns: auto minmax(0, 1fr) auto; align-items: center;
  column-gap: var(--flare-size-spacing-md);
  padding: var(--flare-size-spacing-md);
  border: 1px solid var(--flare-color-border-secondary);
  border-radius: var(--flare-size-radius-lg);
  background: var(--flare-color-bg-elevated);
  overflow: hidden;
}
.flare-profile__identity {
  position: absolute; inset: 0;
  width: 100%; height: 100%; min-width: 0; box-sizing: border-box;
  padding: 0; border-radius: inherit;
  border: 0; background: transparent; color: inherit; font: inherit; text-align: start;
  pointer-events: none;
}
.flare-profile__identity.is-interactive { cursor: pointer; pointer-events: auto; }
@media (hover: hover) { .flare-profile__identity.is-interactive:hover { background: var(--flare-color-bg-hover); } }
.flare-profile__identity:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: -2px; }
.flare-profile__avatar, .flare-profile__meta { position: relative; pointer-events: none; }
.flare-profile__avatar { display: flex; align-items: center; line-height: 1; }
.flare-profile__meta { display: flex; flex-direction: column; min-width: 0; }
.flare-profile__name {
  font-size: var(--flare-size-font-size-3xl); line-height: var(--flare-size-line-height-snug);
  font-weight: var(--flare-size-font-weight-semibold); color: var(--flare-color-text-primary);
  display: -webkit-box; -webkit-box-orient: vertical; -webkit-line-clamp: 2;
  overflow: hidden; overflow-wrap: anywhere;
}
.flare-profile__sig {
  margin-top: var(--flare-size-spacing-2xs); font-size: var(--flare-size-font-size-md); color: var(--flare-color-text-secondary);
  display: -webkit-box; -webkit-box-orient: vertical; -webkit-line-clamp: 2;
  overflow: hidden; overflow-wrap: anywhere; line-height: var(--flare-size-line-height-normal);
}
.flare-profile__sig.is-placeholder { color: var(--flare-color-text-tertiary); }
.flare-profile__id { margin-top: var(--flare-size-spacing-3xs); font-size: var(--flare-size-font-size-sm); color: var(--flare-color-text-secondary); overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.flare-profile__tail {
  position: relative;
  display: inline-flex; align-items: center; justify-content: end; gap: var(--flare-size-spacing-xs);
  color: var(--flare-color-text-tertiary); pointer-events: none;
}
.flare-profile__qr { pointer-events: auto; margin-inline: calc((var(--flare-size-layout-touch-target) - var(--flare-size-component-icon-button-side-md)) / 2); }
.flare-profile__hdr + .flare-profile__sections { margin-top: var(--flare-size-spacing-lg); }
.flare-profile__section { min-width: 0; break-inside: avoid; }
.flare-profile__section + .flare-profile__section { margin-top: var(--flare-size-spacing-lg); }
.flare-profile__list {
  border: 1px solid var(--flare-color-border-secondary);
  border-radius: var(--flare-size-radius-lg);
  background: var(--flare-color-bg-elevated);
  overflow: hidden;
}
/* The settings list's section title and footer (FlareSettingsList), set against the cards' 12px inset. */
.flare-profile__section-title {
  margin: 0;
  padding: 0 var(--flare-size-spacing-sm) var(--flare-size-spacing-sm);
  font-size: var(--flare-size-font-size-sm);
  font-weight: var(--flare-size-font-weight-medium);
  line-height: var(--flare-size-line-height-normal);
  color: var(--flare-color-text-secondary);
}
.flare-profile__section-footer {
  margin: 0;
  padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-sm) 0;
  font-size: var(--flare-size-font-size-sm);
  line-height: var(--flare-size-line-height-normal);
  color: var(--flare-color-text-tertiary);
  overflow-wrap: anywhere;
}
.flare-profile__list :deep(.flare-settings__row:not(.is-current):not(:hover)) { background: transparent; }
/* Whole sections flow down one column before the next. No section or its keyboard order is split. */
@container flare-profile (min-width: 640px) {
  .flare-profile__sections { columns: 2; column-gap: var(--flare-size-spacing-lg); }
  .flare-profile__section { margin: 0 0 var(--flare-size-spacing-lg); }
  .flare-profile__section + .flare-profile__section { margin-top: 0; }
}
/* An explicit host choice, not another viewport breakpoint: phones keep the page presentation. */
.flare-profile--sidebar {
  display: flex;
  flex-direction: column;
  flex: 1 1 0%;
  height: 100%;
  min-height: 0;
  overflow: hidden;
  padding: var(--flare-size-spacing-sm);
}
.flare-profile--sidebar .flare-profile__hdr { flex: none; }
.flare-profile--sidebar .flare-profile__name { font-size: var(--flare-size-font-size-lg); }
.flare-profile--sidebar .flare-profile__sig { font-size: var(--flare-size-font-size-sm); -webkit-line-clamp: 1; }
.flare-profile--sidebar .flare-profile__sections {
  flex: 1;
  min-height: 0;
  overflow-y: auto;
  overscroll-behavior: contain;
  scrollbar-gutter: stable;
  scroll-padding-block: var(--flare-size-spacing-xs);
  columns: auto;
}
.flare-profile--sidebar .flare-profile__hdr + .flare-profile__sections { margin-top: var(--flare-size-spacing-md); }
.flare-profile--sidebar .flare-profile__section { margin: 0; }
.flare-profile--sidebar .flare-profile__section + .flare-profile__section { margin-top: var(--flare-size-spacing-md); }
.flare-profile--sidebar .flare-profile__section-title { padding-bottom: var(--flare-size-spacing-xs); }
.flare-profile--sidebar .flare-profile__list { background: transparent; border: 0; border-radius: 0; overflow: visible; }
.flare-profile--sidebar .flare-profile__list :deep(.flare-settings__row) {
  min-height: var(--flare-size-layout-control-height-md);
  padding: var(--flare-size-spacing-sm);
  gap: var(--flare-size-spacing-sm);
  border: 0;
  border-inline-start: var(--flare-size-spacing-3xs) solid transparent;
  border-radius: var(--flare-size-radius-md);
}
.flare-profile--sidebar .flare-profile__list :deep(.flare-settings__row + .flare-settings__row) { margin-top: var(--flare-size-spacing-3xs); }
.flare-profile--sidebar :deep(.flare-settings__label) { font-size: var(--flare-size-font-size-md); text-wrap: initial; }
.flare-profile--sidebar :deep(.flare-settings__detail) { font-size: var(--flare-size-font-size-sm); -webkit-line-clamp: 1; }
.flare-profile--sidebar .flare-profile__list :deep(.flare-settings__row.is-current) {
  background: var(--flare-color-bg-selected);
  border-inline-start-color: var(--flare-color-border-selected);
}
.flare-profile--sidebar :deep(.is-current .flare-settings__ico),
.flare-profile--sidebar :deep(.is-current .flare-settings__chev) { color: var(--flare-color-primary-text); }
@media (any-pointer: coarse) {
  .flare-profile--sidebar .flare-profile__list :deep(.flare-settings__row) { min-height: var(--flare-size-layout-touch-target); }
}
</style>
