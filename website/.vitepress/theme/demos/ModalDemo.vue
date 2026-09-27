<script setup>
import { ref } from "vue";
import { FlareButton, FlareModal } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";
// 模态框承载需要专注完成的任务；busy 期间关闭键、Escape、平台返回与遮罩都不生效。
const open = ref(false);
const busy = ref(false);
async function save() {
  busy.value = true;
  await new Promise((resolve) => setTimeout(resolve, 600));
  busy.value = false;
  open.value = false;
}
</script>
<template>
  <DemoStage>
    <FlareButton label="打开模态框" @click="open = true" />
    <FlareModal :open="open" title="群公告" :busy="busy" @close="open = false">
      <p class="body">本周五 18:00 进行版本发布演练，请各位提前同步分支并在群里确认负责模块。</p>
      <template #footer>
        <FlareButton label="取消" variant="secondary" :disabled="busy" @click="open = false" />
        <FlareButton label="发布" :loading="busy" @click="save" />
      </template>
    </FlareModal>
  </DemoStage>
</template>
<style scoped>
.body { margin: 0; font-size: var(--flare-size-font-size-lg); line-height: 1.6; color: var(--flare-color-text-primary); }
</style>
