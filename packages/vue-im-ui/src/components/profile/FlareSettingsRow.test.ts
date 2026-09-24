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
  it('marks the row the other pane is showing, separately from disabled and read-only', () => {
    // 设置列表被当成导航列用时（左边四个入口、右边加载对应名单）必须标出当前那条，
    // 否则读的人看不出左右的对应关系。
    const plain = mount(Row, { props: { item: { key: 'friends', label: '好友', kind: 'navigation' as const } } });
    expect(plain.classes()).not.toContain('is-current');
    expect(plain.attributes('aria-current')).toBeUndefined();
    const current = mount(Row, { props: { item: { key: 'friends', label: '好友', kind: 'navigation' as const, current: true } } });
    expect(current.classes()).toContain('is-current');
    expect(current.attributes('aria-current')).toBe('true');
    plain.unmount();
    current.unmount();
  });
  it('renders an in-place action as a button without a chevron, keeping detail, danger and icon composition', async () => {
    const row = mount(Row, { props: { item: { key: 'clear', label: '清空记录', kind: 'action', danger: true, detail: '不可撤销' } }, slots: { icon: '<svg aria-hidden="true"></svg>' } });
    expect(row.element.tagName).toBe('BUTTON');
    expect(row.text()).toContain('不可撤销');
    expect(row.classes()).toContain('is-danger');
    expect(row.find('.flare-settings__chev').exists()).toBe(false);
    await row.trigger('click'); expect(row.emitted('select')).toHaveLength(1);
    row.unmount();
  });
  it('renders a value as read-only information, not a control', async () => {
    const row = mount(Row, { props: { item: { key: 'version', label: '版本', kind: 'value', detail: '2.0.0' } } });
    expect(row.element.tagName).toBe('DIV');
    expect(row.attributes('role')).toBeUndefined();
    expect(row.attributes('tabindex')).toBeUndefined();
    expect(row.find('button').exists()).toBe(false);
    expect(row.find('.flare-settings__chev').exists()).toBe(false);
    expect(row.text()).toContain('版本');
    expect(row.text()).toContain('2.0.0');
    await row.trigger('click');
    expect(row.emitted('select')).toBeUndefined();
    row.unmount();
  });
  it('gives rows that open something a chevron, including rows without a kind', () => {
    const nav = mount(Row, { props: { item: { key: 'qr', label: '我的二维码', kind: 'navigation' } } });
    const bare = mount(Row, { props: { item: { key: 'storage', label: '存储空间' } } });
    expect(nav.find('.flare-settings__chev').exists()).toBe(true);
    expect(bare.find('.flare-settings__chev').exists()).toBe(true);
    nav.unmount(); bare.unmount();
  });
  it('puts a long value on its own lines under the label instead of squeezing the label', () => {
    const short = mount(Row, { props: { item: { key: 'name', label: '群名称', kind: 'value', detail: '2.0 发版协调' } } });
    expect(short.classes()).not.toContain('is-stacked');
    const long = mount(Row, { props: { item: { key: 'announcement', label: '群公告', kind: 'value', detail: '发版当天所有问题统一在本群同步，线上告警请直接 @徐知远。' } } });
    expect(long.classes()).toContain('is-stacked');
    expect(long.get('.flare-settings__label').text()).toBe('群公告');
    const toggle = mount(Row, { props: { item: { key: 'mute', label: '消息免打扰', kind: 'toggle', value: true, detail: '这是一段很长很长很长很长的说明文字' } } });
    expect(toggle.classes()).not.toContain('is-stacked');
    short.unmount(); long.unmount(); toggle.unmount();
  });
});
