#!/usr/bin/env node
// browser baseline — the Vue package promises a minimum browser in two places (`package.json`'s
// browserslist and COMPATIBILITY.md), and the CSS quietly decides another one. On 2026-09-18 the
// promise was Chrome 87 / Edge 88 / Firefox 78 / Safari 14 while the styles used `color-mix()` 213
// times, with no `@supports` guard and no fallback declaration anywhere: on a promised browser those
// declarations are dropped, so borders and backgrounds simply vanish (FR-152).
//
// This gate reads the features the styles actually use and holds the promise to them: a feature may
// be used only when the declared floor is at or above what it needs, in every declared engine. The
// table below is the contract — adding a feature to the CSS means adding it here with its floor
// (caniuse), and raising the promise if it is higher than what is written down.
import { readFileSync, readdirSync, statSync } from "node:fs";
import { dirname, extname, join, relative } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const packageFile = join(root, "packages/vue-im-ui/package.json");
const compatibilityFile = join(root, "COMPATIBILITY.md");

/**
 * What each CSS feature needs, per engine (caniuse; the version the feature shipped unprefixed).
 *
 * `progressive` marks a feature whose absence changes nothing a person needs — the scrollbar still
 * scrolls, the surface still has its background — and which is written with its own fallback beside
 * it. Those are reported, not enforced. Everything else is load-bearing: without it a box collapses
 * or a colour disappears, so the promise has to cover it.
 */
const FEATURES = [
  { id: "color-mix()", test: /color-mix\(/, floors: { Chrome: 111, Edge: 111, Firefox: 113, Safari: 16.2 } },
  { id: "container queries", test: /@container|container-type\s*:/, floors: { Chrome: 105, Edge: 105, Firefox: 110, Safari: 16 } },
  { id: ":has()", test: /:has\(/, floors: { Chrome: 105, Edge: 105, Firefox: 121, Safari: 15.4 } },
  { id: "aspect-ratio", test: /aspect-ratio\s*:/, floors: { Chrome: 88, Edge: 88, Firefox: 89, Safari: 15 } },
  { id: "inset-inline / inset-block", test: /inset-(?:inline|block)/, floors: { Chrome: 87, Edge: 87, Firefox: 63, Safari: 14.1 } },
  { id: "overscroll-behavior-inline", test: /overscroll-behavior-(?:inline|block)/, floors: { Chrome: 87, Edge: 87, Firefox: 73, Safari: 16 } },
  // Every blur sits on its own background, so an engine without it shows the surface, not a hole.
  { id: "backdrop-filter", test: /backdrop-filter\s*:/, floors: { Chrome: 87, Edge: 87, Firefox: 103, Safari: 14 }, progressive: true },
  // Always written beside `::-webkit-scrollbar { display: none }`; without either the bar is visible, nothing else.
  { id: "scrollbar-width", test: /scrollbar-width\s*:/, floors: { Chrome: 121, Edge: 121, Firefox: 64, Safari: 18.2 }, progressive: true },
  { id: "text-wrap: balance", test: /text-wrap\s*:\s*balance/, floors: { Chrome: 114, Edge: 114, Firefox: 121, Safari: 17.5 } },
  // 这两条补的是「用户要求更强对比」时的轮廓。引擎不认得它们，也就没有那个模式可补 ——
  // 页面落回默认画法，没有任何东西塌掉，所以是 progressive。
  // The batch toolbar's pinned exit key: without sticky it scrolls away with the strip, so it is load-bearing.
  { id: "position: sticky", test: /position\s*:\s*sticky/, floors: { Chrome: 56, Edge: 16, Firefox: 59, Safari: 13 } },
  { id: "scroll-padding-inline / -block", test: /scroll-padding-(?:inline|block)/, floors: { Chrome: 69, Edge: 79, Firefox: 68, Safari: 15 } },
  { id: "padding-inline / margin-inline", test: /(?:padding|margin)-(?:inline|block)(?:-start|-end)?\s*:/, floors: { Chrome: 87, Edge: 87, Firefox: 66, Safari: 14.1 } },
  { id: "forced-colors", test: /@media[^{]*forced-colors\s*:/, floors: { Chrome: 89, Edge: 89, Firefox: 89, Safari: 14.1 }, progressive: true },
  { id: "prefers-contrast", test: /@media[^{]*prefers-contrast\s*:/, floors: { Chrome: 96, Edge: 96, Firefox: 101, Safari: 14.1 }, progressive: true },
];

/** Where the styles live: the Vue package's own sources and the generated token stylesheet. */
const STYLE_ROOTS = ["packages/vue-im-ui/src", "tokens/dist"];
const STYLE_EXTENSIONS = new Set([".css", ".vue"]);

function styleFiles(path, out = []) {
  for (const entry of readdirSync(path)) {
    if (["node_modules", "dist", "build", ".cache"].includes(entry)) continue;
    const absolute = join(path, entry);
    if (statSync(absolute).isDirectory()) styleFiles(absolute, out);
    else if (STYLE_EXTENSIONS.has(extname(entry))) out.push(absolute);
  }
  return out;
}

/** Prose is not CSS: a comment that names a feature must not count as using it. */
function withoutComments(text) {
  return text.replace(/\/\*[\s\S]*?\*\//g, " ").replace(/(^|\s)\/\/[^\n]*/g, "$1 ");
}

const files = STYLE_ROOTS.flatMap((relativeRoot) => styleFiles(join(root, relativeRoot)));
const used = new Map();
for (const file of files) {
  const text = withoutComments(readFileSync(file, "utf8"));
  for (const feature of FEATURES) {
    if (!feature.test.test(text)) continue;
    const seen = used.get(feature.id) ?? { feature, files: [], uses: 0 };
    seen.files.push(relative(root, file));
    seen.uses += text.match(new RegExp(feature.test.source, "g"))?.length ?? 1;
    used.set(feature.id, seen);
  }
}

const declared = JSON.parse(readFileSync(packageFile, "utf8")).browserslist ?? [];
const promise = new Map();
for (const entry of declared) {
  const match = /^([A-Za-z ]+?)\s*>=\s*([\d.]+)$/.exec(entry.trim());
  if (!match) {
    console.error(`browser baseline: browserslist entry "${entry}" is not "<Engine> >= <version>"`);
    process.exit(1);
  }
  promise.set(match[1].trim(), Number(match[2]));
}

const errors = [];
const progressive = [];
for (const { feature, files: where, uses } of used.values()) {
  if (feature.progressive) { progressive.push(`${feature.id} (${uses})`); continue; }
  for (const [engine, floor] of Object.entries(feature.floors)) {
    const promised = promise.get(engine);
    if (promised === undefined) {
      errors.push(`${feature.id}: browserslist does not mention ${engine}, which the feature needs from ${floor}`);
      continue;
    }
    if (promised < floor) {
      errors.push(
        `${feature.id} (${uses} uses, e.g. ${where[0]}): needs ${engine} ${floor}, but the package promises ${engine} ${promised}`,
      );
    }
  }
}

// The same promise is printed for humans in COMPATIBILITY.md; the two must not drift.
const compatibility = readFileSync(compatibilityFile, "utf8");
const printed = [...promise.entries()].map(([engine, version]) => `${engine} ${version}`);
for (const line of printed) {
  if (!compatibility.includes(line)) errors.push(`COMPATIBILITY.md does not say "${line}", which package.json promises`);
}

if (errors.length) {
  console.error(`browser baseline check failed (${relative(root, packageFile)}):\n  ${errors.join("\n  ")}`);
  console.error(`\n  A promised browser that cannot run the CSS is worse than a higher floor: the declarations`);
  console.error(`  are dropped silently, so a border or a background simply disappears. Raise the floor, or`);
  console.error(`  guard the feature with @supports and a fallback declaration.`);
  process.exit(1);
}
const floors = [...promise.entries()].map(([engine, version]) => `${engine} ${version}`).join(", ");
const enforced = used.size - progressive.length;
console.log(
  `browser baseline passed: ${enforced} load-bearing CSS features in use, all within ${floors}` +
    (progressive.length ? `; progressive, with their own fallback: ${progressive.join(", ")}` : ""),
);
