<script setup lang="ts">
/** Composes compiled-in Kit components over inert, already-resolved props. No SDK or target interpretation. */
// The one compiled-in renderer left: redPacket.card (the envelope). The payment confirmation is no renderer any more:
// it is the host capability paymentConfirmation (FlarePaymentConfirmation, drawn by the host for the engine's
// confirmPayment request), and redPacket.pay / payment.confirm draw as the plain document like every other
// retired renderer name.
import { computed } from "vue";
import FlareRedPacketCard from "../FlareRedPacketCard.vue";
import type { FlarePluginViewModel } from "../../../shared/contracts/plugin-ui";
import { flareRedPacketCardState, type FlareRedPacketKind, type FlareRedPacketStatus } from "../../../shared/contracts/red-packet";
const props=defineProps<{view:FlarePluginViewModel;busy?:boolean}>();
const emit=defineEmits<{request:[id:string]}>();
const p=computed(()=>props.view.presentation!.props);
const bound=(key:string)=>{const id=props.view.presentation?.actions[key];return props.view.actions.find(a=>a.id===id);};
const object=(v:unknown):Record<string,unknown> => v!==null&&typeof v==='object'&&!Array.isArray(v)?v as Record<string,unknown>:{};
const text=(v:unknown)=>typeof v==='string'?v:'';
const journalUnknown=computed(()=>object(p.value.journal).known===false);
const cardState=computed(()=>flareRedPacketCardState({status:text(p.value.status) as FlareRedPacketStatus,claimedByMe:p.value.claimedByMe===true,tapAction:p.value.canClaim===false?'details':'open'}));
function requestOpen(){const a=bound('open');if(a&&!props.busy&&!journalUnknown.value)emit('request',a.id);}
</script>
<template>
  <FlareRedPacketCard :blessing="text(p.blessing)" :brand-name="text(p.brandName)" :kind="(text(p.kind)||'normal') as FlareRedPacketKind" :state="cardState" :busy="busy" :disabled="!bound('open')" @open="requestOpen">
    <template v-if="$slots.quote" #quote><slot name="quote" /></template>
  </FlareRedPacketCard>
</template>
