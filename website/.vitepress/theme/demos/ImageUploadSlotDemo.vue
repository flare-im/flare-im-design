<script setup>
import { computed, ref } from 'vue';
import { FlareImageUploadSlot, FlareSegmentedControl } from '@flare-im/vue-ui/components';
import DemoStage from './DemoStage.vue';
const index = ref(0);
const states = ['empty', 'selected', 'uploading', 'uploaded', 'failed'];
const state = computed(() => states[index.value]);
const texts = ['点击选择图片', '已选择，等待上传', '上传中 45%', '已上传', '上传失败，可重试'];
</script>
<template>
  <DemoStage>
    <div class="image-slot-demo">
    <div class="image-slot-demo">
      <FlareSegmentedControl v-model="index" :options="['空态', '待上传', '上传中', '已完成', '失败']" aria-label="图片上传状态" />
      <FlareImageUploadSlot title="图片材料" :state="state" :status-text="texts[index]" pick-label="选择图片" :progress="45" action-label="继续" replaceable
        @choose="index = 1" @action="index = 2" />
    </div>
    </div>
  </DemoStage>
</template>
<style scoped>
.image-slot-demo { display: grid; min-width: 0; gap: var(--flare-size-spacing-md); }
</style>
