<script setup lang="ts">
// Send — a paper plane, and nothing else. Emits `send` only when active;
// `label` is the accessible label.
//
// It used to be a filled brand disc with a white glyph inside. Sending is the
// same kind of act as every other key in the tool row — one press, one outcome
// — so it is drawn the same way, and only colour says which one sends: the
// brand at rest against the row, faded while there is nothing to send. That is
// also what EnhancedComposer's own send key does, and the two must not drift.
const props = withDefaults(defineProps<{ active: boolean; label?: string }>(), { label: "Send" });
const emit = defineEmits<{ (e: "send"): void }>();
function click() {
  if (props.active) emit("send");
}
</script>

<template>
  <button class="flare-send" :class="{ active }" :disabled="!active" @click="click" :aria-label="label">
    <svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor"
      stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
      <path d="M4.5 19.5 21 12 4.5 4.5v6l8.5 1.5-8.5 1.5z" />
    </svg>
  </button>
</template>

<style scoped>
.flare-send {
  width: 44px;
  height: 44px;
  border: none;
  border-radius: 0;
  display: grid;
  place-items: center;
  background: transparent;
  color: var(--flare-color-primary, #7047D6);
  opacity: 0.38;
  cursor: not-allowed;
  transition: opacity 0.15s;
}
.flare-send.active {
  opacity: 1;
  cursor: pointer;
}
@media (prefers-reduced-motion: reduce) {
  .flare-send { transition: none; }
}
</style>
