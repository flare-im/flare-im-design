// @vitest-environment happy-dom
import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {mount} from '@vue/test-utils';
import {describe,it,expect,afterEach} from 'vitest';
import {defineComponent,h} from 'vue';
import {useFlareI18nProvider} from '../../../shared/i18n/useFlareI18n';
import FlarePluginView from '../FlarePluginView.vue';
import FlareRedPacketCard from '../FlareRedPacketCard.vue';
import FlareRedPacketReview from '../FlareRedPacketReview.vue';
import FlareResolvedPresentation from './FlareResolvedPresentation.vue';
import type {FlarePluginViewModel} from '../../../shared/contracts/plugin-ui';
import {provideFlareMessageQuote} from '../../../shared/message-renderers';
const fixtures=JSON.parse(readFileSync(resolve(__dirname,'../../../../../../spec/financial-presentation-vectors.json'),'utf8')) as Record<string,FlarePluginViewModel>;
const mounted:ReturnType<typeof mount>[]=[];afterEach(()=>{mounted.splice(0).forEach(w=>w.unmount());});
function mountView(view:FlarePluginViewModel,error?:string,extra:Record<string,unknown>={}){const root=mount(defineComponent({setup(){useFlareI18nProvider('zh-CN');return()=>h(FlarePluginView,{view,error,...extra});}}));mounted.push(root);return root.getComponent(FlarePluginView);}
describe('resolved red packet Kit composition',()=>{
 it('draws the retired payment renderer as its fields and actions, never a pay sheet',()=>{
  const w=mountView(fixtures.payment);
  expect(w.findComponent(FlareRedPacketCard).exists()).toBe(false);
  expect(w.find('[data-payment-confirmation]').exists()).toBe(false);
  expect(w.findAll('button').some(b=>b.text()==='确认授权')).toBe(true);
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
 it.each(['redPacket.composer','redPacket.detail','account','flare.qr','redPacket.pay','payment.confirm'])('draws the retired %s renderer as the plain document',(renderer)=>{
  const view=structuredClone(fixtures.card);
  view.presentation={renderer,actions:{},props:{}};
  view.blocks=[{kind:'text',text:'Declarative body'}];
  const w=mountView(view);
  expect(w.findComponent(FlareRedPacketCard).exists()).toBe(false);
  expect(w.get('[data-block="text"]').text()).toBe('Declarative body');
 });
});
describe('redPacket.review renderer',()=>{
 const review=(actions:FlarePluginViewModel['actions'],bound:Record<string,string>):FlarePluginViewModel=>({available:true,title:'',fields:[],actions,
  presentation:{renderer:'redPacket.review',props:{amount:'¥26.64',kindLabel:'拼手气红包 · 3 个',blessing:'恭喜发财',brandName:1},actions:bound}});
 function mountReview(view:FlarePluginViewModel,busy=false){const root=mount(defineComponent({setup(){useFlareI18nProvider('zh-CN');return()=>h(FlareResolvedPresentation,{view,busy});}}));mounted.push(root);return root.getComponent(FlareResolvedPresentation);}
 it('draws the review from its props and sends only the bound submit action',async()=>{
  const w=mountReview(review([{id:'commit',label:'发红包',style:'primary'}],{submit:'commit'}));
  expect(w.findComponent(FlareRedPacketCard).exists()).toBe(false);
  const r=w.getComponent(FlareRedPacketReview);
  expect(r.props()).toMatchObject({amount:'¥26.64',kindLabel:'拼手气红包 · 3 个',blessing:'恭喜发财',submitLabel:'发红包'});
  await r.get('[data-review-submit]').trigger('click');
  expect(w.emitted('request')).toEqual([['commit']]);
 });
 it('reads props defensively and asks nothing without a bound action or while busy',async()=>{
  const view=review([],{});view.presentation!.props={amount:3,blessing:null};
  const w=mountReview(view);
  expect(w.get('[data-review-amount]').text()).toBe('');
  await w.get('[data-review-submit]').trigger('click');
  expect(w.emitted('request')).toBeUndefined();
  const busy=mountReview(review([{id:'commit',label:'发红包'}],{submit:'commit'}),true);
  await busy.get('[data-review-submit]').trigger('click');
  expect(busy.emitted('request')).toBeUndefined();
 });
});
