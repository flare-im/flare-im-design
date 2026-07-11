<script setup>
import FlareRichMarkdownInput from "flare-core-vue-im-ui/components/composer/ComposerRichMarkdownInput.vue";
import DemoStage from "./DemoStage.vue";
</script>

<template>
  <DemoStage>
    <div class="stage">
      <FlareRichMarkdownInput placeholder="输入消息，支持 **加粗** / *斜体* / 链接…" formatting-preview />
    </div>
  </DemoStage>
</template>

<style scoped>
.stage { width: 100%; max-width: 480px; }
</style>
