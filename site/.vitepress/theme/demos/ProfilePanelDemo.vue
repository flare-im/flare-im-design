<script setup>
import DemoIcon from "./DemoIcon.vue";
const entries = [
  { icon: "star", label: "我的收藏" },
  { icon: "collections", label: "朋友圈" },
  { icon: "image", label: "卡包" },
  { icon: "settings", label: "设置" },
];
</script>

<template>
  <div class="pp">
    <div class="hdr">
      <div class="av">Me</div>
      <div class="meta">
        <div class="name">我的账号</div>
        <div class="id">Flare ID: flare_me</div>
      </div>
      <span class="qr"><DemoIcon name="qr" /></span>
    </div>
    <div class="list">
      <div v-for="e in entries" :key="e.label" class="row">
        <span class="i"><DemoIcon :name="e.icon" :size="19" /></span>
        <span class="l">{{ e.label }}</span>
        <span class="chev"><DemoIcon name="chevronRight" :size="17" /></span>
      </div>
    </div>
  </div>
</template>

<style scoped>
.pp { width: 100%; max-width: 420px; border: 1px solid var(--flare-color-border-primary); border-radius: 14px; overflow: hidden; background: var(--flare-color-bg-primary); }
.hdr { display: flex; align-items: center; gap: 14px; padding: 20px 16px; background: var(--flare-color-bg-selected); }
.av { width: 56px; height: 56px; border-radius: 14px; background: var(--flare-color-primary); color: #fff; display: flex; align-items: center; justify-content: center; font-weight: 600; }
.meta { flex: 1; }
.name { font-size: 18px; font-weight: 600; color: var(--flare-color-text-primary); }
.id { font-size: 12px; color: var(--flare-color-text-tertiary); margin-top: 2px; }
.qr { color: var(--flare-color-text-tertiary); display: flex; }
.row { display: flex; align-items: center; gap: 12px; padding: 13px 16px; }
.row + .row { border-top: 1px solid var(--flare-color-border-secondary); }
.i { color: var(--flare-color-text-secondary); display: flex; }
.l { flex: 1; color: var(--flare-color-text-primary); }
.chev { color: var(--flare-color-text-tertiary); display: flex; }
</style>
