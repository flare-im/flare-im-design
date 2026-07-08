<script setup>
import { ref } from "vue";
import DemoIcon from "./DemoIcon.vue";
import { tint } from "./tint.js";
const q = ref("");
const busy = ref(false);
const people = [
  { id: "u1", n: "Henry Ford", i: "HF" },
  { id: "u2", n: "Ivy Chen", i: "IC" },
  { id: "u3", n: "Kai Wang", i: "KW" },
].map((p) => ({ ...p, av: tint(p.n) }));
const picked = ref(["u2"]);
function toggle(id) {
  const i = picked.value.indexOf(id);
  if (i >= 0) picked.value.splice(i, 1); else picked.value.push(id);
}
function create() {
  busy.value = true;
  setTimeout(() => (busy.value = false), 1200);
}
</script>

<template>
  <div class="dlg">
    <div class="hd">
      <span>发起会话</span>
      <button class="x"><DemoIcon name="close" :size="18" /></button>
    </div>
    <div class="sb">
      <DemoIcon name="search" :size="17" />
      <input v-model="q" placeholder="搜索联系人" />
    </div>
    <div class="list">
      <button
        v-for="p in people.filter(p => p.n.toLowerCase().includes(q.toLowerCase()))"
        :key="p.id" class="row" @click="toggle(p.id)"
      >
        <span class="chk" :class="{ on: picked.includes(p.id) }">
          <DemoIcon v-if="picked.includes(p.id)" name="check" :size="12" />
        </span>
        <span class="av" :style="{ background: p.av.bg, color: p.av.fg }">{{ p.i }}</span>
        <span class="n">{{ p.n }}</span>
      </button>
    </div>
    <div class="ft">
      <span class="cnt">已选 {{ picked.length }} 人</span>
      <button class="go" :disabled="!picked.length || busy" @click="create">
        <span v-if="busy" class="spin" />{{ busy ? "创建中" : "创建" }}
      </button>
    </div>
  </div>
</template>

<style scoped>
.dlg { width: 100%; max-width: 380px; border: 1px solid var(--flare-color-border-primary); border-radius: 16px; background: var(--flare-color-bg-primary); box-shadow: 0 12px 40px rgba(0,0,0,.14); overflow: hidden; }
.hd { display: flex; align-items: center; justify-content: space-between; padding: 14px 16px; font-weight: 600; color: var(--flare-color-text-primary); border-bottom: 1px solid var(--flare-color-border-secondary); }
.x { border: none; background: none; color: var(--flare-color-text-tertiary); cursor: pointer; display: flex; }
.sb { display: flex; align-items: center; gap: 8px; margin: 12px 16px; padding: 8px 12px; border-radius: 10px; background: var(--flare-color-bg-secondary); color: var(--flare-color-text-tertiary); }
.sb input { flex: 1; border: none; outline: none; background: none; font-size: 14px; color: var(--flare-color-text-primary); }
.list { display: flex; flex-direction: column; max-height: 190px; overflow-y: auto; }
.row { display: flex; align-items: center; gap: 12px; padding: 9px 16px; border: none; background: none; cursor: pointer; }
.chk { width: 18px; height: 18px; border-radius: 50%; border: 1.5px solid var(--flare-color-border-primary); display: flex; align-items: center; justify-content: center; color: #fff; flex: none; }
.chk.on { background: var(--flare-color-primary); border-color: var(--flare-color-primary); }
.av { width: 34px; height: 34px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 12px; font-weight: 600; }
.n { color: var(--flare-color-text-primary); font-size: 14px; }
.ft { display: flex; align-items: center; justify-content: space-between; padding: 12px 16px; border-top: 1px solid var(--flare-color-border-secondary); }
.cnt { font-size: 12px; color: var(--flare-color-text-tertiary); }
.go { display: flex; align-items: center; gap: 6px; padding: 7px 18px; border: none; border-radius: 8px; background: var(--flare-color-primary); color: #fff; font-size: 13px; cursor: pointer; }
.go:disabled { background: var(--flare-color-bg-disabled); color: var(--flare-color-text-disabled); cursor: not-allowed; }
.spin { width: 11px; height: 11px; border-radius: 50%; border: 1.5px solid rgba(255,255,255,.4); border-top-color: #fff; animation: sp .7s linear infinite; }
@keyframes sp { to { transform: rotate(360deg); } }
</style>
