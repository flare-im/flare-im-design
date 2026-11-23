<script setup>
import { ref } from "vue";
import { FlareButton, FlareCommentComposer } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";
const text = ref(""); const error = ref(""); const busy = ref(false);
const target = { id: "c1", author: { id: "peer", name: "陈默" }, text: "下次一起去😀" };
const reply = ref(target);
async function submit() { busy.value = true; await new Promise(resolve => setTimeout(resolve, 350)); busy.value = false; if (!error.value) error.value = "评论没有发出，请重试。"; else { text.value = ""; error.value = ""; reply.value = undefined; } }
</script>
<template><DemoStage><div class="comment-demo"><FlareButton size="sm" variant="secondary" label="回复示例评论" @click="reply = target" /><FlareCommentComposer v-model="text" :reply-to="reply" :error="error" :busy="busy" @submit="submit" @cancel-reply="reply = undefined" /></div></DemoStage></template>
<style scoped>.comment-demo { width: 100%; max-width: var(--flare-size-layout-readable-width); display: grid; gap: var(--flare-size-spacing-md); }</style>
