<script setup>
import FlareConfigProvider from "flare-core-vue-im-ui/components/general/FlareConfigProvider.vue";
import FlareButton from "flare-core-vue-im-ui/components/general/FlareButton.vue";
import FlareSelect from "flare-core-vue-im-ui/components/form/FlareSelect.vue";
import ConfigPlaygroundPanel from "./ConfigPlaygroundPanel.vue";
import DemoStage from "./DemoStage.vue";
const opts = [{ value: "a", label: "选项 A" }, { value: "b", label: "选项 B" }];
</script>
<template>
  <DemoStage>
    <div class="stack">
      <!-- Live: one provider drives language + theme + size for everything inside -->
      <FlareConfigProvider>
        <ConfigPlaygroundPanel />
      </FlareConfigProvider>

      <!-- Static: size inherited from the provider by every descendant -->
      <div class="sub">size 继承</div>
      <FlareConfigProvider size="sm">
        <div class="row"><span class="tag">size="sm"</span><FlareButton label="按钮" /><FlareButton label="Ghost" variant="ghost" /><FlareSelect :options="opts" placeholder="选择" /></div>
      </FlareConfigProvider>
      <FlareConfigProvider size="lg">
        <div class="row"><span class="tag">size="lg"</span><FlareButton label="按钮" /><FlareButton label="Ghost" variant="ghost" /><FlareSelect :options="opts" placeholder="选择" /></div>
      </FlareConfigProvider>
    </div>
  </DemoStage>
</template>
<style scoped>
.stack { display: flex; flex-direction: column; gap: 18px; padding: 24px; border-radius: 14px; background: var(--flare-color-bg-secondary); }
.sub { font-size: 12px; color: var(--flare-color-text-tertiary); margin-top: 4px; }
.row { display: flex; align-items: center; gap: 12px; flex-wrap: wrap; }
.tag { width: 80px; font-size: 12px; font-family: var(--vp-font-family-mono); color: var(--flare-color-text-tertiary); }
</style>
