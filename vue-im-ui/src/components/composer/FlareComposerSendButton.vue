<script setup lang="ts">
// Send button (发送) — a composable composer part. Purple when active, disabled
// otherwise. Emits `send` only when active.
const props = defineProps<{ active: boolean }>();
const emit = defineEmits<{ (e: "send"): void }>();
function click() {
  if (props.active) emit("send");
}
</script>

<template>
  <button class="flare-send" :class="{ active }" :disabled="!active" @click="click" aria-label="发送">
    <svg viewBox="0 0 24 24" width="16" height="16" fill="none" stroke="currentColor"
      stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
      <path d="M4.5 19.5 21 12 4.5 4.5v6l8.5 1.5-8.5 1.5z" />
    </svg>
  </button>
</template>

<style scoped>
.flare-send {
  width: 34px;
  height: 34px;
  border: none;
  border-radius: 50%;
  display: grid;
  place-items: center;
  background: var(--flare-color-bg-disabled, #e8eaef);
  color: var(--flare-color-text-disabled, #b0b5bf);
  cursor: not-allowed;
  transition: background 0.15s, color 0.15s;
}
.flare-send.active {
  background: var(--flare-color-primary, #7c3aed);
  color: #fff;
  cursor: pointer;
}
</style>
