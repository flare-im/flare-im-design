<script setup>
import { computed, ref } from "vue";
import FlareStorageUsage from "@flare-im/vue-ui/components/profile/FlareStorageUsage.vue";
import DemoStage from "./DemoStage.vue";

const MB = 1024 * 1024;
const GB = 1024 * MB;

function snapshot() {
  return [
    { id: "images", label: "图片与视频", bytes: 1.4 * GB, fileCount: 2160, clearable: true },
    { id: "files", label: "文件", bytes: 268 * MB, fileCount: 74, clearable: true },
    { id: "voice", label: "语音", bytes: 12 * MB, fileCount: 310, clearable: true },
    // Not measured yet: it reads 未知, draws no bar, and still offers a clear button.
    { id: "cache", label: "临时缓存", bytes: null, clearable: true },
    // Measured at exactly 0: no clear button, because there is nothing to clear.
    { id: "drafts", label: "草稿", bytes: 0, fileCount: 0, clearable: true },
    // The host cannot clear the database, so no button at all.
    { id: "database", label: "消息数据库", bytes: 96 * MB, clearable: false },
  ];
}

const categories = ref(snapshot());
const loading = ref(false);
const error = ref("");
// Demo switch: the host pretends the next 临时缓存 clear fails, to show partial failure.
const failCache = ref(true);
const last = ref("尚未操作");

function clear(id) {
  last.value = `clear：${id}`;
  // The host sets busy synchronously before dispatching, per category.
  categories.value = categories.value.map((c) =>
    c.id === id ? { ...c, busy: true, error: undefined } : c,
  );
  setTimeout(() => {
    categories.value = categories.value.map((c) => {
      if (c.id !== id) return c;
      if (id === "cache" && failCache.value) {
        // Failure keeps the row and its reason; every other row keeps its result.
        return { ...c, busy: false, error: "清理失败：缓存目录被占用，请稍后重试" };
      }
      return { ...c, busy: false, error: undefined, bytes: 0, fileCount: 0 };
    });
  }, 900);
}

function reload() {
  last.value = "reload";
  error.value = "";
  loading.value = true;
  categories.value = [];
  setTimeout(() => {
    loading.value = false;
    categories.value = snapshot();
  }, 1200);
}

function dismiss(id) {
  last.value = `dismissError：${id ?? "整体"}`;
  if (id === null) {
    error.value = "";
    return;
  }
  categories.value = categories.value.map((c) => (c.id === id ? { ...c, error: undefined } : c));
}

function failWhole() {
  error.value = "统计失败：无法读取本机存储目录";
}
function emptyOut() {
  categories.value = [];
  error.value = "";
  loading.value = false;
}
function reset() {
  categories.value = snapshot();
  loading.value = false;
  error.value = "";
  failCache.value = true;
  last.value = "尚未操作";
}

const summary = computed(() =>
  categories.value.length ? `${categories.value.length} 个分类` : "无分类",
);
</script>

<template>
  <DemoStage>
    <div class="storage-demo">
      <FlareStorageUsage
        :categories="categories"
        :device-free-bytes="18.6 * 1024 * 1024 * 1024"
        :loading="loading"
        :error="error"
        @clear="clear"
        @reload="reload"
        @dismiss-error="dismiss"
      />

      <div class="storage-demo__controls">
        <label><input v-model="failCache" type="checkbox" /> 让「临时缓存」清理失败</label>
        <button type="button" @click="failWhole">整体统计失败</button>
        <button type="button" @click="emptyOut">清空分类（空态）</button>
        <button type="button" @click="reload">重新统计（加载态）</button>
        <button type="button" @click="reset">重置演示</button>
      </div>
      <p role="status">{{ last }}。当前：{{ summary }}。本地模拟，不触发 SDK。</p>
    </div>
  </DemoStage>
</template>

<style scoped>
.storage-demo { width: 100%; min-width: 0; display: grid; gap: 16px; max-width: 560px; }
.storage-demo__controls { display: flex; flex-wrap: wrap; gap: 8px 14px; align-items: center; font-size: 13px; }
.storage-demo__controls button {
  min-height: 40px;
  padding: 6px 12px;
  border: 1px solid var(--flare-color-border-primary);
  border-radius: 8px;
  background: var(--flare-color-bg-primary);
  color: inherit;
}
p { font-size: 13px; overflow-wrap: anywhere; }
</style>
