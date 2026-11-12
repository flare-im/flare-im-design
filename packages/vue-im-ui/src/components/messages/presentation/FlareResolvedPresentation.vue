<script setup lang="ts">
/** Composes compiled-in Kit components over inert, already-resolved props. No SDK or target interpretation. */
// The compiled-in renderers left after vocabulary 2: redPacket.card (the envelope) and the payment confirmation
// (redPacket.pay, payment.confirm). The red packet composer and detail are declarative now (money input; hero,
// entries and banner blocks), so their renderer names fall back to the plain document.
import { computed, getCurrentInstance, ref, watch } from "vue";
import FlareRedPacketCard from "../FlareRedPacketCard.vue";
import FlareRedPacketPayConfirm from "../FlareRedPacketPayConfirm.vue";
import FlarePluginView from "../FlarePluginView.vue";
import FlareInput from "../../general/FlareInput.vue";
import FlareButton from "../../general/FlareButton.vue";
import type { FlarePluginFileState, FlarePluginFileAction, FlarePluginViewModel, FlarePluginActionPayload, FlarePluginFormError, FlarePluginResolveUser, FlarePluginMember, FlarePluginImageSource, FlarePluginQrRefresh } from "../../../shared/contracts/plugin-ui";
import { flareRedPacketCardState, type FlareRedPacketKind, type FlareRedPacketStatus } from "../../../shared/contracts/red-packet";
const props=defineProps<{view:FlarePluginViewModel;busy?:boolean;error?:string;formErrors?:ReadonlyArray<FlarePluginFormError>;settleToken?:number;resolveUser?:FlarePluginResolveUser;members?:FlarePluginMember[];membersLoading?:boolean;membersRevision?:number;membersError?:string;onMemberSearch?:(query:string)=>void;onMembersRetry?:()=>void;fileStates?:Record<string,FlarePluginFileState>;resolveImage?:(source:FlarePluginImageSource)=>string|undefined|Promise<string|undefined>}>();
const instance = getCurrentInstance();
const emit=defineEmits<{action:[id:string,payload:FlarePluginActionPayload];request:[id:string];fileAction:[event:FlarePluginFileAction];qrRefresh:[request:FlarePluginQrRefresh]}>();
const p=computed(()=>props.view.presentation!.props);
const renderer=computed(()=>props.view.presentation!.renderer);
const bound=(key:string)=>{const id=props.view.presentation?.actions[key] ?? (key==='confirm'?props.view.presentation?.actions.authorize:undefined);return props.view.actions.find(a=>a.id===id);};
const object=(v:unknown):Record<string,unknown> => v!==null&&typeof v==='object'&&!Array.isArray(v)?v as Record<string,unknown>:{};
const text=(v:unknown)=>typeof v==='string'?v:'';
const journalUnknown=computed(()=>object(p.value.journal).known===false);
// A failed submit can arrive before a refreshed journal projection. Require
// review/recovery before offering another payment on that stale view.
const passwordInput=computed(()=>props.view.inputs?.find(i=>i.kind==='password'&&bound('confirm')?.form?.includes(i.id)));
const paymentPassword=ref('');
watch(()=>props.view,()=>{paymentPassword.value='';});
const passwordInvalid=computed(()=>Boolean(passwordInput.value)&&!/^[0-9]{6}$/.test(paymentPassword.value));
const paymentBlocked=computed(()=>journalUnknown.value||(Boolean(props.error)&&!passwordInput.value));
const handled=computed(()=>new Set(Object.values(props.view.presentation?.actions??{})));
const remainder=computed<FlarePluginViewModel>(()=>({...props.view,presentation:undefined,title:'',fields:['redPacket.pay','payment.confirm'].includes(renderer.value)?props.view.fields:[],blocks:renderer.value==='redPacket.card'?[]:props.view.blocks,actions:props.view.actions.filter(a=>!handled.value.has(a.id)),detail:false}));
const cardState=computed(()=>flareRedPacketCardState({status:text(p.value.status) as FlareRedPacketStatus,claimedByMe:p.value.claimedByMe===true,tapAction:p.value.canClaim===false?'details':'open'}));
const payOpen=ref(true);
watch(()=>props.settleToken,()=>{if(props.error||props.formErrors?.length)payOpen.value=false;});
function requestOpen(){const a=bound('open');if(a&&!props.busy&&!journalUnknown.value)emit('request',a.id);}
function confirmPay(){
 const a=bound('confirm');if(!a||props.busy||paymentBlocked.value||passwordInvalid.value)return;
 payOpen.value=false;
 if(passwordInput.value){const value=paymentPassword.value;paymentPassword.value='';emit('action',a.id,{formValues:{[passwordInput.value.id]:value}});}
 else emit('request',a.id);
}
function cancelPay(){paymentPassword.value='';payOpen.value=false;}
function forwardFileAction(event: FlarePluginFileAction): void { emit("fileAction", event); }
// The blocks under a pay sheet draw images and refresh QR codes as any view does (the host's resolver and listener).
function forwardQrRefresh(request: FlarePluginQrRefresh): void { emit("qrRefresh", request); }
</script>
<template>
  <FlareRedPacketCard v-if="renderer==='redPacket.card'" :blessing="text(p.blessing)" :brand-name="text(p.brandName)" :kind="(text(p.kind)||'normal') as FlareRedPacketKind" :state="cardState" :busy="busy" :disabled="!bound('open')" @open="requestOpen">
    <template v-if="$slots.quote" #quote><slot name="quote" /></template>
  </FlareRedPacketCard>
  <template v-else-if="['redPacket.pay','payment.confirm'].includes(renderer)">
    <FlareButton v-if="bound('confirm')" :label="bound('confirm')!.label" :disabled="busy||paymentBlocked" @click="payOpen=true" />
    <FlareRedPacketPayConfirm :open="payOpen&&Boolean(bound('confirm'))&&!paymentBlocked" :confirm-label="bound('confirm')?.label" :amount="text(p.amount)" :method-label="text(p.methodLabel)" :busy="busy" :confirm-disabled="passwordInvalid" @confirm="confirmPay" @cancel="cancelPay">
      <template v-if="passwordInput" #credential><FlareInput v-model="paymentPassword" :placeholder="passwordInput.placeholder ?? passwordInput.label" :aria-label="passwordInput.label" :secure="true" inputmode="numeric" autocomplete="off" :max-length="6" :disabled="busy" @submit="confirmPay" /></template>
    </FlareRedPacketPayConfirm>
  </template>
  <FlarePluginView v-if="renderer!=='redPacket.card'" :view="remainder" :file-states="fileStates" :onFileAction="instance?.vnode.props?.onFileAction ? forwardFileAction : undefined" embedded :busy="busy" :form-errors="[...(formErrors??[])]" :settle-token="settleToken" :resolve-user="resolveUser" :members="members" :members-loading="membersLoading" :members-revision="membersRevision" :members-error="membersError" :on-member-search="onMemberSearch" :on-members-retry="onMembersRetry" :resolve-image="resolveImage" :onQrRefresh="instance?.vnode.props?.onQrRefresh ? forwardQrRefresh : undefined" @action="(id,payload)=>emit('action',id,payload)" />
</template>
