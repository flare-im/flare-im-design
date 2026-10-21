// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { defineComponent, h } from "vue";
import { describe, expect, it } from "vitest";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import FlareRedPacketCard from "./FlareRedPacketCard.vue";

function render(props: InstanceType<typeof FlareRedPacketCard>["$props"], locale: "zh-CN" | "en-US" = "zh-CN") {
  return mount(defineComponent({
    setup() {
      useFlareI18nProvider(locale);
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

  it.each(["disabled", "busy"] as const)("blocks %s packets without claiming they are finished", async (state) => {
    const wrapper = render({ blessing: "Hello", [state]: true });
    const card = wrapper.findComponent(FlareRedPacketCard);
    expect(card.get("button").attributes("disabled")).toBeDefined();
    expect(card.get("button").classes()).not.toContain("is-finished");
    await card.get("button").trigger("click");
    expect(card.emitted("open")).toBeUndefined();
    expect(card.text()).toContain(state === "busy" ? "处理中" : "暂不可用");
  });

  it("uses the library locale for progress and unavailable states", () => {
    expect(render({ blessing: "Hello", busy: true }, "en-US").text()).toContain("Processing");
    expect(render({ blessing: "Hello", disabled: true }, "en-US").text()).toContain("Unavailable");
  });

  it("renders host status as inert text; progress wins while an original command is pending", () => {
    const wrapper = render({ blessing: "Hello", disabled: true, statusLabel: "<b>Created</b>" });
    expect(wrapper.text()).toContain("<b>Created</b>");
    expect(wrapper.find("b").exists()).toBe(false);
    expect(render({ blessing: "Hello", busy: true, statusLabel: "Created" }).text()).toContain("处理中");
  });
});
