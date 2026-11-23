<script setup>
import { computed, ref } from "vue";
import { useRoute } from "vitepress";
import { FlareFileUpload } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";
const route = useRoute();
const english = computed(() => route.path.startsWith("/en/"));
const lastEvent = ref("");
const copy = computed(() => english.value
  ? { title: "Verification material", pick: "Choose a file", failed: "Upload failed. Your file is retained.", retry: "Retry", busy: "Uploading 45%", cancel: "Cancel", note: "Controlled preview; no file is uploaded.", event: "Last intent" }
  : { title: "认证材料", pick: "选择文件", failed: "上传失败，已保留所选文件", retry: "重试", busy: "正在上传 45%", cancel: "取消", note: "受控组件预览，不上传文件。", event: "最近操作" });
</script>
<template>
  <DemoStage>
    <div class="file-upload-demo">
      <p class="file-upload-demo__note">{{ copy.note }}</p>
      <FlareFileUpload :title="copy.title" state="failed" :status-text="copy.failed" :pick-label="copy.pick"
        file-name="verification.jpg" :retry-label="copy.retry" host-picker @retry="lastEvent = 'retry'" @replace="lastEvent = 'replace'" />
      <FlareFileUpload :title="copy.title" state="uploading" :status-text="copy.busy" :pick-label="copy.pick"
        :progress="45" :cancel-label="copy.cancel" host-picker @cancel="lastEvent = 'cancel'" />
      <p v-if="lastEvent" role="status" class="file-upload-demo__note">{{ copy.event }}: {{ lastEvent }}</p>
    </div>
  </DemoStage>
</template>
<style scoped>
.file-upload-demo { display: grid; min-width: 0; gap: var(--flare-size-spacing-lg); }
.file-upload-demo__note { margin: 0; color: var(--flare-color-text-secondary); font-size: var(--flare-size-font-size-sm); }
</style>
