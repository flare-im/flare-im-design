<script setup lang="ts">
import { computed } from "vue";
import { useFlareConfig } from "../../shared/useFlareConfig";
import type { FlareControlSize } from "../../shared/contracts";
import { resolveFlareMessage } from "../../shared/i18n/messages";
import { useFlareFormControl } from "../../shared/useFlareFormField";
import { ref, onMounted } from "vue";
import FlareIcon from "./FlareIcon.vue";
const props = withDefaults(
  defineProps<{
    /** Controlled value. Optional so a host state field that is momentarily unset still type-checks; Select models the same way. */
    modelValue?: string;
    placeholder?: string;
    /** Control height, matching Button / Select. Falls back to the provider size. */
    size?: FlareControlSize;
    multiline?: boolean;
    maxLength?: number;
    disabled?: boolean;
    clearable?: boolean;
    /** Mask the value (password entry). Ignored when `multiline`. */
    secure?: boolean;
    /** A secure input the person can unmask: the field draws the reveal key itself, named by the kit. */
    revealable?: boolean;
    autofocus?: boolean;
    /** Control id; inside FlareFormField the field's id is used when omitted. */
    id?: string;
    /** Accessible name when no visible label points here; falls back to `placeholder` outside a labelled FlareFormField. */
    ariaLabel?: string;
    /** Ids of the text describing this input; inside FlareFormField its hint / error when omitted. */
    ariaDescribedby?: string;
    /** Autofill hint for the browser / password manager (e.g. "username", "current-password", "url"). */
    autocomplete?: string;
    /** On-screen-keyboard hint. */
    inputmode?: "text" | "none" | "search" | "url" | "numeric" | "tel" | "email" | "decimal";
    /** Form control name. */
    name?: string;
    /** Enable spellcheck; identifiers and URLs should keep it off. */
    spellcheck?: boolean;
    /** Marks the control invalid for assistive technology; inside FlareFormField also set by its error. */
    invalid?: boolean;
    /** Draw the value in the platform's monospaced face (codes, identifiers); the field's geometry does not change. */
    monospace?: boolean;
  }>(),
  { modelValue: "", placeholder: "", multiline: false, disabled: false, clearable: false, secure: false, revealable: false, autofocus: false, spellcheck: false, monospace: false },
);
const emit = defineEmits<{
  (e: "update:modelValue", v: string): void;
  (e: "submit"): void;
  (e: "clear"): void;
  (e: "focus"): void;
  (e: "blur"): void;
}>();
const config = useFlareConfig();
const control = useFlareFormControl(props);
const rsize = computed(() => props.size ?? config.size.value);
// A labelled field names the input; the placeholder is only the fallback name.
const accessibleName = computed(() => props.ariaLabel || (control.value.labelId ? undefined : props.placeholder || undefined));
const t = (key: string) => resolveFlareMessage(config.locale.value, key);
const input = ref<HTMLInputElement | HTMLTextAreaElement | null>(null);
// Unmasking is the person's own, momentary choice: it belongs to the field and is never reported or stored.
const revealed = ref(false);
const masked = computed(() => props.secure && !(props.revealable && revealed.value));
const showsReveal = computed(() => props.secure && props.revealable && !props.multiline && !props.disabled);
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
  <div class="flare-input" :class="`flare-input--${rsize}`">
    <div class="flare-input__field" :class="{ 'is-disabled': disabled, 'has-prefix': Boolean($slots.prefix), 'is-monospace': monospace }">
      <span v-if="$slots.prefix" class="flare-input__prefix" aria-hidden="true"><slot name="prefix" /></span>
      <textarea
        v-if="multiline"
        ref="input"
        class="flare-input__el"
        rows="3"
        :id="control.id"
        :name="name"
        :value="modelValue"
        :placeholder="placeholder"
        :aria-label="accessibleName"
        :aria-describedby="control.describedBy"
        :aria-invalid="control.invalid || undefined"
        :aria-required="control.required || undefined"
        :autocomplete="autocomplete"
        :inputmode="inputmode"
        :spellcheck="spellcheck"
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
        :type="masked ? 'password' : 'text'"
        :id="control.id"
        :name="name"
        :value="modelValue"
        :placeholder="placeholder"
        :aria-label="accessibleName"
        :aria-describedby="control.describedBy"
        :aria-invalid="control.invalid || undefined"
        :aria-required="control.required || undefined"
        :autocomplete="autocomplete"
        :inputmode="inputmode"
        :spellcheck="spellcheck"
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
      ><FlareIcon name="close" :size="16" /></button>
      <button
        type="button"
        v-if="showsReveal"
        class="flare-input__reveal"
        :aria-label="revealed ? t('input.hide') : t('input.reveal')"
        :aria-pressed="revealed"
        @click="revealed = !revealed"
      ><FlareIcon :name="revealed ? 'eye-off' : 'eye'" :size="16" /></button>
    </div>
    <div v-if="maxLength != null" class="flare-input__count">
      {{ modelValue.length }}/{{ maxLength }}
    </div>
  </div>
</template>

<style scoped>
.flare-input { width: 100%; min-width: 0; }
.flare-input--sm .flare-input__field { min-height: var(--flare-size-layout-control-height-sm); padding: 2px var(--flare-size-spacing-sm); }
.flare-input--lg .flare-input__field { min-height: var(--flare-size-layout-control-height-lg); }
.flare-input--sm .flare-input__el { font-size: var(--flare-size-font-size-sm); }
.flare-input__prefix {
  display: grid;
  flex: none;
  place-items: center;
  color: var(--flare-color-text-tertiary);
}
.flare-input__field {
  box-sizing: border-box;
  min-width: 0;
  display: flex;
  align-items: center;
  gap: var(--flare-size-spacing-sm);
  min-height: var(--flare-size-layout-control-height-md);
  padding: var(--flare-size-spacing-xs) var(--flare-size-spacing-md);
  /* radius-lg (10px), matching Textarea/Select/SearchBar here and the field box
     on the other three platforms. */
  border-radius: var(--flare-size-radius-lg);
  background: var(--flare-color-bg-secondary);
  border: 1px solid var(--flare-color-border-primary);
  transition:
    border-color var(--flare-transition-fast),
    box-shadow var(--flare-transition-fast);
}
.flare-input__field:focus-within {
  border-color: var(--flare-color-border-selected);
  box-shadow: 0 0 0 2px var(--flare-color-focus-ring);
}
.flare-input__field.is-disabled { opacity: var(--flare-opacity-disabled); }
.flare-input__el {
  flex: 1;
  min-width: 0;
  width: 100%;
  border: none;
  outline: none;
  background: none;
  font-size: var(--flare-size-font-size-lg);
  color: var(--flare-color-text-primary);
  resize: vertical;
  font-family: inherit;
}
/* Codes and identifiers: a fixed-pitch face so every character has the same width; nothing else moves. */
.flare-input__field.is-monospace .flare-input__el { font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace; letter-spacing: 0.08em; }
.flare-input__clear { border: 0; background: none; padding: var(--flare-size-spacing-xs); display: inline-flex; color: var(--flare-color-text-tertiary); cursor: pointer; }
/* The reveal key sits beside the clear key and shares its geometry; the pointer target is the field row. */
.flare-input__reveal { border: 0; background: none; padding: var(--flare-size-spacing-xs); display: inline-flex; color: var(--flare-color-text-tertiary); cursor: pointer; }
.flare-input__reveal[aria-pressed="true"] { color: var(--flare-color-text-secondary); }
.flare-input__count {
  text-align: right;
  font-size: var(--flare-size-font-size-sm);
  color: var(--flare-color-text-tertiary);
  margin-top: var(--flare-size-spacing-xs);
}
</style>
