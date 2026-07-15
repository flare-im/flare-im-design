<script setup>
import { ref } from "vue";
import { ImageOutline, FolderOpenOutline, LocationOutline, GiftOutline } from "@vicons/ionicons5";
import FlareComposer from "flare-core-vue-im-ui/components/composer/EnhancedComposer.vue";
import DemoStage from "./DemoStage.vue";

// A tenant supplies exactly the "+" actions it supports — its own order,
// labels, icons and tones. Anything not listed simply doesn't appear.
const attachActions = [
  { op: "image", label: "图片", icon: ImageOutline, tone: "cyan" },
  { op: "file", label: "文件", icon: FolderOpenOutline, tone: "amber" },
  { op: "location", label: "位置", icon: LocationOutline, tone: "green" },
  { op: "redpacket", label: "红包", icon: GiftOutline, tone: "red" },
];

const last = ref("");
// The "+" / emoji panels are controlled — the host owns which one is open.
const activePanel = ref(null);
</script>

<template>
  <DemoStage>
    <div class="stage">
      <FlareComposer
        target-name="Ivy Chen"
        :attach-actions="attachActions"
        :active-panel="activePanel"
        @toggle-panel="(p) => (activePanel = p)"
        @build="(op) => { last = op; activePanel = null; }"
      />
      <p class="hint">点「＋」展开 —— 只有租户声明的四个动作。最近触发：<code>{{ last || "—" }}</code></p>
    </div>
  </DemoStage>
</template>

<style scoped>
.stage { width: 100%; max-width: 520px; }
.hint { margin: 10px 2px 0; font-size: 12px; color: var(--vp-c-text-3); }
</style>
