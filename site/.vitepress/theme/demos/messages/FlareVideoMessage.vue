<script setup>
import DemoIcon from "../DemoIcon.vue";
defineProps({ poster: String, duration: { type: String, default: "00:42" } });
</script>
<template>
  <div class="video">
    <img v-if="poster" :src="poster" alt="" />
    <DemoIcon v-else name="video" :size="24" class="ph" />
    <span class="play"><DemoIcon name="play" :size="30" /></span>
    <span class="dur">{{ duration }}</span>
  </div>
</template>
<style scoped>
.video { position: relative; width: 148px; height: 92px; border-radius: 12px; overflow: hidden; background: var(--flare-color-bg-tertiary); display: grid; place-items: center; }
.video img { width: 100%; height: 100%; object-fit: cover; }
.ph { opacity: 0.5; color: var(--flare-color-text-tertiary); }
.play { position: absolute; inset: 0; display: grid; place-items: center; color: #fff; background: rgba(0,0,0,.28); }
.dur { position: absolute; right: 6px; bottom: 5px; font-size: 10px; color: #fff; background: rgba(0,0,0,.45); padding: 1px 5px; border-radius: 5px; font-variant-numeric: tabular-nums; }
</style>
