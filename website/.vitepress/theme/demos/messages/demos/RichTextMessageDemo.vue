<script setup>
import { FlareRichTextMessage as C } from "@flare-im/vue-ui/components";
const text = (value, ...marks) => (marks.length ? { type: "text", text: value, marks: marks.map((type) => ({ type })) } : { type: "text", text: value });
const docJson = JSON.stringify({
  type: "doc",
  version: 2,
  children: [
    { type: "heading", level: 2, children: [text("周会纪要")] },
    { type: "paragraph", children: [text("结论："), text("周五发布", "bold"), text("，详见 "), { type: "link", href: "https://flare.im", children: [text("发布说明")] }] },
    { type: "bullet_list", children: [
      { type: "list_item", children: [{ type: "paragraph", children: [text("前端："), { type: "inline_code", text: "npm test" }, text(" 全绿")] }] },
      { type: "list_item", children: [{ type: "paragraph", children: [text("服务端灰度 "), text("10%", "strike"), text(" 30%")] }] },
    ] },
    { type: "quote", children: [{ type: "paragraph", children: [text("先发内测版，再全量。")] }] },
    { type: "paragraph", children: [text("彩蛋："), text("下周团建", "spoiler")] },
  ],
});
</script>
<template>
  <C :doc-json="docJson" plain-text="周会纪要" />
</template>
