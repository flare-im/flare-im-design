<script setup>
import { ref } from "vue";
import FlareFormField from "flare-core-vue-im-ui/components/form/FlareFormField.vue";
import FlareInput from "flare-core-vue-im-ui/components/general/FlareInput.vue";
import FlareSelect from "flare-core-vue-im-ui/components/form/FlareSelect.vue";
import FlareButton from "flare-core-vue-im-ui/components/general/FlareButton.vue";
import DemoStage from "./DemoStage.vue";
const name = ref("Ivy Chen");
const email = ref("");
const lang = ref("zh");
const opts = [{ value: "zh", label: "简体中文" }, { value: "en", label: "English" }];
</script>
<template>
  <DemoStage>
    <div class="form">
      <FlareFormField label="昵称" required hint="展示给好友的名字">
        <FlareInput v-model="name" placeholder="输入昵称" :max-length="24" />
      </FlareFormField>
      <FlareFormField label="邮箱" required :error="email ? '' : '邮箱不能为空'">
        <FlareInput v-model="email" placeholder="you@example.com" />
      </FlareFormField>
      <FlareFormField label="语言">
        <FlareSelect v-model="lang" :options="opts" />
      </FlareFormField>
      <FlareButton label="保存" block />
    </div>
  </DemoStage>
</template>
<style scoped>
.form { display: flex; flex-direction: column; gap: 16px; max-width: 340px; margin: 0 auto; padding: 24px; border-radius: 14px; background: var(--flare-color-bg-primary); border: 1px solid var(--flare-color-border-primary); }
</style>
