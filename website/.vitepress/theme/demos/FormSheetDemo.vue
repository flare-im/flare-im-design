<script setup>
import { ref } from "vue";
import { FlareButton, FlareFormField, FlareFormSheet, FlareInput } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";
const open = ref(false);
const busy = ref(false);
const name = ref("设计评审");
const error = ref("");
async function confirm() {
  error.value = name.value.trim() ? "" : "名称不能为空";
  if (error.value) return;
  busy.value = true;
  await new Promise((resolve) => setTimeout(resolve, 600));
  busy.value = false;
  open.value = false;
}
</script>
<template>
  <DemoStage>
    <FlareButton label="重命名群聊" @click="open = true" />
    <FlareFormSheet :open="open" title="群聊名称" :busy="busy" :confirm-disabled="!name.trim()" :error="error" @confirm="confirm" @close="open = false">
      <FlareFormField label="名称"><FlareInput v-model="name" placeholder="输入群聊名称" /></FlareFormField>
    </FlareFormSheet>
  </DemoStage>
</template>
