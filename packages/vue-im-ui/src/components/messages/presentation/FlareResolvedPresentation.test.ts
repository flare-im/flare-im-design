// @vitest-environment happy-dom
import {readFileSync} from 'node:fs';
import {resolve} from 'node:path';
import {mount} from '@vue/test-utils';
import {describe,it,expect,afterEach} from 'vitest';
import {defineComponent,h} from 'vue';
import {useFlareI18nProvider} from '../../../shared/i18n/useFlareI18n';
import FlarePluginView from '../FlarePluginView.vue';
import FlareRedPacketCard from '../FlareRedPacketCard.vue';
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
