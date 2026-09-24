<script setup lang="ts">
// Group permission panel — the "group settings" section of group management.
// Every row is one real backend field of FlareGroupDetailModel: joinPolicy,
// muteAll, onlyAdminCanAtAll, onlyAdminCanPin, shareCardPermission. The host
// owns the values: switching a row only emits `change`, and the displayed value
// flips when the host writes the confirmed settings back. Each row has its own
// busy and its own failure, so a partial failure keeps the rows that succeeded.
import { computed, ref } from "vue";
import { NIcon } from "naive-ui";
import { flareIcons } from "../../shared/icons";
import {
  groupJoinPolicies,
  groupPermissionRows,
  type FlareGroupJoinPolicy,
  type GroupPermissionChangePayload,
  type GroupPermissionKey,
  type GroupPermissionRow,
  type GroupPermissionSettings,
} from "../../shared/contracts/group-permissions";
import { useFlareI18n } from "../../shared/i18n/useFlareI18n";

const props = withDefaults(
  defineProps<{
    settings: GroupPermissionSettings;
    /** Viewer may edit; false renders read-only value rows, never dead switches. */
    canManage?: boolean;
    /** Keys whose command is in flight — the host sets this before dispatching. */
    busyKeys?: string[];
    /** Per-key failure reason, kept on screen until the host dismisses it. */
    errors?: Record<string, string>;
    title?: string;
    readOnlyHintText?: string;
    joinPolicyLabel?: string;
    joinPolicyDescription?: string;
    joinInviteText?: string;
    joinApprovalText?: string;
    joinOpenText?: string;
    unknownJoinPolicyText?: string;
    muteAllLabel?: string;
    muteAllDescription?: string;
    onlyAdminCanAtAllLabel?: string;
    onlyAdminCanAtAllDescription?: string;
    onlyAdminCanPinLabel?: string;
    onlyAdminCanPinDescription?: string;
    shareCardPermissionLabel?: string;
    shareCardPermissionDescription?: string;
    onText?: string;
    offText?: string;
    busyText?: string;
    retryText?: string;
    dismissErrorText?: string;
  }>(),
  {
    canManage: false,
    busyKeys: () => [],
    errors: () => ({}),
  },
);
const { t } = useFlareI18n();
const strings = computed(() => ({
  title: props.title ?? t("groupPermissionMatrix.title"),
  readOnlyHintText: props.readOnlyHintText ?? t("groupPermissionMatrix.readOnlyHint"),
  joinPolicyLabel: props.joinPolicyLabel ?? t("groupPermissionMatrix.joinPolicy"),
  joinPolicyDescription: props.joinPolicyDescription ?? t("groupPermissionMatrix.joinPolicyDescription"),
  joinInviteText: props.joinInviteText ?? t("groupPermissionMatrix.joinInvite"),
  joinApprovalText: props.joinApprovalText ?? t("groupPermissionMatrix.joinApproval"),
  joinOpenText: props.joinOpenText ?? t("groupPermissionMatrix.joinOpen"),
  unknownJoinPolicyText: props.unknownJoinPolicyText ?? t("groupPermissionMatrix.unknownJoinPolicy"),
  muteAllLabel: props.muteAllLabel ?? t("groupPermissionMatrix.muteAll"),
  muteAllDescription: props.muteAllDescription ?? t("groupPermissionMatrix.muteAllDescription"),
  onlyAdminCanAtAllLabel: props.onlyAdminCanAtAllLabel ?? t("groupPermissionMatrix.onlyAdminCanAtAll"),
  onlyAdminCanAtAllDescription: props.onlyAdminCanAtAllDescription ?? t("groupPermissionMatrix.onlyAdminCanAtAllDescription"),
  onlyAdminCanPinLabel: props.onlyAdminCanPinLabel ?? t("groupPermissionMatrix.onlyAdminCanPin"),
  onlyAdminCanPinDescription: props.onlyAdminCanPinDescription ?? t("groupPermissionMatrix.onlyAdminCanPinDescription"),
  shareCardPermissionLabel: props.shareCardPermissionLabel ?? t("groupPermissionMatrix.shareCardPermission"),
  shareCardPermissionDescription: props.shareCardPermissionDescription ?? t("groupPermissionMatrix.shareCardPermissionDescription"),
  onText: props.onText ?? t("groupPermissionMatrix.on"),
  offText: props.offText ?? t("groupPermissionMatrix.off"),
  busyText: props.busyText ?? t("groupPermissionMatrix.busy"),
  retryText: props.retryText ?? t("groupPermissionMatrix.retry"),
  dismissErrorText: props.dismissErrorText ?? t("groupPermissionMatrix.dismissError"),
}));

const emit = defineEmits<{
  (event: "change", payload: GroupPermissionChangePayload): void;
  (event: "dismissError", key: GroupPermissionKey): void;
}>();

const rows = computed(() =>
  groupPermissionRows(props.settings, props.canManage, props.busyKeys, props.errors),
);

const glyphs: Record<GroupPermissionKey, unknown> = {
  joinPolicy: flareIcons.lock,
  muteAll: flareIcons.silence,
  onlyAdminCanAtAll: flareIcons.mention,
  onlyAdminCanPin: flareIcons.pin,
  shareCardPermission: flareIcons.share,
};

function labelFor(key: GroupPermissionKey): string {
  switch (key) {
    case "joinPolicy": return strings.value.joinPolicyLabel;
    case "muteAll": return strings.value.muteAllLabel;
    case "onlyAdminCanAtAll": return strings.value.onlyAdminCanAtAllLabel;
    case "onlyAdminCanPin": return strings.value.onlyAdminCanPinLabel;
    case "shareCardPermission": return strings.value.shareCardPermissionLabel;
  }
}
function descriptionFor(key: GroupPermissionKey): string {
  switch (key) {
    case "joinPolicy": return strings.value.joinPolicyDescription;
    case "muteAll": return strings.value.muteAllDescription;
    case "onlyAdminCanAtAll": return strings.value.onlyAdminCanAtAllDescription;
    case "onlyAdminCanPin": return strings.value.onlyAdminCanPinDescription;
    case "shareCardPermission": return strings.value.shareCardPermissionDescription;
  }
}
const joinPolicyLabels = computed<Record<FlareGroupJoinPolicy, string>>(() => ({
  open: strings.value.joinOpenText,
  approval: strings.value.joinApprovalText,
  invite: strings.value.joinInviteText,
}));
const joinOptions = computed(() => groupJoinPolicies.map((value) => ({ value, label: joinPolicyLabels.value[value] })));
function joinPolicyText(value: FlareGroupJoinPolicy | null): string {
  return value ? joinPolicyLabels.value[value] : strings.value.unknownJoinPolicyText;
}

// Remembers the value this component last asked for, per key, so "retry" resends
// the same intent. It is not optimistic state: the rendered value stays the host's.
const lastAttempt = ref<Partial<Record<GroupPermissionKey, boolean | FlareGroupJoinPolicy>>>({});

function dispatch(row: GroupPermissionRow, value: boolean | FlareGroupJoinPolicy): void {
  if (!row.editable || row.busy) return;
  lastAttempt.value = { ...lastAttempt.value, [row.key]: value };
  emit("change", { key: row.key, value });
}
function toggle(row: GroupPermissionRow): void {
  dispatch(row, !(row.value === true));
}
/** A choice row can only be retried when we know what was attempted; its options stay live anyway. */
function retryValue(row: GroupPermissionRow): boolean | FlareGroupJoinPolicy | null {
  const attempted = lastAttempt.value[row.key];
  if (attempted !== undefined) return attempted;
  return row.kind === "toggle" ? !(row.value === true) : null;
}
function retry(row: GroupPermissionRow): void {
  const value = retryValue(row);
  if (value === null) return;
  dispatch(row, value);
}
</script>

<template>
  <section class="flare-gpm" :aria-label="strings.title">
    <header class="flare-gpm__head">
      <h3 class="flare-gpm__title">{{ strings.title }}</h3>
      <p v-if="!canManage" class="flare-gpm__hint">
        <n-icon :size="14" :component="flareIcons.lock" aria-hidden="true" />
        <span>{{ strings.readOnlyHintText }}</span>
      </p>
    </header>

    <ul class="flare-gpm__rows">
      <li
        v-for="row in rows"
        :key="row.key"
        class="flare-gpm__row"
        :class="{ 'flare-gpm__row--failed': !!row.error }"
        :aria-busy="row.busy || undefined"
      >
        <div class="flare-gpm__main">
          <span class="flare-gpm__icon" aria-hidden="true">
            <n-icon aria-hidden="true" :size="18" :component="glyphs[row.key] as any" />
          </span>
          <div class="flare-gpm__text">
            <span class="flare-gpm__label" :id="`flare-gpm-${row.key}`">{{ labelFor(row.key) }}</span>
            <span class="flare-gpm__desc">{{ descriptionFor(row.key) }}</span>
          </div>

          <div class="flare-gpm__control">
            <span v-if="row.busy" class="flare-gpm__busy" role="status">
              <span class="flare-gpm__spinner" aria-hidden="true" />
              <span class="flare-gpm__busy-text">{{ strings.busyText }}</span>
            </span>

            <template v-if="row.kind === 'toggle'">
              <button
                v-if="row.editable"
                type="button"
                role="switch"
                class="flare-gpm__switch"
                :class="{ 'is-on': row.value === true }"
                :aria-checked="row.value === true"
                :aria-labelledby="`flare-gpm-${row.key}`"
                :disabled="row.busy"
                @click="toggle(row)"
              >
                <span class="flare-gpm__knob" />
              </button>
              <span v-else class="flare-gpm__value">{{ row.value === true ? strings.onText : strings.offText }}</span>
            </template>

            <span v-else-if="!row.editable" class="flare-gpm__value">
              {{ joinPolicyText(row.value as FlareGroupJoinPolicy | null) }}
            </span>
          </div>
        </div>

        <div
          v-if="row.kind === 'choice' && row.editable"
          class="flare-gpm__choices"
          role="radiogroup"
          :aria-labelledby="`flare-gpm-${row.key}`"
        >
          <button
            v-for="option in joinOptions"
            :key="option.value"
            type="button"
            role="radio"
            class="flare-gpm__choice"
            :class="{ 'is-selected': row.value === option.value }"
            :aria-checked="row.value === option.value"
            :disabled="row.busy"
            @click="dispatch(row, option.value)"
          >
            <span class="flare-gpm__choice-mark" aria-hidden="true">
              <n-icon aria-hidden="true" v-if="row.value === option.value" :size="14" :component="flareIcons.check" />
            </span>
            <span>{{ option.label }}</span>
          </button>
          <p v-if="row.value === null" class="flare-gpm__unknown" role="status">
            {{ strings.unknownJoinPolicyText }}
          </p>
        </div>

        <div v-if="row.error" class="flare-gpm__error" role="alert">
          <n-icon :size="14" :component="flareIcons.error" class="flare-gpm__error-icon" aria-hidden="true" />
          <span class="flare-gpm__error-text">{{ row.error }}</span>
          <button
            v-if="row.editable && retryValue(row) !== null"
            type="button"
            class="flare-gpm__btn"
            :disabled="row.busy"
            @click="retry(row)"
          >
            <n-icon :size="14" :component="flareIcons.refresh" aria-hidden="true" />
            <span>{{ strings.retryText }}</span>
          </button>
          <button
            type="button"
            class="flare-gpm__btn flare-gpm__btn--icon"
            :aria-label="strings.dismissErrorText"
            :title="strings.dismissErrorText"
            @click="emit('dismissError', row.key)"
          >
            <n-icon :size="14" :component="flareIcons.close" aria-hidden="true" />
          </button>
        </div>
      </li>
    </ul>
  </section>
</template>

<style scoped>
.flare-gpm {
  display: grid;
  gap: var(--flare-size-spacing-sm);
  min-width: 0;
  padding: var(--flare-size-spacing-md);
  border-radius: var(--flare-size-radius-lg);
  border: 1px solid var(--flare-color-border-primary);
  background: var(--flare-color-bg-primary);
  color: var(--flare-color-text-primary);
}
.flare-gpm__head {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  gap: var(--flare-size-spacing-sm);
  flex-wrap: wrap;
}
.flare-gpm__title {
  margin: 0;
  font-size: var(--flare-size-font-size-lg);
  font-weight: 600;
}
.flare-gpm__hint {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  margin: 0;
  font-size: var(--flare-size-font-size-sm);
  color: var(--flare-color-text-tertiary);
}
.flare-gpm__rows {
  list-style: none;
  margin: 0;
  padding: 0;
  display: grid;
  gap: var(--flare-size-spacing-xs);
}
.flare-gpm__row {
  display: grid;
  gap: var(--flare-size-spacing-xs);
  padding: var(--flare-size-spacing-sm) 0;
  border-bottom: 1px solid var(--flare-color-border-secondary);
}
.flare-gpm__row:last-child { border-bottom: none; }
.flare-gpm__main {
  display: flex;
  align-items: center;
  gap: var(--flare-size-spacing-md);
  min-height: var(--flare-size-layout-touch-target);
  min-width: 0;
}
.flare-gpm__icon {
  display: grid;
  place-items: center;
  width: 32px;
  height: 32px;
  flex: none;
  border-radius: var(--flare-size-radius-full);
  color: var(--flare-color-primary-text);
  background: color-mix(in srgb, var(--flare-color-primary) 10%, var(--flare-color-bg-primary));
}
.flare-gpm__text { display: grid; gap: 2px; min-width: 0; flex: 1 1 auto; }
.flare-gpm__label {
  font-size: var(--flare-size-font-size-lg);
  font-weight: 500;
  overflow-wrap: anywhere;
}
.flare-gpm__desc {
  font-size: var(--flare-size-font-size-sm);
  color: var(--flare-color-text-secondary);
  overflow-wrap: anywhere;
}
.flare-gpm__control {
  display: inline-flex;
  align-items: center;
  gap: var(--flare-size-spacing-sm);
  flex: none;
}
.flare-gpm__value {
  font-size: var(--flare-size-font-size-md);
  color: var(--flare-color-text-secondary);
  text-align: end;
  overflow-wrap: anywhere;
}
.flare-gpm__busy {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  font-size: var(--flare-size-font-size-sm);
  color: var(--flare-color-text-tertiary);
}
.flare-gpm__spinner {
  width: 14px;
  height: 14px;
  border-radius: 50%;
  border: 2px solid currentColor;
  border-right-color: transparent;
  animation: flare-gpm-spin 0.8s linear infinite;
  flex: none;
}
@keyframes flare-gpm-spin { to { transform: rotate(360deg); } }
@media (prefers-reduced-motion: reduce) { .flare-gpm__spinner { animation-duration: 2s; } }
.flare-gpm__switch {
  position: relative;
  width: 44px;
  height: 26px;
  flex: none;
  padding: 0;
  border: none;
  border-radius: var(--flare-size-radius-full);
  background: var(--flare-color-border-hover);
  cursor: pointer;
  transition: background var(--flare-transition-fast);
}
.flare-gpm__switch.is-on { background: var(--flare-color-primary); }
.flare-gpm__switch:disabled { opacity: 0.5; cursor: progress; }
.flare-gpm__switch:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: 2px; }
.flare-gpm__knob {
  position: absolute;
  top: 3px;
  left: 3px;
  width: 20px;
  height: 20px;
  border-radius: 50%;
  background: var(--flare-color-bg-primary);
  box-shadow: var(--flare-shadow-sm);
  transition: transform var(--flare-transition-normal);
}
.flare-gpm__switch.is-on .flare-gpm__knob { transform: translateX(18px); }
.flare-gpm__choices {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  padding-inline-start: 44px;
}
.flare-gpm__choice {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  min-height: 40px;
  padding: 0 var(--flare-size-spacing-2sm);
  border: 1px solid var(--flare-color-border-primary);
  border-radius: var(--flare-size-radius-md);
  background: var(--flare-color-bg-secondary);
  color: var(--flare-color-text-primary);
  font: inherit;
  font-size: var(--flare-size-font-size-md);
  cursor: pointer;
}
@media (pointer: coarse) {
  .flare-gpm__choice { min-height: var(--flare-size-layout-touch-target); }
}
.flare-gpm__choice.is-selected {
  border-color: var(--flare-color-border-selected);
  background: var(--flare-color-bg-selected);
  color: var(--flare-color-primary-text);
  font-weight: 600;
}
.flare-gpm__choice:disabled { opacity: 0.5; cursor: progress; }
.flare-gpm__choice:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: 2px; }
.flare-gpm__choice-mark { display: grid; place-items: center; width: 14px; height: 14px; flex: none; }
.flare-gpm__unknown {
  flex-basis: 100%;
  margin: 0;
  font-size: var(--flare-size-font-size-sm);
  color: var(--flare-color-warning-text);
  overflow-wrap: anywhere;
}
.flare-gpm__error {
  display: flex;
  align-items: center;
  gap: 6px;
  flex-wrap: wrap;
  margin-inline-start: 44px;
  padding: 6px 8px;
  border-radius: var(--flare-size-radius-sm);
  background: color-mix(in srgb, var(--flare-color-error) 8%, var(--flare-color-bg-primary));
}
.flare-gpm__error-icon { color: var(--flare-color-error-text); flex: none; }
.flare-gpm__error-text {
  font-size: var(--flare-size-font-size-sm);
  color: var(--flare-color-error-text);
  min-width: 0;
  overflow-wrap: anywhere;
  flex: 1 1 auto;
}
.flare-gpm__btn {
  display: inline-flex;
  align-items: center;
  gap: 4px;
  min-height: 32px;
  padding: 0 8px;
  border: none;
  border-radius: var(--flare-size-radius-sm);
  background: var(--flare-color-bg-secondary);
  color: var(--flare-color-text-primary);
  font: inherit;
  font-size: var(--flare-size-font-size-sm);
  cursor: pointer;
  flex: none;
}
.flare-gpm__btn:disabled { opacity: 0.5; cursor: progress; }
.flare-gpm__btn:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: 2px; }
.flare-gpm__btn--icon { padding: 0 6px; }
</style>
