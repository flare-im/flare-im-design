// @vitest-environment happy-dom
import { mount, flushPromises } from '@vue/test-utils';
import { defineComponent, h, onMounted } from 'vue';
import { expect, it } from 'vitest';
import FlareCallSurface from './FlareCallSurface.vue';
import FlareModal from '../general/FlareModal.vue';
import { useFlareI18nProvider } from '../../shared/i18n/useFlareI18n';

it('resizes a focused call without remounting media', async () => {
  let mounts = 0;
  const stage = defineComponent({ setup() { onMounted(() => mounts++); return () => h('div', 'live media'); } });
  const host = mount(defineComponent({ props: {expanded: Boolean}, setup(props) {
    useFlareI18nProvider('en-US');
    return () => h(FlareCallSurface, {mode: 'video', expanded: props.expanded, label: 'Call'}, () => h(stage));
  }}), {attachTo: document.body});
  await flushPromises();
  expect(document.querySelector('[role="dialog"]')?.getAttribute('aria-modal')).toBe('true');
  const initialMounts = mounts;
  const initial = host.getComponent(FlareModal).props('width');
  await host.setProps({expanded: true});
  expect(host.getComponent(FlareModal).props('width')).not.toBe(initial);
  expect(mounts).toBe(initialMounts);
  host.unmount();
});
