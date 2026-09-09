#!/usr/bin/env node
// Flare IM design tokens — generator.
// One neutral source (tokens.json) → per-platform outputs.
// Web (CSS custom properties + the typed token object) is generated here because
// @flare-im/vue-ui is the current consumer. Dart / Swift / Compose emitters are
// added when their component packages land (no generator without a consumer).

import { readFileSync, writeFileSync as writeOutput, mkdirSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

// CI checks generated output without overwriting drift.
function writeFileSync(path, content) {
  if (!process.argv.includes("--check")) return writeOutput(path, content);
  let current;
  try { current = readFileSync(path, "utf8"); } catch { current = undefined; }
  if (current !== content) { console.error(`Generated output out of date: ${path}`); process.exitCode = 1; }
}

const here = dirname(fileURLToPath(import.meta.url));
const src = JSON.parse(readFileSync(join(here, "tokens.json"), "utf8"));
const dist = join(here, "dist");
mkdirSync(dist, { recursive: true });

const kebab = (k) => k.replace(/([a-z0-9])([A-Z])/g, "$1-$2").toLowerCase();

/** flatten a colors map (flat entries + nested bg/border/bubble/text groups) to [--flare-color-*, value] */
function colorVars(colors) {
  const out = [];
  for (const [key, val] of Object.entries(colors)) {
    if (val && typeof val === "object") {
      for (const [sub, v] of Object.entries(val)) {
        out.push([`--flare-color-${kebab(key)}-${kebab(sub)}`, v]);
      }
    } else {
      out.push([`--flare-color-${kebab(key)}`, val]);
    }
  }
  return out;
}

function sizeVars(sizes) {
  const groupPrefix = {
    spacing: "spacing",
    radius: "radius",
    fontSize: "font-size",
    lineHeight: "line-height",
    layout: "layout",
  };
  const out = [];
  for (const [group, entries] of Object.entries(sizes)) {
    const p = groupPrefix[group] ?? kebab(group);
    for (const [key, v] of Object.entries(entries)) {
      out.push([`--flare-size-${p}-${kebab(key)}`, v]);
    }
  }
  return out;
}

const lightVars = [
  ...colorVars(src.colors),
  ...sizeVars(src.sizes),
  ...Object.entries(src.shadows).map(([k, v]) => [`--flare-shadow-${kebab(k)}`, v]),
  ...Object.entries(src.transitions).map(([k, v]) => [`--flare-transition-${kebab(k)}`, v]),
];
const darkVars = [
  ...colorVars(src.dark.colors),
  // dark-mode elevation overrides — light shadows use dark ink and vanish on a dark
  // canvas, so the dark theme ships its own violet-tinted, top-lit shadow set.
  ...Object.entries(src.dark.shadows ?? {}).map(([k, v]) => [`--flare-shadow-${kebab(k)}`, v]),
];

const block = (sel, vars) =>
  `${sel} {\n${vars.map(([k, v]) => `  ${k}: ${v};`).join("\n")}\n}`;

const css =
  `/* GENERATED. Do not edit by hand. Source: @flare-im/tokens/tokens.json */\n` +
  `${block(":root", lightVars)}\n\n${block('[data-flare-theme="dark"]', darkVars)}\n`;

const banner = `// GENERATED. Do not edit by hand. Source: @flare-im/tokens/tokens.json\n`;
const obj = JSON.stringify(src, null, 2);
const ts = `${banner}\nexport const flareDesignTokens = ${obj} as const;\n\nexport type FlareDesignTokens = typeof flareDesignTokens;\n`;
// runtime ESM for npm consumers that don't compile .ts
const js = `${banner}\nexport const flareDesignTokens = ${obj};\n`;
// hand-authored .d.ts (generic) so it types without a TS build step
const dts = `${banner}\nexport declare const flareDesignTokens: { readonly [group: string]: any };\nexport type FlareDesignTokens = typeof flareDesignTokens;\n`;

writeFileSync(join(dist, "tokens.css"), css);
writeFileSync(join(dist, "tokens.ts"), ts);
writeFileSync(join(dist, "tokens.js"), js);
writeFileSync(join(dist, "tokens.d.ts"), dts);

// ---------------------------------------------------------------------------
// Dart target — emitted directly into the flutter-im-ui package's source tree
// (pub can't consume an npm package, so the generated tokens are vendored there,
// same single source: tokens.json). Consumer landed → generator added, per policy.
// ---------------------------------------------------------------------------
const cap = (s) => s.charAt(0).toUpperCase() + s.slice(1);

/** [#RRGGBB | rgb(a)] → const-friendly `Color(0xAARRGGBB)` */
function dartColor(value) {
  const v = value.trim();
  const hx = (n) => Math.max(0, Math.min(255, Math.round(n))).toString(16).padStart(2, "0").toUpperCase();
  if (v.startsWith("#")) {
    const h = v.slice(1);
    const rgb = h.length === 3 ? h.split("").map((c) => c + c).join("") : h;
    return `Color(0xFF${rgb.toUpperCase()})`;
  }
  const m = v.match(/rgba?\(([^)]+)\)/);
  if (m) {
    const parts = m[1].split(",").map((s) => s.trim());
    const [r, g, b] = parts;
    const a = parts[3] !== undefined ? parseFloat(parts[3]) : 1;
    return `Color(0x${hx(a * 255)}${hx(+r)}${hx(+g)}${hx(+b)})`;
  }
  throw new Error(`unhandled color literal: ${value}`);
}

/** flat color map { fieldName: cssValue } from flat + nested (bg/border/bubble/text) groups */
function flattenColors(colors) {
  const out = {};
  for (const [key, val] of Object.entries(colors)) {
    if (val && typeof val === "object") {
      for (const [sub, v] of Object.entries(val)) out[key + cap(sub)] = v;
    } else {
      out[key] = val;
    }
  }
  return out;
}

const lightColors = flattenColors(src.colors);
// dark has all fields: light merged with the dark overrides (dark.json is a subset)
const darkColors = { ...lightColors, ...flattenColors(src.dark.colors) };
const colorFields = Object.keys(lightColors);

const dartNum = (value) => {
  const n = parseFloat(value);
  return Number.isInteger(n) ? `${n}.0` : `${n}`;
};
const sizeConsts = [];
for (const [group, entries] of Object.entries(src.sizes)) {
  for (const [key, v] of Object.entries(entries)) {
    // layout keys are already descriptive; others carry their group as prefix
    const name = group === "layout" ? key : group + cap(key);
    sizeConsts.push([name, dartNum(v)]);
  }
}

const dartBanner = `// GENERATED. Do not edit by hand. Source: @flare-im/tokens/tokens.json\n`;
const dart =
  dartBanner +
  `\nimport 'dart:ui';\n\n` +
  `/// Flare IM design colours, theme-aware. Use [FlareColors.of] with the ambient\n` +
  `/// [Brightness] (e.g. \`Theme.of(context).brightness\`).\n` +
  `class FlareColors {\n` +
  `  const FlareColors({\n` +
  colorFields.map((f) => `    required this.${f},`).join("\n") +
  `\n  });\n\n` +
  colorFields.map((f) => `  final Color ${f};`).join("\n") +
  `\n\n  static const FlareColors light = FlareColors(\n` +
  colorFields.map((f) => `    ${f}: ${dartColor(lightColors[f])},`).join("\n") +
  `\n  );\n\n  static const FlareColors dark = FlareColors(\n` +
  colorFields.map((f) => `    ${f}: ${dartColor(darkColors[f])},`).join("\n") +
  `\n  );\n\n  static FlareColors of(Brightness brightness) =>\n` +
  `      brightness == Brightness.dark ? dark : light;\n}\n\n` +
  `/// Flare IM spacing / radius / font-size / line-height / layout tokens (logical px).\n` +
  `abstract final class FlareSizes {\n` +
  sizeConsts.map(([n, v]) => `  static const double ${n} = ${v};`).join("\n") +
  `\n}\n`;

const flutterTokens = join(here, "../flutter-im-ui/lib/src/tokens/flare_tokens.dart");
mkdirSync(dirname(flutterTokens), { recursive: true });
const dartPalette = `\n/// Const palette for const widget and ThemeData declarations.\nabstract final class FlarePalette {\n` +
  colorFields.map((f) => `  static const Color light${cap(f)} = ${dartColor(lightColors[f])};\n  static const Color dark${cap(f)} = ${dartColor(darkColors[f])};`).join("\n") +
  `\n}\n`;
const dartLayout = `
/// Decisions use the available container width, never the physical device model.
abstract final class FlareLayoutPolicy {
  static int paneCount(double width, {bool hasDetail = false, double textScale = 1,
      double listWidth = FlareSizes.leftPanel, double detailWidth = FlareSizes.rightPanel}) {
    final chat = FlareSizes.chatMinWidth * textScale.clamp(1.0, 2.0);
    final list = listWidth.clamp(0.0, double.infinity);
    final detail = detailWidth.clamp(0.0, double.infinity);
    if (hasDetail && width >= FlareSizes.triplePaneMinWidth && width >= list + detail + chat + 2) return 3;
    if (width >= FlareSizes.dualPaneMinWidth && width >= list + chat + 1) return 2;
    return 1;
  }
}
`;
writeFileSync(flutterTokens, dart + dartPalette + dartLayout);

// ---------------------------------------------------------------------------
// Swift target — vendored into the FlareIMUI SwiftPM package.
// ---------------------------------------------------------------------------
/** [#RRGGBB | rgb(a)] → SwiftUI `Color(.sRGB, red:…, green:…, blue:…, opacity:…)` */
function swiftColor(value) {
  const v = value.trim();
  const f = (n) => (n / 255).toFixed(4);
  if (v.startsWith("#")) {
    const h = v.slice(1);
    const rgb = h.length === 3 ? h.split("").map((c) => c + c).join("") : h;
    const r = parseInt(rgb.slice(0, 2), 16);
    const g = parseInt(rgb.slice(2, 4), 16);
    const b = parseInt(rgb.slice(4, 6), 16);
    return `Color(.sRGB, red: ${f(r)}, green: ${f(g)}, blue: ${f(b)}, opacity: 1.0)`;
  }
  const m = v.match(/rgba?\(([^)]+)\)/);
  if (m) {
    const p = m[1].split(",").map((s) => s.trim());
    const a = p[3] !== undefined ? parseFloat(p[3]) : 1;
    return `Color(.sRGB, red: ${f(+p[0])}, green: ${f(+p[1])}, blue: ${f(+p[2])}, opacity: ${a.toFixed(4)})`;
  }
  throw new Error(`unhandled color literal: ${value}`);
}

const swift =
  `// GENERATED. Do not edit by hand. Source: @flare-im/tokens/tokens.json\n` +
  `import SwiftUI\n\n` +
  `/// Flare IM design colours, theme-aware. Use \`FlareColors.of(colorScheme)\`.\n` +
  `public struct FlareColors: Sendable {\n` +
  colorFields.map((f) => `    public let ${f}: Color`).join("\n") +
  `\n\n    public static let light = FlareColors(\n` +
  colorFields.map((f) => `        ${f}: ${swiftColor(lightColors[f])}`).join(",\n") +
  `\n    )\n\n    public static let dark = FlareColors(\n` +
  colorFields.map((f) => `        ${f}: ${swiftColor(darkColors[f])}`).join(",\n") +
  `\n    )\n\n    public static func of(_ scheme: ColorScheme) -> FlareColors {\n` +
  `        scheme == .dark ? dark : light\n    }\n}\n\n` +
  `/// Flare IM spacing / radius / font-size / line-height / layout tokens (logical px).\n` +
  `public enum FlareSizes {\n` +
  sizeConsts.map(([n, v]) => `    public static let ${n}: CGFloat = ${v}`).join("\n") +
  `\n}\n`;

const swiftTokens = join(here, "../ios-im-ui/Sources/FlareIMUI/Tokens/FlareTokens.swift");
mkdirSync(dirname(swiftTokens), { recursive: true });
const swiftLayout = `
/// Shared logical-point layout policy. Large text reserves more reading width.
public enum FlareLayoutPolicy {
    public static func paneCount(width: CGFloat, hasDetail: Bool = false, textScale: CGFloat = 1,
                                listWidth: CGFloat = FlareSizes.leftPanel, detailWidth: CGFloat = FlareSizes.rightPanel) -> Int {
        let chat = FlareSizes.chatMinWidth * min(2, max(1, textScale))
        let list = max(0, listWidth)
        let detail = max(0, detailWidth)
        if hasDetail && width >= FlareSizes.triplePaneMinWidth && width >= list + detail + chat + 2 { return 3 }
        if width >= FlareSizes.dualPaneMinWidth && width >= list + chat + 1 { return 2 }
        return 1
    }
}
`;
writeFileSync(swiftTokens, swift + swiftLayout);

// ---------------------------------------------------------------------------
// Compose (Kotlin) target — vendored into the flare-im-ui-compose module.
// ---------------------------------------------------------------------------
const composeColor = dartColor; // Kotlin androidx Color literal is also 0xAARRGGBB

const kotlin =
  `// GENERATED. Do not edit by hand. Source: @flare-im/tokens/tokens.json\n` +
  `package com.flare.im.ui\n\n` +
  `import androidx.compose.runtime.Composable\nimport androidx.compose.runtime.CompositionLocalProvider\nimport androidx.compose.runtime.staticCompositionLocalOf\n` +
  `import androidx.compose.foundation.isSystemInDarkTheme\n` +
  `import androidx.compose.ui.graphics.Color\n` +
  `import androidx.compose.ui.unit.Dp\n` +
  `import androidx.compose.ui.unit.dp\n\n` +
  `/** Flare IM design colours, theme-aware. Prefer [flareColors]. */\n` +
  `data class FlareColors(\n` +
  colorFields.map((f) => `    val ${f}: Color`).join(",\n") +
  `,\n) {\n    companion object {\n        val Light = FlareColors(\n` +
  colorFields.map((f) => `            ${f} = ${composeColor(lightColors[f]).replace("Color(0x", "Color(0x")}`).join(",\n") +
  `,\n        )\n        val Dark = FlareColors(\n` +
  colorFields.map((f) => `            ${f} = ${composeColor(darkColors[f])}`).join(",\n") +
  `,\n        )\n    }\n}\n\n` +
  `@Composable\nfun flareColors(): FlareColors =\n` +
  `    LocalFlareColors.current ?: if (isSystemInDarkTheme()) FlareColors.Dark else FlareColors.Light\n\n` +
  `private val LocalFlareColors = staticCompositionLocalOf<FlareColors?> { null }\n\n` +
  `/** Wrap the app with the same resolved dark flag as its MaterialTheme. */\n` +
  `@Composable\nfun FlareThemeProvider(dark: Boolean = isSystemInDarkTheme(), content: @Composable () -> Unit) {\n` +
  `    CompositionLocalProvider(LocalFlareColors provides if (dark) FlareColors.Dark else FlareColors.Light, content = content)\n}\n\n` +
  `/** Flare IM spacing / radius / font-size / line-height / layout tokens. */\n` +
  `object FlareSizes {\n` +
  sizeConsts.map(([n, v]) => `    val ${n}: Dp = ${v.replace(".0", "")}.dp`).join("\n") +
  `\n}\n`;

const kotlinTokens = join(
  here,
  "../android-im-ui/src/main/kotlin/com/flare/im/ui/FlareTokens.kt",
);
mkdirSync(dirname(kotlinTokens), { recursive: true });
const kotlinLayout = `
/** Shared logical-dp layout policy. Use the available container, excluding rail and insets. */
object FlareLayoutPolicy {
    fun paneCount(width: Float, hasDetail: Boolean = false, textScale: Float = 1f,
                  listWidth: Float = FlareSizes.leftPanel.value, detailWidth: Float = FlareSizes.rightPanel.value): Int {
        val chat = FlareSizes.chatMinWidth.value * textScale.coerceIn(1f, 2f)
        val list = listWidth.coerceAtLeast(0f)
        val detail = detailWidth.coerceAtLeast(0f)
        if (hasDetail && width >= FlareSizes.triplePaneMinWidth.value && width >= list + detail + chat + 2) return 3
        if (width >= FlareSizes.dualPaneMinWidth.value && width >= list + chat + 1) return 2
        return 1
    }
}
`;
writeFileSync(kotlinTokens, kotlin + kotlinLayout);

console.log(
  `@flare-im/tokens: generated dist/tokens.{css,ts,js,d.ts} (${lightVars.length} light + ${darkVars.length} dark vars)` +
    ` + Dart/Swift/Kotlin token files (${colorFields.length} colours × 2 themes, ${sizeConsts.length} sizes)`,
);

const layout = Object.fromEntries(Object.entries(src.sizes.layout).map(([k, v]) => [k, parseFloat(v)]));
writeFileSync(join(here, "../vue-im-ui/src/design-system/theme/layout-policy.ts"), `// GENERATED by tokens/build.mjs. Logical CSS pixels, measured inside the container.
export const flareLayout = ${JSON.stringify(layout, null, 2)} as const;
export function paneCount(width: number, hasDetail = false, textScale = 1,
  listWidth: number = flareLayout.leftPanel, detailWidth: number = flareLayout.rightPanel): number {
  const chat = flareLayout.chatMinWidth * Math.min(2, Math.max(1, textScale));
  const list = Math.max(0, listWidth), detail = Math.max(0, detailWidth);
  if (hasDetail && width >= flareLayout.triplePaneMinWidth && width >= list + detail + chat + 2) return 3;
  if (width >= flareLayout.dualPaneMinWidth && width >= list + chat + 1) return 2;
  return 1;
}
`);
