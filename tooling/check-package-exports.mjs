#!/usr/bin/env node
import { execFileSync } from "node:child_process";
import { existsSync, mkdtempSync, readFileSync, readdirSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const packageDir = join(root, "packages/vue-im-ui");
const stage = mkdtempSync(join(tmpdir(), "flare-vue-exports-"));
const forbidden = ["./app", "./sdk-lab", "./composables/sdk", "./app/style.css"];

try {
  execFileSync("npm", ["pack", "--pack-destination", stage], {
    cwd: packageDir,
    stdio: ["ignore", "pipe", "pipe"],
  });
  const tarball = readdirSync(stage).find((file) => file.endsWith(".tgz"));
  if (!tarball) throw new Error("npm pack did not produce a tarball");
  execFileSync("tar", ["-xzf", join(stage, tarball)], { cwd: stage });

  const packedRoot = join(stage, "package");
  const manifest = JSON.parse(readFileSync(join(packedRoot, "package.json"), "utf8"));
  const exportsMap = manifest.exports;
  const errors = [];
  if (!exportsMap || typeof exportsMap !== "object") errors.push("package.json must declare explicit exports");
  for (const [subpath, target] of Object.entries(exportsMap ?? {})) {
    if (subpath.includes("*")) errors.push(`${subpath}: wildcard exports are forbidden`);
    if (typeof target !== "string") errors.push(`${subpath}: export target must be one explicit file`);
    else if (!existsSync(join(packedRoot, target))) errors.push(`${subpath}: packed target is missing (${target})`);
  }
  for (const subpath of forbidden) {
    if (Object.hasOwn(exportsMap ?? {}, subpath)) errors.push(`${subpath}: deprecated export remains`);
  }
  if (errors.length) {
    console.error("Vue package export errors:");
    for (const error of errors) console.error(`  ${error}`);
    process.exitCode = 1;
  } else {
    console.log(`Vue package exports passed: ${Object.keys(exportsMap).length} explicit packed entry points, no compatibility wildcard`);
  }
} finally {
  rmSync(stage, { recursive: true, force: true });
}
