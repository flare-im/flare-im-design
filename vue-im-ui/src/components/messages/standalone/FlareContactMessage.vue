<script setup lang="ts">
import { computed } from "vue";
import MsgIcon from "./MsgIcon.vue";
const props = withDefaults(defineProps<{ name?: string; flareId?: string }>(), { name: "contact" });
const emit = defineEmits<{ (e: "open"): void }>();
// pastel identity, matching FlareAvatar
const av = computed(() => {
  const pairs = [
    { bg: "#DBEAFE", fg: "#1D4ED8" }, { bg: "#E9D5FF", fg: "#6D28D9" }, { bg: "#FBCFE8", fg: "#BE185D" },
    { bg: "#D1FAE5", fg: "#047857" }, { bg: "#FEF3C7", fg: "#B45309" }, { bg: "#E5E7EB", fg: "#374151" },
  ];
  let h = 0;
  for (const c of props.name || "user") h = c.charCodeAt(0) + ((h << 5) - h);
  return pairs[Math.abs(h) % pairs.length];
});
const initials = computed(() => {
  const p = (props.name || "").trim().split(/\s+/);
  return ((p.length > 1 ? p[0][0] + p[1][0] : (p[0] || "?")[0]) || "?").toUpperCase();
});
</script>
<template>
  <div class="fm-contact" @click="emit('open')">
    <span class="av" :style="{ background: av.bg, color: av.fg }">{{ initials }}</span>
    <span class="meta"><b>{{ name }}</b><small v-if="flareId">Flare ID: {{ flareId }}</small></span>
    <MsgIcon name="chevronRight" :size="16" class="chev" />
  </div>
</template>
<style scoped>
.fm-contact { display: inline-flex; align-items: center; gap: 12px; min-width: 240px; padding: 9px 14px; border-radius: 16px 16px 16px 4px; background: var(--im-bg-surface, #fff); border: 1px solid var(--im-border-subtle, #eef0f4); box-shadow: var(--im-bubble-shadow, 0 2px 10px rgba(0,0,0,.05)); cursor: pointer; }
.av { width: 44px; height: 44px; border-radius: 10px; display: grid; place-items: center; font-weight: 600; font-size: 14px; }
.meta { flex: 1; display: flex; flex-direction: column; }
.meta b { font-size: 15px; font-weight: 600; color: var(--im-text-primary, #111318); }
.meta small { font-size: 11px; color: var(--im-text-tertiary, #a3a7ae); }
.chev { color: var(--im-text-tertiary, #a3a7ae); }
</style>
