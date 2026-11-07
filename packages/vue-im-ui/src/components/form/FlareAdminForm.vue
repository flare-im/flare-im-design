<script lang="ts">
// One current Native picker across form instances, never business or model state.
let activePicker: { form: HTMLElement; picker: HTMLElement } | undefined;
</script>

<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref } from "vue";
import { NForm } from "naive-ui";

defineOptions({ inheritAttrs: false });
const props = withDefaults(
  defineProps<{
    /** Short editing fields align on desktop; long/grouped fields may opt into top labels. */
    labelPlacement?: "responsive" | "left" | "top";
    labelWidth?: number | string;
    size?: "small" | "medium" | "large";
    disabled?: boolean;
  }>(),
  { labelPlacement: "responsive", labelWidth: 128, size: "small" },
);
const form = ref<InstanceType<typeof NForm>>();
function rememberPicker(event: Event) {
  const owner = form.value?.$el;
  if (!(owner instanceof HTMLElement) || !(event.target instanceof Element))
    return;
  const picker = event.target.closest<HTMLElement>(
    ".n-select, .n-date-picker, .n-time-picker",
  );
  activePicker =
    picker && owner.contains(picker) ? { form: owner, picker } : undefined;
}
function onFieldEscape(event: KeyboardEvent) {
  // Native picker inputs already consume Escape to close their own popup, but
  // Naive marks that internally rather than preventing the DOM event. Keep the
  // same key from reaching the surrounding Kit drawer and discarding its draft.
  // Ordinary inputs still bubble Escape normally; no value or write is touched.
  if (
    event.target instanceof Element &&
    event.target.closest(".n-select, .n-date-picker, .n-time-picker")
  )
    event.stopPropagation();
}
function onPopupEscape(event: KeyboardEvent) {
  // Naive teleports picker panels outside the form. Let that panel process the
  // key while marking the DOM event for the shared drawer's defaultPrevented
  // contract. Do not block other shortcuts or close a parent surface ourselves.
  if (
    event.key === "Escape" &&
    event.target instanceof Element &&
    event.target.closest(
      ".n-date-panel, .n-time-picker-panel, .n-base-select-menu",
    )
  ) {
    event.preventDefault();
    const owner = form.value?.$el;
    const active = activePicker;
    if (!active || active.form !== owner || !active.picker.isConnected) return;
    const trigger = active.picker.querySelector<HTMLElement>(
      "input, .n-base-selection-label",
    );
    if (!trigger) return;
    // Native's panel text inputs do not forward Escape to its main input.
    // Delegate this same intent to the owning Native trigger so Native closes
    // its own popup and restores focus; never synthesize a value or blur-write.
    event.stopPropagation();
    trigger.dispatchEvent(
      new KeyboardEvent("keydown", {
        key: "Escape",
        bubbles: true,
        cancelable: true,
      }),
    );
  }
}
const narrow = ref(false);
const placement = computed(() =>
  props.labelPlacement === "responsive"
    ? narrow.value
      ? "top"
      : "left"
    : props.labelPlacement,
);
let observer: ResizeObserver | undefined;
onMounted(() => {
  document.addEventListener("keydown", onPopupEscape, true);
  const root = form.value?.$el;
  if (!(root instanceof HTMLElement)) return;
  const measure = () => {
    // Measure layout width, not the scaled rectangle during a Native modal's
    // enter animation (transforms do not trigger a later ResizeObserver update).
    narrow.value = root.clientWidth < 520;
  };
  measure();
  if (typeof ResizeObserver !== "undefined") {
    observer = new ResizeObserver(measure);
    observer.observe(root);
  }
});
onBeforeUnmount(() => {
  observer?.disconnect();
  document.removeEventListener("keydown", onPopupEscape, true);
  if (activePicker?.form === form.value?.$el) activePicker = undefined;
});
// Preserve access to the real Naive form for callers that explicitly need validation.
defineExpose({ form });
</script>

<template>
  <NForm
    ref="form"
    class="flare-admin-form"
    v-bind="$attrs"
    :size="size"
    :disabled="disabled"
    :label-placement="placement"
    :label-width="placement === 'left' ? labelWidth : undefined"
    label-align="left"
    @keydown.esc="onFieldEscape"
    @focusin.capture="rememberPicker"
    @pointerdown.capture="rememberPicker"
  >
    <slot />
  </NForm>
</template>

<style scoped>
.flare-admin-form {
  min-width: 0;
  width: 100%;
  box-sizing: border-box;
}
.flare-admin-form :deep(.n-date-picker) {
  width: 100%;
  min-width: 0;
}
.flare-admin-form :deep(.n-form-item) {
  min-width: 0;
}
.flare-admin-form :deep(.n-form-item-feedback-wrapper),
.flare-admin-form :deep(.n-form-item-feedback) {
  /* JSON defaults, IDs and validation messages wrap within their field,
     including native forms composed inside a structured editor. */
  min-width: 0;
  overflow-wrap: anywhere;
}
.flare-admin-form :deep(.n-form-item-feedback) {
  padding-block-end: var(--flare-size-spacing-sm);
}
.flare-admin-form > :deep(details) {
  margin-bottom: var(--flare-size-spacing-md);
}
</style>
