<script setup>
import { ref } from "vue";
import { FlareButton, FlareFileMessage as C } from "@flare-im/vue-ui/components";
import DemoIcon from "../../DemoIcon.vue";
const log = ref("");
// 右侧的键跟着宿主的下载状态走：下载 → 下载中 → 文件夹（在文件夹中显示）；
// 文件被删了，宿主把状态放回 idle，键又变回下载。
const state = ref("idle");
const onDisk = ref(false);
function download() {
  state.value = "downloading";
  log.value = "download · 宿主开始保存";
  setTimeout(() => {
    state.value = "openFolder";
    onDisk.value = true;
    log.value = "已保存 · 键变成文件夹";
  }, 1200);
}
function reveal() {
  if (onDisk.value) {
    log.value = "reveal · 宿主在文件管理器里定位这个文件";
    return;
  }
  state.value = "idle";
  log.value = "reveal · 文件已不在，键回到下载";
}
</script>
<template>
  <div class="wrap">
    <C name="设计规范 v2.pdf" size="2.4 MB" ext="PDF" :state="state"
      @open="log = 'open · 打开文件（宿主用自己的 URL）'"
      @download="download"
      @reveal="reveal" />
    <!-- 自定义图标：用 icon 插槽换成任意图标 -->
    <C name="周会录屏.mp4" size="18 MB" ext="MP4"
      @open="log = 'open · 视频文件'" @download="log = 'download · 视频文件'">
      <template #icon><DemoIcon name="video" :size="20" /></template>
    </C>
    <FlareButton size="sm" label="模拟：在本机删掉第一个文件" :disabled="!onDisk" @click="onDisk = false" />
    <div class="echo">{{ log || "点卡片 = open，点右侧的键 = download；保存后键变成文件夹（reveal）。第二个用 #icon 插槽自定义了图标" }}</div>
  </div>
</template>
<style scoped>
.wrap { display: flex; flex-direction: column; gap: 10px; align-items: flex-start; }
.echo { font-size: 12px; color: var(--flare-color-text-tertiary); margin-top: 4px; }
</style>
