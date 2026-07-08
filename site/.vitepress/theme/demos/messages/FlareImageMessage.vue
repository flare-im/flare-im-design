<script setup>
import DemoIcon from "../DemoIcon.vue";
defineProps({ src: String, w: { type: Number, default: 132 }, h: { type: Number, default: 92 } });
</script>
<template>
  <div class="img" :style="{ width: w + 'px', height: h + 'px' }">
    <img v-if="src" :src="src" alt="" />
    <DemoIcon v-else name="image" :size="26" />
  </div>
</template>
<style scoped>
.img { border-radius: 12px; overflow: hidden; background: var(--flare-color-bg-tertiary); display: grid; place-items: center; color: var(--flare-color-text-tertiary); }
.img img { width: 100%; height: 100%; object-fit: cover; }
</style>
