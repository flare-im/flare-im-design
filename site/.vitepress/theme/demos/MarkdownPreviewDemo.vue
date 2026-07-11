<script setup>
import FlareMarkdownPreview from "flare-core-vue-im-ui/components/message-preview/MarkdownPreview.vue";
import DemoStage from "./DemoStage.vue";

const content = `## 新版设计稿

- 支持 **加粗**、*斜体*、\`代码\`
- 列表与 [链接](https://flare.im)

> 引用：一套契约，四端原生实现。`;
</script>

<template>
  <DemoStage>
    <div class="stage">
      <FlareMarkdownPreview :content="content" show-stats />
    </div>
  </DemoStage>
</template>

<style scoped>
.stage { width: 100%; max-width: 420px; }
</style>
