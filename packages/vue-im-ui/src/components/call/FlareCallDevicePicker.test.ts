// @vitest-environment happy-dom
import {mount} from '@vue/test-utils';
import {describe, expect, it} from 'vitest';
import {translateFlare} from '../../shared/i18n/messages';
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
  it('names a group with nothing selected, and only that group', () => {
    const view = mount(Picker, {props:{groups:[{...group,selectedId:'removed'},{...group,kind:'speaker' as const}],permission:'available',permissionText:'',placeholder:'Pick one'}});
    expect(view.findAll('.flare-call-devices__placeholder').map(line=>line.text())).toEqual(['Pick one']);
    view.unmount();
  });
  it('takes the empty selection from the strings table by default', () => {
    const view = mount(Picker, {props:{groups:[{...group,selectedId:undefined}],permission:'available',permissionText:''}});
    expect(view.find('.flare-call-devices__placeholder').text()).toBe(translateFlare('callDevicePicker.placeholder'));
    view.unmount();
  });
});
