#!/usr/bin/env node
// dead-components — nothing ships that nothing can reach:
//   * Vue: every .vue / .ts file under packages/vue-im-ui/src is reachable from a
//     package entry point (package.json "exports") through static imports;
//   * Flutter: every public widget class under lib/ is a catalog symbol or is used
//     by another library file;
//   * iOS / Compose: every public View / @Composable is a catalog symbol or is used
//     by another source file (previews and tests do not count as consumers);
//   * website: every demo under .vitepress/theme/demos is either the preview of a
//     catalog component or referenced by another site source.
// A hit is a defect: delete the file / symbol, register it in the catalog, or wire it in.
import { existsSync, readFileSync, readdirSync, statSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const read = (rel) => readFileSync(join(root, rel), "utf8");
const spec = JSON.parse(read("spec/components.json"));
const exceptions = JSON.parse(read("spec/public-api-exceptions.json"));
const register = JSON.parse(read("spec/duplication-register.json"));
const strict = process.argv.includes("--strict");
// Symbols an open duplication-register entry still has to decide about: warned, not failed.
const pending = {};
for (const entry of register.entries) {
  if (entry.state === "DONE") continue;
  for (const [platform, names] of Object.entries(entry.pending ?? {})) for (const name of names) (pending[platform] ??= new Map()).set(name, entry.id);
}
const companions = Object.fromEntries(Object.entries(exceptions.nativeCompanions ?? {}).map(([platform, table]) => [platform, new Set(Object.keys(table))]));
const symbols = Object.fromEntries(["vue", "flutter", "ios", "compose"].map((p) => [p, new Set(spec.components.map((c) => c.platforms?.[p]?.symbol).filter(Boolean))]));
const errors = [];
const warnings = [];
const stats = {};
function report(platform, name, message) {
  const owner = pending[platform]?.get(name);
  if (owner) warnings.push(`${message} — pending register ${owner}`);
  else errors.push(message);
}

function walk(dir, keep, files = []) {
  if (!existsSync(dir)) return files;
  for (const name of readdirSync(dir)) {
    const absolute = join(dir, name);
    if (statSync(absolute).isDirectory()) {
      if (name === "node_modules" || name === "build" || name === ".build" || name === "dist" || name === "cache") continue;
      walk(absolute, keep, files);
    } else if (keep(name)) files.push(absolute);
  }
  return files;
}
const rel = (absolute) => absolute.slice(root.length + 1);
const isTest = (file) => /\.(test|spec)\.[cm]?[jt]sx?$|\.d\.ts$|\/__tests__\/|\/test-utils\//.test(file);

// ── Vue: static import reachability from the package entry points ──────────────
{
  const pkgRoot = join(root, "packages/vue-im-ui");
  const pkg = JSON.parse(readFileSync(join(pkgRoot, "package.json"), "utf8"));
  const entries = Object.values(pkg.exports).filter((target) => typeof target === "string" && /\.(ts|vue)$/.test(target)).map((target) => resolve(pkgRoot, target));
  const candidates = walk(join(pkgRoot, "src"), (name) => /\.(ts|vue)$/.test(name)).filter((file) => !isTest(file));
  const resolveImport = (from, specifier) => {
    if (!specifier.startsWith(".")) return null;
    const base = resolve(dirname(from), specifier);
    for (const candidate of [base, `${base}.ts`, `${base}.vue`, `${base}.mts`, join(base, "index.ts")]) if (existsSync(candidate) && statSync(candidate).isFile()) return candidate;
    return null;
  };
  const seen = new Set();
  const queue = [...entries];
  while (queue.length) {
    const file = queue.pop();
    if (seen.has(file)) continue;
    seen.add(file);
    const text = readFileSync(file, "utf8");
    for (const match of text.matchAll(/(?:from|import)\s*["']([^"']+)["']|import\(\s*["']([^"']+)["']\s*\)/g)) {
      const target = resolveImport(file, match[1] ?? match[2]);
      if (target && !seen.has(target)) queue.push(target);
    }
  }
  const dead = candidates.filter((file) => !seen.has(file));
  for (const file of dead) errors.push(`vue: ${rel(file)} is not reachable from any package entry point`);
  stats.vue = `${candidates.length - dead.length}/${candidates.length} source files reachable`;
}

// ── Native: public component definitions must be catalog symbols or internal consumers ──
function nativeCheck(platform, dir, ext, definitionRegex, options = {}) {
  const files = walk(join(root, dir), (name) => name.endsWith(ext)).filter((file) => !(options.skip ?? (() => false))(rel(file)));
  const texts = new Map(files.map((file) => [file, readFileSync(file, "utf8")]));
  let total = 0;
  const dead = [];
  for (const [file, text] of texts) {
    for (const match of text.matchAll(definitionRegex)) {
      const name = match[1];
      if (name.startsWith("_")) continue;
      total += 1;
      if (symbols[platform].has(name) || companions[platform]?.has(name)) continue;
      const usedElsewhere = [...texts].some(([other, otherText]) => other !== file && new RegExp(`\\b${name}\\b`).test(otherText));
      if (usedElsewhere) continue;
      const usedInside = (text.match(new RegExp(`\\b${name}\\b`, "g")) ?? []).length > 1;
      dead.push(name);
      report(platform, name, usedInside
        ? `${platform}: ${name} (${rel(file)}) is public but only its own file uses it — make it private`
        : `${platform}: ${name} (${rel(file)}) is public, not in the catalog, and used nowhere`);
    }
  }
  stats[platform] = `${total - dead.length}/${total} public components live`;
}
nativeCheck("flutter", "packages/flutter-im-ui/lib", ".dart", /^class (\w+) extends (?:StatelessWidget|StatefulWidget)\b/gm, { skip: (file) => file.endsWith("flare_im_ui.dart") });
nativeCheck("ios", "packages/ios-im-ui/Sources", ".swift", /^public struct (\w+)(?:<[^>]*>)?\s*:\s*View\b/gm, { skip: (file) => /Previews\.swift$/.test(file) });
nativeCheck("compose", "packages/android-im-ui/src/main", ".kt", /^@Composable\s*\n(?:public )?fun (\w+)\(/gm, { skip: (file) => /Previews\.kt$/.test(file) || /FlareTokens\.kt$/.test(file) });

// ── Website demos: previews of catalog components or referenced by the site ────
{
  const demosDir = join(root, "website/.vitepress/theme/demos");
  const registry = await import(pathToFileURL(join(demosDir, "preview-registry.mjs")).href);
  const live = new Set();
  for (const component of spec.components) {
    live.add(registry.previewDemoName(component.name));
    live.add(`${component.name}Demo`);
  }
  const siteFiles = walk(join(root, "website"), (name) => /\.(vue|ts|mts|mjs|md)$/.test(name)).filter((file) => !rel(file).includes("/.vitepress/cache/") && !rel(file).includes("/.vitepress/dist/") && !rel(file).includes("/node_modules/"));
  const siteTexts = siteFiles.map((file) => [file, readFileSync(file, "utf8")]);
  const demos = walk(demosDir, (name) => /\.(vue|ts|mjs)$/.test(name)).filter((file) => !isTest(file));
  let dead = 0;
  for (const demo of demos) {
    const base = demo.split("/").pop().replace(/\.(vue|ts|mjs)$/, "");
    if (live.has(base)) continue;
    const referenced = siteTexts.some(([file, text]) => file !== demo && new RegExp(`\\b${base}\\b`).test(text));
    if (!referenced) { dead += 1; report("website", base, `website: demo ${rel(demo)} previews no catalog component and is referenced nowhere`); }
  }
  stats.website = `${demos.length - dead}/${demos.length} demos live`;
}

if (errors.length) {
  console.error("dead components check failed:\n  " + errors.join("\n  "));
  process.exit(1);
}
if (warnings.length) {
  console[strict ? "error" : "warn"](`dead components: ${warnings.length} symbol(s) wait on open duplication-register entries:\n  ${warnings.join("\n  ")}`);
  if (strict) process.exit(1);
}
console.log(`dead components check passed: ${Object.entries(stats).map(([k, v]) => `${k} ${v}`).join("; ")}`);
