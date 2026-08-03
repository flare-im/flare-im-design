<script setup>
import FlareComposerSendButton from "@flare-im/vue-ui/components/composer/FlareComposerSendButton.vue";
import DemoStage from "./DemoStage.vue";
</script>

<template>
  <DemoStage>
    <div class="row">
      <div class="cell">
        <FlareComposerSendButton :active="false" />
        <span class="lbl">无内容</span>
      </div>
      <div class="cell">
        <FlareComposerSendButton :active="true" />
        <span class="lbl">可发送</span>
      </div>
    </div>
  </DemoStage>
</template>

<style scoped>
.row { display: flex; gap: 28px; }
.cell { display: flex; flex-direction: column; align-items: center; gap: 6px; }
.lbl { font-size: 12px; color: var(--flare-color-text-tertiary); }
</style>
