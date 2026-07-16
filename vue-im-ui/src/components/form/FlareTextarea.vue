<script setup lang="ts">
import { computed, nextTick, onMounted, ref, watch } from "vue";
import type { FlareControlSize } from "../../shared/contracts";
import { useFlareConfig } from "../../shared/useFlareConfig";

const props = withDefaults(
  defineProps<{
    placeholder?: string;
    disabled?: boolean;
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
  { placeholder: "", disabled: false, rows: 3, maxRows: 0, showCount: false, autofocus: false },
);
const value = defineModel<string>({ default: "" });
const emit = defineEmits<{ (e: "enter"): void; (e: "change", value: string): void }>();

const config = useFlareConfig();
const rsize = computed(() => props.size ?? config.size.value);
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
      :rows="rows"
      :placeholder="placeholder"
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
  position: relative;
  display: block;
  width: 100%;
  border: 1px solid var(--flare-color-border-primary, #e9e6f1);
  border-radius: var(--flare-size-radius-lg, 10px);
  background: var(--flare-color-bg-secondary, #f6f5fb);
  transition: border-color var(--flare-transition-fast, 150ms ease), box-shadow var(--flare-transition-fast, 150ms ease);
}
.flare-textarea:focus-within {
  border-color: var(--flare-color-primary, #7c3aed);
  box-shadow: 0 0 0 3px var(--flare-color-focus-ring, rgba(124, 58, 237, 0.28));
  background: var(--flare-color-bg-primary, #fff);
}
.flare-textarea.is-disabled { opacity: 0.55; }
.flare-textarea__field {
  width: 100%;
  box-sizing: border-box;
  border: none;
  outline: none;
  resize: none;
  background: transparent;
  color: var(--flare-color-text-primary, #15131c);
  font: inherit;
  line-height: 1.5;
  display: block;
}
.flare-textarea__field::placeholder { color: var(--flare-color-text-tertiary, #a7a2b4); }
.flare-textarea--sm .flare-textarea__field { padding: 8px 10px; font-size: 13px; }
.flare-textarea--md .flare-textarea__field { padding: 10px 12px; font-size: 14px; }
.flare-textarea--lg .flare-textarea__field { padding: 12px 14px; font-size: 15px; }
.flare-textarea__count {
  position: absolute;
  right: 10px;
  bottom: 6px;
  font-size: 12px;
  color: var(--flare-color-text-tertiary, #a7a2b4);
  pointer-events: none;
  background: linear-gradient(transparent, var(--flare-color-bg-secondary, #f6f5fb) 40%);
  padding-left: 6px;
}
.flare-textarea:focus-within .flare-textarea__count { background: linear-gradient(transparent, var(--flare-color-bg-primary, #fff) 40%); }
</style>
