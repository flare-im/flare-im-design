#!/usr/bin/env node
// Reference applications are this kit's real consumers. The five flare-social apps
// (sibling checkout ../flare-social/flare-social-sdk/examples/apps) compose the public kit
// and nothing else, so a public rename or removal they have not migrated off breaks them —
// and nothing in this repository imports them. On 2026-09-14 all five failed to compile
// against the kit after removals that the migration record had declared consumer-free.
//
// This gate resolves what those apps reference against what the kit defines today:
//   Vue (web, tauri)  every name imported from an @flare-im/vue-ui entry is exported by that entry;
//   Compose (android) every `import com.flare.im.ui.X` names a declaration in the package;
//   Flutter           every Flare-prefixed identifier is declared by the kit, the app or a path dependency;
//   SwiftUI (ios)     no identifier the duplication register lists as removed for iOS.
// A renamed parameter is only visible to a compiler; release:check compiles the apps.
// Without the sibling checkout (a CI clone of this repository alone) the gate skips.
import { existsSync, readFileSync, readdirSync, statSync } from "node:fs";
import { createRequire } from "node:module";
import { dirname, join, relative, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const appsRoot = resolve(root, process.env.FLARE_REFERENCE_APPS ?? "../flare-social/flare-social-sdk/examples/apps");
if (!existsSync(appsRoot)) {
  console.log(`reference app consumers skipped: no sibling checkout at ${relative(root, appsRoot)}`);
  process.exit(0);
}

const SKIP_DIRS = new Set(["node_modules", "dist", "build", "target", ".dart_tool", ".build", ".gradle", "Pods", "ffi"]);
function walk(dir, extensions, files = []) {
  if (!existsSync(dir)) return files;
  for (const name of readdirSync(dir)) {
    if (SKIP_DIRS.has(name)) continue;
    const path = join(dir, name);
    if (statSync(path).isDirectory()) walk(path, extensions, files);
    else if (extensions.some((extension) => name.endsWith(extension))) files.push(path);
  }
  return files;
}
// Comments may name old symbols in prose; only code counts.
const stripComments = (source) => source.replace(/\/\*[\s\S]*?\*\//g, (block) => block.replace(/[^\n]/g, " ")).replace(/\/\/[^\n]*/g, "");
const lineOf = (source, index) => source.slice(0, index).split("\n").length;

const errors = [];
const summary = [];

// ── Vue: resolve named imports against each published entry ─────────────────
const vuePackage = join(root, "packages/vue-im-ui");
const vueEntries = JSON.parse(readFileSync(join(vuePackage, "package.json"), "utf8")).exports;
const require = createRequire(join(vuePackage, "package.json"));
const ts = require("typescript");
const entryFiles = Object.fromEntries(Object.entries(vueEntries)
  .filter(([, target]) => /\.ts$/.test(target))
  .map(([subpath, target]) => [subpath === "." ? "@flare-im/vue-ui" : `@flare-im/vue-ui/${subpath.slice(2)}`, join(vuePackage, target)]));
const program = ts.createProgram(Object.values(entryFiles), {
  noEmit: true, skipLibCheck: true, target: ts.ScriptTarget.ESNext,
  module: ts.ModuleKind.ESNext, moduleResolution: ts.ModuleResolutionKind.Bundler,
});
const checker = program.getTypeChecker();
const exportsBySpecifier = new Map();
for (const [specifier, file] of Object.entries(entryFiles)) {
  const source = program.getSourceFile(file);
  const module = source && checker.getSymbolAtLocation(source);
  if (!module) throw new Error(`cannot resolve ${specifier} (${relative(root, file)})`);
  exportsBySpecifier.set(specifier, new Set(checker.getExportsOfModule(module).map((symbol) => symbol.name)));
}

function vueApp(name) {
  let resolved = 0;
  for (const file of walk(join(appsRoot, name, "src"), [".vue", ".ts"])) {
    const source = stripComments(readFileSync(file, "utf8"));
    for (const match of source.matchAll(/import\s+(?:type\s+)?\{([^}]*)\}\s*from\s*["'](@flare-im\/vue-ui(?:\/[\w-]+)?)["']/g)) {
      const exported = exportsBySpecifier.get(match[2]);
      if (!exported) {
        errors.push(`${name}/${relative(join(appsRoot, name), file)}:${lineOf(source, match.index)}: imports ${match[2]}, which is not a published entry`);
        continue;
      }
      for (const raw of match[1].split(",")) {
        const imported = raw.replace(/^\s*type\s+/, "").split(/\s+as\s+/)[0].trim();
        if (!imported) continue;
        if (exported.has(imported)) resolved++;
        else errors.push(`${name}/${relative(join(appsRoot, name), file)}:${lineOf(source, match.index)}: ${imported} is not exported by ${match[2]}`);
      }
    }
  }
  summary.push(`${name}: ${resolved} kit imports resolve`);
}

// ── Compose: resolve explicit imports against package declarations ───────────
function composeApp(name) {
  const declared = new Set();
  for (const file of walk(join(root, "packages/android-im-ui/src/main/kotlin"), [".kt"])) {
    const source = stripComments(readFileSync(file, "utf8"));
    for (const match of source.matchAll(/\b(?:fun|class|interface|object|typealias|val|var)\s+(?:<[^>]*>\s*)?(?:[\w.]+\.)?([A-Za-z_]\w*)/g)) declared.add(match[1]);
  }
  let resolved = 0;
  let wildcard = 0;
  for (const file of walk(join(appsRoot, name, "app/src/main/kotlin"), [".kt"])) {
    const source = stripComments(readFileSync(file, "utf8"));
    for (const match of source.matchAll(/^import\s+com\.flare\.im\.ui\.([\w.*]+)/gm)) {
      const symbol = match[1].split(".")[0];
      if (symbol === "*") { wildcard++; continue; }
      if (declared.has(symbol)) resolved++;
      else errors.push(`${name}/${relative(join(appsRoot, name), file)}:${lineOf(source, match.index)}: com.flare.im.ui.${symbol} is not declared by the Compose kit`);
    }
  }
  summary.push(`${name}: ${resolved} kit imports resolve${wildcard ? `, ${wildcard} wildcard import(s) left to the compiler` : ""}`);
}

// ── Flutter: Flare-prefixed identifiers must be declared somewhere reachable ─
function dartDeclarations(dir, into) {
  for (const file of walk(dir, [".dart"])) {
    const source = stripComments(readFileSync(file, "utf8"));
    for (const match of source.matchAll(/\b(?:class|enum|mixin|extension|typedef)\s+(?:type\s+)?(Flare[A-Z]\w*)/g)) into.add(match[1]);
  }
}
function flutterApp(name) {
  const appDir = join(appsRoot, name);
  const declared = new Set();
  dartDeclarations(join(root, "packages/flutter-im-ui/lib"), declared);
  dartDeclarations(join(appDir, "lib"), declared);
  const pubspec = readFileSync(join(appDir, "pubspec.yaml"), "utf8");
  for (const match of pubspec.matchAll(/^\s+path:\s*(\S+)/gm)) dartDeclarations(join(resolve(appDir, match[1]), "lib"), declared);
  let resolved = 0;
  for (const file of walk(join(appDir, "lib"), [".dart"])) {
    const source = stripComments(readFileSync(file, "utf8")).replace(/'(?:\\.|[^'\\\n])*'|"(?:\\.|[^"\\\n])*"/g, "''");
    const seen = new Set();
    for (const match of source.matchAll(/\bFlare[A-Z]\w*/g)) {
      if (seen.has(match[0])) continue;
      seen.add(match[0]);
      if (declared.has(match[0])) resolved++;
      else errors.push(`${name}/${relative(appDir, file)}:${lineOf(source, match.index)}: ${match[0]} is declared by neither the kit, the app nor a path dependency`);
    }
  }
  summary.push(`${name}: ${resolved} Flare identifiers resolve`);
}

// ── SwiftUI: removed symbols from the duplication register ───────────────────
const register = JSON.parse(readFileSync(join(root, "spec/duplication-register.json"), "utf8"));
const removedIos = new Set((register.entries ?? register).flatMap((entry) => entry.removed?.ios ?? []));
function iosApp(name) {
  let files = 0;
  for (const file of walk(join(appsRoot, name, "Sources"), [".swift"])) {
    files++;
    const source = stripComments(readFileSync(file, "utf8"));
    for (const symbol of removedIos) {
      const match = new RegExp(`\\b${symbol}\\b`).exec(source);
      if (match) errors.push(`${name}/${relative(join(appsRoot, name), file)}:${lineOf(source, match.index)}: ${symbol} was removed from FlareIMUI (spec/duplication-register.json)`);
    }
  }
  summary.push(`${name}: ${files} Swift files free of ${removedIos.size} removed symbols`);
}

vueApp("flare-social-web-app");
vueApp("flare-social-tauri-app");
composeApp("flare-social-android-app");
flutterApp("flare-social-flutter-app");
iosApp("flare-social-ios-app");

if (errors.length) {
  console.error("reference app consumers failed — migrate the app in the same change as the kit, or keep the symbol:");
  for (const error of errors) console.error(`  ${error}`);
  process.exit(1);
}
console.log(`reference app consumers passed: ${summary.join("; ")}`);
