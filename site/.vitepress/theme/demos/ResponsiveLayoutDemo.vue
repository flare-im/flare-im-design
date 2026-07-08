<script setup>
import { ref } from "vue";
import DemoIcon from "./DemoIcon.vue";
const bp = ref("pc");
const pane = ref("chat");
const panes = { list: "会话列表", chat: "聊天", detail: "详情" };
</script>

<template>
  <div class="wrap">
    <div class="tabs">
      <button v-for="k in ['h5', 'ipad', 'pc']" :key="k" :class="{ on: bp === k }" @click="bp = k">
        {{ k === "h5" ? "手机 ≤599" : k === "ipad" ? "平板 ≤1023" : "PC ≥1024" }}
      </button>
    </div>

    <div class="frame" :class="bp">
      <template v-if="bp === 'pc'">
        <div class="p list">会话列表</div>
        <div class="p chat">聊天</div>
        <div class="p detail">详情</div>
      </template>
      <template v-else-if="bp === 'ipad'">
        <div class="p list">会话列表</div>
        <div class="p chat">聊天 <small>详情以抽屉呈现</small></div>
      </template>
      <template v-else>
        <div class="p single">
          <div v-if="pane !== 'list'" class="back" @click="pane = pane === 'detail' ? 'chat' : 'list'">
            <DemoIcon name="arrowLeft" :size="15" /><span>返回</span>
          </div>
          <div class="pl">{{ panes[pane] }}</div>
        </div>
      </template>
    </div>

    <div v-if="bp === 'h5'" class="hint">
      <button v-for="(v, k) in panes" :key="k" :class="{ on: pane === k }" @click="pane = k">{{ v }}</button>
    </div>
  </div>
</template>

<style scoped>
.wrap { width: 100%; max-width: 520px; }
.tabs, .hint { display: flex; gap: 6px; }
.tabs { margin-bottom: 10px; }
.hint { margin-top: 10px; }
.tabs button, .hint button { padding: 5px 12px; border-radius: 999px; border: 1px solid var(--flare-color-border-primary); background: none; color: var(--flare-color-text-secondary); font-size: 12px; cursor: pointer; }
.tabs button.on, .hint button.on { background: var(--flare-color-primary); border-color: transparent; color: #fff; }
.frame { display: flex; height: 190px; border: 1px solid var(--flare-color-border-primary); border-radius: 12px; overflow: hidden; background: var(--flare-color-bg-primary); }
.frame.h5 { max-width: 200px; }
.frame.ipad { max-width: 380px; }
.p { display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 4px; font-size: 13px; color: var(--flare-color-text-secondary); }
.p + .p { border-left: 1px solid var(--flare-color-border-secondary); }
.p small { font-size: 10px; color: var(--flare-color-text-tertiary); }
.list { flex: 0 0 34%; background: var(--flare-color-bg-secondary); }
.chat { flex: 1; }
.detail { flex: 0 0 30%; background: var(--flare-color-bg-secondary); }
.single { flex: 1; position: relative; }
.back { position: absolute; top: 10px; left: 10px; display: flex; align-items: center; gap: 3px; font-size: 12px; color: var(--flare-color-primary); cursor: pointer; }
.pl { font-size: 14px; }
</style>
