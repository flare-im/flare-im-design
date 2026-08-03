<script setup>
import FlareSlashCommandMenu from "@flare-im/vue-ui/components/composer/FlareSlashCommandMenu.vue";
import DemoStage from "./DemoStage.vue";
const commands = [
  { command: "mute", description: "临时禁言某位成员", hint: "@user 10m" },
  { command: "remind", description: "设置一条稍后提醒", hint: "18:00 开会" },
  { command: "poll", description: "发起一个群投票", hint: "问题 选项…" },
  { command: "shrug", description: "插入 ¯\\_(ツ)_/¯" },
  { command: "giphy", description: "搜索并发送 GIF", hint: "关键词" },
];
</script>
<template>
  <DemoStage>
    <div class="stage">
      <FlareSlashCommandMenu :commands="commands" query="" @select="() => {}" @close="() => {}" />
    </div>
  </DemoStage>
</template>
<style scoped>
.stage { display: flex; justify-content: center; padding: 24px; border-radius: 14px; background: var(--flare-color-bg-secondary); }
</style>
