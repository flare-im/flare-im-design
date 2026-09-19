<script setup>
import { computed, inject, ref } from "vue";
import { FlareBottomSheet, FlareDangerConfirm, FlareEmptyState, FlareMemberRoleSheet, FlareSettingsRow } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";
import { previewContextKey } from "./preview-context";

const preview = inject(previewContextKey, null);
const mobile = computed(() => preview?.viewport.value === "mobile");
const initialMember = { id: "u-member", name: "王强", role: "member", muted: false };
const member = ref({ ...initialMember });
const viewerRole = ref("owner");
const capabilities = { promote: true, demote: true, mute: true, unmute: true, remove: true, transferOwner: true };
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
  if (pending.value === "transferOwner") { member.value.role = "owner"; viewerRole.value = "member"; }
  if (pending.value === "remove") member.value = null;
  pending.value = null;
}
</script>

<template>
  <DemoStage>
    <div v-if="!mobile" class="mrs-demo__popover" data-preview-platform="desktop">
      <FlareMemberRoleSheet v-if="member" :member="member" :viewer-role="viewerRole" :capabilities="capabilities" :mute-durations="durations" @action="apply" />
    </div>
    <div v-else data-preview-platform="mobile">
      <FlareSettingsRow v-if="member" :item="{ id: member.id, label: member.name, kind: 'navigation', detail: member.muted ? '已禁言' : '成员' }" @select="open = true" />
      <FlareBottomSheet :open="open" @close="open = false">
        <FlareMemberRoleSheet v-if="member" :member="member" :viewer-role="viewerRole" :capabilities="capabilities" :mute-durations="durations" @action="apply" @close="open = false" />
      </FlareBottomSheet>
    </div>
    <FlareEmptyState v-if="!member" title="成员已移出" action-text="恢复示例" @action="member = { ...initialMember }; viewerRole = 'owner'; open = true" />
    <FlareDangerConfirm :open="pending !== null" :title="pending === 'remove' ? '移出群聊？' : '转让群主？'" :target="member?.name" @confirm="confirm" @cancel="pending = null" />
  </DemoStage>
</template>

<style scoped>
.mrs-demo__popover { width: 300px; max-width: 100%; margin-inline: auto; border: 1px solid var(--flare-color-border-primary); border-radius: var(--flare-size-radius-md); background: var(--flare-color-bg-primary); }
</style>
