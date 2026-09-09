<script setup lang="ts">
import FlareCapabilityBoundary from './FlareCapabilityBoundary.vue';
import type { CapabilityState,NotificationPreference } from '../../shared/contracts/scenes';
withDefaults(defineProps<{items:NotificationPreference[];permission:CapabilityState;permissionText:string;permissionActionText?:string;title?:string}>(),{title:'通知设置'});
const emit=defineEmits<{change:[value:{id:string;value:boolean}];permissionAction:[]}>();
</script>
<template><section class="notification-preferences"><h3>{{ title }}</h3><FlareCapabilityBoundary :state="permission" :text="permissionText" :action-text="permissionActionText" @action="emit('permissionAction')"><span role="status">{{ permissionText }}</span></FlareCapabilityBoundary><label v-for="item in items" :key="item.id"><span><strong>{{ item.title }}</strong><small>{{ item.detail }}</small></span><input type="checkbox" role="switch" :checked="item.value" :disabled="permission!=='available'||!item.enabled||item.busy" @change="emit('change',{id:item.id,value:($event.target as HTMLInputElement).checked})" /></label></section></template>
<style scoped>h3{font-size:16px}label{display:flex;align-items:center;gap:12px;min-height:48px;padding:12px 0;border-bottom:1px solid var(--flare-color-border-primary)}span{flex:1;min-width:0}small{display:block;overflow-wrap:anywhere;color:var(--flare-color-text-secondary);margin-top:4px}input{width:24px;height:24px;margin:12px;accent-color:var(--flare-color-primary)}</style>
