<script setup lang="ts">
import { computed } from 'vue';
import FlareCapabilityBoundary from '../scenes/FlareCapabilityBoundary.vue';
import { selectableCallDevices, type CallDeviceGroup, type CallDeviceKind } from '../../shared/contracts/call-devices';
import type { CapabilityState } from '../../shared/contracts/scenes';
const props = defineProps<{groups: CallDeviceGroup[]; permission: CapabilityState; permissionText: string; actionText?: string; placeholder?: string}>();
const emit = defineEmits<{select: [value: {kind: CallDeviceKind; deviceId: string}]; permissionAction: []}>();
const groups = computed(() => props.groups.map(group => ({...group, devices: selectableCallDevices(group)})));
function selected(group: CallDeviceGroup): string {
  if (group.devices.some(d => d.id === group.selectedId)) return group.selectedId!;
  return group.selectedId ? '' : group.devices.find(d => d.id === 'default')?.id ?? '';
}
function select(group: CallDeviceGroup, id: string) {
  if (props.permission === 'available' && !group.busy && group.devices.some(d => d.id === id && !d.disabled)) emit('select', {kind: group.kind, deviceId: id});
}
</script>
<template>
  <section class="flare-call-devices">
    <FlareCapabilityBoundary v-if="permission !== 'available'" :state="permission" :text="permissionText" :action-text="actionText" @action="emit('permissionAction')" />
    <div v-for="group in groups" :key="group.kind" class="flare-call-devices__group">
      <span>{{ group.label }}</span>
      <button v-for="device in group.devices" :key="device.id" class="flare-call-devices__option" type="button"
        :aria-pressed="selected(group) === device.id" :disabled="permission !== 'available' || group.busy || device.disabled"
        @click="select(group, device.id)"><span>{{ device.label }}</span><span aria-hidden="true">{{ selected(group) === device.id ? '✓' : '' }}</span></button>
    </div>
  </section>
</template>
<style scoped>
.flare-call-devices { display: grid; gap: 12px; min-width: 0; max-height: min(360px, 55vh); overflow-y: auto; overscroll-behavior: contain; color: #f4f4f5; }
.flare-call-devices__group { display: grid; gap: var(--flare-size-spacing-sm); min-width: 0; }
.flare-call-devices__group > span { font-size: var(--flare-size-font-size-md); color: rgba(255,255,255,.6); overflow-wrap: anywhere; }
</style>

<style scoped>
.flare-call-devices__group { gap: 4px; }
.flare-call-devices__option { display:flex; align-items:center; justify-content:space-between; gap:12px; min-height:44px; width:100%; border:0; border-radius:8px; padding:8px; text-align:start; font:inherit; font-size:13px; color:inherit; background:transparent; cursor:pointer; }
.flare-call-devices__option span:first-child { min-width:0; overflow-wrap:anywhere; }
.flare-call-devices__option:hover, .flare-call-devices__option[aria-pressed="true"] { background:rgba(255,255,255,.1); }
.flare-call-devices__option:focus-visible { outline:2px solid var(--flare-color-primary); }
.flare-call-devices__option:disabled { opacity:.45; cursor:default; }
</style>
