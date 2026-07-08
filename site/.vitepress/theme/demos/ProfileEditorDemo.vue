<script setup>
import { ref } from "vue";
import DemoIcon from "./DemoIcon.vue";
const name = ref("我的账号");
const sig = ref("构建跨端 IM 组件库");
const busy = ref(false);
function save() {
  busy.value = true;
  setTimeout(() => (busy.value = false), 1100);
}
</script>

<template>
  <div class="pe">
    <div class="avw">
      <div class="av">Me</div>
      <button class="cam" aria-label="更换头像"><DemoIcon name="camera" :size="15" /></button>
    </div>
    <label>昵称</label>
    <div class="field">
      <input v-model="name" maxlength="24" />
      <span class="c">{{ name.length }}/24</span>
    </div>
    <label>个性签名</label>
    <div class="field">
      <textarea v-model="sig" maxlength="60" rows="2" />
      <span class="c">{{ sig.length }}/60</span>
    </div>
    <div class="acts">
      <button class="ghost">取消</button>
      <button class="save" :disabled="!name.trim() || busy" @click="save">
        <span v-if="busy" class="spin" />{{ busy ? "保存中" : "保存" }}
      </button>
    </div>
  </div>
</template>

<style scoped>
.pe { width: 100%; max-width: 400px; padding: 20px; border: 1px solid var(--flare-color-border-primary); border-radius: 14px; background: var(--flare-color-bg-primary); }
.avw { position: relative; width: 80px; margin: 0 auto 18px; }
.av { width: 80px; height: 80px; border-radius: 22px; background: var(--flare-color-primary); color: #fff; display: flex; align-items: center; justify-content: center; font-size: 26px; font-weight: 600; }
.cam { position: absolute; right: -4px; bottom: -4px; width: 28px; height: 28px; border-radius: 50%; border: 2px solid var(--flare-color-bg-primary); background: var(--flare-color-primary); color: #fff; display: flex; align-items: center; justify-content: center; cursor: pointer; }
label { display: block; font-size: 12px; color: var(--flare-color-text-secondary); margin-bottom: 5px; }
.field { position: relative; margin-bottom: 14px; }
.field input, .field textarea { width: 100%; border: none; outline: none; resize: none; padding: 10px 46px 10px 12px; border-radius: 9px; background: var(--flare-color-bg-secondary); border-bottom: 2px solid transparent; font-size: 14px; color: var(--flare-color-text-primary); font-family: inherit; }
.field input:focus, .field textarea:focus { border-bottom-color: var(--flare-color-primary); }
.c { position: absolute; right: 10px; bottom: 8px; font-size: 11px; color: var(--flare-color-text-tertiary); font-variant-numeric: tabular-nums; }
.acts { display: flex; gap: 10px; margin-top: 4px; }
.acts button { flex: 1; padding: 9px 0; border-radius: 9px; font-size: 14px; cursor: pointer; display: flex; align-items: center; justify-content: center; gap: 6px; }
.ghost { border: 1px solid var(--flare-color-border-primary); background: none; color: var(--flare-color-text-secondary); }
.save { border: none; background: var(--flare-color-primary); color: #fff; }
.save:disabled { background: var(--flare-color-bg-disabled); color: var(--flare-color-text-disabled); cursor: not-allowed; }
.spin { width: 12px; height: 12px; border-radius: 50%; border: 1.5px solid rgba(255,255,255,.4); border-top-color: #fff; animation: sp .7s linear infinite; }
@keyframes sp { to { transform: rotate(360deg); } }
</style>
