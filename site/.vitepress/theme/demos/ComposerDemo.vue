<script setup>
import { ref } from "vue";
import DemoIcon from "./DemoIcon.vue";
const text = ref("");
const sent = ref([]);
const voice = ref(false);
const panel = ref(false);
const actions = [
  { k: "image", label: "图片", icon: "image" },
  { k: "camera", label: "拍摄", icon: "camera" },
  { k: "file", label: "文件", icon: "folder" },
  { k: "location", label: "位置", icon: "location" },
  { k: "card", label: "名片", icon: "person" },
  { k: "vote", label: "投票", icon: "poll" },
  { k: "task", label: "任务", icon: "task" },
  { k: "schedule", label: "日程", icon: "calendar" },
];
function send() {
  const t = text.value.trim();
  if (!t) return;
  sent.value.push(t);
  text.value = "";
}
function pick(a) { sent.value.push(`[${a.label}]`); panel.value = false; }
</script>

<template>
  <div class="wrap">
    <div v-if="sent.length" class="echo">
      <div v-for="(s, i) in sent" :key="i" class="bubble">{{ s }}</div>
    </div>
    <div class="composer">
      <div class="bar">
        <button class="ico" :class="{ on: voice }" @click="voice = !voice">
          <DemoIcon :name="voice ? 'keyboard' : 'mic'" />
        </button>
        <button class="ico" :class="{ on: panel }" @click="panel = !panel"><DemoIcon name="plus" /></button>
        <div v-if="!voice" class="field">
          <input v-model="text" placeholder="发送消息…" @keyup.enter="send" />
        </div>
        <button v-else class="voicebar">按住 说话</button>
        <button v-if="!voice" class="ico"><DemoIcon name="emoji" /></button>
        <button v-if="!voice" class="send" :class="{ active: text.trim() }" @click="send">
          <DemoIcon name="send" :size="17" />
        </button>
      </div>
      <transition name="panel">
        <div v-if="panel" class="grid">
          <button v-for="a in actions" :key="a.k" class="tile" @click="pick(a)">
            <span class="tico"><DemoIcon :name="a.icon" :size="23" /></span>
            <span class="tlbl">{{ a.label }}</span>
          </button>
        </div>
      </transition>
    </div>
  </div>
</template>

<style scoped>
.wrap { width: 100%; max-width: 460px; }
.echo { display: flex; flex-direction: column; align-items: flex-end; gap: 6px; margin-bottom: 10px; }
.bubble { background: var(--flare-color-bubble-self); color: #fff; padding: 8px 12px; border-radius: 16px 16px 4px 16px; font-size: 14px; max-width: 78%; }
.composer { background: var(--flare-color-bg-primary); border: 1px solid var(--flare-color-border-primary); border-radius: 14px; overflow: hidden; }
.bar { display: flex; align-items: center; gap: 8px; padding: 8px; }
.ico { border: none; background: none; color: var(--flare-color-text-secondary); cursor: pointer; width: 32px; height: 32px; border-radius: 50%; display: flex; align-items: center; justify-content: center; }
.ico.on { color: var(--flare-color-primary); }
.field { flex: 1; background: var(--flare-color-bg-secondary); border-radius: 12px; padding: 8px 12px; }
.field input { width: 100%; border: none; outline: none; background: none; font-size: 14px; color: var(--flare-color-text-primary); }
.voicebar { flex: 1; height: 38px; border: none; border-radius: 12px; background: var(--flare-color-bg-secondary); color: var(--flare-color-text-secondary); font-size: 14px; font-weight: 500; cursor: pointer; }
.send { width: 34px; height: 34px; border: none; border-radius: 50%; background: var(--flare-color-bg-disabled); color: var(--flare-color-text-disabled); cursor: pointer; transition: 0.15s; display: flex; align-items: center; justify-content: center; }
.send.active { background: var(--flare-color-primary); color: #fff; }
.grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 16px; padding: 16px; border-top: 1px solid var(--flare-color-border-secondary); }
.tile { display: flex; flex-direction: column; align-items: center; gap: 6px; border: none; background: none; cursor: pointer; }
.tico { width: 52px; height: 52px; border-radius: 12px; background: var(--flare-color-bg-secondary); display: flex; align-items: center; justify-content: center; color: var(--flare-color-text-secondary); }
.tlbl { font-size: 12px; color: var(--flare-color-text-secondary); }
.panel-enter-active, .panel-leave-active { transition: opacity 0.18s, transform 0.18s; }
.panel-enter-from, .panel-leave-to { opacity: 0; transform: translateY(-6px); }
</style>
