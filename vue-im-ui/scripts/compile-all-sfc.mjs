// SFC compile-all gate.
//
// Why this exists: `vue-tsc --noEmit` type-checks <script> blocks but does NOT
// catch SFC *compilation* errors (malformed <template>, bad <style>, broken
// <script setup> macros). Because src/index.ts barrel-re-exports every
// component, a single un-compilable .vue silently blanks every consumer at
// runtime with no build-time signal. This script closes that gap: it parses and
// compiles every src/**/*.vue with @vue/compiler-sfc and exits non-zero on the
// first failure.
//
// Run: `npm run check:sfc` (or `node scripts/compile-all-sfc.mjs`).

import { readdir, readFile } from "node:fs/promises";
import { join, relative } from "node:path";
import { fileURLToPath } from "node:url";

import { compileScript, compileStyleAsync, compileTemplate, parse } from "@vue/compiler-sfc";

const root = fileURLToPath(new URL("..", import.meta.url));
const srcDir = join(root, "src");

async function collectVueFiles(dir) {
  const out = [];
  const entries = await readdir(dir, { withFileTypes: true });
  for (const entry of entries) {
    const full = join(dir, entry.name);
    if (entry.isDirectory()) {
      if (entry.name === "node_modules" || entry.name === "__tests__") continue;
      out.push(...(await collectVueFiles(full)));
    } else if (entry.isFile() && entry.name.endsWith(".vue")) {
      out.push(full);
    }
  }
  return out;
}

function collectErrors(errors) {
  if (!errors) return [];
  return errors.map((err) => (typeof err === "string" ? err : err.message ?? String(err)));
}

async function compileOne(file) {
  const rel = relative(root, file);
  const source = await readFile(file, "utf8");
  const errors = [];

  const { descriptor, errors: parseErrors } = parse(source, { filename: rel });
  errors.push(...collectErrors(parseErrors));

  const scopeId = `data-v-${Buffer.from(rel).toString("hex").slice(0, 8)}`;
  const hasScoped = descriptor.styles.some((s) => s.scoped);

  if (descriptor.script || descriptor.scriptSetup) {
    try {
      compileScript(descriptor, { id: scopeId });
    } catch (err) {
      errors.push(err.message ?? String(err));
    }
  }

  if (descriptor.template) {
    const templateResult = compileTemplate({
      source: descriptor.template.content,
      filename: rel,
      id: scopeId,
      scoped: hasScoped,
      slotted: descriptor.slotted,
      compilerOptions: {
        bindingMetadata:
          descriptor.script || descriptor.scriptSetup
            ? compileScript(descriptor, { id: scopeId }).bindings
            : undefined,
      },
    });
    errors.push(...collectErrors(templateResult.errors));
  }

  for (const style of descriptor.styles) {
    const styleResult = await compileStyleAsync({
      source: style.content,
      filename: rel,
      id: scopeId,
      scoped: style.scoped,
      preprocessLang: style.lang,
    });
    errors.push(...collectErrors(styleResult.errors));
  }

  return errors;
}

const files = await collectVueFiles(srcDir);
let failed = 0;

for (const file of files) {
  let errors;
  try {
    errors = await compileOne(file);
  } catch (err) {
    errors = [err.message ?? String(err)];
  }
  if (errors.length > 0) {
    failed += 1;
    console.error(`\n✗ ${relative(root, file)}`);
    for (const message of errors) console.error(`    ${message}`);
  }
}

if (failed > 0) {
  console.error(`\ncheck:sfc — ${failed} of ${files.length} SFC(s) failed to compile.`);
  process.exit(1);
}

console.log(`check:sfc — all ${files.length} SFC(s) compiled cleanly.`);
