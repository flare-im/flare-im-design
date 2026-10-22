// @vitest-environment happy-dom
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { mount } from "@vue/test-utils";
import { defineComponent, h } from "vue";
import FlareIconButton from "../general/FlareIconButton.vue";
import { describe, expect, it } from "vitest";
import {
  flareRedPacketAmountText,
  flareRedPacketClaimTexts,
  flareRedPacketDetailTexts,
  flareRedPacketMoney,
  type FlareRedPacketClaim,
  type FlareRedPacketDetailStrings,
  type FlareRedPacketDetailsView,
} from "../../shared/contracts/red-packet";
import { flareMessages } from "../../shared/i18n/messages";
import { useFlareI18nProvider } from "../../shared/i18n/useFlareI18n";
import FlareRedPacketDetail from "./FlareRedPacketDetail.vue";

type Expect = { amount: string | null; deposited: boolean; headline: string | null; summary: string | null; claims: boolean; note: string | null };
const vectors = JSON.parse(readFileSync(resolve(__dirname, "../../../../../spec/red-packet-vectors.json"), "utf8")) as {
  amount: { cases: Array<{ minor: string; exponent: number; currency: string; text: string | null; money: string | null }> };
  detail: {
    nowMs: number;
    utcOffsetMinutes: number;
    copy: Record<"zh" | "en", Record<string, string>>;
    cases: Array<{ id: string; designatedName?: string | null; details: FlareRedPacketDetailsView; expect: Expect }>;
    claimRows: Array<{ claim: FlareRedPacketClaim; currency: string; currencyExponent: number; expect: { amount: string; time: string; best: boolean } }>;
  };
};
const detail = vectors.detail;

type RedPacketTree = { redPacket: Record<string, string> & { duration: Record<string, string> }; pluginView: Record<string, string> };
function strings(locale: "zh-CN" | "en-US"): FlareRedPacketDetailStrings {
  const tree = flareMessages[locale] as unknown as RedPacketTree;
  const rp = tree.redPacket;
  return {
    summarySender: rp.summarySender, summaryCompleted: rp.summaryCompleted, summaryCount: rp.summaryCount,
    refundAt: rp.refundAt, refundedNote: rp.refundedNote, missed: rp.missed, expired: rp.expiredNotice,
    notEligible: rp.notEligible, notEligibleName: rp.notEligibleName,
    durationSeconds: rp.duration.seconds, durationMinutes: rp.duration.minutes, durationHours: rp.duration.hours, durationDays: rp.duration.days,
    dateTime: tree.pluginView.dateTime, dateTimeYear: tree.pluginView.dateTimeYear,
  };
}

function render(props: Partial<InstanceType<typeof FlareRedPacketDetail>["$props"]> = {}, locale: "zh-CN" | "en-US" = "zh-CN") {
  return mount(defineComponent({
    setup() {
      useFlareI18nProvider(locale);
      return () => h(FlareRedPacketDetail, {
        senderName: "小明",
        details: detail.cases[0].details,
        nowMs: detail.nowMs,
        ...props,
      });
    },
  }));
}

describe("red packet amounts (spec amount)", () => {
  it.each(vectors.amount.cases.map((c) => [`${c.minor}/${c.exponent}/${c.currency}`, c] as const))("%s", (_id, c) => {
    expect(flareRedPacketAmountText(c.minor, c.exponent)).toBe(c.text);
    expect(flareRedPacketMoney(c.minor, c.exponent, c.currency)).toBe(c.money);
  });
});

describe("red packet details by viewer role (spec detail)", () => {
  it("keeps the vector copy and the kit copy the same", () => {
    const zh = strings("zh-CN");
    for (const [key, text] of Object.entries(detail.copy.zh)) {
      const kit = key === "expired" ? zh.expired : (zh as unknown as Record<string, string>)[key] ?? (flareMessages["zh-CN"] as unknown as RedPacketTree).redPacket[key];
      expect(kit, key).toBe(text);
    }
  });

  it.each(detail.cases.map((c) => [c.id, c] as const))("%s", (_id, c) => {
    const texts = flareRedPacketDetailTexts(c.details, { designatedName: c.designatedName ?? undefined, nowMs: detail.nowMs, utcOffsetMinutes: detail.utcOffsetMinutes }, strings("zh-CN"));
    expect({ ...texts, deposited: texts.amount !== null }).toEqual(c.expect);
  });

  it.each(detail.claimRows.map((c) => [c.claim.id, c] as const))("formats the claim row of %s", (_id, c) => {
    const texts = flareRedPacketClaimTexts(c.claim, c.currency, c.currencyExponent, detail.nowMs, strings("zh-CN"), detail.utcOffsetMinutes);
    expect({ ...texts, best: c.claim.best }).toEqual(c.expect);
  });

  // The component draws exactly what the rules give; the device zone is not pinned, so the time-free cases are used.
  it.each(detail.cases.filter((c) => !c.expect.note).map((c) => [c.id, c] as const))("draws %s", (_id, c) => {
    const claims: FlareRedPacketClaim[] = c.details.claimsListed
      ? [{ id: "u1", name: "阿花", amountMinor: "62", claimedAtMs: detail.nowMs - 60_000, best: false }, { id: "u2", name: "大壮", amountMinor: "88", claimedAtMs: detail.nowMs - 30_000, best: true }]
      : [];
    const wrapper = render({ details: c.details, designatedName: c.designatedName ?? undefined, claims });
    const text = (selector: string) => (wrapper.find(selector).exists() ? wrapper.get(selector).text() : null);
    expect(text("[data-detail-amount]")).toBe(c.expect.amount);
    expect(wrapper.text().includes("已存入钱包")).toBe(c.expect.deposited);
    expect(text("[data-detail-headline]")).toBe(c.expect.headline);
    expect(text("[data-detail-summary]")).toBe(c.expect.summary);
    expect(wrapper.findAll("[data-detail-claim]")).toHaveLength(c.expect.claims ? 2 : 0);
    expect(text("[data-detail-note]")).toBe(null);
    // No amount the server did not return: the claim list is the only other place an amount appears.
    if (!c.expect.claims && !c.expect.amount && !c.expect.summary?.includes("¥")) expect(wrapper.text()).not.toMatch(/[¥$€]/);
  });
});

describe("FlareRedPacketDetail", () => {
  it("leads with the sender, the kind badge and the greeting", () => {
    const wrapper = render();
    expect(wrapper.get("h2").text()).toBe("小明的红包");
    expect(wrapper.get("[data-detail-badge]").text()).toBe("拼手气");
    expect(wrapper.get(".flare-rp-detail__blessing").text()).toBe("恭喜发财，大吉大利");
    expect(wrapper.get("section").attributes("aria-label")).toBe("小明的红包");
    expect(wrapper.get("section").attributes("data-viewer-role")).toBe("sender");
  });

  it("lists every claim with name, time and amount, and marks only the best one", () => {
    const claims: FlareRedPacketClaim[] = [
      { id: "u1", name: "阿花", amountMinor: "62", claimedAtMs: detail.nowMs - 60_000, best: false },
      { id: "u2", name: "大壮", amountMinor: "88", claimedAtMs: detail.nowMs - 30_000, best: true },
    ];
    const wrapper = render({ claims });
    const rows = wrapper.findAll(".flare-rp-detail__row");
    expect(rows).toHaveLength(2);
    expect(rows[0].text()).toContain("阿花");
    expect(rows[0].text()).toContain("¥0.62");
    expect(rows[0].find(".flare-rp-detail__best").exists()).toBe(false);
    expect(rows[1].classes()).toContain("is-best");
    expect(rows[1].get(".flare-rp-detail__best").text()).toBe("手气最佳");
    expect(wrapper.get("ul").attributes("aria-label")).toBe("领取记录");
  });

  it("says nobody has claimed yet instead of an empty list", () => {
    const wrapper = render({ claims: [] });
    expect(wrapper.find("ul").exists()).toBe(false);
    expect(wrapper.get(".flare-rp-detail__empty").text()).toBe("暂无人领取");
  });

  it("uses the library locale for its own copy", () => {
    const wrapper = render({ senderName: "Ming", claims: [{ id: "u2", name: "Zhuang", amountMinor: "88", claimedAtMs: detail.nowMs, best: true }] }, "en-US");
    expect(wrapper.get("h2").text()).toBe("Red packet from Ming");
    expect(wrapper.get(".flare-rp-detail__best").text()).toBe("Best luck");
    expect(wrapper.get("[data-detail-summary]").text()).toBe("2/5 opened, ¥3.88/¥10.00");
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
