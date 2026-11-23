<script setup lang="ts">
// The PC device panel (docs/plugin-experience.md §3.6): one radio group per kind on color.call.popover; up and down
// move within a group, Enter / Space choose. While a group's device switches (group.busy) its options are disabled and
// a small spinner follows its title.
import { computed } from 'vue';
import FlareCapabilityBoundary from '../scenes/FlareCapabilityBoundary.vue';
import FlareIcon from '../general/FlareIcon.vue';
import { selectableCallDevices, type CallDeviceGroup, type CallDeviceKind } from '../../shared/contracts/call-devices';
import type { CapabilityState } from '../../shared/contracts/scenes';
import { useFlareI18nOptional } from '../../shared/i18n/useFlareI18n';
const props = defineProps<{groups: CallDeviceGroup[]; permission: CapabilityState; permissionText: string; actionText?: string; placeholder?: string}>();
const emit = defineEmits<{select: [value: {kind: CallDeviceKind; deviceId: string}]; permissionAction: []}>();
const {t} = useFlareI18nOptional();
const groups = computed(() => props.groups.map(group => ({...group, devices: selectableCallDevices(group)})));
const placeholderText = computed(() => props.placeholder ?? t('callDevicePicker.placeholder'));
function selected(group: CallDeviceGroup): string {
  if (group.devices.some(d => d.id === group.selectedId)) return group.selectedId!;
  return group.selectedId ? '' : group.devices.find(d => d.id === 'default')?.id ?? '';
}
function select(group: CallDeviceGroup, id: string) {
  if (props.permission === 'available' && !group.busy && group.devices.some(d => d.id === id && !d.disabled)) emit('select', {kind: group.kind, deviceId: id});
}
/** Up / down: the previous / next enabled option of the same group, wrapping. */
function move(event: KeyboardEvent, step: 1 | -1) {
  const options = [...((event.currentTarget as HTMLElement).querySelectorAll<HTMLButtonElement>('[role="radio"]:not(:disabled)'))];
  const at = options.indexOf(document.activeElement as HTMLButtonElement);
  if (!options.length || at < 0) return;
  event.preventDefault();
  options[(at + step + options.length) % options.length]!.focus();
}
</script>
<template>
  <section class="flare-call-devices">
    <FlareCapabilityBoundary v-if="permission !== 'available'" :state="permission" :text="permissionText" :action-text="actionText" @action="emit('permissionAction')" />
    <div v-for="group in groups" :key="group.kind" class="flare-call-devices__group" role="radiogroup" :aria-label="group.label" :aria-busy="group.busy || undefined"
      @keydown.down="move($event, 1)" @keydown.up="move($event, -1)">
      <span class="flare-call-devices__label" aria-hidden="true">{{ group.label }}<span v-if="group.busy" class="flare-call-devices__spinner" data-device-switching="true" /></span>
      <span v-if="!selected(group)" class="flare-call-devices__placeholder">{{ placeholderText }}</span>
      <button v-for="device in group.devices" :key="device.id" class="flare-call-devices__option" type="button" role="radio"
        :aria-checked="selected(group) === device.id" :disabled="permission !== 'available' || group.busy || device.disabled"
        @click="select(group, device.id)"><span>{{ device.label }}</span><FlareIcon v-if="selected(group) === device.id" name="check" size="sm" /></button>
    </div>
  </section>
</template>
<style scoped>
.flare-call-devices { display: grid; gap: var(--flare-size-spacing-md); min-width: 0; max-height: min(360px, 55vh); overflow-y: auto; overscroll-behavior: contain; color: var(--flare-color-call-on-stage); }
.flare-call-devices__group { display: grid; gap: var(--flare-size-spacing-xs); min-width: 0; }
.flare-call-devices__label,
.flare-call-devices__placeholder { font-size: var(--flare-size-font-size-sm); color: var(--flare-color-call-on-stage-secondary); overflow-wrap: anywhere; }
.flare-call-devices__option {
  display: flex; align-items: center; justify-content: space-between; gap: var(--flare-size-spacing-md);
  min-height: var(--flare-size-layout-touch-target-min); width: 100%;
  padding: var(--flare-size-spacing-sm); border: 0; border-radius: var(--flare-size-radius-md);
  text-align: start; font: inherit; font-size: var(--flare-size-font-size-lg); color: inherit; background: transparent; cursor: pointer;
}
.flare-call-devices__option span { min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.flare-call-devices__option[aria-checked="true"] { background: var(--flare-color-call-control); }
@media (hover: hover) {
  .flare-call-devices__option:not(:disabled):hover { background: var(--flare-color-call-control-hover); }
}
.flare-call-devices__option:focus-visible { outline: 2px solid var(--flare-color-border-selected); outline-offset: -2px; }
.flare-call-devices__option:disabled { opacity: var(--flare-opacity-disabled); cursor: default; }
.flare-call-devices__label { display: inline-flex; align-items: center; gap: var(--flare-size-spacing-xs); }
.flare-call-devices__spinner {
  width: var(--flare-size-font-size-sm); height: var(--flare-size-font-size-sm); box-sizing: border-box;
  border: 2px solid currentColor; border-top-color: transparent; border-radius: var(--flare-size-radius-full);
  animation: flare-call-devices-spin 0.7s linear infinite;
}
@media (prefers-reduced-motion: reduce) { .flare-call-devices__spinner { animation: none; } }
@keyframes flare-call-devices-spin { to { transform: rotate(360deg); } }
</style>
