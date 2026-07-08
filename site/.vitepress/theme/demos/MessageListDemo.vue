<script setup>
import { ref } from "vue";
import DemoIcon from "./DemoIcon.vue";
import { tint } from "./tint.js";
const ivy = tint("Ivy Chen");
const multi = ref(false);
const selected = ref(["m3"]);
const thread = [
  { id: "d1", kind: "date", text: "今天" },
  { id: "m1", self: false, name: "Ivy", ini: "I", av: ivy, text: "新版设计稿已经上传啦", time: "14:30" },
  { id: "m2", self: false, name: "Ivy", ini: "I", av: ivy, text: "帮忙看下交互细节～", time: "14:30" },
  { id: "u1", kind: "unread", text: "以下为新消息" },
  { id: "m3", self: true, text: "收到，我下午过一遍", time: "14:31", status: "read" },
];
function toggle(id) {
  const i = selected.value.indexOf(id);
  if (i >= 0) selected.value.splice(i, 1);
  else selected.value.push(id);
}
</script>

<template>
  <div class="wrap">
    <div class="canvas">
      <div class="older">
        <span class="spin" /> 加载更早的消息
      </div>
      <template v-for="m in thread" :key="m.id">
        <div v-if="m.kind === 'date'" class="date">{{ m.text }}</div>
        <div v-else-if="m.kind === 'unread'" class="unread"><span>{{ m.text }}</span></div>
        <div v-else class="line" :class="{ self: m.self, pick: multi }" @click="multi && toggle(m.id)">
          <span v-if="multi" class="check" :class="{ on: selected.includes(m.id) }">
            <DemoIcon v-if="selected.includes(m.id)" name="check" :size="13" />
          </span>
          <div v-if="!m.self" class="av" :style="{ background: m.av.bg, color: m.av.fg }">{{ m.ini }}</div>
          <div class="bubble" :class="{ self: m.self }">
            <span>{{ m.text }}</span>
            <span class="meta">
              {{ m.time }}
              <DemoIcon v-if="m.status === 'read'" name="checkDouble" :size="14" />
            </span>
          </div>
        </div>
      </template>
    </div>
    <button class="tgl" @click="multi = !multi">{{ multi ? "退出多选" : "进入多选模式" }}</button>
  </div>
</template>

<style scoped>
.wrap { width: 100%; max-width: 460px; }
.canvas { display: flex; flex-direction: column; gap: 8px; padding: 14px; border-radius: 14px; background: var(--flare-color-bg-secondary); }
.older { align-self: center; display: flex; align-items: center; gap: 6px; font-size: 12px; color: var(--flare-color-text-tertiary); }
.date, .unread { align-self: center; font-size: 12px; color: var(--flare-color-text-tertiary); }
.date { background: var(--flare-color-bg-tertiary); padding: 3px 12px; border-radius: 999px; }
.unread { width: 100%; display: flex; align-items: center; gap: 10px; }
.unread::before, .unread::after { content: ""; flex: 1; height: 1px; background: var(--flare-color-border-secondary); }
.line { display: flex; gap: 8px; align-items: flex-end; }
.line.self { justify-content: flex-end; }
.line.pick { cursor: pointer; }
.check { width: 18px; height: 18px; border-radius: 50%; border: 1.5px solid var(--flare-color-border-primary); display: flex; align-items: center; justify-content: center; align-self: center; flex: none; color: #fff; }
.check.on { background: var(--flare-color-primary); border-color: var(--flare-color-primary); }
.av { width: 30px; height: 30px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-weight: 600; font-size: 12px; flex: none; }
.bubble { max-width: 74%; padding: 9px 14px; border-radius: 16px 16px 16px 4px; background: var(--flare-color-bg-primary); border: 1px solid var(--flare-color-border-secondary); box-shadow: 0 2px 10px rgba(0,0,0,.05); color: var(--flare-color-text-primary); font-size: 15px; line-height: 1.45; display: flex; flex-direction: column; align-items: flex-start; }
.bubble.self { background: var(--flare-color-bubble-self); border-color: transparent; color: #fff; border-radius: 16px 16px 4px 16px; align-items: flex-end; }
.meta { display: flex; align-items: center; gap: 3px; font-size: 11px; margin-top: 3px; color: var(--flare-color-text-tertiary); }
.bubble.self .meta { color: rgba(255,255,255,.8); }
.tgl { margin-top: 10px; padding: 6px 14px; border-radius: 8px; border: 1px solid var(--flare-color-border-primary); background: none; color: var(--flare-color-text-secondary); font-size: 13px; cursor: pointer; }
.spin { width: 11px; height: 11px; border-radius: 50%; border: 1.5px solid var(--flare-color-border-primary); border-top-color: var(--flare-color-text-tertiary); animation: sp .8s linear infinite; }
@keyframes sp { to { transform: rotate(360deg); } }
</style>
