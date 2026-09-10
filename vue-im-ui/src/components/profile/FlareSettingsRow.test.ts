// @vitest-environment happy-dom
import { describe, expect, it } from 'vitest';
import { mount } from '@vue/test-utils';
import Row from './FlareSettingsRow.vue';

describe('shared settings row', () => {
  it('reports one toggle from the entire row and respects disabled state', async () => {
    const item = { key: 'mute', label: '消息免打扰', kind: 'toggle' as const, value: false };
    const row = mount(Row, { props: { item } });
    expect(row.attributes('role')).toBe('switch');
    expect(row.attributes('aria-checked')).toBe('false');
    await row.trigger('click');
    expect(row.emitted('toggle')).toEqual([[item, true]]);
    await row.setProps({ item: { ...item, disabled: true } });
    await row.trigger('click');
    expect(row.emitted('toggle')).toHaveLength(1);
    row.unmount();
  });
  it('keeps detail, danger and icon composition in the shared renderer', async () => {
    const row = mount(Row, { props: { item: { key: 'clear', label: '清空记录', kind: 'value', danger: true, detail: '不可撤销' } }, slots: { icon: '<svg aria-hidden="true"></svg>' } });
    expect(row.element.tagName).toBe('BUTTON');
    expect(row.text()).toContain('不可撤销');
    expect(row.classes()).toContain('is-danger');
    expect(row.find('.flare-settings__chev').exists()).toBe(false);
    await row.trigger('click'); expect(row.emitted('select')).toHaveLength(1);
    row.unmount();
  });
});
