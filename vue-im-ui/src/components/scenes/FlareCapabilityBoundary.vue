<script setup lang="ts">
import { ref, onErrorCaptured, watch } from 'vue';
import FlareStatusBanner from '../general/FlareStatusBanner.vue';
import type { CapabilityState } from '../../shared/contracts/scenes';
const props=defineProps<{state:CapabilityState;text:string;actionText?:string;resetKey?:string|number}>();
const emit=defineEmits<{action:[];error:[error:unknown]}>();const failed=ref(false);
onErrorCaptured(error=>{failed.value=true;emit('error',error);return false;});
watch(()=>props.resetKey,()=>{failed.value=false;});
</script>
<template><slot v-if="state==='available' && !failed" /><div v-else><progress v-if="state==='loading' && !failed" :aria-label="text" /><FlareStatusBanner :text="text" :tone="failed || state==='failed'?'danger':'neutral'" :action-text="state==='loading'?undefined:actionText" @action="emit('action')" /></div></template>
