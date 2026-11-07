<script setup>
import { computed, ref } from "vue";
import { useRoute } from "vitepress";
import { FlareButton, FlareConnectionNotice, FlareSwitch } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";
// 宿主只把 SDK 的 connection://status 原样交给组件：何时显示、显示什么、给什么动作都由组件库决定。
// syncing 满 1 秒、switching 满 2 秒才出现；reconnecting 倒计时到下次尝试并提供「立即重试」，
// 重连横幅至少停留 1.5 秒；actionRequired 按原因给出「重新登录」或「立即更新」。
const route = useRoute();
const en = computed(() => route.path.startsWith("/en"));
const phases = [
  { id: "online", status: () => ({ phase: "online", quality: "good" }) },
  { id: "connecting", status: () => ({ phase: "connecting" }) },
  { id: "syncing", status: () => ({ phase: "syncing", progress: 0.4 }) },
  { id: "switching", status: () => ({ phase: "switching" }) },
  { id: "reconnecting", status: () => ({ phase: "reconnecting", nextRetryAt: Date.now() + 8000, attempt: 2 }) },
  { id: "waitingForNetwork", status: () => ({ phase: "waitingForNetwork" }) },
  { id: "serviceUnavailable", status: () => ({ phase: "serviceUnavailable" }) },
  { id: "kicked", status: () => ({ phase: "actionRequired", reason: "kicked" }) },
  { id: "expired", status: () => ({ phase: "actionRequired", reason: "expired" }) },
  { id: "upgradeRequired", status: () => ({ phase: "actionRequired", reason: "upgradeRequired" }) },
  { id: "tenantUnavailable", status: () => ({ phase: "actionRequired", reason: "tenantUnavailable" }) },
  { id: "idle", status: () => ({ phase: "idle" }) },
];
const selected = ref("reconnecting");
const developmentMode = ref(false);
const base = ref(phases.find((p) => p.id === selected.value).status());
const status = computed(() => ({ ...base.value, developmentMode: developmentMode.value }));
const log = ref("");

function pick(phase) {
  selected.value = phase.id;
  base.value = phase.status();
  log.value = "";
}
function intent(name) {
  // A retry is the host calling connection.reconnectNow: the SDK goes back to connecting.
  if (name === "retry") pick(phases.find((p) => p.id === "connecting"));
  log.value = en.value ? `Host handles: ${name}` : `宿主处理：${name}`;
}
</script>

<template>
  <DemoStage>
    <div class="stage">
      <div class="phases" role="group" :aria-label="en ? 'Connection phase' : '连接阶段'">
        <FlareButton
          v-for="phase in phases"
          :key="phase.id"
          size="sm"
          :variant="selected === phase.id ? 'primary' : 'secondary'"
          :label="phase.id"
          @click="pick(phase)"
        />
      </div>
      <label class="dev">
        <FlareSwitch v-model="developmentMode" />
        <span>developmentMode</span>
      </label>
      <div class="shell">
        <FlareConnectionNotice
          :status="status"
          @retry="intent('retry')"
          @sign-in="intent('signIn')"
          @update="intent('update')"
          @diagnose="intent('diagnose')"
        />
        <p class="content">{{ en ? "App content" : "应用内容" }}</p>
      </div>
      <p v-if="log" class="log">{{ log }}</p>
    </div>
  </DemoStage>
</template>

<style scoped>
.stage { display: flex; flex-direction: column; gap: 14px; width: 100%; max-width: 560px; padding: 20px; border-radius: 14px; background: var(--flare-color-bg-secondary); }
.phases { display: flex; flex-wrap: wrap; gap: 6px; }
.dev { display: inline-flex; align-items: center; gap: 8px; font-size: 13px; color: var(--flare-color-text-secondary); }
.shell { display: flex; flex-direction: column; gap: 10px; padding: 12px; border-radius: 12px; background: var(--flare-color-bg-primary); min-height: 120px; }
.content { margin: 0; font-size: 13px; color: var(--flare-color-text-tertiary); }
.log { margin: 0; font-size: 12px; color: var(--flare-color-text-tertiary); }
</style>
