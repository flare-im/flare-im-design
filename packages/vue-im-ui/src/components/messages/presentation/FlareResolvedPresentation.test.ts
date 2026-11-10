// @vitest-environment happy-dom
import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {mount} from '@vue/test-utils';
import {describe,it,expect,afterEach} from 'vitest';
import {nextTick,defineComponent,h,reactive} from 'vue';
import {useFlareI18nProvider} from '../../../shared/i18n/useFlareI18n';
import FlarePluginView from '../FlarePluginView.vue';
import FlarePluginForm from '../../form/FlarePluginForm.vue';
import FlareRedPacketCard from '../FlareRedPacketCard.vue';
import FlareRedPacketComposer from '../FlareRedPacketComposer.vue';
import FlareRedPacketPayConfirm from '../FlareRedPacketPayConfirm.vue';
import FlareRedPacketOpenSheet from '../FlareRedPacketOpenSheet.vue';
import FlareInput from '../../general/FlareInput.vue';
import FlareContactPicker from '../../composer/FlareContactPicker.vue';
import type {FlarePluginViewModel} from '../../../shared/contracts/plugin-ui';
import {provideFlareMessageQuote} from '../../../shared/message-renderers';
const fixtures=JSON.parse(readFileSync(resolve(__dirname,'../../../../../../spec/financial-presentation-vectors.json'),'utf8')) as Record<string,FlarePluginViewModel>;
const mounted:ReturnType<typeof mount>[]=[];afterEach(()=>{mounted.splice(0).forEach(w=>w.unmount());});
function mountView(view:FlarePluginViewModel,error?:string,extra:Record<string,unknown>={}){const root=mount(defineComponent({setup(){useFlareI18nProvider('zh-CN');return()=>h(FlarePluginView,{view,error,...extra});}}));mounted.push(root);return root.getComponent(FlarePluginView);}
describe('resolved payment Kit composition',()=>{
 it('requires a masked payment password and clears it before invoking the declared action',async()=>{
  const view=structuredClone(fixtures.payment);
  view.inputs=[{id:'password',kind:'password',label:'支付密码',required:true,maxLength:6}];
  const id=view.presentation!.actions.authorize!;
  view.presentation!.actions={confirm:id};
  view.actions.find(a=>a.id===id)!.form=['password'];
  const w=mountView(view);
  const pay=w.getComponent(FlareRedPacketPayConfirm);
  expect(pay.props('confirmDisabled')).toBe(true);
  const input=w.getComponent(FlareInput);expect(input.props('secure')).toBe(true);
  input.vm.$emit('update:modelValue','839271');await nextTick();
  expect(pay.props('confirmDisabled')).toBe(false);
  pay.vm.$emit('confirm');await nextTick();
  expect(w.emitted('action')?.[0]).toEqual([id,{formValues:{password:'839271'}}]);
  await w.findAll('button').find(b=>b.text()==='确认授权')!.trigger('click');
  expect(w.getComponent(FlareInput).props('modelValue')).toBe('');
 });

 it('uses the existing red packet card and routes only its declared action',async()=>{
  const w=mountView(fixtures.card);
  const card=w.getComponent(FlareRedPacketCard);expect(card.props('state')).toBe('refunded');
  await card.get('.flare-red-packet__open').trigger('click');expect(w.emitted('action')?.[0]).toEqual(['open',{}]);
 });
 it('passes the immutable brand prop into the existing envelope',()=>{
  const view=structuredClone(fixtures.card);view.presentation!.props.brandName='Company Gift';
  const w=mountView(view),card=w.getComponent(FlareRedPacketCard);
  expect(card.props('brandName')).toBe('Company Gift');
  expect(card.get('.flare-red-packet__brand-name').text()).toBe('Company Gift');
 });
 it('keeps read-only copies inert',async()=>{
  const view=structuredClone(fixtures.card);view.unavailableReason='unbound_copy';view.actions=[];view.presentation!.actions={};
  const w=mountView(view);const card=w.getComponent(FlareRedPacketCard);
  expect(card.props('disabled')).toBe(true);await card.get('.flare-red-packet__open').trigger('click');expect(w.emitted('action')).toBeUndefined();
 });
 it.each([false,true])('delegates the row quote inside the packet without sharing its open action (disabled %s)',async(disabled)=>{
  const view=structuredClone(fixtures.card);
  if(disabled){view.actions=[];view.presentation!.actions={};view.unavailableReason='unbound_copy';}
  let located=0,claimed=0;
  const root=mount(defineComponent({setup(){
   useFlareI18nProvider('zh-CN');
   provideFlareMessageQuote({active:()=>true,preview:()=> 'Earlier message',locate:()=>()=>located++,claim:()=>claimed++});
   return()=>h(FlarePluginView,{view});
  }}));mounted.push(root);
  const w=root.getComponent(FlarePluginView),packet=w.getComponent(FlareRedPacketCard);
  expect(claimed).toBe(1);
  expect(w.find('[data-plugin-quote]').exists()).toBe(false);
  expect(w.findAll('[data-card-quote]')).toHaveLength(1);
  const quote=packet.get('[data-card-quote]');
  expect(quote.element.closest('.flare-red-packet')).not.toBeNull();
  expect(quote.element.closest('.flare-red-packet__open')).toBeNull();
  expect(packet.findAll('button button')).toHaveLength(0);
  expect(quote.attributes('disabled')).toBeUndefined();
  await quote.trigger('click');expect(located).toBe(1);expect(w.emitted('action')).toBeUndefined();
  await packet.get('.flare-red-packet__open').trigger('click');
  expect(w.emitted('action')?.length??0).toBe(disabled?0:1);
 });
 it('keeps an explicit packet quote slot inside the envelope',async()=>{
  let located=0;
  const root=mount(defineComponent({setup(){useFlareI18nProvider('zh-CN');return()=>h(FlarePluginView,{view:fixtures.card},{quote:()=>h('button',{'data-custom-quote':'true',onClick:()=>located++},'Custom quote')});}}));mounted.push(root);
  const w=root.getComponent(FlarePluginView),packet=w.getComponent(FlareRedPacketCard),quote=packet.get('[data-custom-quote]');
  expect(w.find('[data-plugin-quote]').exists()).toBe(false);
  expect(quote.element.closest('.flare-red-packet__open')).toBeNull();
  expect(packet.findAll('button button')).toHaveLength(0);
  await quote.trigger('click');expect(located).toBe(1);expect(w.emitted('action')).toBeUndefined();
 });
 it('shows the payment confirmation with the exact amount and authorization label',()=>{
  const w=mountView(fixtures.payment);
  const pay=w.getComponent(FlareRedPacketPayConfirm);expect(pay.props('amount')).toBe('999999999999999999.99');expect(pay.props('confirmLabel')).toBe('确认授权');
 });
 it('locks a payment whose original result is unknown',()=>{
  const view=structuredClone(fixtures.payment);view.presentation!.props.journal={known:false,commandId:'original'};
  const w=mountView(view);expect(w.findComponent(FlareRedPacketPayConfirm).props('open')).toBe(false);
 });
 it('locks payment after a failed submit before the journal projection catches up',()=>{
  const w=mountView(fixtures.payment,'Result not confirmed');expect(w.findComponent(FlareRedPacketPayConfirm).props('open')).toBe(false);
  expect(w.findAll('button').find(b=>b.text()==='确认授权')?.attributes('disabled')).toBeDefined();
 });
 it('keeps an unknown original operation visible without reopening a claim sheet',()=>{
  const view=structuredClone(fixtures.card);
  view.presentation={renderer:'redPacket.detail',actions:{open:'open'},props:{journal:{known:false},claims:[],details:{viewerRole:'sender',status:'open',kind:'normal',greeting:'pending',currency:'CNY',currencyExponent:2,totalMinor:'24',claimedMinor:'0',refundedMinor:'0',claimedCount:0,shareCount:2,createdAtMs:1,expiresAtMs:Date.now()+60000,claimsListed:true}}};
  const w=mountView(view);expect(w.findComponent(FlareRedPacketOpenSheet).props('open')).toBe(false);
 });
 it('shows packet details before opening the envelope on an explicit claim tap',async()=>{
  const view=structuredClone(fixtures.card);
  view.actions=[{id:'open',label:'领取红包'}];
  view.presentation={renderer:'redPacket.detail',actions:{open:'open'},props:{journal:{known:true},claims:[],details:{viewerRole:'eligible',status:'open',kind:'normal',greeting:'Ready packet',currency:'CNY',currencyExponent:2,totalMinor:'24',claimedMinor:'0',refundedMinor:'0',claimedCount:0,shareCount:2,createdAtMs:1,expiresAtMs:Date.now()+60000,claimsListed:true}}};
  const w=mountView(view),sheet=w.getComponent(FlareRedPacketOpenSheet);
  expect(sheet.props('open')).toBe(false);
  expect(w.emitted('action')).toBeUndefined();
  await w.findAll('button').find(button=>button.text()==='领取红包')!.trigger('click');
  expect(sheet.props('open')).toBe(true);
  expect(w.emitted('action')).toBeUndefined();
  sheet.vm.$emit('close');await nextTick();
  expect(sheet.props('open')).toBe(false);
  await w.findAll('button').find(button=>button.text()==='领取红包')!.trigger('click');
  sheet.vm.$emit('open');await nextTick();
  expect(sheet.props('open')).toBe(false);
  expect(w.emitted('action')).toEqual([['open',{}]]);
 });
 it('opens the composer directly and emits only user editable values',async()=>{
  const w=mountView(fixtures.composer);
  expect(w.findComponent(FlarePluginForm).exists()).toBe(false);
  const composer=w.getComponent(FlareRedPacketComposer);
  composer.vm.$emit('update:amount','0.23');composer.vm.$emit('update:count',2);await nextTick();
  expect(composer.props('total')).toBe('CNY 0.46');composer.vm.$emit('submit');await nextTick();
  const [id,payload]=w.emitted('action')![0] as [string,{formValues:Record<string,unknown>}];
  expect(id).toBe('prepare');expect(payload.formValues).toEqual({kind:'normal',decimalAmount:'0.23',shareCount:2,greeting:expect.any(String),designatedUserIds:[]});
 });
 it('offers only a normal packet in direct chats and locks an unknown conversation type',async()=>{
  const direct=structuredClone(fixtures.composer);direct.presentation!.props.conversationType='single';
  const w=mountView(direct);const composer=w.getComponent(FlareRedPacketComposer);
  expect(composer.props('kinds')).toEqual(['normal']);
  expect(w.find('[data-red-packet-recipient]').exists()).toBe(false);
  const unknown=structuredClone(fixtures.composer);delete unknown.presentation!.props.conversationType;
  const other=mountView(unknown);const blocked=other.getComponent(FlareRedPacketComposer);
  expect(blocked.props('locked')).toBe(true);blocked.vm.$emit('submit');await nextTick();
  expect(other.emitted('action')).toBeUndefined();
 });
 it('chooses one allowed group member, preserves that name across queries and clears only members on revision',async()=>{
  const view=structuredClone(fixtures.composer);view.presentation!.props.conversationType='group';
  const searches:string[]=[];
  const options=reactive({members:[{userId:'bob',name:'Bob'},{userId:'carol',name:'Carol'}],membersRevision:0,onMemberSearch:(query:string)=>searches.push(query)});
  const w=mountView(view,undefined,options);const composer=w.getComponent(FlareRedPacketComposer);
  composer.vm.$emit('update:amount','1.30');composer.vm.$emit('update:greeting','Selected member');composer.vm.$emit('update:kind','exclusive');await nextTick();
  expect(composer.props('locked')).toBe(true);composer.vm.$emit('submit');expect(w.emitted('action')).toBeUndefined();
  await w.get('[data-red-packet-recipient]').trigger('click');await nextTick();
  const picker=w.getComponent(FlareContactPicker);expect(picker.props('multiple')).toBe(false);expect(searches).toEqual(['']);
  picker.vm.$emit('select',[{userId:'bob',name:'Bob'}]);await nextTick();
  expect(w.get('[data-red-packet-recipient]').text()).toBe('Bob');
  options.members=[{userId:'carol',name:'Carol'}];await nextTick();
  expect(w.get('[data-red-packet-recipient]').text()).toBe('Bob');
  composer.vm.$emit('submit');await nextTick();
  expect((w.emitted('action')![0][1] as {formValues:Record<string,unknown>}).formValues).toEqual({kind:'exclusive',decimalAmount:'1.30',shareCount:1,greeting:'Selected member',designatedUserIds:['bob']});
  options.membersRevision+=1;await nextTick();
  expect(w.get('[data-red-packet-recipient]').text()).not.toBe('Bob');
  expect(composer.props('amount')).toBe('1.30');expect(composer.props('greeting')).toBe('Selected member');
  composer.vm.$emit('submit');await nextTick();expect(w.emitted('action')).toHaveLength(1);
 });
 it('rejects stale member choices while loading or failed and exposes the host retry',async()=>{
  const view=structuredClone(fixtures.composer);view.presentation!.props.conversationType='group';
  let retries=0;
  const options=reactive({members:[{userId:'bob',name:'Bob'}],membersLoading:false,membersError:undefined as string|undefined,onMemberSearch:(_query:string)=>undefined,onMembersRetry:()=>{retries++;}});
  const w=mountView(view,undefined,options);const composer=w.getComponent(FlareRedPacketComposer);
  composer.vm.$emit('update:kind','exclusive');await nextTick();await w.get('[data-red-packet-recipient]').trigger('click');
  const picker=w.getComponent(FlareContactPicker);
  options.membersLoading=true;await nextTick();picker.vm.$emit('select',[{userId:'bob',name:'Bob'}]);await nextTick();
  expect(composer.props('locked')).toBe(true);
  options.membersLoading=false;options.membersError='Members unavailable';await nextTick();
  picker.vm.$emit('select',[{userId:'bob',name:'Bob'}]);await nextTick();expect(composer.props('locked')).toBe(true);
  await picker.get('.flare-empty__act').trigger('click');expect(retries).toBe(1);
  options.membersError=undefined;options.members=[{userId:'carol',name:'Carol'}];await nextTick();
  picker.vm.$emit('select',[{userId:'bob',name:'Bob'}]);await nextTick();expect(composer.props('locked')).toBe(true);
  expect(w.emitted('action')).toBeUndefined();
 });
});
