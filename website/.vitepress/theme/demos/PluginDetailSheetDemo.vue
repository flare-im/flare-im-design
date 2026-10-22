<script setup>
import { ref } from "vue";
import { FlareButton, FlarePluginDetailSheet } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";
// 「查看全部」：先转圈，第一次加载失败可重试，第二次拿到 detail 视图。
const open = ref(false);
const loading = ref(false);
const error = ref("");
const view = ref(undefined);
let attempts = 0;
function load() {
  loading.value = true;
  error.value = "";
  setTimeout(() => {
    loading.value = false;
    attempts += 1;
    if (attempts === 1) {
      error.value = "加载失败，请稍后再试";
      return;
    }
    view.value = {
      available: true, title: "接龙全部条目", fields: [], actions: [],
      blocks: [{
        kind: "entries", numbered: true, total: 4, more: false,
        items: [
          { index: 1, text: "《三体》", name: "Ivy Chen" },
          { index: 2, text: "《活着》", name: "周屿" },
          { index: 3, text: "《百年孤独》", name: "Leo Wang" },
          { index: 4, text: "《小王子》", name: "林晓" },
        ],
      }],
    };
  }, 700);
}
function show() {
  open.value = true;
  attempts = 0;
  view.value = undefined;
  load();
}
</script>
<template>
  <DemoStage>
    <FlareButton label="查看全部（4）" variant="secondary" @click="show" />
    <FlarePluginDetailSheet
      :open="open"
      title="周末读书会报名"
      :view="view"
      :loading="loading"
      :error="error || undefined"
      @retry="load"
      @close="open = false"
    />
  </DemoStage>
</template>
