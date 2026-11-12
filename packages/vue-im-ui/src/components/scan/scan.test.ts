// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { defineComponent, h } from "vue";
import { describe, expect, it } from "vitest";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import FlareScanResultSheet from "./FlareScanResultSheet.vue";
import FlareScanViewfinder from "./FlareScanViewfinder.vue";
import FlareQRCard from "../profile/FlareQRCard.vue";
function wrap(component: unknown, props: Record<string, unknown>) {
  return mount(defineComponent({ setup() { useFlareI18nProvider('en-US'); return () => h(component as Parameters<typeof h>[0], props); } }), { global: { stubs: { FlareBottomSheet: { template: '<section><slot/></section>' } } } });
}
describe('scan presentation', () => {
  it('disables actions whose input kind is unknown', async () => {
    const view = wrap(FlareScanResultSheet, { phase: 'ready', header: { title: 'Group' }, actions: [{ id: 'apply', label: 'Apply', inputs: [{ id: 'secret', kind: 'password', label: 'Password', maxLen: 32 }] }] });
    expect(view.find('input').exists()).toBe(false); expect(view.get('button').attributes('disabled')).toBeDefined();
    await view.get('button').trigger('click'); expect(view.findComponent(FlareScanResultSheet).emitted('action')).toBeUndefined(); view.unmount();
  });
  it('sends only the selected action inputs', async () => {
    const view = wrap(FlareScanResultSheet, { phase: 'ready', header: { title: 'User' }, actions: [{ id: 'first', label: 'First', inputs: [{ id: 'reason', kind: 'text', label: 'First reason', maxLen: 10 }] }, { id: 'second', label: 'Second', inputs: [{ id: 'message', kind: 'text', label: 'Second message', maxLen: 10 }] }] });
    const inputs = view.findAll('input'); await inputs[0]!.setValue('private'); await inputs[1]!.setValue('hello'); await view.findAll('button')[1]!.trigger('click');
    expect(view.findComponent(FlareScanResultSheet).emitted('action')).toEqual([['second', { message: 'hello' }]]); view.unmount();
  });
  it('keeps image intake available after camera denial and hides unsupported torch', () => {
    const view = wrap(FlareScanViewfinder, { state: 'denied', capabilities: { live: false, album: true, paste: false, torch: false, myCode: false } });
    expect(view.text()).toContain('Choose image'); expect(view.text()).not.toContain('Turn torch'); view.unmount();
  });
  it('never shows the stale QR matrix after expiry or while rotating', () => {
    for (const props of [{ phase: 'ready', refreshInMs: 0 }, { phase: 'refreshing' }]) { const view = wrap(FlareQRCard, { name: 'My code', qrPayload: 'https://scan.test/u/token', ...props }); expect(view.find('svg').exists()).toBe(false); view.unmount(); }
  });
});
