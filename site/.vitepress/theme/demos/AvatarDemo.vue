<script setup>
import { tint, initials } from "./tint.js";
const people = [
  { id: "u1", name: "Henry Ford", presence: "online" },
  { id: "u2", name: "Ivy Chen", presence: "busy" },
  { id: "u3", name: "Kai", presence: "away" },
  { id: "u4", name: "Team Flare", presence: null },
].map((p) => ({ ...p, av: tint(p.id) }));
const dot = { online: "var(--flare-color-success)", busy: "var(--flare-color-error)", away: "var(--flare-color-warning)" };
</script>

<template>
  <div v-for="p in people" :key="p.id" class="av-wrap">
    <div class="av" :style="{ background: p.av.bg, color: p.av.fg }">{{ initials(p.name) }}</div>
    <span v-if="p.presence" class="av-dot" :style="{ background: dot[p.presence] }" />
  </div>
</template>

<style scoped>
.av-wrap { position: relative; width: 42px; height: 42px; }
.av {
  width: 42px; height: 42px; border-radius: 50%;
  display: flex; align-items: center; justify-content: center;
  font-weight: 600; font-size: 17px;
}
.av-dot {
  position: absolute; right: 0; bottom: 0; width: 12px; height: 12px;
  border-radius: 50%; border: 2px solid var(--flare-color-bg-primary);
}
</style>
