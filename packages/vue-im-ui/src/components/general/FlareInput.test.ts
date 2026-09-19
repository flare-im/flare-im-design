// @vitest-environment happy-dom
import { describe, expect, it } from 'vitest';
import { mount } from '@vue/test-utils';
import Input from './FlareInput.vue';

describe('shared input interactions', () => {
  it('does not submit while confirming an IME composition', async () => {
    const wrapper = mount(Input, { props: { modelValue: '你好' } });
    await wrapper.get('input').trigger('keydown', { key: 'Enter', isComposing: true });
    expect(wrapper.emitted('submit')).toBeUndefined();
    await wrapper.get('input').trigger('keydown', { key: 'Enter', isComposing: false });
    expect(wrapper.emitted('submit')).toHaveLength(1);
    await wrapper.setProps({ disabled: true });
    await wrapper.get('input').trigger('keydown', { key: 'Enter' });
    expect(wrapper.emitted('submit')).toHaveLength(1);
    wrapper.unmount();
  });
  it('focuses the actual field and exposes clearing as a keyboard button', async () => {
    const wrapper = mount(Input, { attachTo: document.body, props: { modelValue: 'draft', autofocus: true, clearable: true, maxLength: 8 } });
    expect(document.activeElement).toBe(wrapper.get('input').element);
    expect(wrapper.get('input').attributes('maxlength')).toBe('8');
    const clear = wrapper.get('button');
    expect(clear.attributes('aria-label')).toBeTruthy();
    await clear.trigger('click');
    expect(wrapper.emitted('update:modelValue')).toEqual([['']]);
    wrapper.unmount();
  });
});
