#!/usr/bin/env node
import { existsSync, readdirSync, readFileSync, statSync } from "node:fs";
import { dirname, join, normalize, relative, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { loadSurface, vueExportMap } from "../spec/signatures.mjs";

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, "..");
const spec = JSON.parse(readFileSync(join(root, "spec/components.json"), "utf8"));
const layers = JSON.parse(readFileSync(join(root, "spec/component-layers.json"), "utf8"));
const order = new Map(layers.dependencyDirection.map((layer, index) => [layer, index]));
const errors = [];

for (const component of spec.components) {
  if (!layers.components[component.name]) errors.push(`missing layer: ${component.name}`);
}
for (const name of Object.keys(layers.components)) {
  if (!spec.components.some((component) => component.name === name)) {
    errors.push(`stale layer entry: ${name}`);
  }
}
for (const [layer, dependencies] of Object.entries(layers.allowedDependencies)) {
  for (const dependency of dependencies) {
    if (!order.has(dependency) || order.get(dependency) >= order.get(layer)) {
      errors.push(`invalid dependency direction: ${layer} -> ${dependency}`);
    }
  }
}

const roots = {
  vueExports: vueExportMap(join(root, "packages/vue-im-ui/src")),
  flutter: join(root, "packages/flutter-im-ui/lib"),
  ios: join(root, "packages/ios-im-ui/Sources"),
  compose: join(root, "packages/android-im-ui/src/main"),
};

const forbiddenGeneralDependencies = {
  vue: [/@flare-im\/sdk/, /shared\/contracts\/message-lifecycle/, /components\/messages\//],
  flutter: [/flare_im_sdk/, /models\/message_(?:data|lifecycle)/, /components\/flare_message_/],
  compose: [/com\.flare\.im\.sdk/, /FlareMessageLifecycle/, /MessageBubble\(/],
  ios: [/import FlareIMCore/, /FlareMessageLifecycle/, /MessageBubbleView/],
};

for (const platform of ["vue", "flutter", "compose", "ios"]) {
  const fileLayers = new Map();
  for (const component of spec.components) {
    if (!component.platforms?.[platform]) continue;
    const surface = loadSurface(roots, component, platform);
    if (surface) fileLayers.set(normalize(surface.file), layers.components[component.name]);
  }
  for (const [file, ownerLayer] of fileLayers) {
    if (ownerLayer !== "general-ui") continue;
    const source = readFileSync(file, "utf8");
    for (const pattern of forbiddenGeneralDependencies[platform]) {
      if (pattern.test(source)) errors.push(`${platform}: ${file} (${ownerLayer}) references an IM/SDK dependency`);
    }
    if (platform !== "vue" && platform !== "flutter") continue;
    for (const match of source.matchAll(/(?:from\s+|import\s+)["'](\.[^"']+)["']/g)) {
      const base = resolve(dirname(file), match[1]);
      const target = [base, `${base}.vue`, `${base}.dart`, join(base, "index.vue")]
        .find((candidate) => existsSync(candidate));
      if (!target) continue;
      const targetLayer = fileLayers.get(normalize(target));
      if (targetLayer && order.get(targetLayer) > order.get(ownerLayer)) {
        errors.push(`${platform}: ${file} (${ownerLayer}) imports ${target} (${targetLayer})`);
      }
    }
  }
}

// One icon set. The kit renders Lucide through `shared/icon-glyphs`, a shim that
// keeps the ionicons5 NAMES as the call-site vocabulary. An `@vicons/*` import
// anywhere in kit source drags a second glyph library into every consumer's
// bundle for the sake of a handful of icons — and draws them in the other style.
const iconImport = /(?:from|import|require\()\s*["']@vicons\/[^"']+["']/;
function vueSources(directory) {
  const out = [];
  for (const entry of readdirSync(directory)) {
    const path = join(directory, entry);
    if (statSync(path).isDirectory()) out.push(...vueSources(path));
    else if (entry.endsWith(".vue") || entry.endsWith(".ts")) out.push(path);
  }
  return out;
}
let iconShimImports = 0;
for (const file of vueSources(join(root, "packages/vue-im-ui/src"))) {
  const source = readFileSync(file, "utf8");
  if (source.includes('shared/icon-glyphs"')) iconShimImports += 1;
  if (iconImport.test(source))
    errors.push(`${relative(root, file)}: imports @vicons directly — icons come from shared/icon-glyphs (see scripts/gen-icon-shim.mjs)`);
}
const vuePkg = JSON.parse(readFileSync(join(root, "packages/vue-im-ui/package.json"), "utf8"));
for (const field of ["dependencies", "peerDependencies"]) {
  for (const name of Object.keys(vuePkg[field] ?? {})) {
    if (name.startsWith("@vicons/"))
      errors.push(`packages/vue-im-ui/package.json: ${field}.${name} — the kit ships one icon library (@lucide/vue) through the shim`);
  }
}

if (errors.length) {
  console.error("package boundary violations:");
  for (const error of errors) console.error(`  ${error}`);
  process.exit(1);
}
console.log(`package boundaries passed: ${spec.components.length} mapped components; four platform ownership scans and Vue/Flutter source imports checked; ${iconShimImports} Vue file(s) take icons from the one shim`);
