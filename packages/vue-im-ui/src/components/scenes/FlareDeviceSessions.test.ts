// @vitest-environment happy-dom
import { mount } from '@vue/test-utils';
import { defineComponent, h } from 'vue';
import { describe, expect, it } from 'vitest';
import FlareUiProvider from '../../design-system/provider/FlareUiProvider.vue';
import FlareDeviceSessions from './FlareDeviceSessions.vue';
import type { DeviceSessionEntry } from '../../shared/contracts/scenes';

const device = (id: string, current = false): DeviceSessionEntry => ({
  id, current, title: `Browser ${id}`, detail: `Last active ${id}`,
  actions: [{ id: 'revoke', label: 'Sign out', destructive: true }],
});
function setup(items: DeviceSessionEntry[], extra: Record<string, unknown> = {}) {
  return mount(defineComponent({ setup: () => () => h(FlareUiProvider, { locale: 'en-US' }, () =>
    h(FlareDeviceSessions, { items, ...extra })) }));
}

describe('device management presentation', () => {
  it('puts this device first without changing source order or allowing its actions', () => {
    const items = [device('other'), device('current', true), device('older')];
    const wrapper = setup(items), rows = wrapper.findAll('article');
    expect(rows.map(row => row.find('strong').text())).toEqual(['Browser current', 'Browser other', 'Browser older']);
    expect(items.map(row => row.id)).toEqual(['other', 'current', 'older']);
    expect(rows[0].text()).toContain('This device');
    expect(rows[0].find('button').exists()).toBe(false);
    expect(wrapper.text()).toContain('Sign out any device you do not recognize.');
  });

  it('keeps destructive row actions quiet, available and scoped to the right device', async () => {
    const wrapper = setup([device('one'), device('two')]);
    const action = wrapper.findAll('article')[1].get('button');
    expect(action.classes()).toContain('is-text');
    expect(action.classes()).toContain('flare-button--danger');
    await action.trigger('click');
    expect(wrapper.findComponent(FlareDeviceSessions).emitted('action')).toEqual([[{ id: 'two', action: 'revoke' }]]);
    const ids = (action.attributes('aria-describedby') ?? '').split(' ');
    expect(ids.map(id => wrapper.get(`[id="${id}"]`).text())).toEqual(['Browser two', 'Last active two']);
  });

  it('retains disabled, loading and failure protections', () => {
    const disabled = device('disabled'); disabled.actions[0].disabled = true;
    expect(setup([disabled]).get('article button').attributes('disabled')).toBeDefined();
    expect(setup([], { loading: true }).find('[role="status"]').exists()).toBe(true);
    expect(setup([], { error: 'Cannot load devices' }).get('[role="alert"]').text()).toContain('Cannot load devices');
  });
});
