<script setup>
import { ref } from "vue";
import { FlareButton, FlareDrawer } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";
// 抽屉承载长驻的次级内容；页内导航由宿主驱动：换页时打开 showBack，
// Escape 与平台返回键发出 back（退一页），遮罩与关闭键关掉整个抽屉。
const open = ref(false);
const page = ref("root");
const pages = { root: "群设置", members: "群成员" };
const members = ["林夏", "周屿", "陈可", "许知远"];
function close() {
  open.value = false;
  page.value = "root";
}
</script>
<template>
  <DemoStage>
    <FlareButton label="打开侧边抽屉" @click="open = true" />
    <FlareDrawer
      :open="open"
      :title="pages[page]"
      :show-back="page !== 'root'"
      @back="page = 'root'"
      @close="close"
    >
      <ul v-if="page === 'root'" class="list">
        <li><button type="button" class="row" @click="page = 'members'">群成员 · {{ members.length }}</button></li>
        <li><button type="button" class="row">消息免打扰</button></li>
        <li><button type="button" class="row">置顶聊天</button></li>
      </ul>
      <ul v-else class="list">
        <li v-for="name in members" :key="name" class="member">{{ name }}</li>
      </ul>
      <template #footer>
        <FlareButton label="退出群聊" variant="danger" block @click="close" />
      </template>
    </FlareDrawer>
  </DemoStage>
</template>
<style scoped>
.list { list-style: none; margin: 0; padding: var(--flare-size-spacing-sm) 0; }
.row, .member { display: flex; align-items: center; width: 100%; min-height: var(--flare-size-layout-touch-target); padding: 0 var(--flare-size-spacing-lg); font-size: var(--flare-size-font-size-lg); color: var(--flare-color-text-primary); }
.row { border: 0; background: none; text-align: start; cursor: pointer; }
.row:hover { background: var(--flare-color-bg-hover); }
</style>
