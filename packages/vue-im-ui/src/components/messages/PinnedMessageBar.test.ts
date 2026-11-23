// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { defineComponent, h, nextTick, ref } from "vue";
import { describe, expect, it } from "vitest";
import FlareUiProvider from "../../design-system/provider/FlareUiProvider.vue";
import { resolveMessageId } from "../../shared/contracts/messageRow";
import PinnedMessageBar from "./PinnedMessageBar.vue";
import { useFlarePlatformProvider } from '../../shared/platform/useFlarePlatform';
import type { FlareAdaptiveContext } from '../../composables/useAdaptiveMode';

describe("PinnedMessageBar", () => {
  it.each([false, true])('uses the shell form factor (phone=%s) and preserves the open list across resizing', async (phone) => {
    const isH5 = ref(phone);
    const items = [1, 2].map(i => ({ serverId: `s${i}`, clientMsgId: `c${i}`, senderDisplayName: 'Ivy', content: { contentType: 'text', data: { text: `Pin ${i}` } } }));
    const Scope = defineComponent({ setup() {
      useFlarePlatformProvider({ adaptive: { isH5 } as unknown as FlareAdaptiveContext });
      return () => h(PinnedMessageBar, { items });
    } });
    const host = mount(FlareUiProvider, { props: { locale: 'en-US' }, slots: { default: () => h(Scope) }, attachTo: document.body });
    try {
      const bar = host.findComponent(PinnedMessageBar);
      await bar.get('.pinned-panel__all').trigger('click');
      const list = document.body.querySelector('.pinned-panel__list');
      expect(document.body.querySelectorAll('[role="dialog"]')).toHaveLength(1);
      expect(document.body.querySelector('[role="dialog"]')?.getAttribute('data-flare-presentation')).toBe(phone ? 'sheet' : 'drawer');
      isH5.value = !phone;
      await nextTick();
      expect(document.body.querySelector('.pinned-panel__list')).toBe(list);
      document.dispatchEvent(new KeyboardEvent('keydown', { key: 'Escape' }));
      await nextTick();
      expect(bar.get('.pinned-panel__all').attributes('aria-expanded')).toBe('false');
      await bar.get('.pinned-panel__all').trigger('click');
      expect(document.body.querySelector('[role="dialog"]')?.getAttribute('data-flare-presentation')).toBe(phone ? 'drawer' : 'sheet');
      document.body.querySelector<HTMLButtonElement>('.pinned-panel__item')!.click();
      await nextTick();
      expect(bar.emitted('focus')?.[0]).toEqual(['s2']);
      expect(bar.get('.pinned-panel__all').attributes('aria-expanded')).toBe('false');
    } finally { host.unmount(); }
  });
  it('locates the displayed pin directly, with a separate newest-first list', async () => {
    const items = [1, 2].map(i => ({ serverId: `s${i}`, clientMsgId: `c${i}`, senderDisplayName: 'Ivy', content: { contentType: 'text', data: { text: `Pin ${i}` } } }));
    const host = mount(FlareUiProvider, { props: { themeMode: 'light', locale: 'en-US' }, slots: { default: () => h(PinnedMessageBar, { items }) }, attachTo: document.body });
    const bar = host.findComponent(PinnedMessageBar);
    expect(bar.get('.pinned-panel__summary').text()).toContain('Pin 2');
    expect(document.body.querySelectorAll('.pinned-panel__item')).toHaveLength(0);
    await bar.get('.pinned-panel__summary').trigger('click');
    expect(bar.emitted('focus')?.[0]).toEqual(['s2']);
    expect(document.body.querySelectorAll('.pinned-panel__item')).toHaveLength(0);
    await bar.get('.pinned-panel__all').trigger('click');
    const buttons = document.body.querySelectorAll<HTMLButtonElement>('.pinned-panel__item');
    expect(buttons).toHaveLength(2);
    buttons[0].click();
    await host.vm.$nextTick();
    expect(buttons[0].textContent).toContain('Pin 2');
    expect(bar.emitted('focus')?.[1]).toEqual(['s2']);
    expect(bar.get('.pinned-panel__all').attributes('aria-expanded')).toBe('false');
    host.unmount();
  });
  it("focuses a pinned message by the id MessageList.scrollToMessage resolves", async () => {
    const item = { serverId: "server-7", clientMsgId: "client-7", senderDisplayName: "Ivy", content: { contentType: "text", data: { text: "Release notes" } } };
    const host = mount(FlareUiProvider, {
      props: { themeMode: "light", locale: "en-US" },
      slots: { default: () => h(PinnedMessageBar, { items: [item] }) },
    });
    const bar = host.findComponent(PinnedMessageBar);
    await bar.find("button").trigger("click");
    expect(bar.emitted("focus")?.[0]).toEqual([resolveMessageId(item)]);
    expect(bar.emitted("focus")?.[0]).toEqual(["server-7"]);
    host.unmount();
  });
});
