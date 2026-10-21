// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { defineComponent, h } from "vue";
import FlareIconButton from "../general/FlareIconButton.vue";
import { describe, expect, it } from "vitest";
import type { FlareRedPacketClaim } from "../../shared/contracts/red-packet";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import FlareRedPacketDetail from "./FlareRedPacketDetail.vue";

function render(props: Partial<InstanceType<typeof FlareRedPacketDetail>["$props"]> = {}, locale: "zh-CN" | "en-US" = "zh-CN") {
  return mount(defineComponent({
    setup() {
      useFlareI18nProvider(locale);
      return () => h(FlareRedPacketDetail, {
        senderName: "小明",
        blessing: "恭喜发财，大吉大利",
        summary: "已领取 2/3 个，共 1.50/3.00 元",
        ...props,
      });
    },
  }));
}

const claims: FlareRedPacketClaim[] = [
  { id: "u1", name: "阿花", time: "10:02", amount: "0.62 元", best: false },
  { id: "u2", name: "大壮", time: "10:03", amount: "0.88 元", best: true },
];

describe("FlareRedPacketDetail", () => {
  it("leads with the sender, the kind badge and the blessing", () => {
    const wrapper = render({ kindLabel: "拼" });
    expect(wrapper.get("h2").text()).toBe("小明的红包");
    expect(wrapper.get(".flare-rp-detail__kind").text()).toBe("拼");
    expect(wrapper.get(".flare-rp-detail__blessing").text()).toBe("恭喜发财，大吉大利");
    expect(wrapper.get("section").attributes("aria-label")).toBe("小明的红包");
  });

  it("draws the viewer's own amount large with its note, and nothing when they got none", () => {
    const mine = render({ amount: "0.88 元", amountNote: "已存入钱包" });
    expect(mine.get(".flare-rp-detail__amount").text()).toBe("0.88 元");
    expect(mine.get(".flare-rp-detail__amount-note").text()).toBe("已存入钱包");
    const none = render();
    expect(none.find(".flare-rp-detail__amount").exists()).toBe(false);
    expect(none.find(".flare-rp-detail__amount-note").exists()).toBe(false);
  });

  it("lists every claim with name, time and amount, and marks only the best one", () => {
    const wrapper = render({ claims });
    const rows = wrapper.findAll(".flare-rp-detail__row");
    expect(rows).toHaveLength(2);
    expect(rows[0].text()).toContain("阿花");
    expect(rows[0].text()).toContain("10:02");
    expect(rows[0].text()).toContain("0.62 元");
    expect(rows[0].find(".flare-rp-detail__best").exists()).toBe(false);
    expect(rows[1].classes()).toContain("is-best");
    expect(rows[1].get(".flare-rp-detail__best").text()).toBe("手气最佳");
    expect(wrapper.get("ul").attributes("aria-label")).toBe("领取记录");
    expect(wrapper.get(".flare-rp-detail__summary").text()).toBe("已领取 2/3 个，共 1.50/3.00 元");
  });

  it("says nobody has claimed yet instead of an empty list", () => {
    const wrapper = render({ claims: [] });
    expect(wrapper.find("ul").exists()).toBe(false);
    expect(wrapper.get(".flare-rp-detail__empty").text()).toBe("暂无人领取");
  });

  it("closes with the host's note only when one is given", () => {
    expect(render({ note: "未领取的金额将在 24 小时后退回" }).get(".flare-rp-detail__note").text()).toBe("未领取的金额将在 24 小时后退回");
    expect(render().find(".flare-rp-detail__note").exists()).toBe(false);
    expect(render().find(".flare-rp-detail__kind").exists()).toBe(false);
  });

  it("uses the library locale for its own copy", () => {
    const wrapper = render({ senderName: "Ming", claims: [{ ...claims[1] }] }, "en-US");
    expect(wrapper.get("h2").text()).toBe("Red packet from Ming");
    expect(wrapper.get(".flare-rp-detail__best").text()).toBe("Best luck");
    expect(render({ claims: [] }, "en-US").get(".flare-rp-detail__empty").text()).toBe("No one has opened it yet");
  });

  it("draws no title bar unless the host listens to back", () => {
    expect(render().find(".flare-rp-detail__bar").exists()).toBe(false);
  });

  it("with a back listener draws the red title bar: back key and the default or given title", async () => {
    const backs: number[] = [];
    const wrapper = render({ onBack: () => backs.push(1) } as never);
    const bar = wrapper.get(".flare-rp-detail__bar");
    expect(bar.get("h1").text()).toBe("红包详情");
    expect(wrapper.get("section").classes()).toContain("has-bar");
    const back = wrapper.getComponent(FlareIconButton);
    expect(back.attributes("aria-label")).toBe("返回");
    await back.trigger("click");
    expect(backs).toEqual([1]);
    expect(render({ onBack: () => {}, title: "Lucky packet" } as never).get(".flare-rp-detail__bar h1").text()).toBe("Lucky packet");
  });
});
