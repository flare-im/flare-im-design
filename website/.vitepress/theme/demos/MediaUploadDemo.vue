<script setup>
import { computed, onBeforeUnmount, ref, watch } from "vue";
import { useRoute } from "vitepress";
import { FlareImagePreview, FlareMediaUpload, FlareSegmentedControl } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";
const route = useRoute();
const en = computed(() => route.path.startsWith('/en/'));
const t = (zh, english) => en.value ? english : zh;
const mode = ref(2);
const items = ref([]);
const error = ref('');
const previewId = ref(null);
const previewImages = computed(() => items.value.filter(item => !!item.previewUrl));
const previewIndex = computed(() => previewImages.value.findIndex(item => item.id === previewId.value));
const previewItem = computed(() => previewImages.value[previewIndex.value]);
watch(previewItem, item => { if (!item) previewId.value = null; });
function movePreview(offset) { const item = previewImages.value[previewIndex.value + offset]; if (item) previewId.value = item.id; }
const urls = new Set();
const timers = new Map();
let serial = 0;
const layout = computed(() => mode.value === 1 ? 'files' : 'images');
const max = computed(() => mode.value === 2 ? 9 : 12);
const art = 'data:image/svg+xml,' + encodeURIComponent('<svg xmlns="http://www.w3.org/2000/svg" width="200" height="200"><rect width="200" height="200" fill="#d7e7df"/><path d="M0 140 70 65 120 120 155 90 200 150V200H0Z" fill="#8cb6a3"/><circle cx="150" cy="45" r="20" fill="#f1d99a"/></svg>');
function reset() {
  previewId.value = null;
  for (const timer of timers.values()) clearTimeout(timer);
  timers.clear();
  for (const url of urls) URL.revokeObjectURL(url);
  urls.clear();
  error.value = '';
  const count = mode.value === 0 ? 0 : mode.value === 2 ? 9 : 3;
  items.value = Array.from({length: count}, (_, index) => ({
    id: `example-${index}`, name: layout.value === 'images' ? `photo-${index + 1}.jpg` : `document-${index + 1}.pdf`,
    state: index === 1 ? 'uploading' : index === 2 ? 'failed' : 'uploaded',
    statusText: index === 1 ? t('上传中 45%', 'Uploading 45%') : index === 2 ? t('上传失败，可重试', 'Upload failed. Retry available.') : t('已上传', 'Uploaded'),
    progress: index === 1 ? 45 : undefined, previewUrl: layout.value === 'images' ? art : undefined,
  }));
}
watch(mode, reset, { immediate: true });
function selected(files) {
  if (items.value.length + files.length > max.value) {
    error.value = t(`最多选择 ${max.value} 项，请调整本次选择。已有文件已保留。`, `Choose at most ${max.value} items. Existing files are retained.`);
    return;
  }
  error.value = '';
  items.value.push(...files.map((file) => {
    const url = layout.value === 'images' && file.type.startsWith('image/') ? URL.createObjectURL(file) : undefined;
    if (url) urls.add(url);
    return { id: `local-${serial++}`, name: file.name, state: 'selected', statusText: t('已选择，等待上传', 'Selected, ready to upload'), previewUrl: url };
  }));
}
function transfer(id) {
  const item = items.value.find(item => item.id === id);
  if (!item) return;
  item.state = 'uploading'; item.progress = 45; item.statusText = t('上传中 45%', 'Uploading 45%');
  clearTimeout(timers.get(id));
  const timer = setTimeout(() => {
    if (timers.get(id) !== timer) return;
    timers.delete(id);
    if (!items.value.includes(item) || item.state !== 'uploading') return;
    item.state = 'uploaded'; item.progress = 100; item.statusText = t('已上传', 'Uploaded');
  }, 1000);
  timers.set(id, timer);
}
function cancel(id) {
  clearTimeout(timers.get(id)); timers.delete(id);
  const item = items.value.find(item => item.id === id);
  if (item) { item.state = 'selected'; item.progress = undefined; item.statusText = t('已取消，文件已保留', 'Cancelled; file retained'); }
}
function remove(id) {
  clearTimeout(timers.get(id)); timers.delete(id);
  const item = items.value.find(item => item.id === id);
  if (urls.has(item?.previewUrl)) { URL.revokeObjectURL(item.previewUrl); urls.delete(item.previewUrl); }
  items.value = items.value.filter(item => item.id !== id);
}
onBeforeUnmount(() => { for (const timer of timers.values()) clearTimeout(timer); for (const url of urls) URL.revokeObjectURL(url); });
</script>
<template>
  <DemoStage>
    <div class="media-upload-demo">
      <FlareSegmentedControl v-model="mode" :options="[t('空态','Empty'), t('文件队列','Files'), t('九图上传','Nine images'), t('消息图组','Image group')]" :aria-label="t('上传场景','Upload scenario')" />
      <p class="media-upload-demo__note">{{ t('本地交互预览：支持选择、拖拽、取消和重试，文件不会上传到服务器。', 'Local interaction preview: pick, drop, cancel and retry. Files are never uploaded to a server.') }}</p>
      <FlareMediaUpload :title="layout === 'images' ? t('图片附件','Images') : t('文件附件','Files')" :items="items" :layout="layout" :max-count="max" :error="error"
        :status-text="items.length >= max ? t('已达数量上限，移除后可继续添加。','Limit reached. Remove an item to add more.') : t('可点击或拖入固定区域；格式、大小与数量由宿主校验。','Choose or drop files into this area. The host validates type, size and count.')"
        :pick-label="t('选择文件','Choose files')" :accept="layout === 'images' ? 'image/*' : undefined"
        :upload-label="t('上传','Upload')" :retry-label="t('重试','Retry')" :cancel-label="t('取消','Cancel')" :remove-label="t('移除','Remove')"
        :preview-label="t('预览','Preview')" @select="selected" @upload="transfer" @retry="transfer" @cancel="cancel" @remove="remove" @preview="previewId = $event" />
      <FlareImagePreview v-if="previewItem" :show="true" :image-src="previewItem.previewUrl" :alt="previewItem.name"
        :loading-text="t('加载中','Loading')" :error-text="t('图片加载失败','Image failed to load')" :retry-text="t('重试','Retry')"
        :gallery-index="previewIndex" :gallery-count="previewImages.length" @update:show="previewId = null"
        @previous="movePreview(-1)" @next="movePreview(1)" />
    </div>
  </DemoStage>
</template>
<style scoped>
.media-upload-demo { display: grid; min-width: 0; gap: var(--flare-size-spacing-md); width: 100%; max-width: var(--flare-size-layout-detail-pane-max-width); margin-inline: auto; }
.media-upload-demo__note { margin: 0; color: var(--flare-color-text-secondary); font-size: var(--flare-size-font-size-sm); }
</style>
