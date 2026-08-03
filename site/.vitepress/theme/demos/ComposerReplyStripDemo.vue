<script setup>
import FlareComposerReplyStrip from "@flare-im/vue-ui/components/composer/FlareComposerReplyStrip.vue";
import DemoStage from "./DemoStage.vue";
</script>

<template>
  <DemoStage>
    <div class="stage">
      <FlareComposerReplyStrip sender-name="Ivy Chen" summary="新版设计稿已经上传啦，帮忙看下～" />
    </div>
  </DemoStage>
</template>

<style scoped>
.stage { width: 100%; max-width: 420px; }
</style>
