<script setup>
import { ref } from "vue";
import { FlareAccountView } from "@flare-im/vue-ui/components";
import vectors from "../../../../spec/account-view-vectors.json";
import DemoStage from "./DemoStage.vue";

// 虚构的钱包页面（spec/account-view-vectors.json）：金额是服务端格式化好的文字，Kit 原样显示、不做合计。
// 点账单项打开本地详情；行动作原样交还宿主，这里只记录最后一次动作。
const lastAction = ref("");
function onAction(id, payload) {
  lastAction.value = `${id} ${JSON.stringify(payload?.row?.input ?? {})}`;
}
</script>

<template>
  <DemoStage>
    <div class="account-view-demo">
      <FlareAccountView :view="vectors.view" @action="onAction" />
      <p v-if="lastAction" class="account-view-demo__log">{{ lastAction }}</p>
    </div>
  </DemoStage>
</template>

<style scoped>
.account-view-demo {
  display: grid;
  gap: var(--flare-size-spacing-md);
}
.account-view-demo__log {
  margin: 0;
  color: var(--flare-color-text-secondary);
  font-size: var(--flare-size-font-size-sm);
}
</style>
