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
    expect(view.get('[role="radiogroup"]').attributes('aria-label')).toBe('Microphone');
    expect(view.findAll('[role="radio"]').map(b => b.attributes('aria-checked'))).toEqual(['true', 'false']);
    // The chosen device carries the check icon, not a text glyph.
    expect(view.findAll('button')[0]!.find('.flare-icon').exists()).toBe(true);
    expect(view.findAll('button')[1]!.find('.flare-icon').exists()).toBe(false);
    expect(view.text()).not.toContain('✓');
    await view.findAll('button')[1]!.trigger('click');
    expect(view.emitted('select')).toEqual([[{kind:'microphone',deviceId:'b'}]]);
    view.unmount();
  });
  it('blocks switching while a group is busy', () => {
    const view = mount(Picker, {props:{groups:[{...group,busy:true}],permission:'available',permissionText:''}});
    expect(view.findAll('button').every(b=>b.attributes('disabled')!==undefined)).toBe(true);
    // A small spinner follows the switching group's title, and only that group's.
    expect(view.get('.flare-call-devices__label').find('[data-device-switching]').exists()).toBe(true);
    expect(view.get('[role="radiogroup"]').attributes('aria-busy')).toBe('true');
    expect(view.emitted('select')).toBeUndefined();view.unmount();
    const calm = mount(Picker, {props:{groups:[group],permission:'available',permissionText:''}});
    expect(calm.find('[data-device-switching]').exists()).toBe(false);
    calm.unmount();
  });
  it('names a group with nothing selected, and only that group', () => {
    const view = mount(Picker, {props:{groups:[{...group,selectedId:'removed'},{...group,kind:'speaker' as const}],permission:'available',permissionText:'',placeholder:'Pick one'}});
    expect(view.findAll('.flare-call-devices__placeholder').map(line=>line.text())).toEqual(['Pick one']);
    view.unmount();
  });
  it('moves within a group with the arrow keys, wrapping', async () => {
    const view = mount(Picker, {props:{groups:[group],permission:'available',permissionText:''}, attachTo: document.body});
    const [first, second] = view.findAll('[role="radio"]');
    (first!.element as HTMLButtonElement).focus();
    await view.get('[role="radiogroup"]').trigger('keydown', {key: 'ArrowDown'});
    expect(document.activeElement).toBe(second!.element);
    await view.get('[role="radiogroup"]').trigger('keydown', {key: 'ArrowDown'});
    expect(document.activeElement).toBe(first!.element);
    view.unmount();
  });
  it('takes the empty selection from the strings table by default', () => {
    const view = mount(Picker, {props:{groups:[{...group,selectedId:undefined}],permission:'available',permissionText:''}});
    expect(view.find('.flare-call-devices__placeholder').text()).toBe(translateFlare('callDevicePicker.placeholder'));
    view.unmount();
  });
});
