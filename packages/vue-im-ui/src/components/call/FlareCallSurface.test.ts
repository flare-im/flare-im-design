// @vitest-environment happy-dom
import { mount, flushPromises } from '@vue/test-utils';
import { defineComponent, h, onMounted, ref, type Component } from 'vue';
import { expect, it, vi } from 'vitest';
import FlareCallSurface from './FlareCallSurface.vue';
import FlareCallView from './FlareCallView.vue';
import FlareGroupCallView from './FlareGroupCallView.vue';
import FlareModal from '../general/FlareModal.vue';
import { useFlareI18nProvider } from '../../shared/i18n/useFlareI18n';
import { useFlarePlatformProvider } from '../../shared/platform/useFlarePlatform';

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
  expect(initial).toBe('var(--flare-size-component-call-window-video-width)');
  await host.setProps({expanded: true});
  expect(host.getComponent(FlareModal).props('width')).not.toBe(initial);
  expect(mounts).toBe(initialMounts);
  host.unmount();
});

it('sizes a voice window from the audio tokens and never minimizes on Escape', async () => {
  let minimized = 0;
  const host = mount(defineComponent({ setup() {
    useFlareI18nProvider('en-US');
    return () => h(FlareCallSurface, {mode: 'audio', label: 'Call', onMinimize: () => minimized++}, () => h('div', 'stage'));
  }}), {attachTo: document.body});
  await flushPromises();
  const modal = host.getComponent(FlareModal);
  expect(modal.props('width')).toBe('var(--flare-size-component-call-window-audio-width)');
  expect(modal.props('fullscreen')).toBe(false);
  expect(modal.props('dismissible')).toBe(false);
  document.dispatchEvent(new KeyboardEvent('keydown', {key: 'Escape', bubbles: true}));
  await flushPromises();
  expect(minimized).toBe(0);
  host.unmount();
});

it('fills the screen on a phone', async () => {
  const host = mount(defineComponent({ setup() {
    useFlareI18nProvider('en-US');
    useFlarePlatformProvider({capabilities: {bottomSheet: true}});
    return () => h(FlareCallSurface, {mode: 'audio', label: 'Call'}, () => h('div', 'stage'));
  }}), {attachTo: document.body});
  await flushPromises();
  expect(host.getComponent(FlareModal).props('fullscreen')).toBe(true);
  host.unmount();
});

it('moves the PC window by its top 48 and keeps it inside the viewport', async () => {
  const expanded = ref(false);
  const host = mount(defineComponent({ setup() {
    useFlareI18nProvider('en-US');
    return () => h(FlareCallSurface, {mode: 'audio', label: 'Call', expanded: expanded.value}, () => h('div', [h('button', {class: 'key'}, 'Minimize')]));
  }}), {attachTo: document.body});
  await flushPromises();
  const surface = document.querySelector<HTMLElement>('.flare-call-surface')!;
  const dialog = document.querySelector<HTMLElement>('[role="dialog"]')!;
  const rect = (left: number, top: number, right: number, bottom: number) => () =>
    ({left, top, right, bottom, width: right - left, height: bottom - top, x: left, y: top, toJSON: () => ({})}) as DOMRect;
  surface.getBoundingClientRect = rect(300, 100, 700, 660);
  dialog.getBoundingClientRect = rect(300, 100, 700, 660);
  const pointer = (type: string, x: number, y: number) => new PointerEvent(type, {bubbles: true, clientX: x, clientY: y, pointerId: 1, button: 0});
  // Far past the bottom-right corner: it stops at the viewport's edges.
  surface.dispatchEvent(pointer('pointerdown', 400, 120));
  window.dispatchEvent(pointer('pointermove', 5000, 5000));
  expect(dialog.style.translate).toBe(`${window.innerWidth - 700}px ${window.innerHeight - 660}px`);
  window.dispatchEvent(pointer('pointerup', 5000, 5000));
  // Below the top 48 and on a key nothing moves.
  dialog.style.translate = '';
  surface.dispatchEvent(pointer('pointerdown', 400, 300));
  window.dispatchEvent(pointer('pointermove', 450, 350));
  expect(dialog.style.translate).toBe('');
  window.dispatchEvent(pointer('pointerup', 450, 350));
  surface.querySelector('.key')!.dispatchEvent(pointer('pointerdown', 400, 110));
  window.dispatchEvent(pointer('pointermove', 450, 150));
  expect(dialog.style.translate).toBe('');
  window.dispatchEvent(pointer('pointerup', 450, 150));
  // Expanded it does not move at all.
  expanded.value = true;
  await flushPromises();
  surface.dispatchEvent(pointer('pointerdown', 400, 120));
  window.dispatchEvent(pointer('pointermove', 450, 150));
  expect(dialog.style.translate).toBe('');
  window.dispatchEvent(pointer('pointerup', 450, 150));
  host.unmount();
});

it('leaves the expanded state on Escape and casts the xl shadow, without minimizing', async () => {
  const expanded = ref(true);
  const asked: boolean[] = [];
  let minimized = 0;
  const host = mount(defineComponent({ setup() {
    useFlareI18nProvider('en-US');
    return () => h(FlareCallSurface, {mode: 'video', label: 'Call', expanded: expanded.value,
      'onUpdate:expanded': (value: boolean) => { asked.push(value); expanded.value = value; }, onMinimize: () => minimized++}, () => h('div', 'stage'));
  }}), {attachTo: document.body});
  await flushPromises();
  expect(document.querySelector<HTMLElement>('[role="dialog"]')!.style.boxShadow).toBe('var(--flare-shadow-xl)');
  document.dispatchEvent(new KeyboardEvent('keydown', {key: 'Escape', bubbles: true}));
  await flushPromises();
  expect(asked).toEqual([false]);
  // Not expanded any more: Escape does nothing.
  document.dispatchEvent(new KeyboardEvent('keydown', {key: 'Escape', bubbles: true}));
  await flushPromises();
  expect(asked).toEqual([false]);
  expect(minimized).toBe(0);
  host.unmount();
});

it('fills a narrow viewport without a provider', async () => {
  const media = vi.spyOn(window, 'matchMedia').mockImplementation((query: string) =>
    ({matches: query.includes('max-width: 599px'), media: query, addEventListener() {}, removeEventListener() {}}) as unknown as MediaQueryList);
  try {
    const host = mount(defineComponent({ setup() {
      useFlareI18nProvider('en-US');
      return () => h(FlareCallSurface, {mode: 'audio', label: 'Call'}, () => h('div', 'stage'));
    }}), {attachTo: document.body});
    await flushPromises();
    expect(host.getComponent(FlareModal).props('fullscreen')).toBe(true);
    // Full screen draws no shadow of its own.
    expect(document.querySelector<HTMLElement>('[role="dialog"]')!.style.boxShadow).toBe('');
    host.unmount();
  } finally {
    media.mockRestore();
  }
});

it('puts the PC expand key in the call view\'s top row beside minimize, and emits minimize from the window too', async () => {
  for (const view of [FlareCallView, FlareGroupCallView]) {
    const expanded = ref(false);
    const asked: boolean[] = [];
    let minimized = 0;
    const host = mount(defineComponent({ setup() {
      useFlareI18nProvider('en-US');
      return () => h(FlareCallSurface, {mode: 'video', label: 'Call', expanded: expanded.value,
        'onUpdate:expanded': (value: boolean) => { asked.push(value); expanded.value = value; }, onMinimize: () => minimized++},
        () => h(view as Component, {peerName: 'Zhou', participants: [], mode: 'video', state: 'connected'}));
    }}), {attachTo: document.body});
    await flushPromises();
    const row = document.querySelector('[data-call-expand]')!.parentElement!.closest('.flare-call-view__bar, .flare-group-call__bar')!;
    // The window's host listens to minimize, so the view draws the key in the same row.
    const minimize = row.querySelector<HTMLButtonElement>('[aria-label="Minimize"]')!;
    const expand = () => document.querySelector<HTMLButtonElement>('[data-call-expand]')!;
    expect(expand().getAttribute('aria-label')).toBe('Expand');
    expand().click();
    await flushPromises();
    expect(asked).toEqual([true]);
    expect(expand().getAttribute('aria-label')).toBe('Collapse');
    expect(host.getComponent(FlareModal).props('width')).toBe('calc(100vw - var(--flare-size-spacing-xl) * 2)');
    // Escape leaves the expanded state.
    document.dispatchEvent(new KeyboardEvent('keydown', {key: 'Escape', bubbles: true}));
    await flushPromises();
    expect(asked).toEqual([true, false]);
    minimize.click();
    expect(minimized).toBe(1);
    host.unmount();
  }
});

it('expands on its own when the host does not bind expanded, and draws no expand key on a phone', async () => {
  const pc = mount(defineComponent({ setup() {
    useFlareI18nProvider('en-US');
    return () => h(FlareCallSurface, {mode: 'audio', label: 'Call'}, () => h(FlareCallView, {peerName: 'Zhou', mode: 'audio', state: 'connected'}));
  }}), {attachTo: document.body});
  await flushPromises();
  document.querySelector<HTMLButtonElement>('[data-call-expand]')!.click();
  await flushPromises();
  expect(pc.getComponent(FlareModal).props('width')).toBe('calc(100vw - var(--flare-size-spacing-xl) * 2)');
  pc.unmount();
  const phone = mount(defineComponent({ setup() {
    useFlareI18nProvider('en-US');
    useFlarePlatformProvider({capabilities: {bottomSheet: true}});
    return () => h(FlareCallSurface, {mode: 'audio', label: 'Call'}, () => h(FlareCallView, {peerName: 'Zhou', mode: 'audio', state: 'connected'}));
  }}), {attachTo: document.body});
  await flushPromises();
  expect(document.querySelector('[data-call-expand]')).toBeNull();
  phone.unmount();
});
