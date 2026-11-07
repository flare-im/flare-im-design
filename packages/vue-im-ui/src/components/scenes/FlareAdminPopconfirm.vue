<script setup lang="ts">
/** Native Naive confirmation, positioned at the actual invoking control. No business callbacks. */
import {
  computed,
  nextTick,
  onBeforeUnmount,
  onMounted,
  ref,
  shallowRef,
  watch,
} from "vue";
import { NFormItem, NInput, NPopconfirm } from "naive-ui";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";
import { useFlareOverlayContainer } from "../../shared/useOverlayContainer";
import {
  confirmReasonBytes,
  type FlareConfirmInput,
  type FlareConfirmReason,
} from "../../shared/contracts/scenes";

const props = defineProps<{
  open: boolean;
  requestKey?: number;
  title: string;
  description: string;
  target?: string;
  busy?: boolean;
  error?: string;
  confirmText?: string;
  cancelText?: string;
  reason?: FlareConfirmReason;
  /** Optional explicit trigger for a host that already owns its element ref. */
  anchor?: HTMLElement | null;
}>();
const emit = defineEmits<{
  confirm: [input: FlareConfirmInput, requestKey: number | undefined];
  cancel: [requestKey: number | undefined];
}>();
const { t } = useFlareI18nOptional();
const overlay = useFlareOverlayContainer();
const content = ref<HTMLElement | null>(null);
const point = ref<{ x: number; y: number } | null>(null);
const width = ref(320);
const targetContainer = shallowRef<string | HTMLElement>(overlay.value);
const reasonText = ref("");
let lastTrigger: HTMLElement | null = null;
let trigger: HTMLElement | null = null;
let epoch = 0;
const trimmedReason = computed(() => reasonText.value.trim());
const tooLong = computed(
  () =>
    !!props.reason &&
    ((props.reason.maxLength != null &&
      trimmedReason.value.length > props.reason.maxLength) ||
      (props.reason.maxBytes != null &&
        confirmReasonBytes(trimmedReason.value) > props.reason.maxBytes)),
);
const ready = computed(
  () =>
    !tooLong.value &&
    (!props.reason || props.reason.optional || !!trimmedReason.value),
);
const panel = () =>
  content.value?.closest<HTMLElement>(".flare-admin-popconfirm");

function rememberTrigger(event: Event) {
  const element = event
    .composedPath()
    .find((node) => node instanceof HTMLElement) as HTMLElement | undefined;
  const control = element?.closest<HTMLElement>(
    'button, [role="button"], [role="switch"], input, textarea',
  );
  if (control && !control.closest(".flare-admin-popconfirm"))
    lastTrigger = control;
}
function restoreFocus() {
  if (
    panel()?.contains(document.activeElement) &&
    trigger?.isConnected &&
    !trigger.matches(":disabled")
  )
    trigger.focus({ preventScroll: true });
}
function cancel(owner = props.requestKey) {
  if (props.open && !props.busy) emit("cancel", owner);
  return false; // Controlled by the host generation, never Naive's independent close promise.
}
function position() {
  if (!props.open || !trigger) return;
  const rect = trigger.getBoundingClientRect();
  if (!trigger.isConnected || (rect.width === 0 && rect.height === 0)) {
    if (!props.busy) cancel();
    return;
  }
  width.value = Math.min(320, Math.max(160, window.innerWidth - 24));
  point.value = {
    x: Math.max(
      width.value / 2 + 12,
      Math.min(
        window.innerWidth - width.value / 2 - 12,
        rect.left + rect.width / 2,
      ),
    ),
    y: rect.bottom,
  };
}
function onKeydown(event: KeyboardEvent) {
  if (!props.open || !point.value || event.key !== "Escape") return;
  const active = document.activeElement;
  const activeSurface =
    active instanceof HTMLElement
      ? active.closest("[data-flare-presentation]")
      : null;
  const ownSurface = trigger?.closest("[data-flare-presentation]") ?? null;
  // A separate, later-opened drawer owns its own Escape, even while this write is pending.
  if (activeSurface !== ownSurface && !panel()?.contains(active)) return;
  // Consume before a containing drawer: one Escape dismisses only this contextual confirmation.
  event.preventDefault();
  event.stopPropagation();
  cancel();
}
const controls = computed(() => {
  const owner = props.requestKey;
  return {
    positive: () => {
      if (props.open && !props.busy && ready.value)
        emit(
          "confirm",
          { reason: props.reason ? trimmedReason.value : "" },
          owner,
        );
      return false;
    },
    negative: () => cancel(owner),
    show: (show: boolean) => {
      if (!show) cancel(owner);
    },
  };
});
watch(
  [() => props.open, () => props.requestKey],
  async ([open]) => {
    const current = ++epoch;
    if (typeof document === "undefined") return;
    if (!open) {
      restoreFocus();
      point.value = null;
      trigger = null;
      return;
    }
    reasonText.value = "";
    const focused = document.activeElement;
    trigger =
      props.anchor ??
      lastTrigger ??
      (focused instanceof HTMLElement && focused !== document.body
        ? focused
        : null);
    if (!trigger?.isConnected) {
      cancel();
      return;
    }
    // Keep Native popover content inside an existing drawer's focus boundary.
    targetContainer.value =
      trigger.closest<HTMLElement>("[data-flare-presentation]") ??
      overlay.value;
    position();
    await nextTick();
    await nextTick();
    if (current === epoch && props.open && !props.busy)
      panel()
        ?.querySelector<HTMLButtonElement>("button:not([disabled])")
        ?.focus({ preventScroll: true });
  },
  { immediate: true, flush: "post" },
);
onMounted(() => {
  document.addEventListener("click", rememberTrigger, true);
  document.addEventListener("keydown", rememberTrigger, true);
  document.addEventListener("keydown", onKeydown, true);
  window.addEventListener("resize", position);
  document.addEventListener("scroll", position, true);
});
onBeforeUnmount(() => {
  ++epoch;
  restoreFocus();
  document.removeEventListener("click", rememberTrigger, true);
  document.removeEventListener("keydown", rememberTrigger, true);
  document.removeEventListener("keydown", onKeydown, true);
  window.removeEventListener("resize", position);
  document.removeEventListener("scroll", position, true);
  lastTrigger = trigger = null;
});
</script>

<template>
  <NPopconfirm
    trigger="manual"
    placement="bottom"
    :show="open && !!point"
    :x="point?.x ?? 0"
    :y="point?.y ?? 0"
    :width="width"
    :to="targetContainer"
    :show-icon="false"
    content-class="flare-admin-popconfirm"
    :positive-text="confirmText ?? t('dangerConfirm.confirm')"
    :negative-text="cancelText ?? t('dangerConfirm.cancel')"
    :positive-button-props="{
      size: 'small',
      type: 'error',
      loading: busy,
      disabled: busy || !ready,
    }"
    :negative-button-props="{ size: 'small', disabled: busy }"
    :on-positive-click="controls.positive"
    :on-negative-click="controls.negative"
    :on-clickoutside="controls.negative"
    @update:show="controls.show"
  >
    <div
      ref="content"
      class="flare-admin-popconfirm__body"
      role="group"
      :aria-label="title"
    >
      <strong>{{ title }}</strong>
      <span>{{ description }}</span>
      <strong v-if="target" class="flare-admin-popconfirm__target">{{
        target
      }}</strong>
      <NFormItem
        v-if="reason"
        :label="reason.label"
        :required="!reason.optional"
        :show-feedback="!!reason.hint || tooLong"
        :feedback="
          tooLong
            ? t('dangerConfirm.reasonTooLong', {
                max: reason.maxBytes ?? reason.maxLength ?? 0,
              })
            : reason.hint
        "
        :validation-status="tooLong ? 'error' : undefined"
      >
        <NInput
          v-model:value="reasonText"
          size="small"
          :disabled="busy"
          :maxlength="reason.maxLength"
          :placeholder="reason.placeholder"
          :input-props="{ 'aria-label': reason.label }"
          @keydown.enter.prevent
        />
      </NFormItem>
      <span v-if="error" role="alert" class="flare-admin-popconfirm__error">{{
        error
      }}</span>
    </div>
  </NPopconfirm>
</template>

<style scoped>
.flare-admin-popconfirm__body {
  display: flex;
  flex-direction: column;
  gap: var(--flare-size-spacing-sm);
  min-width: 0;
  overflow-wrap: anywhere;
}
.flare-admin-popconfirm__target {
  font-weight: var(--flare-font-weight-medium, 500);
}
.flare-admin-popconfirm__error {
  color: var(--flare-color-error-text);
}
</style>
