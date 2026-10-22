// @vitest-environment happy-dom
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { mount } from "@vue/test-utils";
import { defineComponent, h } from "vue";
import { describe, expect, it } from "vitest";
import {
  flareRedPacketCardBadge,
  flareRedPacketCardState,
  type FlareRedPacketCardState,
  type FlareRedPacketKind,
  type FlareRedPacketStatus,
  type FlareRedPacketTapAction,
} from "../../shared/contracts/red-packet";
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

type StatusKey = "busy" | "statusLabel" | "tapToOpen" | "view" | "claimed" | "finished" | "expired" | "refunded" | "unavailable";
interface CardVector {
  id: string;
  state: FlareRedPacketCardState;
  busy?: boolean;
  disabled?: boolean;
  statusLabel?: string;
  status: StatusKey;
  tappable: boolean;
  dimmed: boolean;
}
interface FadedStop {
  token: string;
  base: string;
  faded: string;
}
interface FadedTable {
  mixToken: string;
  mix: number;
  targetToken: string;
  target: string;
  inkToken: string;
  ink: string;
  minTextContrast: number;
  textStops: string[];
  stops: FadedStop[];
  dark: { target: string; ink: string; stops: FadedStop[] };
}
const vectors = JSON.parse(readFileSync(resolve(__dirname, "../../../../../spec/red-packet-vectors.json"), "utf8")) as {
  cardState: Array<{ id: string; view: { status: FlareRedPacketStatus; claimedByMe?: boolean; tapAction?: FlareRedPacketTapAction }; state: FlareRedPacketCardState }>;
  card: CardVector[];
  cardCopy: Record<"zh" | "en", Record<Exclude<StatusKey, "statusLabel">, string>>;
  cardBadge: Array<{ id: string; kind: FlareRedPacketKind; recipientName?: string; badge: string | null; zh: string | null; en: string | null; recipient: { zh: string; en: string } | null }>;
  faded: FadedTable;
};
const tokens = JSON.parse(readFileSync(resolve(__dirname, "../../../../../tokens/tokens.json"), "utf8"));
const cardSource = readFileSync(resolve(__dirname, "FlareRedPacketCard.vue"), "utf8");

const token = (path: string, dark = false): string => {
  const darkValue = dark ? path.split(".").reduce((node, key) => node?.[key], tokens.dark) : undefined;
  return darkValue ?? path.split(".").reduce((node, key) => node[key], tokens);
};
const rgb = (hex: string) => [1, 3, 5].map((i) => parseInt(hex.slice(i, i + 2), 16));
// The same arithmetic as CSS `color-mix(in srgb, colour, target mix)` and the native kits' lerp.
const mixToward = (hex: string, target: string, mix: number) => {
  const to = rgb(target);
  return rgb(hex).map((c, i) => Math.round(c * (1 - mix) + to[i] * mix));
};
const luminance = (c: number[]) => {
  const [r, g, b] = c.map((v) => {
    const s = v / 255;
    return s <= 0.04045 ? s / 12.92 : ((s + 0.055) / 1.055) ** 2.4;
  });
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
};
const contrast = (a: number[], b: number[]) => {
  const [hi, lo] = [luminance(a), luminance(b)].sort((x, y) => y - x);
  return (hi + 0.05) / (lo + 0.05);
};

const copyOf = (vector: CardVector, locale: "zh" | "en") =>
  vector.status === "statusLabel" ? vector.statusLabel! : vectors.cardCopy[locale][vector.status];

/**
 * A card never shows an amount: greeting, kind badge, "For {name}" and one status line. Unopened and viewable are
 * saturated; claimed, finished, expired and refunded fade and stay tappable. Only busy and disabled block the tap.
 */
describe("FlareRedPacketCard", () => {
  it.each(vectors.cardState.map((v) => [v.id, v] as const))("maps the public and personal layers: %s", (_id, vector) => {
    expect(flareRedPacketCardState(vector.view)).toBe(vector.state);
  });

  it.each(vectors.card.map((v) => [v.id, v] as const))("follows the shared card vector %s", async (_id, vector) => {
    for (const locale of ["zh", "en"] as const) {
      const wrapper = render({
        blessing: "Hello",
        state: vector.state,
        busy: vector.busy,
        disabled: vector.disabled,
        statusLabel: vector.statusLabel,
      }, locale === "zh" ? "zh-CN" : "en-US");
      const card = wrapper.findComponent(FlareRedPacketCard);
      const button = card.get("button");
      expect(card.get("[data-red-packet-status]").text()).toBe(copyOf(vector, locale));
      expect(button.classes().includes("is-dimmed")).toBe(vector.dimmed);
      expect(button.attributes("disabled") === undefined).toBe(vector.tappable);
      await button.trigger("click");
      expect(card.emitted("open")?.length ?? 0).toBe(vector.tappable ? 1 : 0);
    }
  });

  it.each(vectors.cardBadge.map((v) => [v.id, v] as const))("draws the kind badge and recipient: %s", (_id, vector) => {
    expect(flareRedPacketCardBadge(vector.kind, vector.recipientName).badge).toBe(vector.badge);
    for (const locale of ["zh", "en"] as const) {
      const wrapper = render({ blessing: "恭喜发财", kind: vector.kind, recipientName: vector.recipientName }, locale === "zh" ? "zh-CN" : "en-US");
      const badge = wrapper.find("[data-red-packet-badge]");
      expect(badge.exists() ? badge.text() : null).toBe(vector[locale]);
      const recipient = wrapper.find("[data-red-packet-recipient]");
      expect(recipient.exists() ? recipient.text() : null).toBe(vector.recipient?.[locale] ?? null);
      expect(wrapper.find(".flare-red-packet__brand-name").exists()).toBe(true);
    }
  });

  it("never draws an amount, whatever the host passes", () => {
    const wrapper = render({ blessing: "恭喜发财", state: "claimed", ...({ amount: "￥8.88" } as Record<string, unknown>) });
    expect(wrapper.text()).not.toContain("8.88");
    expect(wrapper.find(".flare-red-packet__status b").exists()).toBe(false);
  });

  it("names the button by its blessing and status, in the library locale", () => {
    expect(render({ blessing: "恭喜发财，大吉大利" }).get("button").attributes("aria-label")).toBe("恭喜发财，大吉大利，领取红包");
    expect(render({ blessing: "恭喜发财", state: "refunded" }).get("button").attributes("aria-label")).toBe("恭喜发财，已退回");
    expect(render({ blessing: "Best wishes", busy: true }, "en-US").get("button").attributes("aria-label")).toBe("Best wishes, Processing…");
  });

  it("keeps spent packets tappable so the host can route to the details", async () => {
    for (const state of ["finished", "expired", "refunded", "viewable"] as const) {
      const card = render({ blessing: "恭喜发财", state }).findComponent(FlareRedPacketCard);
      expect(card.get("button").attributes("disabled")).toBeUndefined();
      expect(card.get("button").attributes("data-state")).toBe(state);
      await card.get("button").trigger("click");
      expect(card.emitted("open")).toHaveLength(1);
    }
  });

  it("renders host status as inert text; progress wins while an original command is pending", () => {
    const wrapper = render({ blessing: "Hello", disabled: true, statusLabel: "<b>Created</b>" });
    expect(wrapper.text()).toContain("<b>Created</b>");
    expect(wrapper.find("[data-red-packet-status] b").exists()).toBe(false);
    expect(render({ blessing: "Hello", busy: true, statusLabel: "Created" }).text()).toContain("处理中");
  });

  it("announces progress politely and only while busy", () => {
    expect(render({ blessing: "Hello", busy: true }).get(".flare-red-packet__status").attributes("aria-live")).toBe("polite");
    expect(render({ blessing: "Hello" }).get(".flare-red-packet__status").attributes("aria-live")).toBe("off");
  });

  describe("faded face (spec/red-packet-vectors.json → faded)", () => {
    const faded = vectors.faded;
    const modes = [
      { name: "light", dark: false, target: faded.target, ink: faded.ink, stops: faded.stops },
      { name: "dark", dark: true, target: faded.dark.target, ink: faded.dark.ink, stops: faded.dark.stops },
    ];

    it("fades by mixing toward the shared target token, not by a filter", () => {
      expect(Number(token(faded.mixToken))).toBe(faded.mix);
      expect(cardSource).toContain("var(--flare-size-component-red-packet-faded-mix)");
      expect(cardSource).toContain("var(--flare-color-red-packet-faded-ink)");
      expect(cardSource).not.toMatch(/saturate\(|grayscale/);
      // The card itself is never faded by opacity or a filter; only the glyph's flap shadow is translucent.
      const dimmedBlock = cardSource.slice(cardSource.indexOf(".flare-red-packet.is-dimmed {"));
      expect(dimmedBlock.slice(0, dimmedBlock.indexOf("}"))).not.toMatch(/opacity|filter/);
      for (const stop of faded.stops) {
        const cssName = stop.token.replace("colors.redPacket.", "").replace(/[A-Z]/g, (c) => `-${c.toLowerCase()}`);
        expect(cardSource).toContain(
          `color-mix(in srgb, var(--flare-color-red-packet-${cssName}), var(--flare-color-red-packet-faded-mix-target) var(--rp-mix))`,
        );
      }
    });

    describe.each(modes)("$name mode", (mode) => {
      it("reads its target and ink from the tokens", () => {
        expect(token(faded.targetToken, mode.dark)).toBe(mode.target);
        expect(token(faded.inkToken, mode.dark)).toBe(mode.ink);
      });

      it.each(mode.stops.map((s) => [s.token, s] as const))("%s keeps its hue", (_name, stop) => {
        expect(token(stop.token)).toBe(stop.base);
        const mixed = mixToward(stop.base, mode.target, faded.mix);
        rgb(stop.faded).forEach((c, i) => expect(Math.abs(c - mixed[i])).toBeLessThanOrEqual(1));
      });

      it("keeps the faded ink legible on every stop the words sit on", () => {
        for (const name of faded.textStops) {
          const stop = mode.stops.find((s) => s.token === name)!;
          expect(contrast(rgb(stop.faded), rgb(mode.ink))).toBeGreaterThanOrEqual(faded.minTextContrast);
        }
      });
    });

    it("needs the ink in light mode: white would not be legible on the faded face", () => {
      for (const name of faded.textStops) {
        const stop = faded.stops.find((s) => s.token === name)!;
        expect(contrast(rgb(stop.faded), [255, 255, 255])).toBeLessThan(faded.minTextContrast);
      }
    });

    it.each([{ busy: true }, { disabled: true }])("keeps the unopened face for %o — only the status line changes", (flags) => {
      const button = render({ blessing: "Hello", ...flags }).get("button");
      expect(button.classes()).not.toContain("is-dimmed");
      expect(button.classes()).toContain("is-unopened");
      // Nothing in the stylesheet greys out a blocked card.
      expect(cardSource).not.toMatch(/:disabled\s*\{[^}]*(opacity|filter|color|background)/);
    });
  });

  it("draws the shared small envelope instead of an icon", () => {
    const wrapper = render({ blessing: "Hello" });
    expect(wrapper.find(".n-icon").exists()).toBe(false);
    const svg = wrapper.get("svg.flare-red-packet__glyph");
    expect(svg.attributes("aria-hidden")).toBe("true");
    expect(svg.attributes("viewBox")).toBe("0 0 30 39");
    // iOS / Compose RedPacketGlyph: corners 0.18 w, flap 0.42 h dipping 0.3 of itself, seal 0.36 w on the flap's edge.
    expect(svg.get("clipPath rect").attributes("rx")).toBe("5.4");
    expect(svg.get(".flare-red-packet__glyph-flap").attributes("d")).toBe("M0 0H30V11.47Q15 21.29 0 11.47Z");
    const seal = svg.get(".flare-red-packet__glyph-seal");
    expect([seal.attributes("cx"), seal.attributes("cy"), seal.attributes("r")]).toEqual(["15", "16.38", "5.4"]);
    // Two cards on one page must not share gradient or clip ids.
    const page = mount(defineComponent({
      setup() {
        useFlareI18nProvider("zh-CN");
        return () => h("div", [h(FlareRedPacketCard, { blessing: "A" }), h(FlareRedPacketCard, { blessing: "B" })]);
      },
    }));
    const ids = page.findAll("linearGradient").map((g) => g.attributes("id"));
    expect(ids).toHaveLength(2);
    expect(ids[0]).not.toBe(ids[1]);
  });
});
