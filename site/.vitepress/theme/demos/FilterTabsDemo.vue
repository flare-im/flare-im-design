<script setup>
import { ref } from "vue";
import FlareFilterTabs from "flare-core-vue-im-ui/components/general/FlareFilterTabs.vue";

const active = ref("all");
const options = [
  { value: "all", label: "全部" },
  { value: "unread", label: "未读", badge: 3 },
  { value: "groups", label: "群组" },
  { value: "bots", label: "机器人" },
  { value: "official", label: "官方" },
];
</script>

<template>
  <div class="ft-demo">
    <FlareFilterTabs v-model="active" :options="options" />
    <div class="ft-demo__log">当前筛选 · active: {{ active }}</div>
  </div>
</template>

<style scoped>
.ft-demo {
  width: 100%;
  max-width: 420px;
  display: flex;
  flex-direction: column;
  gap: 10px;
}
.ft-demo__log {
  font-size: 12px;
  color: var(--flare-color-text-tertiary);
}
</style>
