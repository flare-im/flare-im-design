<script setup>
import { computed, ref } from "vue";
import { FlareCheckbox, FlareSchemaForm } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";

// 插件配置页：schema 由插件声明，值由宿主（这个 demo）持有；表单每次修改发出新对象。
// 字符串枚举画成下拉，integer 画成整数输入，boolean 画成开关，string 画成文本框。
const schema = {
  type: "object",
  $defs: { Currency: { type: "string", title: "币种", enum: ["CNY", "USD", "EUR"] } },
  properties: {
    enabled: { type: "boolean", title: "启用红包" },
    currency: { $ref: "#/$defs/Currency" },
    maxAmount: { type: "integer", title: "单个红包上限", description: "单位：分，1 到 20000。", minimum: 1, maximum: 20000 },
    greeting: { type: "string", title: "默认祝福语" },
  },
};
const values = ref({ enabled: true, currency: "CNY", maxAmount: 20000, greeting: "恭喜发财" });
const locked = ref(false);
const preview = computed(() => JSON.stringify(values.value));
</script>

<template>
  <DemoStage>
    <div class="schema-form-demo">
      <FlareSchemaForm v-model="values" :schema="schema" :disabled="locked" />
      <FlareCheckbox v-model="locked" label="锁定（disabled）" />
      <p class="schema-form-demo__status" role="status">{{ preview }}</p>
    </div>
  </DemoStage>
</template>

<style scoped>
.schema-form-demo {
  display: grid;
  gap: var(--flare-size-spacing-md);
  width: 100%;
  max-width: 420px;
}
.schema-form-demo__status {
  margin: 0;
  color: var(--flare-color-text-secondary);
  font-family: ui-monospace, monospace;
  font-size: var(--flare-text-caption-font-size);
  overflow-wrap: anywhere;
}
</style>
