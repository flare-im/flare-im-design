<script setup>
import { ref } from "vue";
import { FlarePermissionTree } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";

// 三层权限目录来自宿主。模型只有叶子权限码：父节点由叶子推出全选 / 半选，所以树里的就是角色真正授予的。
const nodes = [
  {
    code: "users",
    name: "用户管理",
    children: [
      { code: "users.read", name: "查看用户", description: "列表、详情与在线状态" },
      { code: "users.write", name: "编辑用户", description: "改名、冻结与解冻" },
      {
        code: "users.danger",
        name: "高危操作",
        children: [
          { code: "users.danger.delete", name: "删除用户" },
          { code: "users.danger.export", name: "导出用户数据" },
        ],
      },
    ],
  },
  {
    code: "groups",
    name: "群组管理",
    children: [
      { code: "groups.read", name: "查看群组" },
      { code: "groups.write", name: "编辑群组", description: "公告、权限矩阵与成员角色" },
      { code: "groups.dissolve", name: "解散群组" },
    ],
  },
  {
    code: "messages",
    name: "消息管理",
    children: [
      { code: "messages.search", name: "检索消息" },
      {
        code: "messages.moderation",
        name: "内容审核",
        children: [
          { code: "messages.moderation.review", name: "处理举报" },
          { code: "messages.moderation.words", name: "维护敏感词" },
        ],
      },
    ],
  },
  { code: "audit", name: "查看审计日志" },
];
const checked = ref(["users.read", "groups.read", "messages.search", "messages.moderation.review"]);
const readonly = ref(false);
</script>

<template>
  <DemoStage>
    <div class="pt-demo">
      <FlarePermissionTree
        label="角色权限"
        :nodes="nodes"
        v-model:checked-codes="checked"
        :disabled-codes="['users.danger.delete']"
        :readonly="readonly"
      />
      <div class="pt-demo__controls">
        <label><input v-model="readonly" type="checkbox" /> readonly</label>
        <span>已授予：{{ checked.length ? checked.join("、") : "无" }}</span>
      </div>
    </div>
  </DemoStage>
</template>

<style scoped>
.pt-demo { display: grid; gap: var(--flare-size-spacing-md); width: 100%; max-width: 640px; min-width: 0; }
.pt-demo__controls { display: flex; flex-wrap: wrap; gap: var(--flare-size-spacing-sm) var(--flare-size-spacing-md); align-items: center; font-size: var(--flare-text-caption-font-size); color: var(--flare-color-text-secondary); overflow-wrap: anywhere; }
</style>
