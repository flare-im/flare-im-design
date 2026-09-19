#!/usr/bin/env node
// 打印四端签名与契约的差异；`--baseline` 写 signature-baseline.json；`--component X` 只看一个。
import { readFileSync, writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";
import { PLATFORMS, vueExportMap, loadSurface, compareComponent } from "./signatures.mjs";
const here = dirname(fileURLToPath(import.meta.url));
const spec = JSON.parse(readFileSync(join(here, "components.json"), "utf8"));
const roots = {
  vueExports: vueExportMap(join(here, "../packages/vue-im-ui/src")),
  flutter: join(here, "../packages/flutter-im-ui/lib"),
  ios: join(here, "../packages/ios-im-ui/Sources"),
  compose: join(here, "../packages/android-im-ui/src/main"),
};
const args = process.argv.slice(2);
const only = args.includes("--component") ? args[args.indexOf("--component") + 1] : null;
const verbose = args.includes("--verbose") || !!only;
const result = {};
const totals = {};
for (const c of spec.components) {
  if (only && c.name !== only) continue;
  for (const p of PLATFORMS) {
    if (!c.platforms?.[p]) continue;
    const surface = loadSurface(roots, c, p);
    totals[p] ??= { components: 0, noSurface: 0, missingProps: 0, missingEvents: 0, extraEvents: 0 };
    totals[p].components++;
    if (!surface) { totals[p].noSurface++; (result[c.name] ??= {})[p] = { noSurface: true }; continue; }
    const d = compareComponent(spec, c, p, surface);
    totals[p].missingProps += d.missingProps.length;
    totals[p].missingEvents += d.missingEvents.length;
    totals[p].extraEvents += d.extraEvents.length;
    if (d.missingProps.length || d.missingEvents.length || d.extraEvents.length) (result[c.name] ??= {})[p] = d;
    if (verbose) console.log(c.name, p, "props:", [...surface.props].join(","), "| events:", [...surface.events].join(","), "\n   →", JSON.stringify(d));
  }
}
console.log(JSON.stringify(totals, null, 1));
if (args.includes("--baseline")) {
  writeFileSync(join(here, "signature-baseline.json"), JSON.stringify(result, null, 2) + "\n");
  console.log("baseline written:", Object.keys(result).length, "components");
}
if (args.includes("--json")) console.log(JSON.stringify(result, null, 1));
