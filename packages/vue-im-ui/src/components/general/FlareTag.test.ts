// @vitest-environment happy-dom
import { mount } from "@vue/test-utils";
import { readFileSync } from "node:fs";
import { resolve } from "node:path";
import { describe, expect, it } from "vitest";
import FlareTag from "./FlareTag.vue";

describe("FlareTag", () => {
  it("is the words and nothing a person can press", () => {
    const tag = mount(FlareTag, { props: { label: "已冻结", tone: "danger" } });
    expect(tag.text()).toBe("已冻结");
    expect(tag.classes()).toContain("flare-tag--danger");
    expect(tag.attributes("data-tone")).toBe("danger");
    expect(tag.find("button").exists()).toBe(false);
    expect(tag.attributes("tabindex")).toBeUndefined();
    expect(tag.attributes("role")).toBeUndefined();
  });

  it("is neutral unless the host says what the state means", () => {
    const tag = mount(FlareTag, { props: { label: "text" } });
    expect(tag.classes()).toContain("flare-tag--neutral");
    expect(tag.find(".flare-tag__dot").exists()).toBe(false);
    expect(tag.classes()).not.toContain("is-monospace");
  });

  it("draws a dot for a live state, hidden from assistive technology", () => {
    const tag = mount(FlareTag, { props: { label: "在线", tone: "success", dot: true } });
    expect(tag.get(".flare-tag__dot").attributes("aria-hidden")).toBe("true");
    expect(tag.text()).toBe("在线");
  });

  it("sets an identifier in the monospaced face", () => {
    expect(mount(FlareTag, { props: { label: "v2.0.0", monospace: true } }).classes()).toContain("is-monospace");
  });
});

describe("FlareTag colours", () => {
  const source = readFileSync(resolve(__dirname, "FlareTag.vue"), "utf8");
  const tokens = readFileSync(resolve(__dirname, "../../../../../tokens/dist/tokens.css"), "utf8");
  const blocks = [...tokens.matchAll(/([^{}]+)\{([^}]*)\}/g)].map((match) => ({
    selector: match[1].trim().split("\n").pop()?.trim() ?? "",
    vars: Object.fromEntries([...match[2].matchAll(/(--[\w-]+):\s*([^;]+);/g)].map((decl) => [decl[1], decl[2].trim()])),
  }));
  const block = (selector: string) => blocks.find((entry) => entry.selector === selector)?.vars ?? {};
  const rgb = (value: string, under: number[]): number[] => {
    const hex = /^#([0-9a-f]{6})$/i.exec(value);
    if (hex) return [0, 2, 4].map((i) => parseInt(hex[1].slice(i, i + 2), 16));
    const rgba = /^rgba?\(([^)]+)\)$/.exec(value);
    if (!rgba) throw new Error(`unreadable colour ${value}`);
    const [r, g, b, a = 1] = rgba[1].split(",").map((part) => Number(part.trim()));
    return [r, g, b].map((channel, i) => channel * a + under[i] * (1 - a));
  };
  const luminance = (channels: number[]) => {
    const [r, g, b] = channels.map((c) => c / 255).map((c) => (c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4));
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  };
  const contrast = (a: number[], b: number[]) => {
    const [hi, lo] = [luminance(a), luminance(b)].sort((x, y) => y - x);
    return (hi + 0.05) / (lo + 0.05);
  };

  // Each tone's ink and surface as the component declares them: `var(--ink)` on either a token or
  // `color-mix(in srgb, var(--fill) N%, var(--base))`.
  const tones = [...source.matchAll(/\.flare-tag--(\w+) \{\s*--flare-tag-ink: var\((--[\w-]+)\);\s*--flare-tag-surface: ([^;]+);/g)].map((match) => {
    const mix = /color-mix\(in srgb, var\((--[\w-]+)\) (\d+)%, var\((--[\w-]+)\)\)/.exec(match[3]);
    const plain = /^var\((--[\w-]+)\)$/.exec(match[3].trim());
    return { tone: match[1], ink: match[2], mix: mix ? { fill: mix[1], percent: Number(mix[2]) / 100, base: mix[3] } : null, surface: plain?.[1] ?? null };
  });

  it("declares every tone of the shared vocabulary", () => {
    expect(tones.map((entry) => entry.tone).sort()).toEqual(["danger", "info", "neutral", "success", "warning"]);
    expect(source).not.toMatch(/#[0-9a-fA-F]{3,8}\b|\brgba?\(|\bhsla?\(/);
  });

  // WCAG 1.4.3: a tag is text, so its words clear 4.5:1 against its own surface in every brand and both modes.
  it("keeps every tone's words at 4.5:1 on its surface, in every brand and both modes", () => {
    const brands = ["", ...[...tokens.matchAll(/^\[data-flare-brand="(\w+)"\] \{/gm)].map((match) => match[1])];
    expect(brands.length).toBeGreaterThan(1);
    const failures: string[] = [];
    for (const brand of brands) {
      for (const mode of ["light", "dark"]) {
        const vars: Record<string, string> = {
          ...block(":root"),
          ...(mode === "dark" ? block('[data-flare-theme="dark"]') : {}),
          ...(brand ? block(`[data-flare-brand="${brand}"]`) : {}),
          ...(brand && mode === "dark" ? block(`[data-flare-brand="${brand}"][data-flare-theme="dark"]`) : {}),
        };
        const page = rgb(vars["--flare-color-bg-primary"], [255, 255, 255]);
        for (const entry of tones) {
          let surface: number[];
          if (entry.mix) {
            const base = rgb(vars[entry.mix.base], page);
            const fill = rgb(vars[entry.mix.fill], base);
            // The browser paints whole channel values, so the mix is rounded the way it is drawn: at 8% the
            // unrounded warning surface reads 4.50:1 and the painted one 4.49:1 (axe caught that), so it is 6%.
            surface = fill.map((channel, i) => Math.round(channel * entry.mix!.percent + base[i] * (1 - entry.mix!.percent)));
          } else {
            surface = rgb(vars[entry.surface!], page);
          }
          const ratio = contrast(rgb(vars[entry.ink], surface), surface);
          if (ratio < 4.5) failures.push(`${brand || "base"}/${mode} ${entry.tone} ${ratio.toFixed(2)}:1`);
        }
      }
    }
    expect(failures).toEqual([]);
  });
});
