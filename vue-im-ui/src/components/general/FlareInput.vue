<script setup lang="ts">
const props = withDefaults(
  defineProps<{
    modelValue: string;
    placeholder?: string;
    multiline?: boolean;
    maxLength?: number;
    disabled?: boolean;
    clearable?: boolean;
  }>(),
  { placeholder: "", multiline: false, disabled: false, clearable: false },
);
const emit = defineEmits<{
  (e: "update:modelValue", v: string): void;
  (e: "submit"): void;
  (e: "clear"): void;
  (e: "focus"): void;
  (e: "blur"): void;
}>();
function onInput(e: Event) {
  const el = e.target as HTMLInputElement | HTMLTextAreaElement;
  let v = el.value;
  if (props.maxLength != null && v.length > props.maxLength) v = v.slice(0, props.maxLength);
  emit("update:modelValue", v);
}
</script>

<template>
  <div class="flare-input">
    <div class="flare-input__field" :class="{ 'is-disabled': disabled }">
      <textarea
        v-if="multiline"
        class="flare-input__el"
        rows="3"
        :value="modelValue"
        :placeholder="placeholder"
        :disabled="disabled"
        @input="onInput"
        @focus="emit('focus')"
        @blur="emit('blur')"
      />
      <input
        v-else
        class="flare-input__el"
        :value="modelValue"
        :placeholder="placeholder"
        :disabled="disabled"
        @input="onInput"
        @keyup.enter="emit('submit')"
        @focus="emit('focus')"
        @blur="emit('blur')"
      />
      <span
        v-if="clearable && modelValue && !disabled"
        class="flare-input__clear"
        @click="emit('update:modelValue', ''); emit('clear')"
      >✕</span>
    </div>
    <div v-if="maxLength != null" class="flare-input__count">
      {{ modelValue.length }}/{{ maxLength }}
    </div>
  </div>
</template>

<style scoped>
.flare-input { width: 100%; }
.flare-input__field {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 10px 14px;
  border-radius: var(--flare-size-radius-lg, 8px);
  background: var(--flare-color-bg-secondary);
  border-bottom: 2px solid var(--flare-color-primary);
}
.flare-input__field.is-disabled { opacity: 0.6; }
.flare-input__el {
  flex: 1;
  border: none;
  outline: none;
  background: none;
  font-size: 14px;
  color: var(--flare-color-text-primary);
  resize: vertical;
  font-family: inherit;
}
.flare-input__clear { color: var(--flare-color-text-tertiary); cursor: pointer; font-size: 13px; }
.flare-input__count {
  text-align: right;
  font-size: 12px;
  color: var(--flare-color-text-tertiary);
  margin-top: 4px;
}
</style>
