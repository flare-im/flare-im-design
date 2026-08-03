<script setup>
import { ref } from "vue";
import {
  AlbumsOutline,
  ChatbubblesOutline,
  DocumentOutline,
  ImageOutline,
  VideocamOutline,
} from "@vicons/ionicons5";
import FlareFilterTabs from "@flare-im/vue-ui/components/general/FlareFilterTabs.vue";

const active = ref("all");
const options = [
  { value: "all", label: "全部" },
  { value: "unread", label: "未读", badge: 3 },
  { value: "groups", label: "群组" },
  { value: "bots", label: "机器人" },
  { value: "official", label: "官方" },
];

// With optional per-option icons (any Vue component).
const kind = ref("all");
const kindOptions = [
  { value: "all", label: "全部", icon: AlbumsOutline },
  { value: "text", label: "文本", icon: ChatbubblesOutline },
  { value: "image", label: "图片", icon: ImageOutline },
  { value: "video", label: "视频", icon: VideocamOutline },
  { value: "file", label: "文件", icon: DocumentOutline },
];
</script>

<template>
  <div class="ft-demo">
    <FlareFilterTabs v-model="active" :options="options" />
    <div class="ft-demo__log">当前筛选 · active: {{ active }}</div>
    <FlareFilterTabs v-model="kind" :options="kindOptions" />
    <div class="ft-demo__log">带图标 · with icons: {{ kind }}</div>
  </div>
</template>

<style scoped>
.ft-demo {
  width: 100%;
  max-width: 420px;
  display: flex;
  flex-direction: column;
  gap: 10px;
}
.ft-demo__log {
  font-size: 12px;
  color: var(--flare-color-text-tertiary);
}
</style>
