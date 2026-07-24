<script setup lang="ts">
/**
 * Group detail / management — hero, member grid, and Feishu-style settings:
 * 群信息 / 我在本群 / 群管理 / 群权限 (owner-admin gated), plus member actions,
 * join-request approval, invite picker and invite link. Purely presentational —
 * it renders the `model` and emits intents; the host performs social.group.*
 * writes and refreshes the model.
 */
import { computed, ref } from "vue";
import FlareAvatar from "../conversation/FlareAvatar.vue";
import FlareGroupMemberGrid from "./FlareGroupMemberGrid.vue";
import FlareSettingsList from "../profile/FlareSettingsList.vue";
import FlareBottomSheet from "../general/FlareBottomSheet.vue";
import FlareButton from "../general/FlareButton.vue";
import FlareInput from "../general/FlareInput.vue";
import FlareEmptyState from "../general/FlareEmptyState.vue";
import FlareCheckbox from "../form/FlareCheckbox.vue";
import FlareRadioGroup from "../form/FlareRadioGroup.vue";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import type {
  FlareContact,
  FlareGroupDetailModel,
  FlareGroupJoinRequestView,
  FlareSettingsItem,
  FlareSettingsSection,
} from "../../shared/contracts";

const JOIN_OPEN = 3;
const JOIN_APPROVAL = 2;
const JOIN_INVITE = 1;

const props = defineProps<{
  model: FlareGroupDetailModel | null;
  loading?: boolean;
  joinRequests?: FlareGroupJoinRequestView[];
  loadingJoinRequests?: boolean;
  inviteCode?: string;
  loadingInviteLink?: boolean;
  /** Friends the viewer can add to the group (already-members filtered out by the host or here). */
  invitableContacts?: FlareContact[];
}>();
const emit = defineEmits<{
  (e: "back"): void;
  (e: "openChat", payload: { userIds: string[]; name: string }): void;
  (e: "updateName", value: string): void;
  (e: "updateAnnouncement", value: string): void;
  (e: "updateMyNickname", value: string): void;
  (e: "setJoinPolicy", value: number): void;
  (e: "toggleMuteAll", value: boolean): void;
  (e: "setFlag", key: "onlyAdminCanAtAll" | "onlyAdminCanPin" | "shareCardPermission", value: boolean): void;
  (e: "toggleMyMuted", value: boolean): void;
  (e: "toggleMyPinned", value: boolean): void;
  (e: "loadJoinRequests"): void;
  (e: "respondRequest", requestId: string, accept: boolean): void;
  (e: "ensureInviteLink"): void;
  (e: "promoteMember", userId: string): void;
  (e: "muteMember", userId: string): void;
  (e: "transferOwner", userId: string): void;
  (e: "removeMember", userId: string): void;
  (e: "loadContacts"): void;
  (e: "inviteMembers", userIds: string[]): void;
  (e: "leave"): void;
}>();

const { t } = useFlareI18n();
const model = computed(() => props.model);
const canManage = computed(() => model.value?.canManage ?? false);
const groupName = computed(() => model.value?.name || t("group.title"));
const requests = computed(() => props.joinRequests ?? []);

const JOIN_POLICY_LABEL: Record<number, string> = {
  [JOIN_OPEN]: t("group.joinOpen"),
  [JOIN_APPROVAL]: t("group.joinApproval"),
  [JOIN_INVITE]: t("group.joinInvite"),
};
const joinPolicyLabel = computed(() => JOIN_POLICY_LABEL[model.value?.joinPolicy ?? JOIN_OPEN] ?? t("group.joinOpen"));

const settingsSections = computed<FlareSettingsSection[]>(() => {
  const m = model.value;
  if (!m) return [];
  const sections: FlareSettingsSection[] = [
    {
      title: t("group.info"),
      items: [
        { key: "name", label: t("group.name"), icon: "tag", kind: "value", detail: m.name || "-" },
        { key: "announcement", label: t("group.announcement"), icon: "announcement", kind: "value", detail: m.announcement || t("group.notSet") },
        { key: "members", label: t("group.members"), icon: "people", kind: "value", detail: t("group.memberCount", { count: m.memberCount }) },
      ],
    },
    {
      title: t("group.myInGroup"),
      items: [
        { key: "myNickname", label: t("group.myNickname"), icon: "edit", kind: "value", detail: m.myNickname || t("group.notSet") },
        { key: "notif", label: t("group.muteNotif"), icon: "notification", kind: "toggle", value: m.myMuted },
        { key: "pin", label: t("group.pinGroup"), icon: "pin", kind: "toggle", value: m.myPinned },
      ],
    },
  ];
  if (m.canManage) {
    sections.push({
      title: t("group.manage"),
      items: [
        { key: "joinPolicy", label: t("group.joinMode"), icon: "lock", kind: "value", detail: joinPolicyLabel.value },
        { key: "joinRequests", label: t("group.joinRequests"), icon: "person", kind: "navigation", badge: requests.value.length || undefined },
        { key: "muteAll", label: t("group.muteAll"), icon: "mute", kind: "toggle", value: m.muteAll },
        { key: "inviteLink", label: t("group.inviteLink"), icon: "link", kind: "navigation" },
      ],
    });
    sections.push({
      title: t("group.perms"),
      items: [
        { key: "atAll", label: t("group.onlyAdminAtAll"), icon: "people", kind: "toggle", value: m.onlyAdminCanAtAll },
        { key: "pinPerm", label: t("group.onlyAdminPin"), icon: "pin", kind: "toggle", value: m.onlyAdminCanPin },
        { key: "shareCard", label: t("group.shareCard"), icon: "share", kind: "toggle", value: m.shareCardPermission },
      ],
    });
  }
  return sections;
});

// ── Edit name / announcement / nickname ─────────────────────────────────────
const editKind = ref<"name" | "announcement" | "nickname" | null>(null);
const editDraft = ref("");
const editMeta = computed(() => {
  switch (editKind.value) {
    case "announcement": return { title: t("group.editAnnouncement"), placeholder: t("group.announcement"), max: 200, multiline: true };
    case "nickname": return { title: t("group.myNickname"), placeholder: t("group.nicknamePlaceholder"), max: 20, multiline: false };
    default: return { title: t("group.editName"), placeholder: t("group.name"), max: 30, multiline: false };
  }
});
function saveEdit() {
  const v = editDraft.value.trim();
  if (editKind.value === "name") emit("updateName", v);
  else if (editKind.value === "announcement") emit("updateAnnouncement", v);
  else if (editKind.value === "nickname") emit("updateMyNickname", v);
  editKind.value = null;
}

function onSettingSelect(item: FlareSettingsItem) {
  if (item.key === "myNickname") {
    editKind.value = "nickname";
    editDraft.value = model.value?.myNickname || "";
    return;
  }
  if (!canManage.value) return;
  if (item.key === "name") {
    editKind.value = "name";
    editDraft.value = model.value?.name || "";
  } else if (item.key === "announcement") {
    editKind.value = "announcement";
    editDraft.value = model.value?.announcement || "";
  } else if (item.key === "joinPolicy") {
    policyDraft.value = String(model.value?.joinPolicy ?? JOIN_OPEN);
    policyOpen.value = true;
  } else if (item.key === "joinRequests") {
    emit("loadJoinRequests");
    requestsOpen.value = true;
  } else if (item.key === "inviteLink") {
    emit("ensureInviteLink");
    inviteLinkOpen.value = true;
  }
}
function onSettingToggle(item: FlareSettingsItem, value: boolean) {
  if (item.key === "notif") return emit("toggleMyMuted", value);
  if (item.key === "pin") return emit("toggleMyPinned", value);
  if (!canManage.value) return;
  if (item.key === "muteAll") emit("toggleMuteAll", value);
  else if (item.key === "atAll") emit("setFlag", "onlyAdminCanAtAll", value);
  else if (item.key === "pinPerm") emit("setFlag", "onlyAdminCanPin", value);
  else if (item.key === "shareCard") emit("setFlag", "shareCardPermission", value);
}

// ── Join policy ─────────────────────────────────────────────────────────────
const policyOpen = ref(false);
const policyDraft = ref<string>(String(JOIN_OPEN));
const policyOptions = computed(() => [
  { value: String(JOIN_OPEN), label: t("group.joinOpen") },
  { value: String(JOIN_APPROVAL), label: t("group.joinApproval") },
  { value: String(JOIN_INVITE), label: t("group.joinInvite") },
]);
function savePolicy() {
  emit("setJoinPolicy", Number(policyDraft.value));
  policyOpen.value = false;
}

// ── Join requests ───────────────────────────────────────────────────────────
const requestsOpen = ref(false);

// ── Invite link ─────────────────────────────────────────────────────────────
const inviteLinkOpen = ref(false);
const copied = ref(false);
async function copyInviteCode() {
  const code = props.inviteCode;
  if (!code) return;
  try {
    await navigator.clipboard.writeText(code);
    copied.value = true;
    setTimeout(() => (copied.value = false), 1600);
  } catch {
    /* clipboard blocked */
  }
}

// ── Member actions ──────────────────────────────────────────────────────────
const memberSheet = ref<string | null>(null);
const memberIsAdmin = (id: string) => model.value?.adminIds.includes(id) ?? false;
const memberIsMuted = (id: string) => model.value?.mutedIds.includes(id) ?? false;
function onMemberSelect(id: string) {
  if (!canManage.value) return;
  if (id === model.value?.ownerId) return;
  memberSheet.value = id;
}
function actRole() {
  if (memberSheet.value) emit("promoteMember", memberSheet.value);
  memberSheet.value = null;
}
function actMute() {
  if (memberSheet.value) emit("muteMember", memberSheet.value);
  memberSheet.value = null;
}
function actRemove() {
  if (memberSheet.value) emit("removeMember", memberSheet.value);
  memberSheet.value = null;
}
const transferTarget = ref<string | null>(null);
const transferName = computed(() => model.value?.members.find((m) => m.id === transferTarget.value)?.name || "");
function askTransfer() {
  transferTarget.value = memberSheet.value;
  memberSheet.value = null;
}
function confirmTransfer() {
  if (transferTarget.value) emit("transferOwner", transferTarget.value);
  transferTarget.value = null;
}

// ── Invite members ──────────────────────────────────────────────────────────
const inviteOpen = ref(false);
const invitePicked = ref<Set<string>>(new Set());
function openInvite() {
  invitePicked.value = new Set();
  emit("loadContacts");
  inviteOpen.value = true;
}
function toggleInvite(id: string, on: boolean) {
  const next = new Set(invitePicked.value);
  if (on) next.add(id);
  else next.delete(id);
  invitePicked.value = next;
}
const memberIdSet = computed(() => new Set(model.value?.members.map((m) => m.id) ?? []));
const invitable = computed(() => (props.invitableContacts ?? []).filter((c) => !memberIdSet.value.has(c.id)));
function submitInvite() {
  const ids = [...invitePicked.value];
  if (!ids.length) return;
  emit("inviteMembers", ids);
  inviteOpen.value = false;
}
</script>

<template>
  <div class="flare-group-detail">
    <FlareEmptyState
      v-if="!model && !loading"
      class="flare-group-detail__empty"
      icon="people"
      :title="t('group.unavailable')"
      :description="t('group.unavailableHint')"
    />

    <template v-else-if="model">
      <div class="flare-group-detail__hero">
        <FlareAvatar :user-id="model.groupId" :display-name="groupName" :avatar-url="model.avatarUrl || undefined" :size="72" />
        <div class="flare-group-detail__title">{{ groupName }}</div>
      </div>

      <FlareGroupMemberGrid
        :members="model.members"
        :owner-id="model.ownerId"
        :admin-ids="model.adminIds"
        :show-add="canManage"
        @select="onMemberSelect"
        @add-member="openInvite"
      />

      <FlareSettingsList :sections="settingsSections" @select="onSettingSelect" @toggle="onSettingToggle" />

      <div class="flare-group-detail__foot">
        <FlareButton block @click="emit('openChat', { userIds: model.members.map((m) => m.id), name: groupName })">
          {{ t("group.message") }}
        </FlareButton>
        <FlareButton variant="danger" block @click="emit('leave')">
          {{ model.isOwner ? t("group.dissolve") : t("group.leave") }}
        </FlareButton>
      </div>
    </template>

    <!-- Edit name / announcement / nickname -->
    <FlareBottomSheet :open="editKind !== null" :title="editMeta.title" @close="editKind = null">
      <div class="flare-group-detail__sheet">
        <FlareInput v-model="editDraft" :multiline="editMeta.multiline" :placeholder="editMeta.placeholder" :max-length="editMeta.max" />
        <div class="flare-group-detail__sheet-actions">
          <FlareButton variant="secondary" @click="editKind = null">{{ t("group.cancel") }}</FlareButton>
          <FlareButton @click="saveEdit">{{ t("group.save") }}</FlareButton>
        </div>
      </div>
    </FlareBottomSheet>

    <!-- Member management -->
    <FlareBottomSheet :open="memberSheet !== null" :title="t('group.memberManage')" @close="memberSheet = null">
      <div class="flare-group-detail__sheet flare-group-detail__member-actions">
        <FlareButton variant="secondary" block @click="actRole">
          {{ memberSheet && memberIsAdmin(memberSheet) ? t("group.unsetAdmin") : t("group.setAdmin") }}
        </FlareButton>
        <FlareButton variant="secondary" block @click="actMute">
          {{ memberSheet && memberIsMuted(memberSheet) ? t("group.unmute") : t("group.mute") }}
        </FlareButton>
        <FlareButton v-if="model?.isOwner" variant="secondary" block @click="askTransfer">{{ t("group.transferOwner") }}</FlareButton>
        <FlareButton variant="danger" block @click="actRemove">{{ t("group.removeMember") }}</FlareButton>
      </div>
    </FlareBottomSheet>

    <!-- Transfer owner confirm -->
    <FlareBottomSheet :open="transferTarget !== null" :title="t('group.transferOwner')" @close="transferTarget = null">
      <div class="flare-group-detail__sheet">
        <p class="flare-group-detail__confirm">{{ t("group.transferConfirm", { name: transferName }) }}</p>
        <div class="flare-group-detail__sheet-actions">
          <FlareButton variant="secondary" @click="transferTarget = null">{{ t("group.cancel") }}</FlareButton>
          <FlareButton variant="danger" @click="confirmTransfer">{{ t("group.confirmTransfer") }}</FlareButton>
        </div>
      </div>
    </FlareBottomSheet>

    <!-- Invite members -->
    <FlareBottomSheet :open="inviteOpen" :title="t('group.invite')" max-height="80vh" @close="inviteOpen = false">
      <div class="flare-group-detail__sheet">
        <div class="flare-group-detail__list">
          <div v-for="c in invitable" :key="c.id" class="flare-group-detail__row" @click="toggleInvite(c.id, !invitePicked.has(c.id))">
            <FlareAvatar :user-id="c.id" :display-name="c.name" :avatar-url="c.avatarUrl" :size="36" />
            <span class="flare-group-detail__row-name">{{ c.name }}</span>
            <FlareCheckbox :model-value="invitePicked.has(c.id)" style="pointer-events: none" />
          </div>
          <div v-if="!invitable.length" class="flare-group-detail__empty-row">{{ t("group.inviteEmpty") }}</div>
        </div>
        <div class="flare-group-detail__sheet-actions">
          <FlareButton variant="secondary" @click="inviteOpen = false">{{ t("group.cancel") }}</FlareButton>
          <FlareButton :disabled="!invitePicked.size" @click="submitInvite">{{ t("group.invite") }}</FlareButton>
        </div>
      </div>
    </FlareBottomSheet>

    <!-- Join policy -->
    <FlareBottomSheet :open="policyOpen" :title="t('group.joinMode')" @close="policyOpen = false">
      <div class="flare-group-detail__sheet">
        <FlareRadioGroup v-model="policyDraft" :options="policyOptions" />
        <div class="flare-group-detail__sheet-actions">
          <FlareButton variant="secondary" @click="policyOpen = false">{{ t("group.cancel") }}</FlareButton>
          <FlareButton @click="savePolicy">{{ t("group.save") }}</FlareButton>
        </div>
      </div>
    </FlareBottomSheet>

    <!-- Join requests -->
    <FlareBottomSheet :open="requestsOpen" :title="t('group.joinRequests')" max-height="80vh" @close="requestsOpen = false">
      <div class="flare-group-detail__sheet">
        <div v-if="loadingJoinRequests" class="flare-group-detail__empty-row">{{ t("group.loading") }}</div>
        <div v-else-if="!requests.length" class="flare-group-detail__empty-row">{{ t("group.noRequests") }}</div>
        <div v-else class="flare-group-detail__list">
          <div v-for="r in requests" :key="r.requestId" class="flare-group-detail__req">
            <FlareAvatar :user-id="r.applicantId" :display-name="r.applicantName" :avatar-url="r.avatarUrl" :size="36" />
            <div class="flare-group-detail__req-info">
              <span class="flare-group-detail__row-name">{{ r.applicantName }}</span>
              <span v-if="r.message" class="flare-group-detail__req-msg">{{ r.message }}</span>
            </div>
            <div class="flare-group-detail__req-actions">
              <FlareButton size="sm" variant="secondary" @click="emit('respondRequest', r.requestId, false)">{{ t("group.reject") }}</FlareButton>
              <FlareButton size="sm" @click="emit('respondRequest', r.requestId, true)">{{ t("group.approve") }}</FlareButton>
            </div>
          </div>
        </div>
      </div>
    </FlareBottomSheet>

    <!-- Invite link -->
    <FlareBottomSheet :open="inviteLinkOpen" :title="t('group.inviteLink')" @close="inviteLinkOpen = false">
      <div class="flare-group-detail__sheet">
        <p class="flare-group-detail__confirm">{{ t("group.inviteLinkHint") }}</p>
        <div v-if="loadingInviteLink" class="flare-group-detail__empty-row">{{ t("group.generating") }}</div>
        <template v-else-if="inviteCode">
          <div class="flare-group-detail__code">{{ inviteCode }}</div>
          <div class="flare-group-detail__sheet-actions">
            <FlareButton block @click="copyInviteCode">{{ copied ? t("group.copied") : t("group.copyCode") }}</FlareButton>
          </div>
        </template>
        <div v-else class="flare-group-detail__empty-row">{{ t("group.cannotGenerate") }}</div>
      </div>
    </FlareBottomSheet>
  </div>
</template>

<style scoped>
.flare-group-detail { display: flex; flex-direction: column; }
.flare-group-detail__empty { margin: 40px auto; }
.flare-group-detail__hero { display: flex; flex-direction: column; align-items: center; gap: 10px; padding: 20px 16px 8px; }
.flare-group-detail__title { font-size: 18px; font-weight: 600; color: var(--flare-color-text-primary); }
.flare-group-detail__foot { display: flex; flex-direction: column; gap: 10px; padding: 16px; }
.flare-group-detail__sheet { padding: 8px 12px 16px; display: flex; flex-direction: column; gap: 14px; }
.flare-group-detail__sheet-actions { display: flex; gap: 12px; }
.flare-group-detail__sheet-actions > * { flex: 1; }
.flare-group-detail__member-actions { gap: 10px; }
.flare-group-detail__confirm { margin: 0; color: var(--flare-color-text-secondary); font-size: 14px; line-height: 1.6; }
.flare-group-detail__list { max-height: 46vh; overflow-y: auto; border-radius: var(--flare-size-radius-lg, 10px); background: var(--flare-color-bg-secondary); }
.flare-group-detail__row { display: flex; align-items: center; gap: 12px; padding: 8px 12px; cursor: pointer; }
.flare-group-detail__row-name { flex: 1; min-width: 0; color: var(--flare-color-text-primary); }
.flare-group-detail__empty-row { padding: 20px; text-align: center; color: var(--flare-color-text-tertiary); font-size: 13px; }
.flare-group-detail__req { display: flex; align-items: center; gap: 12px; padding: 10px 12px; }
.flare-group-detail__req-info { flex: 1; min-width: 0; display: flex; flex-direction: column; gap: 2px; }
.flare-group-detail__req-msg { font-size: 12px; color: var(--flare-color-text-tertiary); overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.flare-group-detail__req-actions { display: flex; gap: 8px; flex-shrink: 0; }
.flare-group-detail__code { padding: 14px 16px; border-radius: var(--flare-size-radius-lg, 12px); background: var(--flare-color-bg-secondary); text-align: center; font-size: 18px; font-weight: 700; letter-spacing: 0.08em; color: var(--flare-color-text-primary); word-break: break-all; }
</style>
