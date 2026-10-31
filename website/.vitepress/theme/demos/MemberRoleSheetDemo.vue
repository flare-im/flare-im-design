<script setup>
import { computed, inject, ref } from "vue";
import { FlareBottomSheet, FlareDangerConfirm, FlareEmptyState, FlareMemberRoleSheet, FlareSettingsRow } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";
import { previewContextKey } from "./preview-context";

const preview = inject(previewContextKey, null);
const mobile = computed(() => preview?.viewport.value === "mobile");
const initialMember = { id: "u-member", name: "王强", role: "member", muted: false };
const member = ref({ ...initialMember });
// The demo stands in for the host: while the viewer owns the group its permission source allows everything on this member.
const viewerOwns = ref(true);
const actions = computed(() => (viewerOwns.value ? { canRemove: true, canMute: true, canChangeRole: true, canTransferOwner: true } : {}));
const durations = [{ id: "10m", label: "10 分钟" }, { id: "1h", label: "1 小时" }, { id: "1d", label: "1 天" }];
const open = ref(true);
const pending = ref(null);
function apply({ action }) {
  if (action === "remove" || action === "transferOwner") { pending.value = action; open.value = false; return; }
  if (action === "promote" || action === "demote") member.value.role = action === "promote" ? "admin" : "member";
  if (action === "mute" || action === "unmute") member.value.muted = action === "mute";
  open.value = false;
}
function confirm() {
  if (pending.value === "transferOwner") { member.value.role = "owner"; viewerOwns.value = false; }
  if (pending.value === "remove") member.value = null;
  pending.value = null;
}
</script>

<template>
  <DemoStage>
    <div v-if="!mobile" class="mrs-demo__popover" data-preview-platform="desktop">
      <FlareMemberRoleSheet v-if="member" :member="member" :actions="actions" :mute-durations="durations" @action="apply" />
    </div>
    <div v-else data-preview-platform="mobile">
      <FlareSettingsRow v-if="member" :item="{ id: member.id, label: member.name, kind: 'navigation', detail: member.muted ? '已禁言' : '成员' }" @select="open = true" />
      <FlareBottomSheet :open="open" @close="open = false">
        <FlareMemberRoleSheet v-if="member" :member="member" :actions="actions" :mute-durations="durations" @action="apply" @close="open = false" />
      </FlareBottomSheet>
    </div>
    <FlareEmptyState v-if="!member" title="成员已移出" action-text="恢复示例" @action="member = { ...initialMember }; viewerOwns = true; open = true" />
    <FlareDangerConfirm :open="pending !== null" :title="pending === 'remove' ? '移出群聊？' : '转让群主？'" :target="member?.name" @confirm="confirm" @cancel="pending = null" />
  </DemoStage>
</template>

<style scoped>
.mrs-demo__popover { width: 300px; max-width: 100%; margin-inline: auto; border: 1px solid var(--flare-color-border-primary); border-radius: var(--flare-size-radius-md); background: var(--flare-color-bg-primary); }
</style>
