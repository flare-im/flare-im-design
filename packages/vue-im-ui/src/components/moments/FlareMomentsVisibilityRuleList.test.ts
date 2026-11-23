// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { afterEach, describe, expect, it, vi } from "vitest";
import { defineComponent, h } from "vue";
import List from "./FlareMomentsVisibilityRuleList.vue";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
const wrappers: ReturnType<typeof mount>[] = [];
function setup(props: Record<string, unknown> = {}) {
  const wrapper = mount(defineComponent({ setup() {
    useFlareI18nProvider("en-US");
    return () => h(List, { kind: "hideFrom", members: [], ...props });
  } }));
  wrappers.push(wrapper); return wrapper;
}
afterEach(() => { wrappers.splice(0).forEach(wrapper => wrapper.unmount()); });
const person = { userId: "u1", displayName: "A long contact name" };
describe("moment visibility presentation", () => {
  it("names the two opposite directions and associates each with its explanation", () => {
    const hide = setup(); const mute = setup({ kind: "mute" });
    expect(hide.get('h2').text()).not.toBe(mute.get('h2').text());
    for (const wrapper of [hide, mute]) {
      const section = wrapper.get('section');
      expect(section.attributes('aria-labelledby')).toBe(wrapper.get('h2').attributes('id'));
      expect(section.attributes('aria-describedby')).toBe(wrapper.get('.flare-moments-visibility__hint').attributes('id'));
      expect(wrapper.get('[role="status"]').text()).toBe('No one on this list');
    }
  });
  it("shows loading without a false empty list and disables add", () => {
    const wrapper = setup({ loading: true });
    expect(wrapper.get('section').attributes('aria-busy')).toBe('true');
    expect(wrapper.find('.flare-skeleton').exists()).toBe(true);
    expect(wrapper.find('[role="status"]').exists()).toBe(false);
    expect(wrapper.get('button').attributes('disabled')).toBeDefined();
  });
  it("keeps identities read-only when there is no member destination", async () => {
    const wrapper = setup({ members: [person] });
    expect(wrapper.get('.flare-moments-visibility__member').element.tagName).toBe('DIV');
    await wrapper.get('.flare-moments-visibility__row button').trigger('click');
    expect(wrapper.findComponent(List).emitted('remove')).toEqual([[person]]);
    expect(wrapper.findComponent(List).emitted('selectMember')).toBeUndefined();
  });
  it("retains separate add and member actions when supplied", async () => {
    const select = vi.fn(); const add = vi.fn();
    const wrapper = setup({ members: [person], onSelectMember: select, onAdd: add });
    await wrapper.get('.flare-moments-visibility__member').trigger('click');
    await wrapper.get('header button').trigger('click');
    expect(select).toHaveBeenCalledWith(person); expect(add).toHaveBeenCalledOnce();
  });
});
