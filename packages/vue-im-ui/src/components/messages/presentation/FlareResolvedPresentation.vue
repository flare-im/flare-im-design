<script setup lang="ts">
/** Composes compiled-in Kit components over inert, already-resolved props. No SDK or target interpretation. */
import { computed, onBeforeUnmount, ref, shallowReactive, watch } from "vue";
import FlareRedPacketCard from "../FlareRedPacketCard.vue";
import FlareRedPacketComposer from "../FlareRedPacketComposer.vue";
import FlareRedPacketDetail from "../FlareRedPacketDetail.vue";
import FlareRedPacketOpenSheet from "../FlareRedPacketOpenSheet.vue";
import FlareRedPacketPayConfirm from "../FlareRedPacketPayConfirm.vue";
import FlarePluginView from "../FlarePluginView.vue";
import FlareInput from "../../general/FlareInput.vue";
import FlareButton from "../../general/FlareButton.vue";
import { useFlareI18nOptional } from "../../../shared/i18n/useFlareI18n";
import { flarePluginFallbackName, type FlarePluginViewModel, type FlarePluginActionPayload, type FlarePluginFormError, type FlarePluginResolveUser, type FlarePluginMember, type FlarePluginUser } from "../../../shared/contracts/plugin-ui";
import { flareRedPacketCardState, flareRedPacketAmountMinor, flareRedPacketAmountText, type FlareRedPacketKind, type FlareRedPacketStatus, type FlareRedPacketDetailsView, type FlareRedPacketClaim } from "../../../shared/contracts/red-packet";
const props=defineProps<{view:FlarePluginViewModel;busy?:boolean;error?:string;formErrors?:ReadonlyArray<FlarePluginFormError>;settleToken?:number;resolveUser?:FlarePluginResolveUser;members?:FlarePluginMember[]}>();
const emit=defineEmits<{action:[id:string,payload:FlarePluginActionPayload];request:[id:string]}>();
const {t}=useFlareI18nOptional();
const p=computed(()=>props.view.presentation!.props);
const renderer=computed(()=>props.view.presentation!.renderer);
const bound=(key:string)=>{const id=props.view.presentation?.actions[key] ?? (key==='confirm'?props.view.presentation?.actions.authorize:undefined);return props.view.actions.find(a=>a.id===id);};
const object=(v:unknown):Record<string,unknown> => v!==null&&typeof v==='object'&&!Array.isArray(v)?v as Record<string,unknown>:{};
const text=(v:unknown)=>typeof v==='string'?v:'';
const journalUnknown=computed(()=>object(p.value.journal).known===false);
// A failed submit can arrive before a refreshed journal projection. Require
// review/recovery before offering another payment on that stale view.
const paymentBlocked=computed(()=>journalUnknown.value||Boolean(props.error));
const kind=ref<FlareRedPacketKind>('normal'),amount=ref(''),count=ref(1),greeting=ref(text(props.view.inputs?.find(i=>i.id==='greeting')?.default));
const recipient=ref('');
const asset=computed(()=>object(p.value.funding));
const exponent=computed(()=>typeof asset.value?.currencyExponent==='number'?asset.value.currencyExponent:2);
const total=computed(()=>{const minor=flareRedPacketAmountMinor(amount.value,exponent.value);if(minor===null||minor.length>64)return '';const n=kind.value==='normal'?Math.max(0,count.value):1;return `${text(asset.value?.currency)} ${flareRedPacketAmountText((BigInt(minor)*BigInt(n)).toString(),exponent.value)??''}`.trim();});
const formError=computed(()=>props.formErrors?.map(e=>`${props.view.inputs?.find(i=>i.id===e.input)?.label??e.input}: ${t('pluginForm.invalid')}`).join(' · ')||undefined);
function submit(){const action=bound('submit');if(!action||props.busy||journalUnknown.value)return;emit('action',action.id,{formValues:{designatedUserId:kind.value==='exclusive'?recipient.value:'',kind:kind.value,decimalAmount:amount.value,shareCount:kind.value==='exclusive'?1:count.value,greeting:greeting.value}});}
const handled=computed(()=>new Set(Object.values(props.view.presentation?.actions??{})));
const remainder=computed<FlarePluginViewModel>(()=>({...props.view,presentation:undefined,title:'',fields:['redPacket.pay','payment.confirm'].includes(renderer.value)?props.view.fields:[],blocks:renderer.value==='redPacket.card'?[]:props.view.blocks,actions:props.view.actions.filter(a=>!handled.value.has(a.id)),detail:false}));
const cardState=computed(()=>flareRedPacketCardState({status:text(p.value.status) as FlareRedPacketStatus,claimedByMe:p.value.claimedByMe===true,tapAction:p.value.canClaim===false?'details':'open'}));
const open=ref(true),payOpen=ref(true);
watch(()=>props.settleToken,()=>{if(props.error||props.formErrors?.length)payOpen.value=false;});
const details=computed(()=>p.value.details as FlareRedPacketDetailsView|undefined);
const users=shallowReactive(new Map<string,FlarePluginUser>());let alive=true;onBeforeUnmount(()=>{alive=false;});
watch(()=>[p.value.senderId,p.value.claims,props.resolveUser] as const,()=>{
 const ids=[text(p.value.senderId),...(Array.isArray(p.value.claims)?p.value.claims.map(c=>text(object(c).id)):[])];
 for(const id of new Set(ids)){if(!id||users.has(id)||!props.resolveUser)continue;users.set(id,{name:flarePluginFallbackName(id)});Promise.resolve(props.resolveUser(id)).then(u=>{if(alive&&u)users.set(id,u);},()=>undefined);}
},{immediate:true});
const sender=computed(()=>users.get(text(p.value.senderId))??{name:flarePluginFallbackName(text(p.value.senderId))});
const claims=computed<FlareRedPacketClaim[]>(()=>Array.isArray(p.value.claims)?p.value.claims.map(raw=>{const c=object(raw),id=text(c.id),user=users.get(id);return {id,name:user?.name??flarePluginFallbackName(id),avatar:user?.avatarUrl,amountMinor:text(c.amountMinor),claimedAtMs:typeof c.claimedAtMs==='number'?c.claimedAtMs:0,best:c.best===true};}):[]);
const mayOpen=computed(()=>Boolean(bound('open'))&&details.value?.status==='open'&&!journalUnknown.value&&!props.error);
function requestOpen(){open.value=false;const a=bound('open');if(a&&!props.busy&&!journalUnknown.value)emit('request',a.id);}
function confirmPay(){payOpen.value=false;const a=bound('confirm');if(a&&!props.busy&&!paymentBlocked.value)emit('request',a.id);}
</script>
<template>
  <FlareRedPacketCard v-if="renderer==='redPacket.card'" :blessing="text(p.blessing)" :kind="(text(p.kind)||'normal') as FlareRedPacketKind" :state="cardState" :busy="busy" :disabled="!bound('open')" @open="requestOpen" />
  <template v-else-if="renderer==='redPacket.composer'">
    <FlareRedPacketComposer v-model:kind="kind" v-model:amount="amount" v-model:count="count" v-model:greeting="greeting" :kinds="['normal','lucky','exclusive']" :currency-exponent="exponent" :total="total" :error="formError" :busy="busy" :locked="journalUnknown||!bound('submit')" :submit-label="bound('submit')?.label" @submit="submit">
      <template #recipient><FlareInput v-model="recipient" :placeholder="view.inputs?.find(i=>i.id==='designatedUserId')?.label" :disabled="busy||journalUnknown" :max-length="128" /></template>
    </FlareRedPacketComposer>
  </template>
  <template v-else-if="renderer==='redPacket.detail'&&details">
    <FlareRedPacketDetail :sender-name="sender.name" :sender-avatar="sender.avatarUrl" :details="details" :claims="claims" />
    <FlareButton v-if="mayOpen" :label="bound('open')!.label" :disabled="busy||journalUnknown" @click="open=true" />
    <FlareRedPacketOpenSheet :open="open&&mayOpen" :sender-name="sender.name" :sender-avatar="sender.avatarUrl" :blessing="details.greeting" :state="busy?'opening':'ready'" @open="requestOpen" @close="open=false" @view-details="open=false" />
  </template>
  <template v-else-if="['redPacket.pay','payment.confirm'].includes(renderer)">
    <FlareButton v-if="bound('confirm')" :label="bound('confirm')!.label" :disabled="busy||paymentBlocked" @click="payOpen=true" />
    <FlareRedPacketPayConfirm :open="payOpen&&Boolean(bound('confirm'))&&!paymentBlocked" :confirm-label="bound('confirm')?.label" :amount="text(p.amount)" :method-label="text(p.methodLabel)" :busy="busy" @confirm="confirmPay" @cancel="payOpen=false" />
  </template>
  <FlarePluginView v-if="renderer!=='redPacket.card'" :view="remainder" embedded :busy="busy" :form-errors="[...(formErrors??[])]" :settle-token="settleToken" :resolve-user="resolveUser" :members="members" @action="(id,payload)=>emit('action',id,payload)" />
</template>
