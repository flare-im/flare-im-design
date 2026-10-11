<script setup>
import { FlareTag } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";

// 文字承载含义，色调只是重复它：宿主把每个服务端状态映射到一个色调。
</script>

<template>
  <DemoStage>
    <div class="tag-demo">
      <div class="tag-demo__row">
        <FlareTag label="文本" />
        <FlareTag label="审核中" tone="info" />
        <FlareTag label="正常" tone="success" />
        <FlareTag label="即将到期" tone="warning" />
        <FlareTag label="已冻结" tone="danger" />
      </div>
      <div class="tag-demo__row">
        <FlareTag label="在线" tone="success" dot />
        <FlareTag label="同步中" tone="info" dot />
        <FlareTag label="v2.0.0-rc.1" monospace />
        <FlareTag label="app_7f3a9c" monospace tone="info" />
      </div>
    </div>
  </DemoStage>
</template>

<style scoped>
.tag-demo {
  display: grid;
  gap: var(--flare-size-spacing-md);
}
.tag-demo__row {
  display: flex;
  flex-wrap: wrap;
  gap: var(--flare-size-spacing-sm);
}
</style>
