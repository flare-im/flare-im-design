<script setup>
import { FlareUserIdentity } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";

// 宿主只传投影好的昵称、一个账号和头像；加载中与不可用时组件给出提示文字，不显示内部 ID。
</script>

<template>
  <DemoStage>
    <div class="user-identity-demo">
      <FlareUserIdentity :user="{ name: '林晓', account: 'linxiao' }" />
      <FlareUserIdentity :user="{ name: '运营审核用户的完整昵称会完整换行显示', account: 'full-account-20261029' }" />
      <FlareUserIdentity :user="{ state: 'loading' }" />
      <FlareUserIdentity :user="{ state: 'unavailable' }" />
    </div>
  </DemoStage>
</template>

<style scoped>
.user-identity-demo {
  display: grid;
  gap: var(--flare-size-spacing-md);
  max-width: 320px;
}
</style>
