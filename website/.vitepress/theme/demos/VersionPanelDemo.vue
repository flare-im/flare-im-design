<script setup>
import { computed, ref } from "vue";
import { useRoute } from "vitepress";
import { FlareButton, FlareVersionPanel } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";
// 宿主把 UpdateStatus.current 与 state 原样传入，组件决定最后一行写什么、点了做什么。这里动作只切换假状态，不调用 SDK。
const route = useRoute();
const en = computed(() => route.path.startsWith("/en"));
const states = ["idle", "checking", "upToDate", "available", "downloading", "readyToInstall", "failed"];
const updateState = ref("idle");
</script>

<template>
  <DemoStage>
    <div class="stage">
      <div class="scenes" role="group" :aria-label="en ? 'Update state' : '更新状态'">
        <FlareButton
          v-for="state in states"
          :key="state"
          size="sm"
          :variant="updateState === state ? 'primary' : 'secondary'"
          :label="state"
          @click="updateState = state"
        />
      </div>
      <FlareVersionPanel
        version="2.3.2"
        :build="20302"
        channel="stable"
        :update-state="updateState"
        @check="updateState = 'checking'"
        @update="updateState = 'downloading'"
      />
    </div>
  </DemoStage>
</template>

<style scoped>
.stage { display: flex; flex-direction: column; gap: 14px; width: 100%; max-width: 420px; padding: 20px 8px; border-radius: 14px; background: var(--flare-color-bg-secondary); }
.scenes { display: flex; flex-wrap: wrap; gap: 6px; padding-inline: 12px; }
</style>
