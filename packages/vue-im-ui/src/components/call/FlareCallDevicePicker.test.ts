// @vitest-environment happy-dom
import {mount} from '@vue/test-utils';
import {describe, expect, it} from 'vitest';
import Picker from './FlareCallDevicePicker.vue';
const group = {kind: 'microphone' as const, label:'Microphone', selectedId:'a', devices:[{id:'a',label:'Built-in'},{id:'b',label:'USB'},{id:'b',label:'Duplicate'}]};
describe('direct call device choices', () => {
  it('deduplicates inventory and selects in one click', async () => {
    const view = mount(Picker, {props:{groups:[group],permission:'available',permissionText:''}});
    expect(view.findAll('button')).toHaveLength(2);
    expect(view.findAll('button')[0]!.attributes('aria-pressed')).toBe('true');
    await view.findAll('button')[1]!.trigger('click');
    expect(view.emitted('select')).toEqual([[{kind:'microphone',deviceId:'b'}]]);
    view.unmount();
  });
  it('blocks switching while a group is busy', () => {
    const view = mount(Picker, {props:{groups:[{...group,busy:true}],permission:'available',permissionText:''}});
    expect(view.findAll('button').every(b=>b.attributes('disabled')!==undefined)).toBe(true);
    expect(view.emitted('select')).toBeUndefined();view.unmount();
  });
});
