<script setup>
import { ref } from "vue";
import { ImageOutline, FolderOpenOutline, LocationOutline, GiftOutline } from "@vicons/ionicons5";
import { FlareComposer } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";

// A tenant supplies exactly the "+" actions it supports — its own order,
// labels, icons and tones. Anything not listed simply doesn't appear.
const actions = [
  { id: "image", label: "图片", icon: ImageOutline },
  { id: "order", label: "订单", icon: GiftOutline, intent: "open-order" },
  { id: "file", label: "文件", icon: FolderOpenOutline },
  { id: "location", label: "位置", icon: LocationOutline, enabled: false, disabledReason: "当前会话不可用" },
];

const last = ref("");
// The "+" / emoji panels are controlled — the host owns which one is open.
const activePanel = ref(null);
</script>

<template>
  <div class="reference__composer-example">
    <DemoStage>
      <div class="stage">
        <FlareComposer
          target-name="Ivy Chen"
          :actions="actions"
          :active-panel="activePanel"
          @toggle-panel="(p) => (activePanel = p)"
          @build="(op) => { last = op; activePanel = null; }"
        />
        <p class="hint">点「＋」展开 —— 只有租户声明的四个动作。最近触发：<code>{{ last || "—" }}</code></p>
      </div>
    </DemoStage>
  </div>
</template>

<style scoped>
.stage { width: 100%; max-width: 520px; }
.reference__composer-example { width: 100%; }
.hint { margin: 10px 2px 0; font-size: 12px; color: var(--vp-c-text-3); }
</style>
