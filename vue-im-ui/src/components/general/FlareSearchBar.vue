<script setup lang="ts">
withDefaults(
  defineProps<{ modelValue?: string; placeholder?: string; loading?: boolean }>(),
  { modelValue: "", placeholder: "Search", loading: false },
);
const emit = defineEmits<{
  (e: "update:modelValue", v: string): void;
  (e: "submit"): void;
  (e: "clear"): void;
}>();
function onInput(e: Event) {
  emit("update:modelValue", (e.target as HTMLInputElement).value);
}
function clear() {
  emit("update:modelValue", "");
  emit("clear");
}
</script>

<template>
  <div class="flare-search">
    <span class="flare-search__ico">🔍</span>
    <input
      class="flare-search__input"
      :value="modelValue"
      :placeholder="placeholder"
      @input="onInput"
      @keyup.enter="emit('submit')"
    />
    <span v-if="loading" class="flare-search__spin" />
    <span v-else-if="modelValue" class="flare-search__clear" @click="clear">✕</span>
  </div>
</template>

<style scoped>
.flare-search {
  display: flex;
  align-items: center;
  gap: 8px;
  width: 100%;
  padding: 9px 14px;
  border-radius: var(--flare-size-radius-lg, 8px);
  background: var(--flare-color-bg-secondary);
}
.flare-search__ico { color: var(--flare-color-text-tertiary); }
.flare-search__input {
  flex: 1;
  border: none;
  outline: none;
  background: none;
  font-size: 14px;
  color: var(--flare-color-text-primary);
}
.flare-search__clear { color: var(--flare-color-text-tertiary); cursor: pointer; font-size: 13px; }
.flare-search__spin {
  width: 14px; height: 14px; border-radius: 50%;
  border: 2px solid var(--flare-color-border-primary);
  border-top-color: var(--flare-color-text-tertiary);
  animation: flare-spin 0.8s linear infinite;
}
@keyframes flare-spin { to { transform: rotate(360deg); } }
</style>
