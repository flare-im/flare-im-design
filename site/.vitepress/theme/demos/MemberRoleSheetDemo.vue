<script setup>
import { computed, ref } from "vue";
import FlareMemberRoleSheet from "@flare-im/vue-ui/components/contacts/FlareMemberRoleSheet.vue";
import FlareBottomSheet from "@flare-im/vue-ui/components/general/FlareBottomSheet.vue";
import DemoStage from "./DemoStage.vue";

const members = ref([
  { id: "u-owner", name: "张伟（群主）", role: "owner", muted: false },
  { id: "u-admin", name: "李梅（管理员）", role: "admin", muted: false },
  { id: "u-member", name: "王强", role: "member", muted: false },
]);
const selectedId = ref("u-member");
const viewerRole = ref("owner");
const caps = ref({ promote: true, demote: true, mute: true, unmute: true, remove: true, transferOwner: true });
const durations = ref([
  { id: "10m", label: "10 分钟" },
  { id: "1h", label: "1 小时" },
  { id: "1d", label: "1 天" },
]);
const withDurations = ref(true);
const busy = ref(false);
const sheetOpen = ref(false);
const last = ref("尚未操作");
const capKeys = ["promote", "demote", "mute", "unmute", "remove", "transferOwner"];

const member = computed(() => members.value.find((m) => m.id === selectedId.value) ?? members.value[0]);
const muteDurations = computed(() => (withDurations.value ? durations.value : []));

// The host owns confirmation: remove / transferOwner would go through FlareDangerConfirm first.
function apply({ memberId, action, durationId }) {
  last.value = `action：${memberId}/${action}${durationId ? `/${durationId}` : ""}`;
  busy.value = true;
  setTimeout(() => {
    members.value = members.value.map((m) => {
      if (m.id !== memberId) return m;
      if (action === "promote") return { ...m, role: "admin" };
      if (action === "demote") return { ...m, role: "member" };
      if (action === "mute") return { ...m, muted: true };
      if (action === "unmute") return { ...m, muted: false };
      return m;
    });
    if (action === "remove") members.value = members.value.filter((m) => m.id !== memberId);
    if (action === "transferOwner") {
      members.value = members.value.map((m) => ({
        ...m,
        role: m.id === memberId ? "owner" : m.role === "owner" ? "member" : m.role,
      }));
      viewerRole.value = "member";
    }
    if (!members.value.some((m) => m.id === selectedId.value)) selectedId.value = members.value[0]?.id ?? "";
    busy.value = false;
    sheetOpen.value = false;
  }, 700);
}
function reset() {
  members.value = [
    { id: "u-owner", name: "张伟（群主）", role: "owner", muted: false },
    { id: "u-admin", name: "李梅（管理员）", role: "admin", muted: false },
    { id: "u-member", name: "王强", role: "member", muted: false },
  ];
  selectedId.value = "u-member";
  viewerRole.value = "owner";
  caps.value = { promote: true, demote: true, mute: true, unmute: true, remove: true, transferOwner: true };
  withDurations.value = true;
  busy.value = false;
  last.value = "尚未操作";
}
</script>

<template>
  <DemoStage>
    <div class="mrs-demo">
      <div class="mrs-demo__split">
        <div class="mrs-demo__col">
          <div class="mrs-demo__cap">桌面 · 成员列表右键 popover 内容</div>
          <div v-if="member" class="mrs-demo__popover">
            <FlareMemberRoleSheet
              :member="member"
              :viewer-role="viewerRole"
              :capabilities="caps"
              :mute-durations="muteDurations"
              :busy="busy"
              @action="apply"
              @close="last = 'close'"
            />
          </div>
        </div>
        <div class="mrs-demo__col">
          <div class="mrs-demo__cap">移动端 · 长按成员 → FlareBottomSheet</div>
          <button
            v-for="m in members"
            :key="m.id"
            type="button"
            class="mrs-demo__row"
            :class="{ 'is-active': m.id === selectedId }"
            @click="selectedId = m.id; sheetOpen = true"
          >
            <span class="mrs-demo__row-title">{{ m.name }}</span>
            <span class="mrs-demo__row-sub">{{ m.role }}{{ m.muted ? " · 已禁言" : "" }}</span>
          </button>
          <FlareBottomSheet :open="sheetOpen" @close="sheetOpen = false">
            <FlareMemberRoleSheet
              v-if="member"
              :member="member"
              :viewer-role="viewerRole"
              :capabilities="caps"
              :mute-durations="muteDurations"
              :busy="busy"
              @action="apply"
              @close="sheetOpen = false"
            />
          </FlareBottomSheet>
        </div>
      </div>

      <div class="mrs-demo__controls">
        <label>
          我的角色
          <select v-model="viewerRole">
            <option value="owner">owner</option>
            <option value="admin">admin</option>
            <option value="member">member</option>
          </select>
        </label>
        <label v-for="k in capKeys" :key="k"><input v-model="caps[k]" type="checkbox" /> {{ k }}</label>
        <label><input v-model="withDurations" type="checkbox" /> 提供禁言时长</label>
        <label><input v-model="busy" type="checkbox" /> busy</label>
        <button type="button" @click="reset">重置演示</button>
      </div>
      <p role="status">{{ last }}。移出与转让在真实宿主里要先过 DangerConfirm。本地模拟，不触发 SDK。</p>
    </div>
  </DemoStage>
</template>

<style scoped>
.mrs-demo { width: 100%; min-width: 0; display: grid; gap: 16px; }
.mrs-demo__split { display: grid; grid-template-columns: minmax(0, 1fr) minmax(0, 1fr); gap: 20px; align-items: start; }
@media (max-width: 720px) { .mrs-demo__split { grid-template-columns: 1fr; } }
.mrs-demo__cap { margin-bottom: 8px; font-size: 12px; font-weight: 600; color: var(--flare-color-text-tertiary); }
.mrs-demo__popover {
  max-width: 320px;
  border: 1px solid var(--flare-color-border-primary);
  border-radius: 14px;
  background: var(--flare-color-bg-primary);
  box-shadow: var(--flare-shadow-md);
}
.mrs-demo__row {
  display: grid;
  gap: 4px;
  width: 100%;
  min-height: 48px;
  margin-bottom: 6px;
  padding: 10px 14px;
  border: 1px solid var(--flare-color-border-primary);
  border-radius: 12px;
  background: var(--flare-color-bg-primary);
  color: var(--flare-color-text-primary);
  text-align: start;
  cursor: pointer;
  font: inherit;
}
.mrs-demo__row.is-active { border-color: var(--flare-color-border-selected); background: var(--flare-color-bg-selected); }
.mrs-demo__row-title { font-weight: 600; }
.mrs-demo__row-sub { font-size: 12px; color: var(--flare-color-text-secondary); }
.mrs-demo__controls { display: flex; flex-wrap: wrap; gap: 8px 14px; align-items: center; font-size: 13px; }
.mrs-demo__controls select { min-height: 32px; margin-inline-start: 4px; }
.mrs-demo__controls button {
  min-height: 40px;
  padding: 6px 12px;
  border: 1px solid var(--flare-color-border-primary);
  border-radius: 8px;
  background: var(--flare-color-bg-primary);
  color: inherit;
}
p { font-size: 13px; overflow-wrap: anywhere; }
</style>
