// @vitest-environment happy-dom
import { afterEach, expect, it } from 'vitest';
import { mount } from '@vue/test-utils';
import { defineComponent, h } from 'vue';
import { useFlareI18nProvider } from '../../shared/i18n/useFlareI18n';
import FlareScreen from '../layout/FlareScreen.vue';
import FlareStorageUsage from './FlareStorageUsage.vue';

let host: ReturnType<typeof mount> | undefined;
afterEach(() => host?.unmount());

it('uses the screen heading once and keeps clear intents on their stable category ID', async () => {
  const cleared: string[] = [];
  host = mount(defineComponent({ setup() {
    useFlareI18nProvider('zh-CN');
    return () => h(FlareScreen, { title: '存储空间', layout: 'detail' }, () => h(FlareStorageUsage, {
      categories: [{ id: 'cache', label: '缓存', bytes: 1024, clearable: true }], onClear: (id: string) => cleared.push(id),
    }));
  } }));
  expect(host.findAll('h1')).toHaveLength(1);
  expect(host.find('.flare-storage__title').exists()).toBe(false);
  expect(host.get('.flare-storage').attributes('aria-label')).toBe('存储空间');
  await host.get('.flare-storage__clear').trigger('click');
  expect(cleared).toEqual(['cache']);
});

it('retains failed rows, delegates reload and dismissal, and hides an in-flight clear action', async () => {
  const intents: unknown[] = [];
  host = mount(defineComponent({ setup() {
    useFlareI18nProvider('zh-CN');
    return () => h(FlareStorageUsage, {
      categories: [{ id: 'cache', label: '缓存', bytes: 1024, clearable: true, busy: true, error: '离线' }],
      error: '读取失败', onReload: () => intents.push('reload'), onDismissError: (id: string | null) => intents.push(id),
    });
  } }));
  expect(host.find('.flare-storage__clear').exists()).toBe(false);
  expect(host.get('.flare-storage__row--failed').text()).toContain('缓存');
  await host.get('.flare-storage__error--global .flare-storage__btn').trigger('click');
  await host.get('.flare-storage__error--global .flare-storage__btn--icon').trigger('click');
  await host.get('.flare-storage__row--failed .flare-storage__btn--icon').trigger('click');
  expect(intents).toEqual(['reload', null, 'cache']);
});
