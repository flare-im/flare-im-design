<script setup lang="ts">
import { computed } from "vue";
import { DocumentTextOutline } from "@vicons/ionicons5";
import { NIcon } from "naive-ui";
import type { ContentElem } from "../../../../utils/contentElem";
import { getContentDecodedPreview } from "../../../../utils/messagePreview";

const props = defineProps<{ content: ContentElem; isSelf: boolean }>();

const preview = computed(() => getContentDecodedPreview(props.content) || "[暂不支持的消息]");
</script>

<template>
  <div class="im-placeholder">
    <n-icon :component="DocumentTextOutline" />
    <span>{{ preview }}</span>
  </div>
</template>

<style scoped>
.im-placeholder {
  display: flex;
  align-items: center;
  gap: 8px;
  color: var(--im-text-secondary);
  font-size: 13px;
}
</style>
