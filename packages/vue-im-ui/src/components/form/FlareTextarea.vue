<script setup lang="ts">
import { computed, nextTick, onMounted, ref, watch } from "vue";
import type { FlareControlSize } from "../../shared/contracts";
import { useFlareConfig } from "../../shared/useFlareConfig";
import { useFlareFormControl } from "../../shared/useFlareFormField";

const props = withDefaults(
  defineProps<{
    placeholder?: string;
    disabled?: boolean;
    /** DOM id; inside FlareFormField the field's id is used when omitted. */
    id?: string;
    /** Form control name for native submission. */
    name?: string;
    /** Accessible name when no visible label is associated with the field; falls back to `placeholder` outside a labelled FlareFormField. */
    ariaLabel?: string;
    /** Ids of the text that describes this field; inside FlareFormField its hint / error when omitted. */
    ariaDescribedby?: string;
    /** Marks the control invalid for assistive technology; inside FlareFormField also set by its error. */
    invalid?: boolean;
    /** Falls back to the global config size when omitted. */
    size?: FlareControlSize;
    /** Fixed visible rows before auto-grow kicks in. */
    rows?: number;
    /** Cap auto-grow at this many rows (0 = uncapped). */
    maxRows?: number;
    /** Show a character counter; requires maxlength for the "n/max" form. */
    showCount?: boolean;
    maxlength?: number;
    autofocus?: boolean;
  }>(),
  {
    placeholder: "",
    disabled: false,
    id: undefined,
    name: undefined,
    ariaLabel: undefined,
    ariaDescribedby: undefined,
    invalid: false,
    rows: 3,
    maxRows: 0,
    showCount: false,
    autofocus: false,
  },
);
const value = defineModel<string>({ default: "" });
const emit = defineEmits<{ (e: "enter"): void; (e: "change", value: string): void }>();

const config = useFlareConfig();
const control = useFlareFormControl(props);
const rsize = computed(() => props.size ?? config.size.value);
// A labelled field names the textarea; the placeholder is only the fallback name.
const accessibleName = computed(() => props.ariaLabel || (control.value.labelId ? undefined : props.placeholder || undefined));
const el = ref<HTMLTextAreaElement | null>(null);
const count = computed(() => [...value.value].length);

function resize(): void {
  const node = el.value;
  if (!node) return;
  node.style.height = "auto";
  let next = node.scrollHeight;
  if (props.maxRows > 0) {
    const cs = getComputedStyle(node);
    const line = parseFloat(cs.lineHeight) || 20;
    const chrome = parseFloat(cs.paddingTop) + parseFloat(cs.paddingBottom) + parseFloat(cs.borderTopWidth) + parseFloat(cs.borderBottomWidth);
    next = Math.min(next, line * props.maxRows + chrome);
  }
  node.style.height = `${next}px`;
  node.style.overflowY = props.maxRows > 0 && node.scrollHeight > next ? "auto" : "hidden";
}

function onInput(): void {
  emit("change", value.value);
  resize();
}
function onKeydown(e: KeyboardEvent): void {
  if (e.key === "Enter" && (e.metaKey || e.ctrlKey)) {
    e.preventDefault();
    emit("enter");
  }
}

watch(value, () => nextTick(resize));
onMounted(() => {
  resize();
  if (props.autofocus) el.value?.focus();
});
</script>

<template>
  <div class="flare-textarea" :class="[`flare-textarea--${rsize}`, { 'is-disabled': disabled }]">
    <textarea
      ref="el"
      v-model="value"
      class="flare-textarea__field"
      :id="control.id"
      :name="name"
      :rows="rows"
      :placeholder="placeholder"
      :aria-label="accessibleName"
      :aria-describedby="control.describedBy"
      :aria-invalid="control.invalid || undefined"
      :aria-required="control.required || undefined"
      :disabled="disabled"
      :maxlength="maxlength"
      @input="onInput"
      @keydown="onKeydown"
    />
    <span v-if="showCount" class="flare-textarea__count">
      {{ count }}<template v-if="maxlength"> / {{ maxlength }}</template>
    </span>
  </div>
</template>

<style scoped>
.flare-textarea {
  box-sizing: border-box;
  min-width: 0;
  position: relative;
  display: block;
  width: 100%;
  border: 1px solid var(--flare-color-border-primary);
  border-radius: var(--flare-size-radius-lg);
  background: var(--flare-color-bg-secondary);
  transition: border-color var(--flare-transition-fast), box-shadow var(--flare-transition-fast);
}
.flare-textarea:focus-within {
  border-color: var(--flare-color-border-selected);
  box-shadow: 0 0 0 3px var(--flare-color-focus-ring);
  background: var(--flare-color-bg-primary);
}
.flare-textarea.is-disabled { opacity: 0.55; }
.flare-textarea__field {
  width: 100%;
  box-sizing: border-box;
  border: none;
  outline: none;
  resize: none;
  background: transparent;
  color: var(--flare-color-text-primary);
  font: inherit;
  line-height: 1.5;
  display: block;
}
.flare-textarea__field::placeholder { color: var(--flare-color-text-tertiary); }
.flare-textarea--sm .flare-textarea__field { padding: 8px var(--flare-size-spacing-2sm); font-size: 13px; }
.flare-textarea--md .flare-textarea__field { padding: var(--flare-size-spacing-2sm) 12px; font-size: 14px; }
.flare-textarea--lg .flare-textarea__field { padding: 12px var(--flare-size-spacing-2md); font-size: 15px; }
.flare-textarea__count {
  display: block;
  padding: 0 12px 6px;
  text-align: end;
  font-size: 12px;
  color: var(--flare-color-text-tertiary);
  pointer-events: none;
}
</style>
