<script setup>
import { ref } from "vue";
import { FlareInviteCodeField } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";

// The host's half of the contract, simulated locally: it receives `check`, runs the
// pre-check (here: a code ending in X is invalid, anything else resolves to an inviter),
// and feeds `checking` / `checkResult` back. No SDK call is made.
const mode = ref("optional");
const code = ref("");
const checking = ref(false);
const checkResult = ref(null);
const error = ref("");
const prefill = ref("");
const last = ref("尚未预检");
let timer = null;

function onCheck(normalized) {
  last.value = `check：${normalized}`;
  error.value = "";
  checkResult.value = null;
  checking.value = true;
  clearTimeout(timer);
  timer = setTimeout(() => {
    checking.value = false;
    checkResult.value = normalized.endsWith("X")
      ? { valid: false }
      : { valid: true, inviterDisplayName: "A**n" };
  }, 700);
}
function onUpdate(next) {
  code.value = next;
  // A changed code invalidates the previous verdict; the host clears it.
  checkResult.value = null;
  error.value = "";
}
function submitEmpty() {
  error.value = mode.value === "required" && !code.value ? "请输入邀请码后再注册" : "";
}
function deepLink() {
  code.value = "";
  checkResult.value = null;
  prefill.value = `ab-12cd`;
}
function reset() {
  clearTimeout(timer);
  code.value = "";
  checking.value = false;
  checkResult.value = null;
  error.value = "";
  prefill.value = "";
  last.value = "尚未预检";
}
</script>

<template>
  <DemoStage>
    <div class="invite-demo">
      <FlareInviteCodeField
        :model-value="code"
        :mode="mode"
        :prefill="prefill"
        :checking="checking"
        :check-result="checkResult"
        :error="error"
        @update:model-value="onUpdate"
        @check="onCheck"
      />
      <div class="invite-demo__controls">
        <label>模式
          <select v-model="mode">
            <option value="off">off（不渲染）</option>
            <option value="optional">optional（选填）</option>
            <option value="required">required（必填）</option>
          </select>
        </label>
        <button type="button" @click="deepLink">模拟深链预填 ab-12cd</button>
        <button type="button" @click="submitEmpty">模拟提交（必填校验）</button>
        <button type="button" @click="reset">重置</button>
      </div>
      <p role="status">{{ last }}。以 X 结尾的码会被判无效；本地模拟，不触发 SDK。</p>
    </div>
  </DemoStage>
</template>

<style scoped>
.invite-demo { width: 100%; min-width: 0; display: grid; gap: 16px; max-width: 420px; }
.invite-demo__controls { display: flex; flex-wrap: wrap; gap: 8px 14px; align-items: center; font-size: 13px; }
.invite-demo__controls button, .invite-demo__controls select {
  min-height: 40px;
  padding: 6px 12px;
  border: 1px solid var(--flare-color-border-primary);
  border-radius: 8px;
  background: var(--flare-color-bg-primary);
  color: inherit;
}
p { font-size: 13px; overflow-wrap: anywhere; }
</style>
