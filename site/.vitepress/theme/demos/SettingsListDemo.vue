<script setup>
import FlareSettingsList from "flare-core-vue-im-ui/components/profile/FlareSettingsList.vue";
import DemoStage from "./DemoStage.vue";

const sections = [
  {
    title: "通用",
    items: [
      { key: "notify", label: "新消息通知", kind: "toggle", value: true },
      { key: "sound", label: "声音", kind: "toggle", value: false },
      { key: "lang", label: "语言", detail: "简体中文" },
    ],
  },
  {
    title: "隐私",
    items: [
      { key: "read", label: "已读回执", kind: "toggle", value: true },
      { key: "block", label: "黑名单", detail: "2 人" },
    ],
  },
];
</script>

<template>
  <DemoStage>
    <div class="stage">
      <FlareSettingsList :sections="sections" />
    </div>
  </DemoStage>
</template>

<style scoped>
.stage { width: 100%; max-width: 380px; }
</style>
