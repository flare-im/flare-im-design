<script setup>
import { FlareUiProvider } from "@flare-im/vue-ui/components";
import { FlareButton } from "@flare-im/vue-ui/components";
import { FlareSelect } from "@flare-im/vue-ui/components";
import ConfigPlaygroundPanel from "./ConfigPlaygroundPanel.vue";
import DemoStage from "./DemoStage.vue";
const opts = [{ value: "a", label: "选项 A" }, { value: "b", label: "选项 B" }];
</script>
<template>
  <DemoStage>
    <div class="stack">
      <!-- Live: one provider drives language + theme + size for everything inside -->
      <FlareUiProvider>
        <ConfigPlaygroundPanel />
      </FlareUiProvider>

      <!-- Static: size inherited from the provider by every descendant -->
      <div class="sub">size 继承</div>
      <FlareUiProvider size="sm">
        <div class="row"><span class="tag">size="sm"</span><FlareButton label="按钮" /><FlareButton label="Ghost" variant="ghost" /><FlareSelect :options="opts" placeholder="选择" /></div>
      </FlareUiProvider>
      <FlareUiProvider size="lg">
        <div class="row"><span class="tag">size="lg"</span><FlareButton label="按钮" /><FlareButton label="Ghost" variant="ghost" /><FlareSelect :options="opts" placeholder="选择" /></div>
      </FlareUiProvider>
    </div>
  </DemoStage>
</template>
<style scoped>
.stack { display: flex; flex-direction: column; gap: 18px; padding: 24px; border-radius: 14px; background: var(--flare-color-bg-secondary); }
.sub { font-size: 12px; color: var(--flare-color-text-tertiary); margin-top: 4px; }
.row { display: flex; align-items: center; gap: 12px; flex-wrap: wrap; }
.tag { width: 80px; font-size: 12px; font-family: var(--vp-font-family-mono); color: var(--flare-color-text-tertiary); }
</style>
