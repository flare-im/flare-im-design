<script setup lang="ts">
// Management menu for ONE group member: change role, mute, remove, transfer
// ownership. It owns no positioning — hosts place it inside FlareBottomSheet
// (app) or a popover (desktop), exactly like FlareConversationActionSheet.
// Which actions exist is decided by the shared `memberRoleActions` contract, so
// all four platforms agree on set, order and danger grouping. The component
// only emits intent: the second confirmation for remove / transferOwner is the
// host's job (FlareDangerConfirm), and mute durations come from the host.
import { computed, ref, watch } from "vue";
import { NIcon } from "naive-ui";
import FlareAvatar from "../conversation/FlareAvatar.vue";
import { flareIcons } from "../../shared/icons";
import {
  memberRoleActions,
  type GroupMemberRole,
  type GroupMemberSnapshot,
  type MemberMuteDuration,
  type MemberRoleActionEntry,
  type MemberRoleActionId,
  type MemberRoleActionPayload,
  type MemberRoleCapabilities,
} from "../../shared/contracts/group-permissions";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import { useFlareAdaptiveSafe } from "../../composables/useAdaptiveMode";

const props = withDefaults(
  defineProps<{
    member: GroupMemberSnapshot;
    /** The viewer's own role in this group — rank rules come before capabilities. */
    viewerRole: GroupMemberRole;
    capabilities?: MemberRoleCapabilities;
    /** Host-supplied mute durations; empty hides mute — the kit invents no durations. */
    muteDurations?: MemberMuteDuration[];
    /** Host sets this synchronously before dispatching; disables every action. */
    busy?: boolean;
    ownerRoleText?: string;
    adminRoleText?: string;
    memberRoleText?: string;
    mutedText?: string;
    promoteText?: string;
    demoteText?: string;
    muteText?: string;
    unmuteText?: string;
    removeText?: string;
    transferOwnerText?: string;
    dangerGroupText?: string;
    emptyText?: string;
    ownerProtectedText?: string;
  }>(),
  {
    capabilities: () => ({}),
    muteDurations: () => [],
    busy: false,
  },
);
const { t } = useFlareI18n();
const { isH5 } = useFlareAdaptiveSafe();
const strings = computed(() => ({
  ownerRoleText: props.ownerRoleText ?? t("memberRoleSheet.ownerRole"),
  adminRoleText: props.adminRoleText ?? t("memberRoleSheet.adminRole"),
  memberRoleText: props.memberRoleText ?? t("memberRoleSheet.memberRole"),
  mutedText: props.mutedText ?? t("memberRoleSheet.muted"),
  promoteText: props.promoteText ?? t("memberRoleSheet.promote"),
  demoteText: props.demoteText ?? t("memberRoleSheet.demote"),
  muteText: props.muteText ?? t("memberRoleSheet.mute"),
  unmuteText: props.unmuteText ?? t("memberRoleSheet.unmute"),
  removeText: props.removeText ?? t("memberRoleSheet.remove"),
  transferOwnerText: props.transferOwnerText ?? t("memberRoleSheet.transferOwner"),
  dangerGroupText: props.dangerGroupText ?? t("memberRoleSheet.dangerGroup"),
  emptyText: props.emptyText ?? t("memberRoleSheet.empty"),
  ownerProtectedText: props.ownerProtectedText ?? t("memberRoleSheet.ownerProtected"),
}));

const emit = defineEmits<{
  (event: "action", payload: MemberRoleActionPayload): void;
  (event: "close"): void;
}>();

const entries = computed(() => memberRoleActions(props.member, props.viewerRole, props.capabilities));
/** mute needs host durations; with none supplied the row is not offered at all. */
const visible = computed(() =>
  entries.value.filter((e) => e.action !== "mute" || props.muteDurations.length > 0),
);
const primary = computed(() => visible.value.filter((e) => !e.danger));
const danger = computed(() => visible.value.filter((e) => e.danger));
/** The owner is protected by rank, not by missing capabilities — say which it is. */
const emptyReason = computed(() =>
  props.member.role === "owner" ? strings.value.ownerProtectedText : strings.value.emptyText,
);

const glyphs: Record<MemberRoleActionId, unknown> = {
  promote: flareIcons.admin,
  demote: flareIcons.person,
  mute: flareIcons.silence,
  unmute: flareIcons.silence,
  transferOwner: flareIcons["transfer-owner"],
  remove: flareIcons["remove-member"],
};

function labelFor(action: MemberRoleActionId): string {
  switch (action) {
    case "promote": return strings.value.promoteText;
    case "demote": return strings.value.demoteText;
    case "mute": return strings.value.muteText;
    case "unmute": return strings.value.unmuteText;
    case "transferOwner": return strings.value.transferOwnerText;
    case "remove": return strings.value.removeText;
  }
}
const roleText = computed(() => {
  switch (props.member.role) {
    case "owner": return strings.value.ownerRoleText;
    case "admin": return strings.value.adminRoleText;
    default: return strings.value.memberRoleText;
  }
});

// mute expands the host's duration list in place; every other action dispatches at once.
const muteOpen = ref(false);
watch(() => props.member.id, () => { muteOpen.value = false; });
watch(() => props.busy, (busy) => { if (busy) muteOpen.value = false; });

function select(entry: MemberRoleActionEntry): void {
  if (props.busy) return;
  if (entry.action === "mute") {
    muteOpen.value = !muteOpen.value;
    return;
  }
  emit("action", { memberId: props.member.id, action: entry.action });
}
function chooseDuration(duration: MemberMuteDuration): void {
  if (props.busy) return;
  emit("action", { memberId: props.member.id, action: "mute", durationId: duration.id });
}
function onKeydown(event: KeyboardEvent): void {
  if (event.key !== "Escape") return;
  event.preventDefault();
  if (muteOpen.value) {
    muteOpen.value = false;
    return;
  }
  emit("close");
}
</script>

<template>
  <!--
    A menu may only contain menuitem / group / separator, so the identity header
    and the empty-state line live outside it and the actions live inside one
    menu with a group per section (axe `aria-required-children`).
  -->
  <div
    class="flare-mrs"
    :class="{ 'flare-mrs--desktop': !isH5 }"
    :aria-busy="busy || undefined"
    @keydown="onKeydown"
  >
    <header class="flare-mrs__head">
      <FlareAvatar :user-id="member.id" :display-name="member.name" :avatar-url="member.avatarUrl" :size="40" />
      <div class="flare-mrs__identity">
        <span class="flare-mrs__name" :title="member.name">{{ member.name }}</span>
        <span class="flare-mrs__meta">
          <span class="flare-mrs__role" :class="`flare-mrs__role--${member.role}`">{{ roleText }}</span>
          <span v-if="member.muted" class="flare-mrs__muted">
            <n-icon :size="12" :component="flareIcons.silence" aria-hidden="true" />
            <span>{{ strings.mutedText }}</span>
          </span>
        </span>
      </div>
    </header>

    <p v-if="!visible.length" class="flare-mrs__empty" role="status">{{ emptyReason }}</p>

    <div v-if="visible.length" class="flare-mrs__menu" role="menu" :aria-label="member.name">
    <div v-if="primary.length" class="flare-mrs__group" role="group">
      <template v-for="entry in primary" :key="entry.action">
        <button
          type="button"
          role="menuitem"
          class="flare-mrs__row"
          :disabled="busy"
          :aria-expanded="entry.action === 'mute' ? muteOpen : undefined"
          @click="select(entry)"
        >
          <span class="flare-mrs__icon" aria-hidden="true">
            <n-icon aria-hidden="true" :size="20" :component="glyphs[entry.action] as any" />
          </span>
          <span class="flare-mrs__label">{{ labelFor(entry.action) }}</span>
          <span v-if="entry.action === 'mute'" class="flare-mrs__chevron" aria-hidden="true">
            <n-icon aria-hidden="true" :size="16" :component="muteOpen ? flareIcons['chevron-up'] : flareIcons['chevron-down']" />
          </span>
        </button>
        <div v-if="entry.action === 'mute' && muteOpen" class="flare-mrs__durations" role="group" :aria-label="strings.muteText">
          <button
            v-for="duration in muteDurations"
            :key="duration.id"
            type="button"
            role="menuitem"
            class="flare-mrs__duration"
            :disabled="busy"
            @click="chooseDuration(duration)"
          >
            {{ duration.label }}
          </button>
        </div>
      </template>
    </div>

    <div v-if="danger.length" class="flare-mrs__group flare-mrs__group--danger" role="group" :aria-label="strings.dangerGroupText">
      <p class="flare-mrs__group-title" aria-hidden="true">{{ strings.dangerGroupText }}</p>
      <button
        v-for="entry in danger"
        :key="entry.action"
        type="button"
        role="menuitem"
        class="flare-mrs__row flare-mrs__row--danger"
        :disabled="busy"
        @click="select(entry)"
      >
        <span class="flare-mrs__icon" aria-hidden="true">
          <n-icon aria-hidden="true" :size="20" :component="glyphs[entry.action] as any" />
        </span>
        <span class="flare-mrs__label">{{ labelFor(entry.action) }}</span>
      </button>
    </div>
    </div>
  </div>
</template>

<style scoped>
.flare-mrs {
  display: flex;
  flex-direction: column;
  gap: var(--flare-size-spacing-sm);
  min-width: 0;
  padding: var(--flare-size-spacing-xs) var(--flare-size-spacing-sm);
  color: var(--flare-color-text-primary);
}
.flare-mrs__head {
  display: flex;
  align-items: center;
  gap: var(--flare-size-spacing-md);
  padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-md);
  min-width: 0;
}
.flare-mrs__menu {
  display: flex;
  flex-direction: column;
  gap: var(--flare-size-spacing-sm);
  min-width: 0;
}
.flare-mrs__identity { display: grid; gap: 3px; min-width: 0; }
.flare-mrs__name {
  font-size: var(--flare-size-font-size-xl);
  font-weight: 600;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.flare-mrs__meta { display: inline-flex; align-items: center; gap: 6px; flex-wrap: wrap; }
.flare-mrs__role {
  padding: 1px 6px;
  border-radius: var(--flare-size-radius-sm);
  background: var(--flare-color-bg-secondary);
  color: var(--flare-color-text-secondary);
  font-size: var(--flare-size-font-size-sm);
}
.flare-mrs__role--owner,
.flare-mrs__role--admin {
  background: color-mix(in srgb, var(--flare-color-primary) 12%, var(--flare-color-bg-primary));
  color: var(--flare-color-primary-text);
  font-weight: 600;
}
.flare-mrs__muted {
  display: inline-flex;
  align-items: center;
  gap: 3px;
  font-size: var(--flare-size-font-size-sm);
  color: var(--flare-color-warning-text);
}
.flare-mrs__empty {
  margin: 0;
  padding: var(--flare-size-spacing-md);
  font-size: var(--flare-size-font-size-lg);
  color: var(--flare-color-text-secondary);
  text-align: center;
}
.flare-mrs__group {
  display: flex;
  flex-direction: column;
  padding: var(--flare-size-spacing-xs) 0;
  border-radius: var(--flare-size-radius-2xl);
  background: var(--flare-color-bg-primary);
}
.flare-mrs__group--danger { border-top: 1px solid var(--flare-color-border-secondary); }
.flare-mrs__group-title {
  margin: 0;
  padding: var(--flare-size-spacing-xs) var(--flare-size-spacing-md);
  font-size: var(--flare-size-font-size-sm);
  color: var(--flare-color-text-tertiary);
}
.flare-mrs__row {
  display: grid;
  grid-template-columns: 44px minmax(0, 1fr) auto;
  align-items: center;
  gap: var(--flare-size-spacing-md);
  width: 100%;
  min-height: var(--flare-size-layout-touch-target);
  padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-md);
  border: 0;
  border-radius: var(--flare-size-radius-xl);
  background: transparent;
  color: inherit;
  cursor: pointer;
  font: inherit;
  text-align: start;
}
.flare-mrs__row:hover:not(:disabled),
.flare-mrs__row:active:not(:disabled) { background: var(--flare-color-bg-hover); }
.flare-mrs__row:focus-visible {
  outline: 2px solid var(--flare-color-border-selected);
  outline-offset: -2px;
  background: var(--flare-color-bg-hover);
}
.flare-mrs__row:disabled { color: var(--flare-color-text-disabled); cursor: default; }
.flare-mrs__icon {
  display: grid;
  place-items: center;
  width: 44px;
  height: 44px;
  border-radius: var(--flare-size-radius-full);
  color: var(--flare-color-primary-text);
  background: color-mix(in srgb, var(--flare-color-primary) 10%, var(--flare-color-bg-primary));
}
.flare-mrs__row:disabled .flare-mrs__icon {
  color: var(--flare-color-text-disabled);
  background: var(--flare-color-bg-disabled);
}
.flare-mrs__label {
  font-size: var(--flare-size-font-size-2xl);
  font-weight: 600;
  line-height: var(--flare-size-line-height-tight);
  overflow-wrap: anywhere;
}
.flare-mrs__chevron { display: grid; place-items: center; color: var(--flare-color-text-tertiary); }
.flare-mrs__durations {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  padding: var(--flare-size-spacing-xs) var(--flare-size-spacing-md) var(--flare-size-spacing-sm) 56px;
}
.flare-mrs__duration {
  min-height: 40px;
  padding: 0 12px;
  border: 1px solid var(--flare-color-border-primary);
  border-radius: var(--flare-size-radius-md);
  background: var(--flare-color-bg-secondary);
  color: var(--flare-color-text-primary);
  font: inherit;
  font-size: var(--flare-size-font-size-md);
  cursor: pointer;
}
@media (pointer: coarse) {
  .flare-mrs__duration { min-height: var(--flare-size-layout-touch-target); }
}
.flare-mrs__duration:hover:not(:disabled) { background: var(--flare-color-bg-hover); }
.flare-mrs__duration:disabled { opacity: 0.5; cursor: default; }
.flare-mrs__duration:focus-visible {
  outline: 2px solid var(--flare-color-border-selected);
  outline-offset: 2px;
}
.flare-mrs__row--danger:not(:disabled),
.flare-mrs__row--danger:not(:disabled) .flare-mrs__icon { color: var(--flare-color-error-text); }
.flare-mrs__row--danger:not(:disabled) .flare-mrs__icon {
  background: color-mix(in srgb, var(--flare-color-error) 12%, var(--flare-color-bg-primary));
}
.flare-mrs--desktop .flare-mrs__head { gap: 8px; padding: 8px; }
.flare-mrs--desktop .flare-mrs__name { font-size: 14px; }
.flare-mrs--desktop .flare-mrs__group { border-radius: 0; }
.flare-mrs--desktop .flare-mrs__row { grid-template-columns: 18px minmax(0, 1fr) auto; min-height: 36px; padding: 6px 8px; gap: var(--flare-size-spacing-2sm); border-radius: var(--flare-size-radius-sm); }
.flare-mrs--desktop .flare-mrs__icon { width: 18px; height: 18px; border-radius: 0; color: var(--flare-color-text-secondary); background: transparent; }
.flare-mrs--desktop .flare-mrs__label { font-size: 13px; font-weight: 500; }
.flare-mrs--desktop .flare-mrs__durations { padding-inline-start: 36px; }
.flare-mrs--desktop .flare-mrs__duration { min-height: 32px; }
.flare-mrs--desktop .flare-mrs__row--danger:not(:disabled) .flare-mrs__icon { color: var(--flare-color-error-text); background: transparent; }
</style>
