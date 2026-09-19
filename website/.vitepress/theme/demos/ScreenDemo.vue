<script setup>
import { ref } from "vue";
import { FlareScreen, FlareSettingsList } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";
const log = ref("");
const sections = [{ title: "通用", items: [
  { key: "notify", label: "新消息通知", kind: "toggle", value: true },
  { key: "lang", label: "语言", detail: "简体中文" },
] }];
</script>
<template>
  <DemoStage>
    <div class="stage">
      <FlareScreen title="设置" back @back="log = 'back'">
        <FlareSettingsList :sections="sections" />
      </FlareScreen>
      <div class="echo">{{ log || "点返回 = back；正文是 canvas 表面上的分组列表" }}</div>
    </div>
  </DemoStage>
</template>
<style scoped>
.stage { width: 100%; max-width: 420px; height: 360px; display: flex; flex-direction: column; }
.stage > :first-child { flex: 1; min-height: 0; }
.echo { font-size: 12px; color: var(--flare-color-text-tertiary); margin-top: 8px; }
</style>
