// @vitest-environment happy-dom
import {mount} from '@vue/test-utils';import {defineComponent,h} from 'vue';import {it,expect} from 'vitest';
import Picker from './FlareContactPicker.vue';import {useFlareI18nProvider} from '../../shared/i18n/useFlareI18n';
it('limits selection without trapping the chosen rows',async()=>{
 const view=mount(defineComponent({setup(){useFlareI18nProvider('zh-CN');return()=>h(Picker,{multiple:true,maxSelected:2,groups:[{id:'groupMembers',entries:['a','b','c'].map(userId=>({userId,name:userId}))}]});}}));
 const row=(id:string)=>view.get(`[data-user-id="${id}"]`);
 await row('a').trigger('click');await row('b').trigger('click');expect(row('c').attributes('disabled')).toBeDefined();expect(row('a').attributes('disabled')).toBeUndefined();
 await row('a').trigger('click');expect(row('c').attributes('disabled')).toBeUndefined();await row('c').trigger('click');expect(view.text()).toContain('2/2');view.unmount();
});
