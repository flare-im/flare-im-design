<script setup>
import { computed, ref } from "vue";
import { FlareReadReceiptSheet, FlareSegmentedControl } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";
// 标签上的数字取宿主传的摘要人数（readSummary），名单按页追加：这里两栏各三页，「加载更多」用定时器模拟。
const STATES = ["ready", "loading", "error", "unavailable"];
const mode = ref(0);
const state = computed(() => STATES[mode.value]);
const names = ["Ivy Chen", "Leo Wang", "Ada Li", "Mia Zhou", "Sam Gao", "Kai Xu", "Zoe He", "Max Lu", "Eli Ma"];
const page = (prefix, from) => names.slice(from, from + 3).map((name, i) => ({ id: `${prefix}-${from + i}`, name }));
const readers = ref(page("r", 0));
const unread = ref(page("u", 0));
const loadingMore = ref(null);
const failedOnce = ref(false);
const loadMoreFailed = ref(null);
// The template hands the arrays over unwrapped (`readers`, not `readers.value`).
const hasMore = (list) => list.length < names.length;
function loadMore(column) {
  const list = column === "read" ? readers : unread;
  loadingMore.value = column;
  loadMoreFailed.value = null;
  setTimeout(() => {
    loadingMore.value = null;
    // The unread column's second page fails once, to show the retry key.
    if (column === "unread" && !failedOnce.value) {
      failedOnce.value = true;
      loadMoreFailed.value = column;
      return;
    }
    list.value = [...list.value, ...page(column === "read" ? "r" : "u", list.value.length)];
  }, 800);
}
</script>
<template>
  <DemoStage>
    <FlareSegmentedControl v-model="mode" class="switch" :options="['名单', '读取中', '读取失败', '不可查看']" />
    <div class="stage">
      <FlareReadReceiptSheet
        :readers="readers"
        :unread="unread"
        :read-count="30"
        :unread-count="12"
        :state="state"
        :read-has-more="hasMore(readers)"
        :unread-has-more="hasMore(unread)"
        :loading-more="loadingMore"
        :load-more-failed="loadMoreFailed"
        dismissible
        @load-more="loadMore"
        @retry="mode = 0"
      />
    </div>
  </DemoStage>
</template>
<style scoped>
.switch { margin-bottom: 12px; }
.stage { display: flex; justify-content: center; padding: 24px; border-radius: 14px; background: var(--flare-color-bg-secondary); }
</style>
