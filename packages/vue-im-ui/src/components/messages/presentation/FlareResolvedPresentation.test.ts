// @vitest-environment happy-dom
import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {mount} from '@vue/test-utils';
import {describe,it,expect,afterEach} from 'vitest';
import {nextTick,defineComponent,h} from 'vue';
import {useFlareI18nProvider} from '../../../shared/i18n/useFlareI18n';
import FlarePluginView from '../FlarePluginView.vue';
import FlarePluginForm from '../../form/FlarePluginForm.vue';
import FlareRedPacketCard from '../FlareRedPacketCard.vue';
import FlareRedPacketComposer from '../FlareRedPacketComposer.vue';
import FlareRedPacketPayConfirm from '../FlareRedPacketPayConfirm.vue';
import FlareRedPacketOpenSheet from '../FlareRedPacketOpenSheet.vue';
import type {FlarePluginViewModel} from '../../../shared/contracts/plugin-ui';
const fixtures=JSON.parse(readFileSync(resolve(__dirname,'../../../../../../spec/financial-presentation-vectors.json'),'utf8')) as Record<string,FlarePluginViewModel>;
const mounted:ReturnType<typeof mount>[]=[];afterEach(()=>{mounted.splice(0).forEach(w=>w.unmount());});
function mountView(view:FlarePluginViewModel,error?:string){const root=mount(defineComponent({setup(){useFlareI18nProvider('zh-CN');return()=>h(FlarePluginView,{view,error});}}));mounted.push(root);return root.getComponent(FlarePluginView);}
describe('resolved payment Kit composition',()=>{
 it('uses the existing red packet card and routes only its declared action',async()=>{
  const w=mountView(fixtures.card);
  const card=w.getComponent(FlareRedPacketCard);expect(card.props('state')).toBe('refunded');
  await card.trigger('click');expect(w.emitted('action')?.[0]).toEqual(['open',{}]);
 });
 it('keeps read-only copies inert',async()=>{
  const view=structuredClone(fixtures.card);view.unavailableReason='unbound_copy';view.actions=[];view.presentation!.actions={};
  const w=mountView(view);const card=w.getComponent(FlareRedPacketCard);
  expect(card.props('disabled')).toBe(true);await card.trigger('click');expect(w.emitted('action')).toBeUndefined();
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
 it('opens the composer directly and emits only user editable values',async()=>{
  const w=mountView(fixtures.composer);
  expect(w.findComponent(FlarePluginForm).exists()).toBe(false);
  const composer=w.getComponent(FlareRedPacketComposer);
  composer.vm.$emit('update:amount','0.23');composer.vm.$emit('update:count',2);await nextTick();
  expect(composer.props('total')).toBe('CNY 0.46');composer.vm.$emit('submit');await nextTick();
  const [id,payload]=w.emitted('action')![0] as [string,{formValues:Record<string,unknown>}];
  expect(id).toBe('prepare');expect(payload.formValues).toEqual({kind:'normal',decimalAmount:'0.23',shareCount:2,greeting:expect.any(String),designatedUserId:''});
 });
});
