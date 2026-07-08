<script setup>
import { computed } from "vue";
import DemoIcon from "../DemoIcon.vue";
import { tint, initials } from "../tint.js";
const props = defineProps({ name: { type: String, default: "联系人" }, avatarUrl: String, subtitle: String });
const av = computed(() => tint(props.name));
</script>
<template>
  <div class="bubble contact">
    <img v-if="avatarUrl" class="av img" :src="avatarUrl" :alt="name" />
    <span v-else class="av" :style="{ background: av.bg, color: av.fg }">{{ initials(name) }}</span>
    <span class="meta"><b>{{ name }}</b><small v-if="subtitle">{{ subtitle }}</small></span>
    <DemoIcon name="chevronRight" :size="16" class="chev" />
  </div>
</template>
<style scoped>
.bubble { display: inline-flex; align-items: center; gap: 12px; min-width: 240px; padding: 9px 14px; border-radius: 16px 16px 16px 4px; background: var(--flare-color-bg-primary); border: 1px solid var(--flare-color-border-secondary); box-shadow: 0 2px 10px rgba(0,0,0,.05); }
.av { width: 44px; height: 44px; border-radius: 10px; flex: none; display: grid; place-items: center; font-weight: 600; font-size: 14px; }
.av.img { object-fit: cover; }
.meta { flex: 1; display: flex; flex-direction: column; }
.meta b { font-size: 15px; font-weight: 600; color: var(--flare-color-text-primary); }
.meta small { font-size: 11px; color: var(--flare-color-text-tertiary); }
.chev { color: var(--flare-color-text-tertiary); }
</style>
