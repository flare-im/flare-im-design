<script setup lang="ts">
/**
 * Group detail / management — hero, member grid, and Feishu-style settings:
 * 群信息 / 我在本群 / 群管理 / 群权限 (owner-admin gated), plus member actions,
 * join-request approval, invite picker and invite link. Purely presentational —
 * it renders the `model` and emits intents; the host performs social.group.*
 * writes and refreshes the model.
 */
import { flareIcons } from "../../shared/icons";
import { computed, getCurrentInstance, ref, watch } from "vue";
import { NIcon } from "naive-ui";
import FlareAvatar from "../conversation/FlareAvatar.vue";
import FlareGroupMemberGrid from "./FlareGroupMemberGrid.vue";
import FlareSettingsList from "../profile/FlareSettingsList.vue";
import FlareBottomSheet from "../general/FlareBottomSheet.vue";
import FlareFormSheet from "../general/FlareFormSheet.vue";
import FlareButton from "../general/FlareButton.vue";
import FlareInput from "../general/FlareInput.vue";
import FlareEmptyState from "../general/FlareEmptyState.vue";
import FlareSearchBar from "../general/FlareSearchBar.vue";
import FlareContactList from "./FlareContactList.vue";
import FlareRadioGroup from "../form/FlareRadioGroup.vue";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";
import type {
  FlareContact,
  FlareDetailExtraAction,
  FlareGroupDetailModel,
  FlareGroupJoinRequestView,
  FlareSettingsItem,
  FlareSettingsSection,
} from "../../shared/contracts";
import { groupJoinPolicies, type FlareGroupJoinPolicy } from "../../shared/contracts/group-permissions";

const props = defineProps<{
  model: FlareGroupDetailModel | null;
  loading?: boolean;
  /** Await host persistence before closing; rejection keeps the editor draft. */
  submitEdit?: (kind: "name" | "announcement" | "nickname", value: string) => Promise<void>;
  joinRequests?: FlareGroupJoinRequestView[];
  loadingJoinRequests?: boolean;
  inviteCode?: string;
  loadingInviteLink?: boolean;
  /** Host-backed member search state. Without a listener, the component filters the loaded members locally. */
  memberSearchLoading?: boolean;
  memberSearchError?: string;
  /** Host actions the kit cannot know about (report, an admin tool); drawn above leaving the group. */
  extraActions?: FlareDetailExtraAction[];
  /** Friends the viewer can add to the group (already-members filtered out by the host or here). */
  invitableContacts?: FlareContact[];
}>();
const emit = defineEmits<{
  (e: "back"): void;
  /** Positional `(userIds, name)` — same order as the Flutter / iOS / Compose `onOpenChat`. */
  (e: "openChat", userIds: string[], name: string): void;
  (e: "updateName", value: string): void;
  (e: "updateAnnouncement", value: string): void;
  (e: "updateMyNickname", value: string): void;
  (e: "setJoinPolicy", policy: FlareGroupJoinPolicy): void;
  (e: "toggleDiscoverable", value: boolean): void;
  (e: "toggleMuteAll", value: boolean): void;
  (e: "setFlag", key: "onlyAdminCanAtAll" | "onlyAdminCanPin" | "shareCardPermission", value: boolean): void;
  (e: "toggleMyMuted", value: boolean): void;
  (e: "toggleMyPinned", value: boolean): void;
  (e: "loadJoinRequests"): void;
  (e: "respondRequest", requestId: string, accept: boolean): void;
  (e: "ensureInviteLink"): void;
  /** `admin` is the role the member should have after the change: true sets admin, false revokes it. */
  (e: "promoteMember", userId: string, admin: boolean): void;
  /** `muted` is the state the member should have after the change. */
  (e: "muteMember", userId: string, muted: boolean): void;
  (e: "transferOwner", userId: string): void;
  (e: "removeMember", userId: string): void;
  (e: "loadContacts"): void;
  (e: "inviteMembers", userIds: string[]): void;
  (e: "searchMembers", query: string): void;
  (e: "leave"): void;
  /** One of `extraActions` was chosen; the payload is its id. */
  (e: "extraAction", id: string): void;
}>();

const { t } = useFlareI18n();
const instance = getCurrentInstance();
// The message button exists only when the host opens the chat (not inside the chat's own settings).
const canOpenChat = computed(() => Boolean(instance?.vnode.props?.onOpenChat));
const hasHostMemberSearch = computed(() => Boolean(instance?.vnode.props?.onSearchMembers));
// My nickname is editable when the host persists it, through `submitEdit` or the `updateMyNickname` event.
const canEditNickname = (): boolean => Boolean(props.submitEdit || instance?.vnode.props?.onUpdateMyNickname);
const model = computed(() => props.model);
const canManage = computed(() => model.value?.canManage ?? false);
const groupName = computed(() => model.value?.name || t("group.title"));
const requests = computed(() => props.joinRequests ?? []);

const joinPolicyLabels = computed<Record<FlareGroupJoinPolicy, string>>(() => ({
  open: t("group.joinOpen"),
  approval: t("group.joinApproval"),
  invite: t("group.joinInvite"),
}));
// An unknown policy reads "not set" instead of a guessed default.
const joinPolicyLabel = computed(() => {
  const policy = model.value?.joinPolicy;
  return policy ? joinPolicyLabels.value[policy] : t("group.notSet");
});

const settingsSections = computed<FlareSettingsSection[]>(() => {
  const m = model.value;
  if (!m) return [];
  const sections: FlareSettingsSection[] = [
    {
      title: t("group.info"),
      items: [
        // 群名称与群成员不在这里：它们已经分别由 hero 的标题和成员栅格的头部承担 ——
        // 名字在同一屏上写两遍、人数在同一屏上写两遍，是同一件事说两次，不是两条信息。
        // Rows the viewer can change open their editor and carry a chevron; the rest read as values.
        { key: "announcement", label: t("group.announcement"), icon: "announcement", kind: m.canManage ? "navigation" : "value", detail: m.announcement || t("group.notSet") },
      ],
    },
    {
      title: t("group.myInGroup"),
      items: [
        { key: "myNickname", label: t("group.myNickname"), icon: "edit", kind: canEditNickname() ? "navigation" : "value", detail: m.myNickname || t("group.notSet") },
        // A setting that could not be read claims neither state.
        m.myMuted === null
          ? { key: "notif", label: t("group.muteNotif"), icon: "mute", kind: "value", detail: t("group.settingUnavailable") }
          : { key: "notif", label: t("group.muteNotif"), icon: "mute", kind: "toggle", value: m.myMuted },
        m.myPinned === null
          ? { key: "pin", label: t("group.pinGroup"), icon: "pin", kind: "value", detail: t("group.settingUnavailable") }
          : { key: "pin", label: t("group.pinGroup"), icon: "pin", kind: "toggle", value: m.myPinned },
      ],
    },
  ];
  if (m.canManage) {
    sections.push({
      title: t("group.manage"),
      items: [
        { key: "discoverable", label: t("group.discoverable"), icon: "search", kind: "toggle", value: m.discoverable },
        { key: "joinPolicy", label: t("group.joinMode"), icon: "lock", kind: "navigation", detail: joinPolicyLabel.value },
        { key: "joinRequests", label: t("group.joinRequests"), icon: "join-request", kind: "navigation", badge: requests.value.length || undefined },
        { key: "muteAll", label: t("group.muteAll"), icon: "silence", kind: "toggle", value: m.muteAll },
        { key: "inviteLink", label: t("group.inviteLink"), icon: "link", kind: "navigation" },
      ],
    });
    sections.push({
      title: t("group.perms"),
      items: [
        { key: "atAll", label: t("group.onlyAdminAtAll"), icon: "mention", kind: "toggle", value: m.onlyAdminCanAtAll },
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
const editBusy = ref(false);
const editError = ref("");
watch(editKind, () => { editError.value = ""; });
const editMeta = computed(() => {
  switch (editKind.value) {
    case "announcement": return { title: t("group.editAnnouncement"), placeholder: t("group.announcement"), max: 200, multiline: true };
    case "nickname": return { title: t("group.myNickname"), placeholder: t("group.nicknamePlaceholder"), max: 20, multiline: false };
    default: return { title: t("group.editName"), placeholder: t("group.name"), max: 30, multiline: false };
  }
});
async function saveEdit() {
  const kind = editKind.value;
  const v = editDraft.value.trim();
  if (!kind || editBusy.value || (kind === "name" && !v)) return;
  editBusy.value = true;
  editError.value = "";
  try {
    if (props.submitEdit) await props.submitEdit(kind, v);
    else if (kind === "name") emit("updateName", v);
    else if (kind === "announcement") emit("updateAnnouncement", v);
    else emit("updateMyNickname", v);
    editKind.value = null;
  } catch (error) {
    editError.value = error instanceof Error ? error.message : t("common.operationFailed");
  } finally {
    editBusy.value = false;
  }
}

/** 完整成员名单 —— 从成员栅格的头部进去（原来是设置列表里的「群成员」行）。 */
function openRoster() {
  memberQuery.value = "";
  membersOpen.value = true;
}
/** 改群名 —— 从 hero 的标题进去（原来是设置列表里的「群名称」行）。 */
function openRename() {
  if (!canManage.value) return;
  editKind.value = "name";
  editDraft.value = model.value?.name || "";
}

function onSettingSelect(item: FlareSettingsItem) {
  if (item.key === "myNickname") {
    if (!canEditNickname()) return;
    editKind.value = "nickname";
    editDraft.value = model.value?.myNickname || "";
    return;
  }
  if (!canManage.value) return;
  if (item.key === "announcement") {
    editKind.value = "announcement";
    editDraft.value = model.value?.announcement || "";
  } else if (item.key === "joinPolicy") {
    policyDraft.value = model.value?.joinPolicy ?? "";
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
  if (item.key === "discoverable") emit("toggleDiscoverable", value);
  else if (item.key === "muteAll") emit("toggleMuteAll", value);
  else if (item.key === "atAll") emit("setFlag", "onlyAdminCanAtAll", value);
  else if (item.key === "pinPerm") emit("setFlag", "onlyAdminCanPin", value);
  else if (item.key === "shareCard") emit("setFlag", "shareCardPermission", value);
}

// ── Join policy ─────────────────────────────────────────────────────────────
const policyOpen = ref(false);
// Empty until the viewer picks one when the host does not know the current policy.
const policyDraft = ref<FlareGroupJoinPolicy | "">("");
const policyOptions = computed(() => groupJoinPolicies.map((value) => ({ value, label: joinPolicyLabels.value[value] })));
function savePolicy() {
  if (!policyDraft.value) return;
  emit("setJoinPolicy", policyDraft.value);
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

// ── Members: the grid previews the first rows; the members row opens everyone with search ──
/** Cells in the preview grid, the add tile included: four rows of five. */
const MEMBER_PREVIEW_CELLS = 20;
const previewMembers = computed(() => {
  const members = model.value?.members ?? [];
  return members.slice(0, canManage.value ? MEMBER_PREVIEW_CELLS - 1 : MEMBER_PREVIEW_CELLS);
});
const membersOpen = ref(false);
const memberQuery = ref("");
watch(memberQuery, (query) => {
  if (hasHostMemberSearch.value) emit("searchMembers", query);
});
const matchingMembers = computed(() => {
  const query = memberQuery.value.trim().toLocaleLowerCase();
  const members = model.value?.members ?? [];
  if (hasHostMemberSearch.value) return members;
  return query ? members.filter((member) => member.name.toLocaleLowerCase().includes(query)) : members;
});
function onMemberListSelect(member: FlareContact) {
  if (!canManage.value || member.id === model.value?.ownerId) return;
  membersOpen.value = false;
  memberSheet.value = member.id;
}
// Each intent carries the state the viewer asked for — the one its button named — so a host
// never re-derives the direction from data that may have changed since the sheet opened.
function actRole() {
  const id = memberSheet.value;
  if (id) emit("promoteMember", id, !memberIsAdmin(id));
  memberSheet.value = null;
}
function actMute() {
  const id = memberSheet.value;
  if (id) emit("muteMember", id, !memberIsMuted(id));
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
const invitePickedIds = computed(() => [...invitePicked.value]);
function toggleInvite(id: string) {
  const next = new Set(invitePicked.value);
  if (!next.delete(id)) next.add(id);
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
    <FlareEmptyState v-if="!model && loading" class="flare-group-detail__empty" loading :title="t('group.loading')" />
    <FlareEmptyState
      v-else-if="!model"
      class="flare-group-detail__empty"
      icon="people"
      :title="t('group.unavailable')"
      :description="t('group.unavailableHint')"
    />

    <template v-else-if="model">
      <div class="flare-group-detail__hero">
        <FlareAvatar :user-id="model.groupId" :display-name="groupName" :avatar-url="model.avatarUrl || undefined" :size="72" />
        <!-- 标题本身就是改名入口（管理员）。原来标题下面还有一行「群名称 Team ›」，
             同一个名字在同一屏上写两遍；现在名字只有这一处，改名从它进去。 -->
        <component
          :is="canManage ? 'button' : 'div'"
          :type="canManage ? 'button' : undefined"
          class="flare-group-detail__title"
          :class="{ 'is-interactive': canManage }"
          @click="canManage && openRename()"
        >
          <span class="flare-group-detail__title-text">{{ groupName }}</span>
          <!-- 名字是这个按钮的名字,用途挂在铅笔上 —— 把 aria-label 放在外层会顶掉里面的文字,
               而群名现在只有这一处,顶掉就等于读屏里再也读不到这个群叫什么。 -->
          <span
            v-if="canManage"
            class="flare-group-detail__title-edit"
            role="img"
            :aria-label="t('group.editName')"
          >
            <n-icon aria-hidden="true" :size="16" :component="flareIcons['edit']" />
          </span>
        </component>
      </div>

      <FlareGroupMemberGrid
        :members="previewMembers"
        :total="model.memberCount"
        :owner-id="model.ownerId"
        :admin-ids="model.adminIds"
        :show-add="canManage"
        @select="onMemberSelect"
        @add-member="openInvite"
        @view-all="openRoster"
      />

      <!-- Host content that belongs with the group information (an announcement read bar) goes right after that section. -->
      <template v-if="$slots['after-info']">
        <FlareSettingsList :sections="settingsSections.slice(0, 1)" @select="onSettingSelect" @toggle="onSettingToggle" />
        <div class="flare-group-detail__slot">
          <slot name="after-info" />
        </div>
        <FlareSettingsList :sections="settingsSections.slice(1)" @select="onSettingSelect" @toggle="onSettingToggle" />
      </template>
      <FlareSettingsList v-else :sections="settingsSections" @select="onSettingSelect" @toggle="onSettingToggle" />

      <div class="flare-group-detail__foot">
        <FlareButton v-if="canOpenChat" block @click="emit('openChat', model.members.map((m) => m.id), groupName)">
          {{ t("group.message") }}
        </FlareButton>
        <FlareButton
          v-for="action in extraActions ?? []"
          :key="action.id"
          block
          :variant="action.danger ? 'danger' : 'secondary'"
          @click="emit('extraAction', action.id)"
        >{{ action.label }}</FlareButton>
        <FlareButton variant="danger" block @click="emit('leave')">
          {{ model.isOwner ? t("group.dissolve") : t("group.leave") }}
        </FlareButton>
      </div>
      <div v-if="$slots.footer" class="flare-group-detail__footer">
        <slot name="footer" />
      </div>
    </template>

    <!-- Edit name / announcement / nickname -->
    <FlareFormSheet :open="editKind !== null" :title="editMeta.title" :busy="editBusy"
      :error="editError" :confirm-disabled="editKind === 'name' && !editDraft.trim()"
      :confirm-label="t('group.save')" :cancel-label="t('group.cancel')"
      @close="editKind = null" @confirm="saveEdit">
      <FlareInput v-model="editDraft" :multiline="editMeta.multiline" :placeholder="editMeta.placeholder" :max-length="editMeta.max" />
    </FlareFormSheet>

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

    <!-- All members -->
    <FlareBottomSheet :open="membersOpen" :title="t('group.membersTitle', { count: model?.memberCount ?? 0 })" max-height="80vh" @close="membersOpen = false">
      <div class="flare-group-detail__sheet">
        <FlareSearchBar v-model="memberQuery" :placeholder="t('group.searchMembers')" :loading="memberSearchLoading" />
        <div class="flare-group-detail__members">
          <div v-if="memberSearchError" class="flare-group-detail__empty-row" role="alert">{{ memberSearchError }}</div>
          <FlareContactList
            v-else-if="matchingMembers.length"
            :items="matchingMembers"
            :indexed="false"
            @select="onMemberListSelect"
          />
          <div v-else class="flare-group-detail__empty-row">{{ t("group.noMatchingMembers") }}</div>
        </div>
      </div>
    </FlareBottomSheet>

    <!-- Invite members -->
    <FlareBottomSheet :open="inviteOpen" :title="t('group.invite')" max-height="80vh" @close="inviteOpen = false">
      <div class="flare-group-detail__sheet">
        <div class="flare-group-detail__list">
          <FlareContactList
            v-if="invitable.length"
            :items="invitable"
            :indexed="false"
            selectable
            :selected-ids="invitePickedIds"
            @toggle-select="toggleInvite"
          />
          <div v-else class="flare-group-detail__empty-row">{{ t("group.inviteEmpty") }}</div>
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
          <FlareButton :disabled="!policyDraft" @click="savePolicy">{{ t("group.save") }}</FlareButton>
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
.flare-group-detail__hero { display: flex; flex-direction: column; align-items: center; gap: var(--flare-size-spacing-2sm); padding: 20px 16px 8px; }
.flare-group-detail__title {
  display: inline-flex;
  align-items: center;
  gap: var(--flare-size-spacing-xs);
  max-width: 100%;
  padding: 0;
  border: 0;
  background: none;
  color: var(--flare-color-text-primary);
  font-size: 18px;
  font-weight: 600;
  text-align: center;
}
.flare-group-detail__title.is-interactive {
  /* 它替掉的是一整行设置行，触达区得跟那一行一样够得着。 */
  min-height: var(--flare-size-layout-touch-target);
  padding-inline: var(--flare-size-spacing-sm);
  border-radius: var(--flare-size-radius-md);
  cursor: pointer;
}
.flare-group-detail__title.is-interactive:hover { background: var(--flare-color-bg-hover); }
.flare-group-detail__title.is-interactive:focus-visible {
  outline: 2px solid var(--flare-color-border-selected);
  outline-offset: 2px;
}
.flare-group-detail__title-text { min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.flare-group-detail__title-edit { display: inline-flex; flex: none; align-items: center; color: var(--flare-color-text-tertiary); }
.flare-group-detail__foot { display: flex; flex-direction: column; gap: var(--flare-size-spacing-2sm); padding: 16px; }
.flare-group-detail__slot { margin: 0 var(--flare-size-spacing-md); }
.flare-group-detail__footer { display: flex; flex-direction: column; align-items: center; gap: var(--flare-size-spacing-sm); padding: 0 var(--flare-size-spacing-lg) var(--flare-size-spacing-lg); }
.flare-group-detail__sheet { padding: 8px 12px 16px; display: flex; flex-direction: column; gap: var(--flare-size-spacing-2md); }
.flare-group-detail__sheet-actions { display: flex; gap: 12px; }
.flare-group-detail__sheet-actions > * { flex: 1; }
.flare-group-detail__member-actions { gap: var(--flare-size-spacing-2sm); }
.flare-group-detail__confirm { margin: 0; color: var(--flare-color-text-secondary); font-size: 14px; line-height: 1.6; }
.flare-group-detail__list { max-height: 46vh; overflow-y: auto; border-radius: var(--flare-size-radius-lg); background: var(--flare-color-bg-secondary); }
.flare-group-detail__members { height: min(56vh, 520px); min-height: 0; border-radius: var(--flare-size-radius-lg); background: var(--flare-color-bg-secondary); overflow: hidden; }
.flare-group-detail__row-name { flex: 1; min-width: 0; color: var(--flare-color-text-primary); }
.flare-group-detail__empty-row { padding: 20px; text-align: center; color: var(--flare-color-text-tertiary); font-size: 13px; }
.flare-group-detail__req { display: flex; align-items: center; gap: 12px; padding: var(--flare-size-spacing-2sm) 12px; }
.flare-group-detail__req-info { flex: 1; min-width: 0; display: flex; flex-direction: column; gap: 2px; }
.flare-group-detail__req-msg { font-size: 12px; color: var(--flare-color-text-tertiary); overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.flare-group-detail__req-actions { display: flex; gap: 8px; flex-shrink: 0; }
.flare-group-detail__code { padding: var(--flare-size-spacing-2md) 16px; border-radius: var(--flare-size-radius-lg); background: var(--flare-color-bg-secondary); text-align: center; font-size: 18px; font-weight: 700; letter-spacing: 0.08em; color: var(--flare-color-text-primary); word-break: break-all; }
</style>
