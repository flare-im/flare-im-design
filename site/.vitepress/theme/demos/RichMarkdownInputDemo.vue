<script setup>
import { ref } from "vue";
import DemoIcon from "./DemoIcon.vue";
const raw = ref("**评审结论**：方案 A 通过，`P0` 项本周内合入。");
const preview = ref(true);
const max = 200;
const tools = [
  { k: "bold", icon: "bold", wrap: "**" },
  { k: "italic", icon: "italic", wrap: "*" },
  { k: "strike", icon: "strike", wrap: "~~" },
  { k: "code", icon: "code", wrap: "`" },
  { k: "link", icon: "link", wrap: "" },
  { k: "list", icon: "list", wrap: "" },
];
function render(md) {
  return md
    .replace(/&/g, "&amp;").replace(/</g, "&lt;")
    .replace(/\*\*(.+?)\*\*/g, "<b>$1</b>")
    .replace(/(^|\W)\*(.+?)\*/g, "$1<i>$2</i>")
    .replace(/~~(.+?)~~/g, "<s>$1</s>")
    .replace(/`(.+?)`/g, "<code>$1</code>");
}
function apply(t) {
  if (!t.wrap) return;
  raw.value += `${t.wrap}文本${t.wrap}`;
}
</script>

<template>
  <div class="rmi">
    <div class="tools">
      <button v-for="t in tools" :key="t.k" :title="t.k" @click="apply(t)">
        <DemoIcon :name="t.icon" :size="17" />
      </button>
      <span class="sp" />
      <button class="pv" :class="{ on: preview }" @click="preview = !preview">预览</button>
    </div>
    <textarea v-model="raw" :maxlength="max" rows="3" placeholder="支持 Markdown…" />
    <div v-if="preview" class="preview" v-html="render(raw)" />
    <div class="foot">
      <span class="hint">支持 **粗体** · `代码` · ~~删除线~~</span>
      <span class="count" :class="{ over: raw.length >= max }">{{ raw.length }}/{{ max }}</span>
    </div>
  </div>
</template>

<style scoped>
.rmi { width: 100%; max-width: 460px; border: 1px solid var(--flare-color-border-primary); border-radius: 14px; background: var(--flare-color-bg-primary); overflow: hidden; }
.tools { display: flex; align-items: center; gap: 2px; padding: 6px 8px; border-bottom: 1px solid var(--flare-color-border-secondary); }
.tools button { display: flex; align-items: center; justify-content: center; width: 30px; height: 30px; border: none; border-radius: 7px; background: none; color: var(--flare-color-text-secondary); cursor: pointer; }
.tools button:hover { background: var(--flare-color-bg-secondary); }
.sp { flex: 1; }
.pv { width: auto !important; padding: 0 10px; font-size: 12px; }
.pv.on { color: var(--flare-color-primary); background: var(--flare-color-bg-selected); }
textarea { width: 100%; border: none; outline: none; resize: vertical; padding: 12px 14px; background: none; font-size: 15px; line-height: 1.5; color: var(--flare-color-text-primary); font-family: inherit; }
.preview { padding: 10px 14px; border-top: 1px dashed var(--flare-color-border-secondary); background: var(--flare-color-bg-secondary); font-size: 15px; line-height: 1.5; color: var(--flare-color-text-primary); }
.preview :deep(code) { background: var(--flare-color-bg-tertiary); padding: 1px 5px; border-radius: 4px; font-size: 13px; }
.foot { display: flex; justify-content: space-between; align-items: center; padding: 8px 14px; border-top: 1px solid var(--flare-color-border-secondary); }
.hint { font-size: 11px; color: var(--flare-color-text-tertiary); }
.count { font-size: 11px; color: var(--flare-color-text-tertiary); font-variant-numeric: tabular-nums; }
.count.over { color: var(--flare-color-error); }
</style>
