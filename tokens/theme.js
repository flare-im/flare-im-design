// Flare IM design tokens — runtime theming.
//
// Framework-agnostic. Lets a product customise the palette at runtime and scope
// it to any element subtree — "import and use", fully composable:
//
//   import { applyFlareTheme, deriveFlareTheme, flarePresets } from "@flare-im/tokens/theme";
//   applyFlareTheme(deriveFlareTheme({ primary: "#2563EB" }));   // whole page
//   applyFlareTheme(flarePresets.forest, myElement);             // one subtree
//
// Overrides map to the same CSS custom properties the generated tokens.css
// defines (`--flare-color-*`), so they cascade over the base theme.

// ---------- colour math ----------
function hexToRgb(hex) {
  let h = hex.replace("#", "").trim();
  if (h.length === 3) h = h.split("").map((c) => c + c).join("");
  return [parseInt(h.slice(0, 2), 16), parseInt(h.slice(2, 4), 16), parseInt(h.slice(4, 6), 16)];
}
function rgbToHex(r, g, b) {
  const c = (n) => Math.max(0, Math.min(255, Math.round(n))).toString(16).padStart(2, "0");
  return `#${c(r)}${c(g)}${c(b)}`.toUpperCase();
}
function rgbToHsl([r, g, b]) {
  r /= 255; g /= 255; b /= 255;
  const max = Math.max(r, g, b), min = Math.min(r, g, b);
  let h = 0, s = 0; const l = (max + min) / 2;
  if (max !== min) {
    const d = max - min;
    s = l > 0.5 ? d / (2 - max - min) : d / (max + min);
    switch (max) {
      case r: h = (g - b) / d + (g < b ? 6 : 0); break;
      case g: h = (b - r) / d + 2; break;
      default: h = (r - g) / d + 4;
    }
    h /= 6;
  }
  return [h * 360, s * 100, l * 100];
}
function hslToHex(h, s, l) {
  h /= 360; s /= 100; l /= 100;
  const hue = (p, q, t) => {
    if (t < 0) t += 1;
    if (t > 1) t -= 1;
    if (t < 1 / 6) return p + (q - p) * 6 * t;
    if (t < 1 / 2) return q;
    if (t < 2 / 3) return p + (q - p) * (2 / 3 - t) * 6;
    return p;
  };
  let r, g, b;
  if (s === 0) { r = g = b = l; }
  else {
    const q = l < 0.5 ? l * (1 + s) : l + s - l * s;
    const p = 2 * l - q;
    r = hue(p, q, h + 1 / 3); g = hue(p, q, h); b = hue(p, q, h - 1 / 3);
  }
  return rgbToHex(r * 255, g * 255, b * 255);
}
/** shift lightness by delta percentage points (negative = darken). */
function shade(hex, delta) {
  const [h, s, l] = rgbToHsl(hexToRgb(hex));
  return hslToHex(h, s, Math.max(0, Math.min(100, l + delta)));
}
/** mix a colour toward a target (default white) by weight 0..1. */
function mix(hex, weight, target = "#FFFFFF") {
  const a = hexToRgb(hex), b = hexToRgb(target);
  return rgbToHex(
    a[0] + (b[0] - a[0]) * weight,
    a[1] + (b[1] - a[1]) * weight,
    a[2] + (b[2] - a[2]) * weight,
  );
}

/**
 * Derive a complete Flare colour override from one (or a few) brand colours.
 * @param {{primary:string, success?:string, warning?:string, error?:string, info?:string}} opts
 * @returns {Record<string,string>} override map keyed by the css-var suffix after `--flare-color-`
 */
export function deriveFlareTheme(opts) {
  const p = opts.primary;
  const out = {
    "primary": p,
    "primary-hover": shade(p, -6),
    "primary-active": shade(p, -14),
    "bubble-self": p,
    "bubble-other": mix(p, 0.9),
    "bubble-robot": mix(p, 0.93),
    "text-link": p,
    "text-link-hover": shade(p, -8),
    "pinned": p,
    "border-selected": p,
    "bg-selected": mix(p, 0.92),
  };
  for (const k of ["success", "warning", "error", "info"]) {
    if (opts[k]) out[k] = opts[k];
  }
  return out;
}

/** override map → { "--flare-color-<suffix>": value } */
export function flareThemeVars(overrides) {
  const vars = {};
  for (const [k, v] of Object.entries(overrides)) {
    // allow either kebab suffixes ("bubble-self") or css-var names already
    const name = k.startsWith("--") ? k : `--flare-color-${k}`;
    vars[name] = v;
  }
  return vars;
}

/**
 * Apply an override map as inline CSS variables on an element (default the
 * document root). Scope a theme to a subtree by passing that subtree's element.
 */
export function applyFlareTheme(overrides, el) {
  const target = el || (typeof document !== "undefined" ? document.documentElement : null);
  if (!target) return;
  const vars = flareThemeVars(overrides);
  for (const [k, v] of Object.entries(vars)) target.style.setProperty(k, v);
}

/** Ready-made brand themes, each derived from one primary. Compose or extend freely. */
export const flarePresets = {
  violet: deriveFlareTheme({ primary: "#7C3AED" }),
  ocean: deriveFlareTheme({ primary: "#2563EB" }),
  forest: deriveFlareTheme({ primary: "#16A34A" }),
  sunset: deriveFlareTheme({ primary: "#EA580C" }),
  rose: deriveFlareTheme({ primary: "#E11D48" }),
  graphite: deriveFlareTheme({ primary: "#475569" }),
};

export const flareColorMath = { shade, mix };
