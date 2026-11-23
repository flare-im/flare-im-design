// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";
import RadioGroup from "./FlareRadioGroup.vue";
const options = [{ value: 'full', label: 'Name and message' }, { value: 'sender', label: 'Name only', disabled: true }, { value: 'hidden', label: 'Hidden' }];
describe('list choices', () => {
  it('keeps controlled selection and ignores disabled choices', async () => {
    const wrapper = mount(RadioGroup, { props: { options, optionLayout: 'list', modelValue: 'full' } });
    expect(wrapper.get('button').attributes('aria-checked')).toBe('true');
    await wrapper.findAll('button')[1].trigger('click');
    expect(wrapper.emitted('change')).toBeUndefined();
    await wrapper.findAll('button')[2].trigger('click');
    expect(wrapper.emitted('update:modelValue')).toEqual([['hidden']]);
    expect(wrapper.emitted('change')).toEqual([['hidden']]);
    wrapper.unmount();
  });
  it('moves focus and selection with arrows, skips disabled items and supports Home / End', async () => {
    const wrapper = mount(RadioGroup, { attachTo: document.body, props: { options, optionLayout: 'list', modelValue: 'full' } });
    const buttons = wrapper.findAll('button');
    await buttons[0].trigger('keydown', { key: 'ArrowDown' });
    expect(document.activeElement).toBe(buttons[2].element);
    expect(wrapper.emitted('change')?.at(-1)).toEqual(['hidden']);
    await buttons[2].trigger('keydown', { key: 'ArrowDown' });
    expect(document.activeElement).toBe(buttons[0].element);
    await buttons[0].trigger('keydown', { key: 'End' });
    expect(document.activeElement).toBe(buttons[2].element);
    await buttons[2].trigger('keydown', { key: 'Home' });
    expect(document.activeElement).toBe(buttons[0].element);
    wrapper.unmount();
  });
});

describe.each(['compact', 'list'] as const)('%s radio keyboard contract', optionLayout => {
  it('has one tab stop and moves selection past disabled choices in both directions', async () => {
    const wrapper = mount(RadioGroup, { attachTo: document.body, props: {
      options, optionLayout, modelValue: 'full',
      'onUpdate:modelValue': (value: string) => wrapper.setProps({ modelValue: value }),
    } });
    const buttons = wrapper.findAll('button');
    expect(buttons.map(button => button.attributes('tabindex'))).toEqual(['0', '-1', '-1']);
    await buttons[0].trigger('keydown', { key: 'ArrowRight' });
    expect(document.activeElement).toBe(buttons[2].element);
    expect(buttons.map(button => button.attributes('tabindex'))).toEqual(['-1', '-1', '0']);
    await buttons[2].trigger('keydown', { key: 'ArrowLeft' });
    expect(document.activeElement).toBe(buttons[0].element);
    await buttons[0].trigger('keydown', { key: 'End' });
    expect(document.activeElement).toBe(buttons[2].element);
    await buttons[2].trigger('keydown', { key: 'Home' });
    expect(document.activeElement).toBe(buttons[0].element);
    const changes = wrapper.emitted('change')?.length;
    for (const event of [{ key: 'Tab' }, { key: 'ArrowDown', ctrlKey: true }, { key: 'ArrowDown', isComposing: true }]) {
      await buttons[0].trigger('keydown', event);
    }
    expect(wrapper.emitted('change')).toHaveLength(changes!);
    wrapper.unmount();
  });
  it('keeps an entry point when the current value is missing or disabled', async () => {
    const wrapper = mount(RadioGroup, { props: { options, optionLayout, modelValue: 'sender' } });
    expect(wrapper.findAll('button').map(button => button.attributes('tabindex'))).toEqual(['0', '-1', '-1']);
    await wrapper.setProps({ modelValue: 'missing' });
    expect(wrapper.findAll('button').map(button => button.attributes('tabindex'))).toEqual(['0', '-1', '-1']);
    expect(wrapper.emitted('update:modelValue')).toBeUndefined();
    wrapper.unmount();
  });
});
describe('card choices (R6: a select with at most 4 choices)', () => {
  it('draws one card per option, a check only on the selected one, and no radio dot', async () => {
    const wrapper = mount(RadioGroup, { props: { options, optionLayout: 'cards', vertical: true, modelValue: 'full' } });
    expect(wrapper.classes()).toContain('is-cards');
    expect(wrapper.classes()).not.toContain('is-vertical');
    expect(wrapper.findAll('[role=radio]')).toHaveLength(options.length);
    expect(wrapper.find('.flare-radio__dot').exists()).toBe(false);
    expect(wrapper.findAll('.flare-radio__check')).toHaveLength(1);
    expect(wrapper.findAll('button')[0].find('.flare-radio__check').exists()).toBe(true);
    await wrapper.findAll('button')[2].trigger('click');
    expect(wrapper.emitted('update:modelValue')).toEqual([['hidden']]);
    wrapper.unmount();
  });
});
