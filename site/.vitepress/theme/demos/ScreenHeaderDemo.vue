<script setup>
import { NIcon } from "naive-ui";
import { SearchOutline, AddCircleOutline } from "@vicons/ionicons5";
import FlareScreenHeader from "@flare-im/vue-ui/components/layout/FlareScreenHeader.vue";
import DemoStage from "./DemoStage.vue";
</script>
<template>
  <DemoStage>
    <div class="stage">
      <FlareScreenHeader title="消息">
        <template #actions>
          <n-icon :size="22" :component="SearchOutline" style="cursor:pointer" />
          <n-icon :size="22" :component="AddCircleOutline" style="cursor:pointer" />
        </template>
      </FlareScreenHeader>
      <FlareScreenHeader title="通讯录" />
    </div>
  </DemoStage>
</template>
<style scoped>
.stage { display: flex; flex-direction: column; gap: 12px; padding: 20px; border-radius: 14px; background: var(--flare-color-bg-secondary); }
.stage > * { border-radius: 10px; overflow: hidden; border: 1px solid var(--flare-color-border-primary); }
</style>
