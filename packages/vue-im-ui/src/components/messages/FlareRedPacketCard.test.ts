// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { defineComponent, h } from "vue";
import { describe, expect, it } from "vitest";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import FlareRedPacketCard from "./FlareRedPacketCard.vue";

function render(props: InstanceType<typeof FlareRedPacketCard>["$props"]) {
  return mount(defineComponent({
    setup() {
      useFlareI18nProvider("zh-CN");
      return () => h(FlareRedPacketCard, props);
    },
  }));
}

/**
 * Three states a person must be able to tell apart without reading carefully: unopened (tap me),
 * opened (what you got), finished (nothing left, and not tappable). Release criterion §1.
 */
describe("FlareRedPacketCard", () => {
  it("invites a tap while it is unopened", () => {
    const wrapper = render({ blessing: "恭喜发财" });
    expect(wrapper.text()).toContain("恭喜发财");
    expect(wrapper.find("button").attributes("disabled")).toBeUndefined();
    expect(wrapper.find(".flare-red-packet__status").text()).toBe("点击领取");
  });

  it("shows what was received once it is opened", () => {
    const wrapper = render({ blessing: "恭喜发财", amount: "￥8.88", opened: true });
    const status = wrapper.find(".flare-red-packet__status");
    expect(status.text()).toContain("已领取");
    expect(status.text()).toContain("￥8.88");
    expect(wrapper.find("button").classes()).toContain("is-opened");
  });

  it("cannot be tapped once it is finished, and says why", async () => {
    const wrapper = render({ blessing: "恭喜发财", finished: true });
    const button = wrapper.find("button");
    expect(button.attributes("disabled")).toBeDefined();
    expect(button.classes()).toContain("is-finished");
    expect(wrapper.find(".flare-red-packet__status").text()).toBe("已被领完");

    await button.trigger("click");
    expect(wrapper.findComponent(FlareRedPacketCard).emitted("open")).toBeUndefined();
  });

  it("reports the tap and leaves the claiming to the host", async () => {
    const wrapper = render({ blessing: "恭喜发财" });
    await wrapper.find("button").trigger("click");
    expect(wrapper.findComponent(FlareRedPacketCard).emitted("open")).toHaveLength(1);
  });

  it("still invites a tap when it is opened but the host gave no amount", () => {
    const wrapper = render({ blessing: "恭喜发财", opened: true });
    expect(wrapper.find(".flare-red-packet__status").text()).toBe("点击领取");
  });
});
