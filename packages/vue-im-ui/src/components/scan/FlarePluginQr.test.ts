// @vitest-environment happy-dom
import { mount, flushPromises } from "@vue/test-utils";
import { defineComponent, h, nextTick, ref } from "vue";
import { afterEach, describe, expect, it, vi } from "vitest";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import FlarePluginQr from "./FlarePluginQr.vue";
afterEach(() => vi.useRealTimers());
function host(props: Record<string, unknown>) { return mount(defineComponent({ setup() { useFlareI18nProvider("en-US"); return () => h(FlarePluginQr, props); } })); }
describe("plugin code lifetime", () => {
  it("does not guess a route when the trusted encoder is unavailable", async () => { const view = host({ token: "token", ttlMs: 1000 }); await flushPromises(); expect(view.find('svg').exists()).toBe(false); expect(view.text()).toContain('QR code unavailable'); view.unmount(); });
  it("obscures an expired code even when a refresh keeps the old view", async () => { vi.useFakeTimers({ toFake: ['setTimeout', 'clearTimeout', 'performance'] }); const view = host({ token: "token", ttlMs: 1000, encodeQr: async () => 'https://scan.test/p/demo/token' }); await flushPromises(); expect(view.find('svg').exists()).toBe(true); await vi.advanceTimersByTimeAsync(1000); expect(view.find('svg').exists()).toBe(false); expect(view.text()).toContain('expired'); view.unmount(); });
  it("callback identity changes do not renew the lifetime", async () => { vi.useFakeTimers({ toFake: ['setTimeout', 'clearTimeout', 'performance'] }); const encoder = ref(async () => 'https://scan.test/p/demo/token'); const view = mount(defineComponent({ setup() { useFlareI18nProvider('en-US'); return () => h(FlarePluginQr, { token: 'token', ttlMs: 1000, encodeQr: encoder.value }); } })); await flushPromises(); await vi.advanceTimersByTimeAsync(900); encoder.value = async () => 'https://scan.test/p/demo/token'; await nextTick(); await vi.advanceTimersByTimeAsync(100); expect(view.find('svg').exists()).toBe(false); view.unmount(); });
});
