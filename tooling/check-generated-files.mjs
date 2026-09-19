#!/usr/bin/env node
import { spawnSync } from "node:child_process";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const checks = [
  ["icon shim", "packages/vue-im-ui/scripts/gen-icon-shim.mjs", "--check"],
  ["tokens", "tokens/build.mjs", "--check"],
  ["pinyin initials", "tooling/build-pinyin-initials.mjs", "--check"],
  ["maturity model", "spec/build-maturity-model.mjs", "--check"],
  ["component layers", "spec/build-component-layers.mjs", "--check"],
  ["component catalog", "tooling/build-component-catalog.mjs", "--check"],
  ["component style audit", "tooling/build-component-style-audit.mjs", "--check"],
  ["component pages", "tooling/normalize-component-docs.mjs", "--check"],
  ["library guides", "website/scripts/build-library-guides.mjs", "--check"],
  ["repository inventory", "tooling/build-repository-inventory.mjs", "--check"],
];
for (const [label, script, flag] of checks) {
  const result = spawnSync("node", [script, flag], { cwd: root, stdio: "inherit" });
  if (result.status !== 0) process.exit(result.status ?? 1);
  console.log(`generated ${label}: current`);
}
