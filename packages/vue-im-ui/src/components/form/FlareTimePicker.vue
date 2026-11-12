<script setup lang="ts">
import { ref, computed, onBeforeUnmount } from "vue";
import { NIcon } from "naive-ui";
import { TimeOutline } from "../../shared/icon-glyphs";
import type { FlareControlSize } from "../../shared/contracts";
import { useFlareConfig } from "../../shared/useFlareConfig";
import { useFlareAdaptiveSafe } from "../../composables/useAdaptiveMode";
import FlareBottomSheet from "../general/FlareBottomSheet.vue";
import FlareTimeChoice from "./FlareTimeChoice.vue";

const props = withDefaults(
  defineProps<{
    placeholder?: string;
    disabled?: boolean;
    /** Falls back to the global config size when omitted. */
    size?: FlareControlSize;
    /** Minute granularity. */
    minuteStep?: number;
    /** Sheet header title on mobile (defaults to placeholder). */
    title?: string;
  }>(),
  { placeholder: "", disabled: false, minuteStep: 5 },
);
/** v-model as "HH:mm". */
const value = defineModel<string>({ default: "" });
const emit = defineEmits<{ (e: "change", value: string): void }>();

const config = useFlareConfig();
const rsize = computed(() => props.size ?? config.size.value);
const adaptive = useFlareAdaptiveSafe();
const asSheet = computed(() => adaptive.isH5.value);

const open = ref(false);
const root = ref<HTMLElement | null>(null);

// The columns are created each time the picker opens, so they start from the current value.
function show(): void {
  if (props.disabled) return;
  open.value = true;
}
function close(): void { open.value = false; }
function confirm(next: string): void {
  value.value = next;
  emit("change", next);
  open.value = false;
}
// Outside-click for the DESKTOP popover only (capture phase → still fires when
// another trigger stops propagation). Escape closes the popover.
function onDocPointer(e: MouseEvent): void {
  if (asSheet.value || !open.value) return;
  if (root.value && !root.value.contains(e.target as Node)) open.value = false;
}
// 用掉 Escape 就要 preventDefault:下面可能还有一层上下文层(多选工具条)在听同一下键。
// 键盘监听挂在捕获阶段:弹层放在 Drawer / Modal 里时,面的冒泡监听比这里先注册,
// 冒泡阶段它会先把这下 Escape 当成「返回 / 关闭」。捕获阶段先到这里,面看到
// defaultPrevented 就不再处理。不 stopPropagation —— 别的层还靠 defaultPrevented 判断。
function onDocKey(e: KeyboardEvent): void {
  if (e.key === "Escape" && !asSheet.value && open.value) {
    e.preventDefault();
    open.value = false;
  }
}
if (typeof document !== "undefined") {
  document.addEventListener("click", onDocPointer, true);
  document.addEventListener("keydown", onDocKey, true);
}
onBeforeUnmount(() => {
  if (typeof document !== "undefined") {
    document.removeEventListener("click", onDocPointer, true);
    document.removeEventListener("keydown", onDocKey, true);
  }
});
</script>

<template>
  <div ref="root" class="flare-tp" :class="[`flare-tp--${rsize}`, { 'is-open': open, 'is-disabled': disabled }]">
    <button type="button" class="flare-tp__trigger" :disabled="disabled" @click.stop="show">
      <n-icon aria-hidden="true" :size="16" :component="TimeOutline" class="flare-tp__clock" />
      <span class="flare-tp__value" :class="{ 'is-placeholder': !value }">{{ value || placeholder }}</span>
    </button>

    <!-- Desktop: anchored popover -->
    <transition v-if="!asSheet" name="flare-tp-pop">
      <div v-if="open" class="flare-tp__pop" @click.stop>
        <FlareTimeChoice :value="value" :minute-step="minuteStep" @confirm="confirm" @cancel="close" />
      </div>
    </transition>

    <!-- Phone / native app: bottom sheet -->
    <FlareBottomSheet v-if="asSheet" :open="open" :title="title || placeholder || undefined" max-height="82vh" @close="close">
      <FlareTimeChoice v-if="open" sheet :value="value" :minute-step="minuteStep" @confirm="confirm" @cancel="close" />
    </FlareBottomSheet>
  </div>
</template>

<style scoped>
.flare-tp { position: relative; display: inline-block; min-width: 130px; }
.flare-tp__trigger {
  width: 100%;
  display: flex;
  align-items: center;
  gap: 8px;
  border: 1px solid var(--flare-color-border-primary);
  border-radius: var(--flare-size-radius-lg);
  background: var(--flare-color-bg-secondary);
  color: var(--flare-color-text-primary);
  cursor: pointer;
  transition: border-color var(--flare-transition-fast), box-shadow var(--flare-transition-fast);
}
.flare-tp--sm .flare-tp__trigger { height: 32px; padding: 0 var(--flare-size-spacing-2sm); font-size: 13px; }
.flare-tp--md .flare-tp__trigger { height: 40px; padding: 0 12px; font-size: 14px; }
.flare-tp--lg .flare-tp__trigger { height: 48px; padding: 0 var(--flare-size-spacing-2md); font-size: 15px; }
.flare-tp.is-open .flare-tp__trigger {
  border-color: var(--flare-color-primary);
  box-shadow: 0 0 0 3px var(--flare-color-focus-ring);
}
.flare-tp.is-disabled { opacity: 0.55; }
.flare-tp.is-disabled .flare-tp__trigger { cursor: not-allowed; }
.flare-tp__clock { color: var(--flare-color-text-tertiary); flex: 0 0 auto; }
.flare-tp__value { font-variant-numeric: tabular-nums; }
.flare-tp__value.is-placeholder { color: var(--flare-color-text-tertiary); }

/* Popover (desktop) */
.flare-tp__pop {
  position: absolute;
  z-index: 20;
  top: calc(100% + 6px);
  left: 0;
  border-radius: var(--flare-size-radius-lg);
  background: var(--flare-color-bg-primary);
  border: 1px solid var(--flare-color-border-primary);
  box-shadow: var(--flare-shadow-lg);
  overflow: hidden;
}

.flare-tp-pop-enter-active, .flare-tp-pop-leave-active { transition: opacity 0.14s ease, transform 0.14s ease; }
.flare-tp-pop-enter-from, .flare-tp-pop-leave-to { opacity: 0; transform: translateY(-4px); }
</style>
