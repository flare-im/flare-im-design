<script setup lang="ts">
import { computed } from 'vue';
import { NModal, type ButtonProps } from 'naive-ui';
const props=withDefaults(defineProps<{open:boolean;title:string;description:string;target:string;busy?:boolean;error?:string;confirmText?:string;cancelText?:string}>(),{confirmText:'确认',cancelText:'取消'});
const emit=defineEmits<{confirm:[];cancel:[]}>();
const positiveProps = computed<ButtonProps & { 'aria-label': string }>(() => ({ 'aria-label': props.confirmText, disabled: props.busy, type: 'error', style: { minHeight: '48px' } }));
const negativeProps = computed<ButtonProps & { 'aria-label': string }>(() => ({ 'aria-label': props.cancelText, disabled: props.busy, style: { minHeight: '48px' } }));
function confirm(){ if(!props.busy) emit('confirm'); return false; }
function cancel(){ if(!props.busy) emit('cancel'); return false; }
</script>
<template><NModal style="width: min(440px, calc(100vw - 32px))" :show="open" preset="dialog" :title="title" :closable="!busy" :mask-closable="!busy" :close-on-esc="!busy" :positive-text="confirmText" :negative-text="cancelText" :positive-button-props="positiveProps" :negative-button-props="negativeProps" :loading="busy" @positive-click="confirm" @negative-click="cancel" @update:show="!$event && !busy && emit('cancel')"><p>{{ description }}</p><strong>{{ target }}</strong><p v-if="error" role="alert">{{ error }}</p></NModal></template>
