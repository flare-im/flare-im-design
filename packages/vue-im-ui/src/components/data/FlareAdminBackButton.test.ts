// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { expect, it, vi } from "vitest";
import FlareAdminBackButton from "./FlareAdminBackButton.vue";

it("shows the destination and a decorative arrow, and forwards clicks only while enabled", async () => {
  const back = vi.fn();
  const wrapper = mount(FlareAdminBackButton, {
    props: { label: "返回插件市场" },
    attrs: { onClick: back },
  });
  const button = wrapper.get("button");
  expect(button.text()).toBe("返回插件市场");
  expect(button.get(".flare-button__icon").attributes("aria-hidden")).toBe("true");
  await button.trigger("click");
  expect(back).toHaveBeenCalledTimes(1);
  await wrapper.setProps({ disabled: true });
  expect(button.element.disabled).toBe(true);
  await button.trigger("click");
  expect(back).toHaveBeenCalledTimes(1);
  wrapper.unmount();
});
