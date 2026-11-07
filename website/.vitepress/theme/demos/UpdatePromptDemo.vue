<script setup>
import { computed, ref } from "vue";
import { useRoute } from "vitepress";
import { FlareButton, FlareUpdatePrompt } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";
// 宿主把 update://state 的内容原样交给组件，并执行组件上报的动作：每种状态说什么、有哪些按钮、强制时能不能离开都由
// 组件库决定。这里用假数据演示各个阶段，动作只关掉提示，不调用 SDK。
const route = useRoute();
const en = computed(() => route.path.startsWith("/en"));
const notes = computed(() =>
  en.value
    ? ["Faster message sync after reconnecting", "Clearer voice playback", "Fixes for the group member list"]
    : ["重连后消息同步更快", "语音播放更清晰", "修复群成员列表的问题"],
);
const withdrawn = computed(() =>
  en.value ? "This version has been withdrawn. Update to keep your messages safe." : "这个版本已撤回，更新后才能继续使用。",
);

const scenes = [
  { id: "optional", form: "sheet", state: "available", sizeBytes: 52428800 },
  { id: "recommended", form: "modal", state: "available", sizeBytes: 52428800 },
  { id: "required", form: "modal", mandatory: true, state: "required", canContinueReadOnly: true },
  { id: "blocked", form: "fullscreen", mandatory: true, state: "required" },
  { id: "withdrawn", form: "fullscreen", mandatory: true, state: "required" },
  { id: "metered", form: "sheet", state: "available", errorCode: "update.meteredConfirmationRequired", sizeBytes: 52428800 },
  { id: "downloading", form: "sheet", state: "downloading", sizeBytes: 52428800, progress: { received: 26214400, total: 52428800 } },
  { id: "ready", form: "modal", state: "readyToInstall" },
  { id: "failed", form: "modal", state: "failed", errorCode: "update.downloadFailed" },
  { id: "storeFailed", form: "modal", state: "failed", errorCode: "update.manifestUnavailable", fallbackTarget: "store" },
];

const open = ref(false);
const scene = ref(scenes[0]);

function pick(next) {
  scene.value = next;
  open.value = true;
}
function close() {
  open.value = false;
}
</script>

<template>
  <DemoStage>
    <div class="stage">
      <div class="scenes" role="group" :aria-label="en ? 'Update phase' : '更新阶段'">
        <FlareButton
          v-for="item in scenes"
          :key="item.id"
          size="sm"
          variant="secondary"
          :label="item.id"
          @click="pick(item)"
        />
      </div>
      <FlareUpdatePrompt
        :open="open"
        version="2.4.0"
        :notes="notes"
        :reason="scene.id === 'withdrawn' ? withdrawn : null"
        v-bind="scene"
        @update="close"
        @later="close"
        @skip="close"
        @retry="close"
        @fallback="close"
        @continue-read-only="close"
      />
    </div>
  </DemoStage>
</template>

<style scoped>
.stage { width: 100%; max-width: 560px; padding: 20px; border-radius: 14px; background: var(--flare-color-bg-secondary); }
.scenes { display: flex; flex-wrap: wrap; gap: 6px; }
</style>
