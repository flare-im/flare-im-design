<script setup>
import FlareToast from "@flare-im/vue-ui/components/general/FlareToast.vue";
import DemoStage from "./DemoStage.vue";
</script>
<template>
  <DemoStage>
    <div class="stack">
      <FlareToast variant="success" message="消息已发送" />
      <FlareToast variant="error" message="发送失败，请检查网络" action-label="重试" @action="() => {}" />
      <FlareToast variant="info" message="已复制到剪贴板" />
      <FlareToast variant="warning" message="该群已开启全员禁言" />
      <FlareToast variant="loading" message="正在上传附件…" />
    </div>
  </DemoStage>
</template>
<style scoped>
.stack { display: flex; flex-direction: column; gap: 12px; align-items: flex-start; padding: 24px; border-radius: 14px; background: var(--flare-color-bg-secondary); }
</style>
