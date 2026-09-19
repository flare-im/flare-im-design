#!/usr/bin/env node
import { readFileSync } from "node:fs";
import { dirname, join, relative, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { loadSurface, vueExportMap } from "../spec/signatures.mjs";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const spec = JSON.parse(readFileSync(join(root, "spec/components.json"), "utf8"));
const vueExports = vueExportMap(join(root, "packages/vue-im-ui/src"));
const roots = {
  vueExports,
  flutter: join(root, "packages/flutter-im-ui/lib"),
  ios: join(root, "packages/ios-im-ui/Sources"),
  compose: join(root, "packages/android-im-ui/src/main"),
};
const flutterFacadePath = join(root, "packages/flutter-im-ui/lib/flare_im_ui.dart");
function dartExportClosure(entry, seen = new Set()) {
  if (seen.has(entry)) return seen;
  seen.add(entry);
  const source = readFileSync(entry, "utf8");
  for (const match of source.matchAll(/export\s+['"]([^'"]+)['"]/g)) {
    const target = resolve(dirname(entry), match[1]);
    dartExportClosure(target, seen);
  }
  return seen;
}
const flutterExports = dartExportClosure(flutterFacadePath);
const errors = [];
let checked = 0;

for (const component of spec.components) {
  for (const platform of ["vue", "flutter", "compose", "ios"]) {
    const contract = component.platforms?.[platform];
    if (!contract) continue;
    const surface = loadSurface(roots, component, platform);
    if (!surface?.file) {
      errors.push(`${component.name}/${platform}: public surface not found`);
      continue;
    }
    const source = readFileSync(surface.file, "utf8");
    if (platform === "vue" && !Object.values(vueExports).includes(surface.file)) {
      errors.push(`${component.name}/vue: ${contract.symbol} is not reachable from the component facade`);
    }
    if (platform === "flutter") {
      const exportPath = relative(join(root, "packages/flutter-im-ui/lib"), surface.file).replaceAll("\\", "/");
      if (!flutterExports.has(surface.file)) errors.push(`${component.name}/flutter: ${exportPath} is not reachable from flare_im_ui.dart`);
    }
    if (platform === "compose" && new RegExp(`\\b(?:private|internal)\\s+(?:fun|class|object)\\s+${contract.symbol}\\b`).test(source)) {
      errors.push(`${component.name}/compose: ${contract.symbol} is private/internal`);
    }
    if (platform === "ios" && !new RegExp(`\\bpublic\\s+(?:struct|class|enum|protocol|func|typealias)\\s+${contract.symbol}\\b`).test(source)) {
      errors.push(`${component.name}/ios: ${contract.symbol} is not declared public`);
    }
    checked += 1;
  }
}

if (errors.length) {
  console.error("public export violations:");
  for (const error of errors) console.error(`  ${error}`);
  process.exit(1);
}
console.log(`public export check passed: ${checked} platform component surfaces`);
