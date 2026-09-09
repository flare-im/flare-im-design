<script setup lang="ts">
import { computed } from 'vue';
import FlareCapabilityBoundary from '../scenes/FlareCapabilityBoundary.vue';
import { selectableCallDevices, type CallDeviceGroup, type CallDeviceKind } from '../../shared/contracts/call-devices';
import type { CapabilityState } from '../../shared/contracts/scenes';
const props=withDefaults(defineProps<{groups:CallDeviceGroup[];permission:CapabilityState;permissionText:string;actionText?:string;placeholder?:string}>(),{placeholder:'选择设备'});
const emit=defineEmits<{select:[value:{kind:CallDeviceKind;deviceId:string}];permissionAction:[]}>();
const groups=computed(()=>props.groups.map(group=>({...group,devices:selectableCallDevices(group)})));
function select(group:CallDeviceGroup,event:Event){
  const id=(event.target as HTMLSelectElement).value;
  if(props.permission==='available' && !group.busy && group.devices.some(d=>d.id===id&&!d.disabled)) emit('select',{kind:group.kind,deviceId:id});
  // Keep the confirmed host selection while a device switch is pending.
  (event.target as HTMLSelectElement).value=group.devices.some(d=>d.id===group.selectedId)?group.selectedId!:'';
}
</script>
<template><section class="flare-call-devices">
  <FlareCapabilityBoundary :state="permission" :text="permissionText" :action-text="actionText" @action="emit('permissionAction')"><span role="status">{{ permissionText }}</span></FlareCapabilityBoundary>
  <label v-for="group in groups" :key="group.kind"><span>{{ group.label }}</span><select :aria-label="group.label" :value="group.devices.some(d=>d.id===group.selectedId)?group.selectedId:''" :disabled="permission!=='available'||group.busy||!group.devices.some(d=>!d.disabled)" @change="select(group,$event)"><option disabled value="">{{ placeholder }}</option><option v-for="device in group.devices" :key="device.id" :value="device.id" :disabled="device.disabled">{{ device.label }}</option></select></label>
</section></template>
<style scoped>.flare-call-devices{display:grid;gap:12px;min-width:0}label{display:grid;gap:8px;min-width:0}span{overflow-wrap:anywhere}select{min-height:48px;width:100%;min-width:0;max-width:100%;padding:8px 12px;background:var(--flare-color-bg-surface);color:var(--flare-color-text-primary);border:1px solid var(--flare-color-border-primary);border-radius:8px;font:inherit}select:focus-visible{outline:2px solid var(--flare-color-primary);outline-offset:2px}</style>
