<script setup>
import { ref } from "vue";
import { FlareButton, FlareFormField, FlareFormSheet, FlareInput, FlareTextarea } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";
const open = ref(false);
const replyOpen = ref(false);
const reply = ref("");
const replyFailed = ref(false);
function sendReply() { if (!replyFailed.value) replyFailed.value = true; else { replyOpen.value = false; replyFailed.value = false; reply.value = ""; } }
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
    <FlareButton variant="secondary" label="紧凑回复与重试" @click="replyOpen = true" />
    <FlareFormSheet :open="replyOpen" title="回复评论" description="回复 陈默" density="compact" :error="replyFailed ? '回复没有发出，请重试。' : ''" :confirm-label="replyFailed ? '重试' : '发送'" :confirm-disabled="!reply.trim()" @confirm="sendReply" @close="replyOpen = false">
      <FlareTextarea v-model="reply" aria-label="回复评论" placeholder="评论…" :rows="2" :max-rows="5" size="sm" :maxlength="500" autofocus @enter="sendReply" />
    </FlareFormSheet>
    <FlareFormSheet :open="open" title="群聊名称" :busy="busy" :confirm-disabled="!name.trim()" :error="error" @confirm="confirm" @close="open = false">
      <FlareFormField label="名称"><FlareInput v-model="name" placeholder="输入群聊名称" /></FlareFormField>
    </FlareFormSheet>
  </DemoStage>
</template>
