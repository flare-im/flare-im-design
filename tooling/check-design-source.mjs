#!/usr/bin/env node
// design-source — an example app composes the kit; it never re-implements it.
//   * no other UI component library in example source (the kit is the design system);
//   * no deep imports into the kit (only its declared entry points are API);
//   * no styling of another library's internals (`.n-…` and friends) in example CSS;
//   * no example component that re-draws a catalog component (a local Button.vue,
//     Toast.vue, Avatar.vue … is the design system being copied).
// Example roots: this repo's examples plus the client-sdk examples when checked out
// next to it. Package manifests may still depend on a UI library the kit itself
// pulls in (bundle chunking / dedupe) — this gate is about source, not manifests.
// The entry-point rule only binds examples wired to *this* kit by path: an example
// pinned to a published kit version is judged by that version's API, not this one.
import { existsSync, readFileSync, readdirSync, statSync } from "node:fs";
import { dirname, join, relative } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const spec = JSON.parse(readFileSync(join(root, "spec/components.json"), "utf8"));
const pkg = JSON.parse(readFileSync(join(root, "packages/vue-im-ui/package.json"), "utf8"));

const FORBIDDEN_LIBRARIES = [
  "naive-ui", "element-plus", "ant-design-vue", "vuetify", "quasar",
  "@arco-design/web-vue", "primevue", "vant", "view-ui-plus", "bootstrap-vue",
];
// Class prefixes those libraries put in the DOM; styling them couples an example to
// the kit's internal choice of UI runtime.
const FORBIDDEN_CLASS_PREFIXES = [
  ["naive-ui", /(^|[\s,>+~(])\.n-[a-z]/], ["element-plus", /(^|[\s,>+~(])\.el-[a-z]/],
  ["ant-design-vue", /(^|[\s,>+~(])\.ant-[a-z]/], ["vuetify", /(^|[\s,>+~(])\.v-[a-z]+__/],
];
const entryPoints = new Set(Object.keys(pkg.exports ?? {}).map((entry) => entry.replace(/^\./, `${pkg.name}`)));
const catalogNames = new Set(spec.components.map((component) => component.name));

const exampleRoots = [
  join(root, "examples"),
  join(root, "../flare-im-core-client-sdk/examples"),
].filter(existsSync);

/** The nearest package.json above a file, so an example is judged against the kit it actually consumes. */
function nearestManifest(file, stopAt) {
  let dir = dirname(file);
  while (dir.startsWith(stopAt)) {
    const manifest = join(dir, "package.json");
    if (existsSync(manifest)) {
      try { return JSON.parse(readFileSync(manifest, "utf8")); } catch { return undefined; }
    }
    const parent = dirname(dir);
    if (parent === dir) break;
    dir = parent;
  }
  return undefined;
}
function usesLocalKit(manifest) {
  const declared = { ...manifest?.dependencies, ...manifest?.devDependencies }[pkg.name];
  return typeof declared === "string" && /^(file:|link:|workspace:)/.test(declared);
}

const SKIP_DIRS = new Set(["node_modules", "dist", "build", ".output", ".nuxt", "target", ".dart_tool", ".gradle", "DerivedData", ".build", "unpackage"]);
function walk(dir, files = []) {
  for (const name of readdirSync(dir)) {
    if (SKIP_DIRS.has(name) || name.startsWith(".")) continue;
    const absolute = join(dir, name);
    if (statSync(absolute).isDirectory()) walk(absolute, files);
    else if (/\.(vue|ts|tsx|js|mjs|css)$/.test(name)) files.push(absolute);
  }
  return files;
}

const errors = [];
let scanned = 0;
const localComponents = [];
for (const exampleRoot of exampleRoots) {
  for (const file of walk(exampleRoot)) {
    scanned += 1;
    const rel = relative(root, file);
    const source = readFileSync(file, "utf8");
    const isConfig = /\/(vite|vitest|nuxt|playwright|tailwind)\.config\.[cm]?[jt]s$/.test(file);
    const manifest = nearestManifest(file, exampleRoot);
    const localKit = usesLocalKit(manifest);

    for (const library of FORBIDDEN_LIBRARIES) {
      const imported = new RegExp(`(?:from|import|require\\()\\s*["'\`]${library.replace(/[/\\^$*+?.()|[\]{}]/g, "\\$&")}(?:/[^"'\`]*)?["'\`]`).test(source);
      if (imported && !isConfig) errors.push(`${rel}: imports ${library} — compose the kit (@flare-im/vue-ui) instead`);
    }
    if (/\.(vue|css)$/.test(file)) {
      for (const [library, pattern] of FORBIDDEN_CLASS_PREFIXES) {
        if (pattern.test(source)) errors.push(`${rel}: styles ${library} internals — target the kit's own class names`);
      }
    }
    if (localKit) {
      for (const match of source.matchAll(/from\s*["'`](@flare-im\/vue-ui[^"'`]*)["'`]/g)) {
        const target = match[1];
        if (!entryPoints.has(target)) errors.push(`${rel}: deep import ${target} — only the declared entry points are API (${[...entryPoints].join(", ")})`);
      }
    }
    if (file.endsWith(".vue")) {
      const base = file.split("/").pop().replace(/\.vue$/, "");
      if (catalogNames.has(base)) localComponents.push(`${rel}: re-draws catalog component ${base} — use the kit's`);
    }
  }
}
errors.push(...localComponents);

if (errors.length) {
  console.error("design source check failed:\n  " + errors.join("\n  "));
  process.exit(1);
}
console.log(`design source check passed: ${scanned} example source file(s) across ${exampleRoots.length} example root(s) compose the kit only`);
