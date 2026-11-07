<script setup>
import { computed, ref } from "vue";
import { useRoute } from "vitepress";
import { FlareAccessDiagnostics, FlareButton } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";
// 宿主把 access.getStatus 与 access.listAccessPoints 的结果原样交给组件，并执行组件上报的动作：
// 页面处于哪种状态、每种结果说什么、哪条线路能固定都由组件库决定。这里用假数据演示三种状态，
// 动作只改本地数据，不调用 SDK。
const route = useRoute();
const en = computed(() => route.path.startsWith("/en"));

const healthy = {
  loaded: true,
  serial: 42,
  source: "https:https://cfg-b.other-cloud.net/flare/v1/b7f3c9a1e2d4b6a8/",
  stale: false,
  developmentMode: false,
  regionId: "cn-east",
  accessPointId: "ap-sh-1",
  protocol: "quic",
};
const lines = [
  { accessPointId: "ap-sh-1", regionId: "cn-east", host: "sh1.example.net", status: "active", rttMs: 38, breaker: "closed", pinned: false, current: true },
  { accessPointId: "ap-sh-2", regionId: "cn-east", host: "sh2.example.net", status: "active", rttMs: 212, breaker: "halfOpen", pinned: false, current: false },
  { accessPointId: "ap-sg-1", regionId: "sg", host: "sg1.example.net", status: "active", rttMs: 468, breaker: "open", pinned: false, current: false },
  { accessPointId: "ap-sg-2", regionId: "sg", host: "sg2.example.net", status: "draining", breaker: "closed", pinned: false, current: false },
];
const scenes = [
  { id: "normal", status: () => healthy, lines: () => lines },
  { id: "recovering", status: () => ({ ...healthy, accessPointId: null, protocol: null, recovering: { rounds: 2, nextRoundAtMs: Date.now() + 60000 } }), lines: () => lines.map((line) => ({ ...line, current: false, breaker: "open" })) },
  { id: "offline", status: () => ({ ...healthy, accessPointId: null, protocol: null, recovering: { rounds: 3 } }), lines: () => lines.map((line) => ({ ...line, current: false })) },
  { id: "warning", status: () => ({ ...healthy, stale: true, connectAck: { accessPointId: "ap-sh-2", accessPointMismatch: true } }), lines: () => lines },
  { id: "noManifest", status: () => ({ loaded: false, serial: 0, source: "none", stale: false, developmentMode: false }), lines: () => [] },
];

const selected = ref("normal");
const status = ref(scenes[0].status());
const accessPoints = ref(scenes[0].lines());
const refreshOutcome = ref(null);
const importOutcome = ref(null);
const importCode = ref(null);
const exportOutcome = ref(null);

function clearAnswers() {
  refreshOutcome.value = null;
  importOutcome.value = null;
  importCode.value = null;
  exportOutcome.value = null;
}
function pick(scene) {
  selected.value = scene.id;
  status.value = scene.status();
  accessPoints.value = scene.lines();
  clearAnswers();
}
function setPin(id) {
  accessPoints.value = accessPoints.value.map((line) => ({ ...line, pinned: line.accessPointId === id }));
}
function importLink(link) {
  const adopted = link.startsWith("flare-recover://");
  importOutcome.value = adopted ? "adopted" : "rejected";
  importCode.value = adopted ? null : "malformedEnvelope";
}
</script>

<template>
  <DemoStage>
    <div class="stage">
      <div class="scenes" role="group" :aria-label="en ? 'Page state' : '页面状态'">
        <FlareButton
          v-for="scene in scenes"
          :key="scene.id"
          size="sm"
          :variant="selected === scene.id ? 'primary' : 'secondary'"
          :label="scene.id"
          @click="pick(scene)"
        />
      </div>
      <div class="page">
        <FlareAccessDiagnostics
          :status="status"
          :access-points="accessPoints"
          :refresh-outcome="refreshOutcome"
          :import-outcome="importOutcome"
          :import-code="importCode"
          :export-outcome="exportOutcome"
          @pin="setPin"
          @unpin="setPin(null)"
          @refresh="refreshOutcome = 'upToDate'"
          @import-recovery="importLink"
          @export-diagnostics="exportOutcome = 'copied'"
        />
      </div>
    </div>
  </DemoStage>
</template>

<style scoped>
.stage { display: flex; flex-direction: column; gap: 14px; width: 100%; max-width: 560px; padding: 20px; border-radius: 14px; background: var(--flare-color-bg-secondary); }
.scenes { display: flex; flex-wrap: wrap; gap: 6px; }
.page { padding: 16px; border-radius: 12px; background: var(--flare-color-bg-primary); }
</style>
