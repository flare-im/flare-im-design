<script setup lang="ts">
import { useFlareConfig } from "../../shared/useFlareConfig";
import { resolveFlareMessage } from "../../shared/i18n/messages";
import { ref, onMounted } from "vue";
import FlareIcon from "./FlareIcon.vue";
const props = withDefaults(
  defineProps<{
    modelValue: string;
    placeholder?: string;
    multiline?: boolean;
    maxLength?: number;
    disabled?: boolean;
    clearable?: boolean;
    /** Mask the value (password entry). Ignored when `multiline`. */
    secure?: boolean;
    autofocus?: boolean;
  }>(),
  { placeholder: "", multiline: false, disabled: false, clearable: false, secure: false, autofocus: false },
);
const emit = defineEmits<{
  (e: "update:modelValue", v: string): void;
  (e: "submit"): void;
  (e: "clear"): void;
  (e: "focus"): void;
  (e: "blur"): void;
}>();
const config = useFlareConfig();
const t = (key: string) => resolveFlareMessage(config.locale.value, key);
const input = ref<HTMLInputElement | HTMLTextAreaElement | null>(null);
onMounted(() => { if (props.autofocus && !props.disabled) input.value?.focus(); });
function submit(event: KeyboardEvent) {
  if (!props.disabled && !event.isComposing && event.keyCode !== 229) emit("submit");
}
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
        ref="input"
        class="flare-input__el"
        rows="3"
        :value="modelValue"
        :placeholder="placeholder"
        :disabled="disabled"
        :maxlength="maxLength"
        @input="onInput"
        @focus="emit('focus')"
        @blur="emit('blur')"
      />
      <input
        v-else
        ref="input"
        class="flare-input__el"
        :type="secure ? 'password' : 'text'"
        :value="modelValue"
        :placeholder="placeholder"
        :disabled="disabled"
        :maxlength="maxLength"
        @input="onInput"
        @keydown.enter="submit"
        @focus="emit('focus')"
        @blur="emit('blur')"
      />
      <button
        type="button"
        :aria-label="t('input.clear')"
        v-if="clearable && modelValue && !disabled"
        class="flare-input__clear"
        @click="emit('update:modelValue', ''); emit('clear')"
      ><FlareIcon name="close" :size="14" /></button>
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
  border-radius: var(--flare-size-radius-lg, 10px);
  background: var(--flare-color-bg-secondary);
  border: 1px solid var(--flare-color-border-primary);
  transition:
    border-color var(--flare-transition-fast, 150ms cubic-bezier(0.22, 1, 0.36, 1)),
    box-shadow var(--flare-transition-fast, 150ms cubic-bezier(0.22, 1, 0.36, 1));
}
.flare-input__field:focus-within {
  border-color: var(--flare-color-primary);
  box-shadow: 0 0 0 3px var(--flare-color-focus-ring, rgba(124, 58, 237, 0.28));
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
.flare-input__clear { border: 0; background: none; padding: 4px; display: inline-flex; color: var(--flare-color-text-tertiary); cursor: pointer; font-size: 13px; }
.flare-input__count {
  text-align: right;
  font-size: 12px;
  color: var(--flare-color-text-tertiary);
  margin-top: 4px;
}
</style>
