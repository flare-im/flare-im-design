<script setup>
import { computed, ref } from "vue";
import FlareGroupPermissionMatrix from "@flare-im/vue-ui/components/contacts/FlareGroupPermissionMatrix.vue";
import DemoStage from "./DemoStage.vue";

const settings = ref({
  muteAll: false,
  onlyAdminCanAtAll: true,
  onlyAdminCanPin: false,
  shareCardPermission: true,
  joinPolicy: 2,
});
const canManage = ref(true);
const busyKeys = ref([]);
const errors = ref({});
// Demo switch: the host pretends the next muteAll write fails, to show partial failure.
const failMuteAll = ref(false);
const last = ref("尚未修改");

function apply({ key, value }) {
  last.value = `change：${key} = ${value}`;
  // The host sets busy synchronously before dispatching, per key.
  busyKeys.value = [...busyKeys.value, key];
  const { [key]: _dropped, ...rest } = errors.value;
  errors.value = rest;
  setTimeout(() => {
    busyKeys.value = busyKeys.value.filter((k) => k !== key);
    if (key === "muteAll" && failMuteAll.value) {
      // Failure keeps the previous value and the reason; the other rows are untouched.
      errors.value = { ...errors.value, muteAll: "服务端拒绝：你已不是管理员" };
      return;
    }
    settings.value = { ...settings.value, [key]: value };
  }, 900);
}
function dismiss(key) {
  const { [key]: _dropped, ...rest } = errors.value;
  errors.value = rest;
}
function reset() {
  settings.value = {
    muteAll: false,
    onlyAdminCanAtAll: true,
    onlyAdminCanPin: false,
    shareCardPermission: true,
    joinPolicy: 2,
  };
  canManage.value = true;
  busyKeys.value = [];
  errors.value = {};
  failMuteAll.value = false;
  last.value = "尚未修改";
}
const summary = computed(() => {
  const s = settings.value;
  const policy = { 1: "仅邀请", 2: "需审批", 3: "公开" }[s.joinPolicy] ?? "未知";
  return [
    `加群 ${policy}`,
    s.muteAll ? "全员禁言" : "可发言",
    s.onlyAdminCanAtAll ? "限管理员@所有人" : "均可@所有人",
    s.onlyAdminCanPin ? "限管理员置顶" : "均可置顶",
    s.shareCardPermission ? "可分享名片" : "禁止分享名片",
  ].join(" · ");
});
</script>

<template>
  <DemoStage>
    <div class="gpm-demo">
      <FlareGroupPermissionMatrix
        :settings="settings"
        :can-manage="canManage"
        :busy-keys="busyKeys"
        :errors="errors"
        @change="apply"
        @dismiss-error="dismiss"
      />

      <div class="gpm-demo__controls">
        <label><input v-model="canManage" type="checkbox" /> canManage（管理员视角）</label>
        <label><input v-model="failMuteAll" type="checkbox" /> 让「全员禁言」提交失败</label>
        <button type="button" @click="settings = { ...settings, joinPolicy: 9 }">注入未知 joinPolicy</button>
        <button type="button" @click="reset">重置演示</button>
      </div>
      <p role="status">{{ last }}。当前：{{ summary }}。本地模拟，不触发 SDK。</p>
    </div>
  </DemoStage>
</template>

<style scoped>
.gpm-demo { width: 100%; min-width: 0; display: grid; gap: 16px; max-width: 560px; }
.gpm-demo__controls { display: flex; flex-wrap: wrap; gap: 8px 14px; align-items: center; font-size: 13px; }
.gpm-demo__controls button {
  min-height: 40px;
  padding: 6px 12px;
  border: 1px solid var(--flare-color-border-primary);
  border-radius: 8px;
  background: var(--flare-color-bg-primary);
  color: inherit;
}
p { font-size: 13px; overflow-wrap: anywhere; }
</style>
