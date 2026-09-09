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
import {
  ChevronDownOutline,
  ChevronUpOutline,
  LogOutOutline,
  NotificationsOutline,
  PersonOutline,
  ShieldCheckmarkOutline,
  StarOutline,
  VolumeMuteOutline,
} from "../../shared/icon-glyphs";
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
    ownerRoleText: "群主",
    adminRoleText: "管理员",
    memberRoleText: "成员",
    mutedText: "已禁言",
    promoteText: "设为管理员",
    demoteText: "取消管理员",
    muteText: "禁言",
    unmuteText: "解除禁言",
    removeText: "移出群聊",
    transferOwnerText: "转让群主",
    dangerGroupText: "危险操作",
    emptyText: "你没有管理权限",
    ownerProtectedText: "群主不可被管理",
  },
);

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
  props.member.role === "owner" ? props.ownerProtectedText : props.emptyText,
);

const glyphs: Record<MemberRoleActionId, unknown> = {
  promote: ShieldCheckmarkOutline,
  demote: PersonOutline,
  mute: VolumeMuteOutline,
  unmute: NotificationsOutline,
  transferOwner: StarOutline,
  remove: LogOutOutline,
};

function labelFor(action: MemberRoleActionId): string {
  switch (action) {
    case "promote": return props.promoteText;
    case "demote": return props.demoteText;
    case "mute": return props.muteText;
    case "unmute": return props.unmuteText;
    case "transferOwner": return props.transferOwnerText;
    case "remove": return props.removeText;
  }
}
const roleText = computed(() => {
  switch (props.member.role) {
    case "owner": return props.ownerRoleText;
    case "admin": return props.adminRoleText;
    default: return props.memberRoleText;
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
  <div
    class="flare-mrs"
    role="menu"
    :aria-label="member.name"
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
            <n-icon :size="12" :component="VolumeMuteOutline" aria-hidden="true" />
            <span>{{ mutedText }}</span>
          </span>
        </span>
      </div>
    </header>

    <p v-if="!visible.length" class="flare-mrs__empty" role="status">{{ emptyReason }}</p>

    <div v-if="primary.length" class="flare-mrs__group">
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
            <n-icon :size="20" :component="glyphs[entry.action] as any" />
          </span>
          <span class="flare-mrs__label">{{ labelFor(entry.action) }}</span>
          <span v-if="entry.action === 'mute'" class="flare-mrs__chevron" aria-hidden="true">
            <n-icon :size="16" :component="muteOpen ? ChevronUpOutline : ChevronDownOutline" />
          </span>
        </button>
        <div v-if="entry.action === 'mute' && muteOpen" class="flare-mrs__durations" :aria-label="muteText">
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

    <div v-if="danger.length" class="flare-mrs__group flare-mrs__group--danger">
      <p class="flare-mrs__group-title">{{ dangerGroupText }}</p>
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
          <n-icon :size="20" :component="glyphs[entry.action] as any" />
        </span>
        <span class="flare-mrs__label">{{ labelFor(entry.action) }}</span>
      </button>
    </div>
  </div>
</template>

<style scoped>
.flare-mrs {
  display: flex;
  flex-direction: column;
  gap: var(--flare-size-spacing-sm, 8px);
  min-width: 0;
  padding: var(--flare-size-spacing-xs, 4px) var(--flare-size-spacing-sm, 8px);
  color: var(--flare-color-text-primary);
}
.flare-mrs__head {
  display: flex;
  align-items: center;
  gap: var(--flare-size-spacing-md, 12px);
  padding: var(--flare-size-spacing-sm, 8px) var(--flare-size-spacing-md, 12px);
  min-width: 0;
}
.flare-mrs__identity { display: grid; gap: 3px; min-width: 0; }
.flare-mrs__name {
  font-size: var(--flare-size-font-size-xl, 15px);
  font-weight: 600;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.flare-mrs__meta { display: inline-flex; align-items: center; gap: 6px; flex-wrap: wrap; }
.flare-mrs__role {
  padding: 1px 6px;
  border-radius: var(--flare-size-radius-sm, 6px);
  background: var(--flare-color-bg-secondary);
  color: var(--flare-color-text-secondary);
  font-size: var(--flare-size-font-size-sm, 12px);
}
.flare-mrs__role--owner,
.flare-mrs__role--admin {
  background: color-mix(in srgb, var(--flare-color-primary) 12%, var(--flare-color-bg-primary));
  color: var(--flare-color-primary);
  font-weight: 600;
}
.flare-mrs__muted {
  display: inline-flex;
  align-items: center;
  gap: 3px;
  font-size: var(--flare-size-font-size-sm, 12px);
  color: var(--flare-color-warning);
}
.flare-mrs__empty {
  margin: 0;
  padding: var(--flare-size-spacing-md, 12px);
  font-size: var(--flare-size-font-size-lg, 14px);
  color: var(--flare-color-text-secondary);
  text-align: center;
}
.flare-mrs__group {
  display: flex;
  flex-direction: column;
  padding: var(--flare-size-spacing-xs, 4px) 0;
  border-radius: var(--flare-size-radius-2xl, 18px);
  background: var(--flare-color-bg-primary);
}
.flare-mrs__group--danger { border-top: 1px solid var(--flare-color-border-secondary); }
.flare-mrs__group-title {
  margin: 0;
  padding: var(--flare-size-spacing-xs, 4px) var(--flare-size-spacing-md, 12px);
  font-size: var(--flare-size-font-size-sm, 12px);
  color: var(--flare-color-text-tertiary);
}
.flare-mrs__row {
  display: grid;
  grid-template-columns: 44px minmax(0, 1fr) auto;
  align-items: center;
  gap: var(--flare-size-spacing-md, 12px);
  width: 100%;
  min-height: var(--flare-size-layout-touch-target, 48px);
  padding: var(--flare-size-spacing-sm, 8px) var(--flare-size-spacing-md, 12px);
  border: 0;
  border-radius: var(--flare-size-radius-xl, 14px);
  background: transparent;
  color: inherit;
  cursor: pointer;
  font: inherit;
  text-align: start;
}
.flare-mrs__row:hover:not(:disabled),
.flare-mrs__row:active:not(:disabled) { background: var(--flare-color-bg-hover); }
.flare-mrs__row:focus-visible {
  outline: 2px solid var(--flare-color-focus-ring, var(--flare-color-primary));
  outline-offset: -2px;
  background: var(--flare-color-bg-hover);
}
.flare-mrs__row:disabled { color: var(--flare-color-text-disabled); cursor: default; }
.flare-mrs__icon {
  display: grid;
  place-items: center;
  width: 44px;
  height: 44px;
  border-radius: var(--flare-size-radius-full, 999px);
  color: var(--flare-color-primary);
  background: color-mix(in srgb, var(--flare-color-primary) 10%, var(--flare-color-bg-primary));
}
.flare-mrs__row:disabled .flare-mrs__icon {
  color: var(--flare-color-text-disabled);
  background: var(--flare-color-bg-disabled);
}
.flare-mrs__label {
  font-size: var(--flare-size-font-size-2xl, 16px);
  font-weight: 600;
  line-height: var(--flare-size-line-height-tight, 1.2);
  overflow-wrap: anywhere;
}
.flare-mrs__chevron { display: grid; place-items: center; color: var(--flare-color-text-tertiary); }
.flare-mrs__durations {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  padding: var(--flare-size-spacing-xs, 4px) var(--flare-size-spacing-md, 12px) var(--flare-size-spacing-sm, 8px) 56px;
}
.flare-mrs__duration {
  min-height: 40px;
  padding: 0 12px;
  border: 1px solid var(--flare-color-border-primary);
  border-radius: var(--flare-size-radius-md, 8px);
  background: var(--flare-color-bg-secondary);
  color: var(--flare-color-text-primary);
  font: inherit;
  font-size: var(--flare-size-font-size-md, 13px);
  cursor: pointer;
}
@media (pointer: coarse) {
  .flare-mrs__duration { min-height: var(--flare-size-layout-touch-target, 48px); }
}
.flare-mrs__duration:hover:not(:disabled) { background: var(--flare-color-bg-hover); }
.flare-mrs__duration:disabled { opacity: 0.5; cursor: default; }
.flare-mrs__duration:focus-visible {
  outline: 2px solid var(--flare-color-focus-ring, var(--flare-color-primary));
  outline-offset: 2px;
}
.flare-mrs__row--danger:not(:disabled),
.flare-mrs__row--danger:not(:disabled) .flare-mrs__icon { color: var(--flare-color-error); }
.flare-mrs__row--danger:not(:disabled) .flare-mrs__icon {
  background: color-mix(in srgb, var(--flare-color-error) 12%, var(--flare-color-bg-primary));
}
</style>
