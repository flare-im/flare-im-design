<script setup>
import { computed, ref } from "vue";
import { FlareActivityList, FlareButton } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";

// 宿主持有行与已读状态：点一行就把它标成已读（列表自己不记已读）；页脚放「加载更多」。
const rows = ref([
  { id: "a1", title: "林夏赞了你的动态", description: "周末去爬山，山顶信号居然满格。", time: "3 分钟前", unread: true },
  { id: "a2", title: "何川评论了你的动态", description: "带上我！", time: "20 分钟前", unread: true },
  { id: "a3", title: "苏晚晴在评论中提到了你", description: "@你 下次一起", time: "昨天" },
]);
const more = [
  { id: "a4", title: "周屿赞了你的动态", time: "2 天前" },
  { id: "a5", title: "Ivy Chen 评论了你的动态", description: "第三张构图绝了", time: "3 天前" },
];
const empty = ref(false);
const compact = ref(true);
const shown = computed(() => (empty.value ? [] : rows.value));
function select(id) {
  rows.value = rows.value.map((row) => (row.id === id ? { ...row, unread: false } : row));
}
function loadMore() {
  rows.value = [...rows.value, ...more.splice(0)];
}
</script>

<template>
  <DemoStage>
    <div class="activity-demo">
      <FlareActivityList :items="shown" :density="compact ? 'compact' : 'normal'" empty-description="赞、评论和回复会显示在这里" empty-action-text="查看示例通知" @empty-action="empty = false" empty-text="暂无互动通知" aria-label="圈子互动通知" @select="select">
        <template #footer>
          <div v-if="more.length && !empty" class="activity-demo__footer">
            <FlareButton variant="secondary" size="sm" label="加载更多" @click="loadMore" />
          </div>
        </template>
      </FlareActivityList>
      <FlareButton variant="ghost" size="sm" :label="compact ? '标准间距' : '紧凑间距'" @click="compact = !compact" />
      <FlareButton variant="ghost" size="sm" :label="empty ? '显示通知' : '显示空态'" @click="empty = !empty" />
    </div>
  </DemoStage>
</template>

<style scoped>
.activity-demo {
  display: grid;
  gap: var(--flare-size-spacing-md);
  width: 100%;
  max-width: 420px;
}
.activity-demo :deep(.flare-activity-list) {
  max-height: 360px;
  border: 1px solid var(--flare-color-border-secondary);
  border-radius: var(--flare-size-radius-lg);
  background: var(--flare-color-bg-primary);
}
.activity-demo__footer {
  display: flex;
  justify-content: center;
  padding: var(--flare-size-spacing-sm);
}
</style>
