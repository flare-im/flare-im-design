<script setup>
import { ref } from "vue";
import { FlareAuthShell, FlareButton, FlareFormField, FlareInput } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";

// 登录页骨架：品牌与标题层级归组件库，表单、校验与提交归宿主（这个 demo）。
// 宽窗口品牌面板在表单旁，窄窗口品牌移到标题上方；返回键发出 back。
const account = ref("");
const password = ref("");
const busy = ref(false);
const log = ref("还没有提交");

function submit() {
  if (!account.value || !password.value) {
    log.value = "请填写账号和密码";
    return;
  }
  busy.value = true;
  log.value = `登录：${account.value}（本地模拟）`;
  setTimeout(() => { busy.value = false; }, 600);
}
</script>

<template>
  <DemoStage>
    <div class="auth-shell-demo">
      <FlareAuthShell
        product="Flare"
        tagline="即时通讯 · 协作"
        headline="消息、群组与工作台，在一处完成"
        description="品牌面板只在宽窗口显示；窄窗口时品牌移到标题上方。"
        title="登录"
        subtitle="使用你的账号继续"
        back-label="返回"
        @back="log = 'back'"
      >
        <form class="auth-shell-demo__form" @submit.prevent="submit">
          <FlareFormField label="账号" required>
            <FlareInput v-model="account" name="username" autocomplete="username" :spellcheck="false" :disabled="busy" @submit="submit" />
          </FlareFormField>
          <FlareFormField label="密码" required>
            <FlareInput v-model="password" name="password" autocomplete="current-password" secure revealable :disabled="busy" @submit="submit" />
          </FlareFormField>
          <FlareButton block label="登录" :loading="busy" @click="submit" />
        </form>
      </FlareAuthShell>
      <p class="auth-shell-demo__status" role="status">{{ log }}</p>
    </div>
  </DemoStage>
</template>

<style scoped>
.auth-shell-demo {
  display: flex;
  flex-direction: column;
  gap: var(--flare-size-spacing-sm);
  width: 100%;
  height: 560px;
}
.auth-shell-demo > :first-child {
  flex: 1;
  min-height: 0;
}
.auth-shell-demo__form {
  display: flex;
  flex-direction: column;
  gap: var(--flare-size-spacing-md);
}
.auth-shell-demo__status {
  margin: 0;
  color: var(--flare-color-text-secondary);
  font-size: var(--flare-text-caption-font-size);
}
</style>
