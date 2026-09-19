<script setup>
import { SearchOutline, AddCircleOutline } from "@vicons/ionicons5";
import { FlareIconButton, FlareScreenHeader } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";
</script>
<template>
  <DemoStage>
    <div class="stage">
      <FlareScreenHeader title="消息">
        <template #actions>
          <FlareIconButton :icon="SearchOutline" aria-label="搜索" />
          <FlareIconButton :icon="AddCircleOutline" aria-label="新建" />
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
