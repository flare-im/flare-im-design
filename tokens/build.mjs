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
const themeSource = JSON.parse(readFileSync(join(here, "themes.json"), "utf8"));
const dist = join(here, "dist");
mkdirSync(dist, { recursive: true });

const kebab = (k) => k.replace(/([a-z0-9])([A-Z])/g, "$1-$2").toLowerCase();

function deepMerge(base, override) {
  const result = structuredClone(base);
  for (const [key, value] of Object.entries(override ?? {})) {
    result[key] = value && typeof value === "object" && !Array.isArray(value)
      ? deepMerge(result[key] ?? {}, value)
      : value;
  }
  return result;
}

function pathValue(value, path) {
  return path.split(".").reduce((current, key) => current?.[key], value);
}

/** Recursively flatten semantic colors to [--flare-color-*, value]. */
function colorVars(colors, prefix = []) {
  const out = [];
  for (const [key, val] of Object.entries(colors)) {
    if (val && typeof val === "object") {
      out.push(...colorVars(val, [...prefix, key]));
    } else {
      out.push([`--flare-color-${[...prefix, key].map(kebab).join("-")}`, val]);
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
    iconSize: "icon-size",
  };
  const out = [];
  for (const [group, entries] of Object.entries(sizes)) {
    const p = groupPrefix[group] ?? kebab(group);
    for (const [key, v] of Object.entries(entries)) {
      // A text role is three values under one name: --flare-text-<role>-size / -line-height / -weight.
      if (group === "textRole") {
        for (const [field, value] of Object.entries(v)) out.push([`--flare-text-${kebab(key)}-${kebab(field)}`, value]);
        continue;
      }
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
  ...Object.entries(src.opacity).map(([k, v]) => [`--flare-opacity-${kebab(k)}`, v]),
  ...Object.entries(src.zIndex).map(([k, v]) => [`--flare-z-index-${kebab(k)}`, v]),
  ...Object.entries(src.breakpoints).map(([k, v]) => [`--flare-breakpoint-${kebab(k)}`, v]),
];
const darkVars = [
  ...colorVars(src.dark.colors),
  // dark-mode elevation overrides — light shadows use dark ink and vanish on a dark
  // canvas, so the dark theme ships its own violet-tinted, top-lit shadow set.
  ...Object.entries(src.dark.shadows ?? {}).map(([k, v]) => [`--flare-shadow-${kebab(k)}`, v]),
];

const themeNames = Object.keys(themeSource.themes);
const resolvedThemes = Object.fromEntries(themeNames.map((name) => {
  const theme = themeSource.themes[name];
  const light = deepMerge(
    deepMerge({ colors: src.colors }, themeSource.semanticDefaults.light),
    theme.light,
  );
  const darkBase = { colors: deepMerge(src.colors, src.dark.colors) };
  const dark = deepMerge(deepMerge(darkBase, themeSource.semanticDefaults.dark), theme.dark);
  for (const mode of ["light", "dark"]) {
    for (const path of themeSource.requiredSemanticPaths) {
      if (pathValue(mode === "light" ? light : dark, path) === undefined) {
        throw new Error(`theme ${name}.${mode} is missing ${path}`);
      }
    }
  }
  return [name, { label: theme.label, light, dark }];
}));

const block = (sel, vars) =>
  `${sel} {\n${vars.map(([k, v]) => `  ${k}: ${v};`).join("\n")}\n}`;

const themeLightCss = themeNames.map((name) =>
  block(`[data-flare-brand="${name}"]`, colorVars(resolvedThemes[name].light.colors)),
).join("\n\n");
const themeDarkCss = themeNames.map((name) =>
  block(`[data-flare-brand="${name}"][data-flare-theme="dark"]`, colorVars(resolvedThemes[name].dark.colors)),
).join("\n\n");
const css =
  `/* GENERATED. Do not edit by hand. Sources: tokens.json + themes.json */\n` +
  `${block(":root", lightVars)}\n\n${block('[data-flare-theme="dark"]', darkVars)}\n\n${themeLightCss}\n\n${themeDarkCss}\n`;

const banner = `// GENERATED. Do not edit by hand. Sources: @flare-im/tokens/tokens.json + themes.json\n`;
const runtimeTokens = { ...src, themeNames, themes: resolvedThemes };
const obj = JSON.stringify(runtimeTokens, null, 2);
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
// Dart target — emitted directly into the packages/flutter-im-ui package's source tree
// (pub can't consume an npm package, so the generated tokens are vendored there,
// same single source: tokens.json). Consumer landed → generator added, per policy.
// ---------------------------------------------------------------------------
const cap = (s) => s.charAt(0).toUpperCase() + s.slice(1);

// ── shadows / motion / opacity for the native emitters ───────────────────
/** "0 8px 28px rgba(…)" (comma-separated layers) → [{x,y,blur,spread,color}] ; "none" → [] */
function parseShadow(value) {
  if (!value || value.trim() === "none") return [];
  const layers = value.split(/,(?![^()]*\))/).map((l) => l.trim());
  return layers.map((layer) => {
    const color = layer.match(/rgba?\([^)]*\)|#[0-9a-fA-F]{3,8}/)?.[0] ?? "rgba(0,0,0,0.1)";
    const nums = layer.replace(color, "").trim().split(/\s+/).map((n) => parseFloat(n) || 0);
    const [x = 0, y = 0, blur = 0, spread = 0] = nums;
    return { x, y, blur, spread, color };
  });
}
/** "150ms cubic-bezier(0.22, 1, 0.36, 1)" → { ms, easing } */
function parseTransition(value) {
  const ms = parseFloat(value) || 0;
  const easing = value.replace(/^[\d.]+m?s\s*/, "").trim() || "ease";
  const bez = easing.match(/cubic-bezier\(([^)]+)\)/)?.[1].split(",").map((n) => parseFloat(n.trim()));
  return { ms, easing, bezier: bez ?? null };
}
const shadowLayersLight = Object.fromEntries(Object.entries(src.shadows).map(([k, v]) => [k, parseShadow(v)]));
const shadowLayersDark = { ...shadowLayersLight, ...Object.fromEntries(Object.entries(src.dark.shadows ?? {}).map(([k, v]) => [k, parseShadow(v)])) };
const motion = Object.fromEntries(Object.entries(src.transitions).map(([k, v]) => [k, parseTransition(v)]));
const opacityEntries = Object.entries(src.opacity).map(([k, v]) => [k, parseFloat(v)]);

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

/** Flat native field map from arbitrarily nested semantic color groups. */
function flattenColors(colors, prefix = "") {
  const out = {};
  for (const [key, val] of Object.entries(colors)) {
    const name = prefix ? prefix + cap(key) : key;
    if (val && typeof val === "object") {
      Object.assign(out, flattenColors(val, name));
    } else {
      out[name] = val;
    }
  }
  return out;
}

const lightColors = flattenColors(src.colors);
// dark has all fields: light merged with the dark overrides (dark.json is a subset)
const darkColors = { ...lightColors, ...flattenColors(src.dark.colors) };
const colorFields = Object.keys(lightColors);
const nativeThemes = Object.fromEntries(themeNames.map((name) => [name, {
  light: flattenColors(resolvedThemes[name].light.colors),
  dark: flattenColors(resolvedThemes[name].dark.colors),
}]));

const dartNum = (value) => {
  const n = parseFloat(value);
  return Number.isInteger(n) ? `${n}.0` : `${n}`;
};
const sizeConsts = [];
for (const [group, entries] of Object.entries(src.sizes)) {
  // textRole is a set of named roles (size + line height + weight), not a scalar scale: the platform
  // emitters below turn it into one value per role instead of three loose numbers.
  if (group === "textRole") continue;
  // fontWeight 只发 web。原生三端的权重已经在 FlareTextRole 里带着类型走了
  // (Swift 映射 Font.Weight、Kotlin 映射 FontWeight、Dart 拿 int),再生成一组
  // 裸 CGFloat / Float / double 的权重常量,是把一个已经对的 API 换成一个更差的。
  // web 这边没有别的出口:CSS 的 font-weight 只能收一个数,所以那边照发。
  if (group === "fontWeight") continue;
  for (const [key, v] of Object.entries(entries)) {
    // layout keys are already descriptive; others carry their group as prefix
    const name = group === "layout" ? key : group + cap(key);
    // 带上原始值:Kotlin 侧要靠它区分「尺寸(Dp)」和「无单位比例(Float)」。
    // 只看键名前缀不够 —— sizes.component 里既有 14px 也有 0.88 这种比例。
    sizeConsts.push([name, dartNum(v), String(v)]);
  }
}

/** The text roles, in the order the source declares them. */
const textRoles = Object.entries(src.sizes.textRole ?? {});
const roleNumber = (value) => parseFloat(value);

const dartBanner = `// GENERATED. Do not edit by hand. Sources: @flare-im/tokens/tokens.json + themes.json\n`;
const dartColorSet = (colors, indent = "    ") =>
  colorFields.map((f) => `${indent}${f}: ${dartColor(colors[f])},`).join("\n");
const dartThemeConstants = themeNames.flatMap((name) => ["light", "dark"].map((mode) =>
  `  static const FlareColors ${name}${cap(mode)} = FlareColors(\n${dartColorSet(nativeThemes[name][mode])}\n  );`,
)).join("\n\n");
const dartThemeSwitch = themeNames.map((name) =>
  `      FlareBrandTheme.${name} => brightness == Brightness.dark ? ${name}Dark : ${name}Light,`,
).join("\n");
const dart =
  dartBanner +
  `\nimport 'dart:ui' show Brightness, Color;\n\n` +
  `enum FlareBrandTheme { ${themeNames.join(", ")} }\n\n` +
  `/// Flare IM semantic colors resolved by brand and brightness.\n` +
  `class FlareColors {\n` +
  `  const FlareColors({\n` +
  colorFields.map((f) => `    required this.${f},`).join("\n") +
  `\n  });\n\n` +
  colorFields.map((f) => `  final Color ${f};`).join("\n") +
  `\n\n  FlareColors copyWith({\n` +
  colorFields.map((f) => `    Color? ${f},`).join("\n") +
  `\n  }) => FlareColors(\n` +
  colorFields.map((f) => `    ${f}: ${f} ?? this.${f},`).join("\n") +
  `\n  );` +
  `\n\n${dartThemeConstants}\n\n` +
  `  static const FlareColors light = violetLight;\n` +
  `  static const FlareColors dark = violetDark;\n\n` +
  `  static FlareColors resolve(Brightness brightness, {FlareBrandTheme brand = FlareBrandTheme.violet}) => switch (brand) {\n` +
  `${dartThemeSwitch}\n    };\n\n` +
  `  static FlareColors of(Object source, {FlareBrandTheme brand = FlareBrandTheme.violet}) {\n` +
  `    if (source is BuildContext) {\n` +
  `      final inherited = FlareTheme.maybeOf(source);\n` +
  `      final dark = flareThemeIsDark(\n` +
  `        inherited?.mode ?? FlareThemeMode.system,\n` +
  `        systemDark: flareSystemDark(source),\n` +
  `      );\n` +
  `      return inherited?.colors ?? resolve(dark ? Brightness.dark : Brightness.light, brand: inherited?.brand ?? brand);\n` +
  `    }\n` +
  `    return resolve(source as Brightness, brand: brand);\n` +
  `  }\n}\n\n` +
  `/// The theme a host asks for: [light] and [dark] are the person overriding the system, [system] follows it.\n` +
  `enum FlareThemeMode { light, dark, system }\n\n` +
  `/// Whether to draw dark (`+"`spec/theme-mode-vectors.json`"+`, the same rule on four kits).\n` +
  `bool flareThemeIsDark(FlareThemeMode mode, {required bool systemDark}) =>\n` +
  `    mode == FlareThemeMode.system ? systemDark : mode == FlareThemeMode.dark;\n\n` +
  `/// What the app itself is set to: the enclosing Material theme's brightness, which `+"`MaterialApp`"+` resolves from the\n` +
  `/// platform for `+"`ThemeMode.system`"+` and which a host (or a test) can set directly by wrapping in a `+"`Theme`"+`.\n` +
  `bool flareSystemDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;\n\n` +
  `/// The kit's theme for this subtree. [mode] is the person's choice, which the host holds and stores.\n` +
  `class FlareTheme extends InheritedWidget {\n` +
  `  const FlareTheme({\n` +
  `    super.key,\n` +
  `    this.brand = FlareBrandTheme.violet,\n` +
  `    this.mode = FlareThemeMode.system,\n` +
  `    this.colors,\n` +
  `    required super.child,\n` +
  `  });\n` +
  `  final FlareBrandTheme brand;\n` +
  `  final FlareThemeMode mode;\n` +
  `  final FlareColors? colors;\n` +
  `  static FlareTheme? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<FlareTheme>();\n` +
  `  @override\n  bool updateShouldNotify(FlareTheme oldWidget) => brand != oldWidget.brand || mode != oldWidget.mode || colors != oldWidget.colors;\n}\n\n` +
  `/// A named text role: what a title, a section header, body text or a caption is, in one place\n` +
  `/// (FR-051). Sizes are logical px; [weight] is the CSS weight the platform maps to its own.\n` +
  `class FlareTextRole {\n` +
  `  const FlareTextRole({required this.fontSize, required this.lineHeight, required this.weight});\n` +
  `  final double fontSize;\n` +
  `  final double lineHeight;\n` +
  `  final int weight;\n` +
  `}\n\n` +
  `/// Flare IM text roles.\n` +
  `abstract final class FlareTextRoles {\n` +
  textRoles.map(([name, role]) => `  static const FlareTextRole ${name} = FlareTextRole(fontSize: ${dartNum(role.fontSize)}, lineHeight: ${roleNumber(role.lineHeight)}, weight: ${roleNumber(role.weight)});`).join("\n") +
  `\n}\n\n` +
  `/// Flare IM spacing / radius / font-size / line-height / layout tokens (logical px).\n` +
  `abstract final class FlareSizes {\n` +
  sizeConsts.map(([n, v]) => `  static const double ${n} = ${v};`).join("\n") +
  `\n}\n`;

const flutterTokens = join(here, "../packages/flutter-im-ui/lib/src/tokens/flare_tokens.dart");
mkdirSync(dirname(flutterTokens), { recursive: true });
const dartPalette = `\n/// Const palette for const widget and ThemeData declarations.\nabstract final class FlarePalette {\n` +
  colorFields.map((f) => `  static const Color light${cap(f)} = ${dartColor(lightColors[f])};\n  static const Color dark${cap(f)} = ${dartColor(darkColors[f])};`).join("\n") +
  `\n}\n`;
const dartShadow = (l) => `BoxShadow(color: ${dartColor(l.color)}, offset: Offset(${l.x}, ${l.y}), blurRadius: ${l.blur}, spreadRadius: ${l.spread})`;
const dartExtras = `
/// Opacity tokens (disabled / muted / tint overlays).
abstract final class FlareOpacity {
${opacityEntries.map(([k, v]) => `  static const double ${k} = ${v};`).join("\n")}
}

/// Elevation tokens as [BoxShadow] lists; pick by [Brightness] with [FlareShadows.of].
class FlareShadows {
  const FlareShadows({${Object.keys(shadowLayersLight).map((k) => `required this.${k}`).join(", ")}});
${Object.keys(shadowLayersLight).map((k) => `  final List<BoxShadow> ${k};`).join("\n")}
  static const FlareShadows light = FlareShadows(
${Object.entries(shadowLayersLight).map(([k, ls]) => `    ${k}: [${ls.map(dartShadow).join(", ")}],`).join("\n")}
  );
  static const FlareShadows dark = FlareShadows(
${Object.entries(shadowLayersDark).map(([k, ls]) => `    ${k}: [${ls.map(dartShadow).join(", ")}],`).join("\n")}
  );
  static FlareShadows of(Brightness brightness) => brightness == Brightness.dark ? dark : light;
}

/// Motion tokens: durations and curves shared with the web transitions.
abstract final class FlareMotion {
${Object.entries(motion).map(([k, m]) => `  static const Duration ${k} = Duration(milliseconds: ${m.ms});\n  static const Curve ${k}Curve = ${m.bezier ? `Cubic(${m.bezier.join(", ")})` : "Cubic(0.4, 0.0, 0.2, 1.0)"};`).join("\n")}
}
`;
writeFileSync(flutterTokens, dart.replace(
  "import 'dart:ui' show Brightness, Color;",
  "import 'dart:ui' show Brightness, Color, Offset;\nimport 'package:flutter/animation.dart' show Curve, Cubic;\nimport 'package:flutter/material.dart' show Theme;\nimport 'package:flutter/painting.dart' show BoxShadow;\nimport 'package:flutter/widgets.dart' show BuildContext, InheritedWidget;",
) + dartPalette + dartExtras);

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

const swiftColorSet = (colors, indent = "        ") =>
  colorFields.map((f) => `${indent}${f}: ${swiftColor(colors[f])}`).join(",\n");
const swiftThemeConstants = themeNames.flatMap((name) => ["light", "dark"].map((mode) =>
  `    public static let ${name}${cap(mode)} = FlareColors(\n${swiftColorSet(nativeThemes[name][mode])}\n    )`,
)).join("\n\n");
const swift =
  `// GENERATED. Do not edit by hand. Sources: @flare-im/tokens/tokens.json + themes.json\n` +
  `import SwiftUI\n\n` +
  `public struct FlareBrandTheme: Hashable, Sendable, CaseIterable {\n` +
  `    public let name: String\n` +
  `    public let light: FlareColors\n` +
  `    public let dark: FlareColors\n\n` +
  `    public init(name: String, light: FlareColors, dark: FlareColors) {\n` +
  `        self.name = name\n        self.light = light\n        self.dark = dark\n    }\n\n` +
  themeNames.map((name) => `    public static let ${name} = FlareBrandTheme(name: "${name}", light: .${name}Light, dark: .${name}Dark)`).join("\n") +
  `\n\n    public static let allCases: [FlareBrandTheme] = [${themeNames.map((name) => `.${name}`).join(", ")}]\n` +
  `    public static func == (lhs: FlareBrandTheme, rhs: FlareBrandTheme) -> Bool { lhs.name == rhs.name }\n` +
  `    public func hash(into hasher: inout Hasher) { hasher.combine(name) }\n` +
  `}\n\n` +
  `private struct FlareBrandThemeKey: EnvironmentKey { static let defaultValue: FlareBrandTheme = .violet }\n` +
  `public extension EnvironmentValues {\n` +
  `    var flareBrandTheme: FlareBrandTheme {\n` +
  `        get { self[FlareBrandThemeKey.self] }\n` +
  `        set { self[FlareBrandThemeKey.self] = newValue }\n` +
  `    }\n}\n` +
  `/// The theme a host asks for: \`light\` and \`dark\` are the person overriding the system, \`system\` follows it.\n` +
  `public enum FlareThemeMode: String, Sendable, CaseIterable {\n` +
  `    case light, dark, system\n` +
  `}\n` +
  `\n` +
  `/// Whether to draw dark (\`spec/theme-mode-vectors.json\`, the same rule on four kits).\n` +
  `public func flareThemeIsDark(_ mode: FlareThemeMode, systemDark: Bool) -> Bool {\n` +
  `    mode == .system ? systemDark : mode == .dark\n` +
  `}\n` +
  `\n` +
  `public extension FlareThemeMode {\n` +
  `    /// The scheme to ask the window for (\`preferredColorScheme\`), so a host's status bar and system\n` +
  `    /// presentations follow the same choice the kit draws with. \`system\` asks for nothing.\n` +
  `    var colorScheme: ColorScheme? {\n` +
  `        switch self {\n` +
  `        case .system: return nil\n` +
  `        case .light: return .light\n` +
  `        case .dark: return .dark\n` +
  `        }\n` +
  `    }\n` +
  `}\n` +
  `\n` +
  `public extension View {\n` +
  `    /// The kit's theme for this subtree: the brand, and the colour scheme the person chose. \`system\` leaves the\n` +
  `    /// environment's own scheme alone, so the platform setting keeps deciding.\n` +
  `    func flareTheme(mode: FlareThemeMode = .system, brand: FlareBrandTheme = .violet) -> some View {\n` +
  `        environment(\\.flareBrandTheme, brand).modifier(FlareThemeScheme(mode: mode))\n` +
  `    }\n` +
  `}\n` +
  `\n` +
  `private struct FlareThemeScheme: ViewModifier {\n` +
  `    let mode: FlareThemeMode\n` +
  `\n` +
  `    func body(content: Content) -> some View {\n` +
  `        switch mode {\n` +
  `        case .system: content\n` +
  `        case .light: content.environment(\\.colorScheme, .light)\n` +
  `        case .dark: content.environment(\\.colorScheme, .dark)\n` +
  `        }\n` +
  `    }\n` +
  `}\n` +
  `\n` +
  `/// Flare IM semantic colors resolved by brand and color scheme.\n` +
  `public struct FlareColors: Sendable {\n` +
  colorFields.map((f) => `    public let ${f}: Color`).join("\n") +
  `\n\n    public init(\n` +
  colorFields.map((f) => `        ${f}: Color`).join(",\n") +
  `\n    ) {\n` +
  colorFields.map((f) => `        self.${f} = ${f}`).join("\n") +
  `\n    }\n\n` +
  `    public func copy(\n` +
  colorFields.map((f) => `        ${f}: Color? = nil`).join(",\n") +
  `\n    ) -> FlareColors {\n` +
  `        FlareColors(\n` +
  colorFields.map((f) => `            ${f}: ${f} ?? self.${f}`).join(",\n") +
  `\n        )\n    }` +
  `\n\n${swiftThemeConstants}\n\n` +
  `    public static let light = violetLight\n` +
  `    public static let dark = violetDark\n\n` +
  `    public static func of(_ scheme: ColorScheme, brand: FlareBrandTheme = .violet) -> FlareColors {\n` +
  `        scheme == .dark ? brand.dark : brand.light\n    }\n}\n\n` +
  `/// A named text role: what a title, a section header, body text or a caption is, in one place\n` +
  `/// (FR-051). Sizes are points; `+"`weight`"+` is the CSS weight, mapped to `+"`Font.Weight`"+` by `+"`font`"+`.\n` +
  `public struct FlareTextRole: Sendable {\n` +
  `    public let fontSize: CGFloat\n` +
  `    public let lineHeight: CGFloat\n` +
  `    public let weight: Int\n` +
  `    public var font: Font { .system(size: fontSize, weight: weight >= 700 ? .bold : weight >= 600 ? .semibold : weight >= 500 ? .medium : .regular) }\n` +
  `}\n\n` +
  `/// Flare IM text roles.\n` +
  `public enum FlareTextRoles {\n` +
  textRoles.map(([name, role]) => `    public static let ${name} = FlareTextRole(fontSize: ${roleNumber(role.fontSize)}, lineHeight: ${roleNumber(role.lineHeight)}, weight: ${roleNumber(role.weight)})`).join("\n") +
  `\n}\n\n` +
  `/// Flare IM spacing / radius / font-size / line-height / layout tokens (logical px).\n` +
  `public enum FlareSizes {\n` +
  sizeConsts.map(([n, v]) => `    public static let ${n}: CGFloat = ${v}`).join("\n") +
  `\n}\n`;

const swiftTokens = join(here, "../packages/ios-im-ui/Sources/FlareIMUI/Tokens/FlareTokens.swift");
mkdirSync(dirname(swiftTokens), { recursive: true });
const swiftShadow = (l) => `FlareShadowLayer(color: ${swiftColor(l.color)}, x: ${l.x}, y: ${l.y}, blur: ${l.blur})`;
const swiftExtras = `
/// Opacity tokens (disabled / muted / tint overlays).
public enum FlareOpacity {
${opacityEntries.map(([k, v]) => `    public static let ${k}: Double = ${v}`).join("\n")}
}

public struct FlareShadowLayer: Sendable {
    public let color: Color
    public let x: CGFloat
    public let y: CGFloat
    public let blur: CGFloat
}

/// Elevation tokens; apply every layer with \`.shadow(color:radius:x:y:)\`.
public struct FlareShadows: Sendable {
${Object.keys(shadowLayersLight).map((k) => `    public let ${k}: [FlareShadowLayer]`).join("\n")}
    public static let light = FlareShadows(
${Object.entries(shadowLayersLight).map(([k, ls]) => `        ${k}: [${ls.map(swiftShadow).join(", ")}]`).join(",\n")}
    )
    public static let dark = FlareShadows(
${Object.entries(shadowLayersDark).map(([k, ls]) => `        ${k}: [${ls.map(swiftShadow).join(", ")}]`).join(",\n")}
    )
    public static func of(_ scheme: ColorScheme) -> FlareShadows { scheme == .dark ? dark : light }
}

/// Motion tokens: durations (seconds) and animations shared with the web transitions.
public enum FlareMotion {
${Object.entries(motion).map(([k, m]) => `    public static let ${k}: Double = ${(m.ms / 1000).toFixed(3)}\n    public static var ${k}Animation: Animation { ${m.bezier ? `.timingCurve(${m.bezier.join(", ")}, duration: ${(m.ms / 1000).toFixed(3)})` : `.easeInOut(duration: ${(m.ms / 1000).toFixed(3)})`} }`).join("\n")}
}
`;
writeFileSync(swiftTokens, swift + swiftExtras);

// ---------------------------------------------------------------------------
// Compose (Kotlin) target — vendored into the flare-im-ui-compose module.
// ---------------------------------------------------------------------------
const composeColor = dartColor; // Kotlin androidx Color literal is also 0xAARRGGBB

const kotlinColorSet = (colors, indent = "            ") =>
  colorFields.map((f) => `${indent}${f} = ${composeColor(colors[f])}`).join(",\n");
const kotlinThemeConstants = themeNames.flatMap((name) => ["light", "dark"].map((mode) =>
  `        val ${cap(name)}${cap(mode)} = FlareColors(\n${kotlinColorSet(nativeThemes[name][mode])},\n        )`,
)).join("\n\n");
const kotlinThemeSwitch = themeNames.map((name) =>
  `        FlareBrandTheme.${cap(name)} -> if (dark) ${cap(name)}Dark else ${cap(name)}Light`,
).join("\n");
const kotlin =
  `// GENERATED. Do not edit by hand. Sources: @flare-im/tokens/tokens.json + themes.json\n` +
  `package com.flare.im.ui\n\n` +
  `import androidx.compose.runtime.Composable\nimport androidx.compose.runtime.CompositionLocalProvider\nimport androidx.compose.runtime.staticCompositionLocalOf\n` +
  `import androidx.compose.foundation.isSystemInDarkTheme\n` +
  `import androidx.compose.ui.graphics.Color\n` +
  `import androidx.compose.ui.unit.Dp\n` +
  `import androidx.compose.ui.unit.dp\n` +
  `import androidx.compose.ui.unit.TextUnit\n` +
  `import androidx.compose.ui.unit.sp\n` +
  `import androidx.compose.ui.text.font.FontWeight\n` +
  `import androidx.compose.ui.geometry.Offset\n` +
  `import androidx.compose.animation.core.CubicBezierEasing\n` +
  `import androidx.compose.animation.core.Easing\n\n` +
  `enum class FlareBrandTheme { ${themeNames.map(cap).join(", ")} }\n\n` +
  `/** Flare IM semantic colors resolved by brand and dark mode. */\n` +
  `data class FlareColors(\n` +
  colorFields.map((f) => `    val ${f}: Color`).join(",\n") +
  `,\n) {\n    companion object {\n${kotlinThemeConstants}\n\n` +
  `        val Light = VioletLight\n        val Dark = VioletDark\n\n` +
  `        fun resolve(brand: FlareBrandTheme, dark: Boolean): FlareColors = when (brand) {\n${kotlinThemeSwitch}\n        }\n    }\n}\n\n` +
  `@Composable\nfun flareColors(): FlareColors =\n` +
  `    LocalFlareColors.current ?: if (isSystemInDarkTheme()) FlareColors.Dark else FlareColors.Light\n\n` +
  `private val LocalFlareColors = staticCompositionLocalOf<FlareColors?> { null }\n\n` +
  `/** The theme a host asks for: [Light] and [Dark] are the person overriding the system, [System] follows it. */\n` +
  `enum class FlareThemeMode { Light, Dark, System }\n\n` +
  `/** Whether to draw dark (\`spec/theme-mode-vectors.json\`, the same rule on four kits). */\n` +
  `fun flareThemeIsDark(mode: FlareThemeMode, systemDark: Boolean): Boolean =\n` +
  `    if (mode == FlareThemeMode.System) systemDark else mode == FlareThemeMode.Dark\n\n` +
  `/**\n` +
  ` * Provides semantic Flare colors and their Material presentation from one theme. [mode] is the person's choice,\n` +
  ` * which the host holds and stores; the system setting answers for [FlareThemeMode.System].\n` +
  ` */\n` +
  `@Composable\nfun FlareThemeProvider(\n` +
  `    mode: FlareThemeMode = FlareThemeMode.System,\n` +
  `    brand: FlareBrandTheme = FlareBrandTheme.Violet,\n` +
  `    colors: FlareColors? = null,\n` +
  `    content: @Composable () -> Unit,\n` +
  `) {\n` +
  `    val dark = flareThemeIsDark(mode, isSystemInDarkTheme())\n` +
  `    val resolved = colors ?: FlareColors.resolve(brand, dark)\n` +
  `    CompositionLocalProvider(LocalFlareColors provides resolved) {\n` +
  `        androidx.compose.material3.MaterialTheme(\n` +
  `            colorScheme = flareMaterialColorScheme(resolved, dark),\n` +
  `            typography = flareMaterialTypography(),\n` +
  `            content = content,\n` +
  `        )\n    }\n}\n\n` +
  `/**\n` +
  ` * A named text role: what a title, a section header, body text or a caption is, in one place\n` +
  ` * (FR-051). [fontSize] is sp, [weight] the CSS weight mapped to a [FontWeight] by [fontWeight].\n` +
  ` */\n` +
  `data class FlareTextRole(val fontSize: TextUnit, val lineHeight: Float, val weight: Int) {\n` +
  `    val fontWeight: FontWeight get() = FontWeight(weight)\n` +
  `}\n\n` +
  `/** Flare IM text roles. */\n` +
  `object FlareTextRoles {\n` +
  textRoles.map(([name, role]) => `    val ${cap(name)} = FlareTextRole(${roleNumber(role.fontSize)}.sp, ${roleNumber(role.lineHeight)}f, ${roleNumber(role.weight)})`).join("\n") +
  `\n}\n\n` +
  `/** Flare IM spacing / radius / font-size / line-height / layout tokens. */\n` +
  `object FlareSizes {\n` +
  sizeConsts.map(([n, v, raw]) => {
    const plain = v.replace(".0", "");
    if (n.startsWith("fontSize")) return `    val ${n}: TextUnit = ${plain}.sp`;
    // 无单位的源值(1.5、0.88…)是比例,不是尺寸:出 Float。以前只特判 lineHeight 前缀,
    // 于是 sizes.component 里的比例被生成成 `0.88.dp`,编译过得去但语义是错的。
    if (!/px$/.test(raw)) return `    const val ${n}: Float = ${v}f`;
    return `    val ${n}: Dp = ${plain}.dp`;
  }).join("\n") +
  `\n}\n`;

const kotlinTokens = join(
  here,
  "../packages/android-im-ui/src/main/kotlin/com/flare/im/ui/FlareTokens.kt",
);
mkdirSync(dirname(kotlinTokens), { recursive: true });
const ktShadow = (l) => `FlareShadowLayer(color = ${composeColor(l.color)}, offset = Offset(${l.x}f, ${l.y}f), blur = ${l.blur}.dp)`;
const kotlinExtras = `
/** Opacity tokens (disabled / muted / tint overlays). */
object FlareOpacity {
${opacityEntries.map(([k, v]) => `    const val ${k}: Float = ${v}f`).join("\n")}
}

data class FlareShadowLayer(val color: Color, val offset: Offset, val blur: Dp)

/** Elevation tokens; theme-aware via [flareShadows]. */
data class FlareShadows(
${Object.keys(shadowLayersLight).map((k) => `    val ${k}: List<FlareShadowLayer>`).join(",\n")},
) {
    companion object {
        val Light = FlareShadows(
${Object.entries(shadowLayersLight).map(([k, ls]) => `            ${k} = listOf(${ls.map(ktShadow).join(", ")})`).join(",\n")},
        )
        val Dark = FlareShadows(
${Object.entries(shadowLayersDark).map(([k, ls]) => `            ${k} = listOf(${ls.map(ktShadow).join(", ")})`).join(",\n")},
        )
    }
}

@Composable
fun flareShadows(): FlareShadows = if (flareColors() == FlareColors.Dark) FlareShadows.Dark else FlareShadows.Light

/** Motion tokens: durations (ms) and easings shared with the web transitions. */
object FlareMotion {
${Object.entries(motion).map(([k, m]) => `    const val ${k}: Int = ${m.ms}\n    val ${k}Easing: Easing = ${m.bezier ? `CubicBezierEasing(${m.bezier.map((n) => n + "f").join(", ")})` : "CubicBezierEasing(0.4f, 0f, 0.2f, 1f)"}`).join("\n")}
}
`;
writeFileSync(kotlinTokens, kotlin + kotlinExtras);

console.log(
  `@flare-im/tokens: generated dist/tokens.{css,ts,js,d.ts} (${lightVars.length} light + ${darkVars.length} dark vars)` +
    ` + Dart/Swift/Kotlin token files (${colorFields.length} colors × ${themeNames.length} brands × 2 modes, ${sizeConsts.length} sizes)`,
);

// ── 对比度与暗色完备性门禁 ────────────────────────────────────────────────
// 暗色 primary 曾复用亮色值,在暗底上 2.66:1;这里把 WCAG AA 断言写死在生成器里。
{
  const toRgb = (v) => {
    v = v.trim();
    if (v.startsWith("#")) { const h = v.slice(1); const rgb = h.length === 3 ? h.split("").map((c) => c + c).join("") : h; return [0, 2, 4].map((i) => parseInt(rgb.slice(i, i + 2), 16)).concat(1); }
    const m = v.match(/rgba?\(([^)]+)\)/); if (!m) throw new Error(`bad colour ${v}`);
    const p = m[1].split(",").map((x) => parseFloat(x)); return [p[0], p[1], p[2], p[3] ?? 1];
  };
  const over = (fg, bg) => { const a = fg[3]; return [0, 1, 2].map((i) => fg[i] * a + bg[i] * (1 - a)); };
  const lum = ([r, g, b]) => { const f = (c) => { c /= 255; return c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4; }; return 0.2126 * f(r) + 0.7152 * f(g) + 0.0722 * f(b); };
  const ratio = (fg, bg) => { const b = toRgb(bg).slice(0, 3); const f = over(toRgb(fg), b); const [l1, l2] = [lum(f), lum(b)]; return (Math.max(l1, l2) + 0.05) / (Math.min(l1, l2) + 0.05); };
  const fails = [];
  const check = (scheme, colors) => {
    const text = [["text.primary", colors.text.primary], ["text.secondary", colors.text.secondary], ["text.link", colors.text.link], ["text.linkHover", colors.text.linkHover], ["primaryText", colors.primaryText], ["successText", colors.successText], ["warningText", colors.warningText], ["errorText", colors.errorText], ["infoText", colors.infoText]];
    for (const [name, fg] of text) for (const bgName of ["primary", "secondary"]) {
      const r = ratio(fg, colors.bg[bgName]);
      if (r < 4.5) fails.push(`${scheme}: ${name} on bg.${bgName} = ${r.toFixed(2)}:1 (< 4.5)`);
    }
    for (const fill of ["primary", "success", "warning", "error", "info"]) {
      const r = ratio("#FFFFFF", colors[fill]);
      if (r < 3) fails.push(`${scheme}: white on ${fill} fill = ${r.toFixed(2)}:1 (< 3.0 for large text / icons)`);
    }
    const outgoing = ratio(colors.message.outgoing.foreground, colors.message.outgoing.background);
    if (outgoing < 4.5) fails.push(`${scheme}: message.outgoing foreground = ${outgoing.toFixed(2)}:1 (< 4.5)`);
  };
  check("light", lightColors && src.colors);
  const darkMerged = JSON.parse(JSON.stringify(src.colors));
  const deepMerge = (a, b) => { for (const k of Object.keys(b)) a[k] = b[k] && typeof b[k] === "object" && !Array.isArray(b[k]) ? deepMerge(a[k] ?? {}, b[k]) : b[k]; return a; };
  deepMerge(darkMerged, src.dark.colors);
  check("dark", darkMerged);
  for (const name of themeNames) {
    for (const mode of ["light", "dark"]) {
      const colors = resolvedThemes[name][mode].colors;
      const message = colors.message;
      const pairs = [
        ["incoming", message.incoming.foreground, message.incoming.background, 4.5],
        ["outgoing", message.outgoing.foreground, message.outgoing.background, 4.5],
        ["failed", message.failed.foreground, message.failed.background, 4.5],
        ["meta", message.meta.foreground, message.incoming.background, 4.5],
        ["read", message.status.read, message.incoming.background, 3],
        ["readOnOutgoing", message.status.readOnOutgoing, message.outgoing.background, 3],
        ["selectedBorder", message.selected.border, message.selected.background, 3],
      ];
      for (const [label, fg, bg, minimum] of pairs) {
        const value = ratio(fg, bg);
        if (value < minimum) fails.push(`${name}.${mode}: message.${label} = ${value.toFixed(2)}:1 (< ${minimum})`);
      }
    }
  }
  // 暗色完备性:语义色必须在 dark 里显式给值,不能靠继承亮色
  for (const k of ["primary", "primaryHover", "primaryActive", "primaryText", "success", "successText", "warning", "warningText", "error", "errorText", "info", "infoText", "important", "pinned", "robot"])
    if (src.dark.colors[k] === undefined) fails.push(`dark.colors.${k} is missing — it would inherit the light value`);
  if (src.dark.colors.text?.linkHover === undefined) fails.push("dark.colors.text.linkHover is missing");
  if (fails.length) { console.error("✗ token contrast / completeness:"); for (const f of fails) console.error("  - " + f); process.exitCode = 1; }
}

const layout = Object.fromEntries(Object.entries(src.sizes.layout).map(([k, v]) => [k, parseFloat(v)]));
// The pane rule is not generated: it lives in the application contract of each kit and is tested against
// spec/application-layout-vectors.json. Only the numbers it reads come from here.
writeFileSync(join(here, "../packages/vue-im-ui/src/design-system/theme/layout-tokens.ts"), `// GENERATED by tokens/build.mjs. Logical CSS pixels, measured inside the container.
export const flareLayout = ${JSON.stringify(layout, null, 2)} as const;
`);
