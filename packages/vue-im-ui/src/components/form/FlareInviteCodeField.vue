<script setup lang="ts">
// The registration form's invite-code field. The tenant decides whether it exists
// (`mode`), the person types or pastes a code, the field normalizes it the way the
// server reads it and — once the code is complete — asks the host to pre-check it.
// The host owns the request: it sets `checking`, then hands back `checkResult` (or
// an `error` it has already localized). The field never touches the network.
import { computed, nextTick, onBeforeUnmount, ref, watch } from "vue";
import FlareFormField from "./FlareFormField.vue";
import FlareInput from "../general/FlareInput.vue";
import FlareIcon from "../general/FlareIcon.vue";
import {
  FLARE_INVITE_CHECK_DEBOUNCE_MS,
  FLARE_INVITE_CODE_DEFAULT_LENGTH,
  inviteCodeFieldState,
  inviteCodeToCheck,
  normalizeInviteCode,
  type FlareInviteCodeCheckResult,
  type FlareInviteCodeMode,
} from "../../shared/contracts/invite";
import { useFlareI18nOptional } from "../../shared/i18n/useFlareI18n";

const props = withDefaults(
  defineProps<{
    /** Two-way bound code; what the host receives is already normalized. */
    modelValue: string;
    /** Tenant invite mode: `off` renders nothing. */
    mode?: FlareInviteCodeMode;
    /** Deep-link value applied once while the field is empty. */
    prefill?: string;
    /** The host's pre-check is in flight. */
    checking?: boolean;
    /** The host's pre-check result for the current code. */
    checkResult?: FlareInviteCodeCheckResult | null;
    /** Host-localized error shown instead of the hint; wins over `checkResult`. */
    error?: string;
    disabled?: boolean;
    /** Code length the tenant configured; a check is only requested for a complete code. */
    length?: number;
    label?: string;
    placeholder?: string;
  }>(),
  {
    mode: "optional",
    prefill: "",
    checking: false,
    checkResult: null,
    error: "",
    disabled: false,
    length: FLARE_INVITE_CODE_DEFAULT_LENGTH,
    label: undefined,
    placeholder: undefined,
  },
);
const emit = defineEmits<{
  (e: "update:modelValue", value: string): void;
  /** A complete, normalized code the host should pre-check; debounced after typing stops. */
  (e: "check", code: string): void;
}>();

const { t } = useFlareI18nOptional();
const strings = computed(() => ({
  label: props.label ?? t("inviteCode.label"),
  placeholder: props.placeholder ?? t("inviteCode.placeholder"),
  optional: t("inviteCode.optional"),
  checking: t("inviteCode.checking"),
  invalid: t("inviteCode.invalid"),
}));

const state = computed(() =>
  inviteCodeFieldState({
    mode: props.mode,
    value: props.modelValue,
    checking: props.checking,
    checkResult: props.checkResult,
    error: props.error,
    disabled: props.disabled,
  }),
);
const visible = computed(() => state.value !== "off");
const required = computed(() => props.mode === "required");

// A stale result for another code must not be shown as this code's verdict: the
// host clears `checkResult` when the code changes, and this guard covers the tick
// in between.
const resultMatchesValue = computed(
  () => !props.checkResult || inviteCodeToCheck({ value: props.modelValue, length: props.length }) !== null,
);
const inviterLine = computed(() => {
  if (state.value !== "valid" || !resultMatchesValue.value) return "";
  const name = props.checkResult?.inviterDisplayName?.trim();
  return name ? t("inviteCode.inviter", { name }) : t("inviteCode.valid");
});
const errorLine = computed(() => {
  if (props.error) return props.error;
  if (state.value === "invalid" && resultMatchesValue.value) return strings.value.invalid;
  return "";
});
const hintLine = computed(() => (props.mode === "optional" && state.value === "idle" ? strings.value.optional : ""));

/** The one visible status line under the field; a live region so a screen reader hears the verdict. */
const statusLine = computed(() => {
  if (state.value === "checking") return { kind: "checking" as const, text: strings.value.checking };
  if (inviterLine.value) return { kind: "valid" as const, text: inviterLine.value };
  return null;
});

// Debounced pre-check: one request about 400 ms after the last keystroke, and only
// for a complete code. Re-arming on every change means a person still typing never
// triggers a request for the code they are about to change.
let timer: ReturnType<typeof setTimeout> | null = null;
let lastRequested: string | null = null;
function cancelPending(): void {
  if (timer !== null) clearTimeout(timer);
  timer = null;
}
function scheduleCheck(value: string): void {
  cancelPending();
  const code = inviteCodeToCheck({ value, length: props.length, mode: props.mode, disabled: props.disabled });
  if (code === null) {
    lastRequested = null;
    return;
  }
  if (code === lastRequested) return;
  timer = setTimeout(() => {
    timer = null;
    lastRequested = code;
    emit("check", code);
  }, FLARE_INVITE_CHECK_DEBOUNCE_MS);
}
onBeforeUnmount(cancelPending);

// The native input is not capped with `maxlength`: a pasted "Code: o1-l2 i3" must
// be normalized whole, not cut to its first six raw characters. So when the
// normalized code did not change (a seventh character, a separator), the model
// does not move and the element has to be put back by hand.
const control = ref<HTMLElement | null>(null);
function onInput(raw: string): void {
  const next = normalizeInviteCode(raw, props.length);
  if (next !== props.modelValue) emit("update:modelValue", next);
  void nextTick(() => {
    const el = control.value?.querySelector("input");
    if (el && el.value !== next) el.value = next;
  });
  scheduleCheck(next);
}

// Deep-link prefill: applied once, while the field is empty, and checked like a
// paste. A person who clears the field afterwards is not re-filled.
let prefillApplied = false;
watch(
  () => [props.prefill, props.mode] as const,
  ([prefill]) => {
    if (prefillApplied || props.mode === "off" || !prefill || props.modelValue) return;
    const next = normalizeInviteCode(prefill, props.length);
    if (!next) return;
    prefillApplied = true;
    emit("update:modelValue", next);
    scheduleCheck(next);
  },
  { immediate: true },
);
</script>

<template>
  <FlareFormField
    v-if="visible"
    class="flare-invite-code"
    :class="`flare-invite-code--${state}`"
    :label="strings.label"
    :required="required"
    :hint="hintLine || undefined"
    :error="errorLine || undefined"
  >
    <div ref="control" class="flare-invite-code__control">
      <FlareInput
        :model-value="modelValue"
        :placeholder="strings.placeholder"
        :disabled="disabled"
        :invalid="state === 'invalid'"
        monospace
        autocomplete="off"
        inputmode="text"
        name="invite-code"
        :spellcheck="false"
        @update:model-value="onInput"
      />
    </div>
    <p v-if="statusLine" class="flare-invite-code__status" :class="`flare-invite-code__status--${statusLine.kind}`" role="status">
      <span v-if="statusLine.kind === 'checking'" class="flare-invite-code__spinner" aria-hidden="true" />
      <FlareIcon v-else name="success" :size="16" />
      <span>{{ statusLine.text }}</span>
    </p>
  </FlareFormField>
</template>

<style scoped>
.flare-invite-code__status {
  display: inline-flex;
  align-items: center;
  gap: var(--flare-size-spacing-2xs);
  margin: var(--flare-size-spacing-2xs) 0 0;
  font-size: var(--flare-size-font-size-sm);
  color: var(--flare-color-text-secondary);
}
.flare-invite-code__status--valid { color: var(--flare-color-success-text); }
.flare-invite-code__spinner {
  width: var(--flare-size-icon-size-sm);
  height: var(--flare-size-icon-size-sm);
  border-radius: 50%;
  border: 2px solid currentColor;
  border-right-color: transparent;
  animation: flare-invite-spin 0.8s linear infinite;
  flex: none;
}
@keyframes flare-invite-spin { to { transform: rotate(360deg); } }
@media (prefers-reduced-motion: reduce) { .flare-invite-code__spinner { animation-duration: 2s; } }
</style>
