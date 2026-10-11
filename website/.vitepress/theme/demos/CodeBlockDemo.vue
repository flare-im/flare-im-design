<script setup>
import { ref } from "vue";
import { FlareCodeBlock } from "@flare-im/vue-ui/components";
import DemoStage from "./DemoStage.vue";

// 原始报文与初始化代码：文本由宿主格式化，代码块原样保留、在自己的框里滚动、复制全文。
const payload = JSON.stringify({
  server_id: "m_01HZX3K9Q2V7",
  conversation_id: "c_8f2e41",
  conversation_seq: 1287,
  sender_id: "u_10086",
  content_kind: "image",
  status: 2,
  attributes: { "x-trace": "7f3a", source: "web" },
  extension_keys: ["reactions"],
}, null, 2);
const snippet = [
  'import { createFlareClient } from "@flare-im/sdk";',
  "",
  "const client = createFlareClient({",
  '  appId: "app_demo",',
  '  endpoint: "wss://im.example.com/ws",',
  "  token: await fetchTestToken(),",
  "});",
].join("\n");
const last = ref("还没有复制");
function onCopy(what, copied) {
  last.value = copied ? `已复制${what}` : "浏览器拒绝了复制";
}
</script>

<template>
  <DemoStage>
    <div class="code-demo">
      <FlareCodeBlock language="JSON" label="消息原始报文" :code="payload" max-height="240px" @copy="(copied) => onCopy('报文', copied)" />
      <FlareCodeBlock language="TypeScript" label="初始化代码" :code="snippet" wrap @copy="(copied) => onCopy('初始化代码', copied)" />
      <p class="code-demo__status" role="status">{{ last }}</p>
    </div>
  </DemoStage>
</template>

<style scoped>
.code-demo {
  display: grid;
  gap: var(--flare-size-spacing-md);
  width: 100%;
  max-width: 640px;
}
.code-demo__status {
  margin: 0;
  color: var(--flare-color-text-secondary);
  font-size: var(--flare-text-caption-font-size);
}
</style>
