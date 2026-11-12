<script setup>
import { ref } from "vue";
import { FlarePluginUpgradeNotice, FlareSegmentedControl } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";
// What a plugin contribution this build cannot draw shows instead. The host asks the engine
// (update.plugin_upgrade_status) for the placeholder's minBuild and passes the answer; here it is picked by hand.
const statuses = { 有新版本: { available: true, build: 41020 }, 暂无新版本: { available: false }, 未查询: undefined };
const names = Object.keys(statuses);
const pick = ref(0);
const busy = ref(false);
const log = ref("");
function update() {
  busy.value = true;
  log.value = "update.open_flow()";
  setTimeout(() => (busy.value = false), 800);
}
</script>
<template>
  <DemoStage>
    <FlareSegmentedControl v-model="pick" class="switch" :options="names" />
    <div class="stack">
      <section class="card">
        <strong>任务看板</strong>
        <FlarePluginUpgradeNotice variant="card" :status="statuses[names[pick]]" :busy="busy" :on-update="update" />
      </section>
      <div class="entry">
        <span>任务看板</span>
        <FlarePluginUpgradeNotice variant="entry" />
      </div>
      <div class="page">
        <FlarePluginUpgradeNotice variant="page" title="任务看板" :status="statuses[names[pick]]" :busy="busy" :on-update="update" />
      </div>
    </div>
    <p v-if="log" class="note">{{ log }}</p>
  </DemoStage>
</template>
<style scoped>
.switch { margin-bottom: 12px; }
.stack { display: grid; gap: 16px; max-width: 390px; }
.card { display: grid; gap: 8px; padding: 12px; border: 1px solid var(--flare-color-border-secondary); border-radius: 12px; background: var(--flare-color-bg-primary); }
.entry { display: flex; align-items: center; justify-content: space-between; padding: 12px; border-radius: 12px; background: var(--flare-color-bg-primary); }
.page { border: 1px solid var(--flare-color-border-secondary); border-radius: 12px; }
.note { margin: 8px 0 0; font-size: 13px; color: var(--flare-color-text-secondary); }
</style>
