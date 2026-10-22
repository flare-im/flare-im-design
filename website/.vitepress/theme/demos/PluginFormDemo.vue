<script setup>
import { ref } from "vue";
import { FlarePluginForm } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";
// 发起投票的表单：必填和长度先在客户端提示；提交后这里模拟核心 SDK 的 validate_form 返回错误。
const inputs = [
  { id: "question", kind: "text", label: "问题", required: true, maxLength: 40, placeholder: "想问大家什么？" },
  { id: "options", kind: "options", label: "选项", required: true, min: 2, max: 6, maxLength: 20, default: ["", ""] },
  { id: "multiple", kind: "toggle", label: "允许多选", default: false },
  { id: "visibility", kind: "select", label: "结果可见", choices: [{ value: "voted", label: "投票后可见" }, { value: "always", label: "始终可见" }] },
  { id: "deadline", kind: "datetime", label: "截止时间" },
  { id: "owner", kind: "members", label: "负责人", max: 1 },
];
const members = [
  { userId: "u1", name: "Ivy Chen" },
  { userId: "u2", name: "周屿" },
  { userId: "u3", name: "Leo Wang" },
];
const errors = ref([]);
const busy = ref(false);
const sent = ref("");
function submit(values) {
  busy.value = true;
  setTimeout(() => {
    busy.value = false;
    const options = values.options ?? [];
    errors.value = new Set(options).size !== options.length ? [{ input: "options", issue: "duplicateItem" }] : [];
    sent.value = errors.value.length ? "" : JSON.stringify(values);
  }, 500);
}
</script>
<template>
  <DemoStage>
    <div class="frame">
      <FlarePluginForm :inputs="inputs" :errors="errors" :busy="busy" :members="members" submit-label="发起投票" @submit="submit" @cancel="sent = ''" />
    </div>
    <p v-if="sent" class="note">submit({{ sent }})</p>
  </DemoStage>
</template>
<style scoped>
.frame { max-width: 420px; border-radius: 14px; border: 1px solid var(--flare-color-border-secondary); }
.note { margin: 8px 0 0; font-size: 13px; color: var(--flare-color-text-secondary); overflow-wrap: anywhere; }
</style>
