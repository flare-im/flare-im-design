<script setup>
import { ref } from "vue";
import C from "flare-core-vue-im-ui/components/messages/standalone/FlareFileMessage.vue";
import DemoIcon from "../../DemoIcon.vue";
const log = ref("");
</script>
<template>
  <div class="wrap">
    <C name="设计规范 v2.pdf" size="2.4 MB" ext="PDF"
      @open="log = 'open · 打开文件（宿主用自己的 URL）'"
      @download="log = 'download · 下载（宿主用自己的 URL）'" />
    <!-- 自定义图标：用 icon 插槽换成任意图标 -->
    <C name="周会录屏.mp4" size="18 MB" ext="MP4"
      @open="log = 'open · 视频文件'" @download="log = 'download · 视频文件'">
      <template #icon><DemoIcon name="video" :size="20" /></template>
    </C>
    <div class="echo">{{ log || "点卡片 = open，点下载图标 = download；第二个用 #icon 插槽自定义了图标" }}</div>
  </div>
</template>
<style scoped>
.wrap { display: flex; flex-direction: column; gap: 10px; align-items: flex-start; }
.echo { font-size: 12px; color: var(--flare-color-text-tertiary); margin-top: 4px; }
</style>
