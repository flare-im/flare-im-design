<script setup>
import { computed, ref } from "vue";
import { FlareButton, FlareDataTable, FlareSegmentedControl } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";

// 宿主拥有数据：这里用 25 条本地数据模拟服务端 —— 表格只上报下一个排序 / 页码 / 每页条数，
// 排序与切页都在这个 demo 里完成，再把那一页的行传回去。选中项跨页保留，列设置由宿主持久化。
const columns = [
  { key: "name", title: "姓名", sortable: true, hideable: false, minWidth: 120 },
  { key: "email", title: "邮箱", ellipsis: true, minWidth: 200 },
  { key: "role", title: "角色", sortable: true },
  { key: "messages", title: "消息数", sortable: true, align: "end" },
  { key: "lastActive", title: "最近活跃", sortable: true, align: "end" },
];
const names = ["林悦", "周子涵", "陈思源", "王一鸣", "张若曦", "李沐阳", "赵欣怡", "刘梓豪", "黄诗涵", "吴浩然", "徐雅婷", "孙子墨", "马艺涵", "朱俊杰", "胡可欣", "郭宇航", "何语桐", "高梓睿", "罗欣妍", "梁子轩", "宋雨萱", "谢浩宇", "唐语嫣", "韩梓涵", "冯一诺"];
const roles = ["管理员", "运营", "成员"];
const all = names.map((name, index) => ({
  id: `u${index + 1}`,
  name,
  email: `${["lin", "zhou", "chen", "wang", "zhang"][index % 5]}.${index + 1}@example.com`,
  role: roles[index % 3],
  messages: (index * 37) % 500,
  lastActive: `2026-10-${String((index % 9) + 1).padStart(2, "0")}`,
}));

const sort = ref({ key: "name", order: "asc" });
const pagination = ref({ page: 1, pageSize: 10, total: all.length, pageSizes: [5, 10, 25] });
const selected = ref([]);
const visibleColumns = ref(null);
const loading = ref(false);
const densityIndex = ref(0);
const density = computed(() => (densityIndex.value === 0 ? "comfortable" : "compact"));
const last = ref("还没有操作");

const sorted = computed(() => {
  const current = sort.value;
  if (!current) return all;
  const direction = current.order === "asc" ? 1 : -1;
  return [...all].sort((a, b) => {
    const left = a[current.key];
    const right = b[current.key];
    if (typeof left === "number" && typeof right === "number") return (left - right) * direction;
    return String(left).localeCompare(String(right), "zh-Hans-CN") * direction;
  });
});
const rows = computed(() => {
  const { page, pageSize } = pagination.value;
  return sorted.value.slice((page - 1) * pageSize, page * pageSize);
});

function onSort(next) {
  sort.value = next;
  pagination.value = { ...pagination.value, page: 1 };
  last.value = next ? `排序：${next.key} ${next.order}` : "排序：默认顺序";
}
function onPagination(next) {
  pagination.value = next;
  last.value = `第 ${next.page} 页，每页 ${next.pageSize} 条`;
}
function onRowClick(row) {
  last.value = `打开 ${row.name}`;
}
function freeze(keys, clear) {
  last.value = `冻结 ${keys.length} 个账号（本地模拟）`;
  clear();
}
</script>

<template>
  <DemoStage>
    <div class="dt-demo">
      <FlareDataTable
        label="成员"
        :columns="columns"
        :rows="rows"
        :sort="sort"
        :pagination="pagination"
        :loading="loading"
        :density="density"
        selectable
        column-chooser
        v-model:selected-keys="selected"
        v-model:visible-columns="visibleColumns"
        @update:sort="onSort"
        @update:pagination="onPagination"
        @row-click="onRowClick"
      >
        <template #toolbar>
          <FlareSegmentedControl v-model="densityIndex" :options="['舒适', '紧凑']" />
        </template>
        <template #cell-role="{ value }">
          <span class="dt-demo__role" :data-role="value">{{ value }}</span>
        </template>
        <template #row-actions="{ row }">
          <FlareButton variant="text" size="sm" label="编辑" @click="last = `编辑 ${row.name}`" />
        </template>
        <template #batch="{ selectedKeys, clear }">
          <FlareButton variant="danger" size="sm" label="冻结" @click="freeze(selectedKeys, clear)" />
        </template>
      </FlareDataTable>
      <div class="dt-demo__controls">
        <label><input v-model="loading" type="checkbox" /> loading</label>
        <span>已选 {{ selected.length }} 项（跨页）</span>
        <span>可见列：{{ visibleColumns ? visibleColumns.join("、") : "全部" }}</span>
      </div>
      <p role="status">{{ last }}。排序与分页由 demo 本地完成，表格只上报意图。</p>
    </div>
  </DemoStage>
</template>

<style scoped>
.dt-demo { display: grid; gap: var(--flare-size-spacing-md); width: 100%; min-width: 0; }
.dt-demo__role {
  display: inline-block;
  padding: 0 var(--flare-size-spacing-sm);
  border-radius: var(--flare-size-radius-full);
  background: var(--flare-color-bg-secondary);
  color: var(--flare-color-text-secondary);
  font-size: var(--flare-text-caption-font-size);
  line-height: var(--flare-size-line-height-relaxed);
}
.dt-demo__role[data-role="管理员"] { background: var(--flare-color-bg-selected); color: var(--flare-color-primary-text); }
.dt-demo__controls { display: flex; flex-wrap: wrap; gap: var(--flare-size-spacing-sm) var(--flare-size-spacing-md); align-items: center; font-size: var(--flare-text-caption-font-size); color: var(--flare-color-text-secondary); }
p { margin: 0; font-size: var(--flare-text-caption-font-size); color: var(--flare-color-text-secondary); overflow-wrap: anywhere; }
</style>
