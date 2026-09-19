#!/usr/bin/env node
import { spawnSync } from "node:child_process";
import { cpSync, existsSync, mkdtempSync, readFileSync, readdirSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const root = join(dirname(fileURLToPath(import.meta.url)), "..");
const androidProperties = join(root, "packages/android-im-ui/local.properties");
const sdkProperty = existsSync(androidProperties)
  ? readFileSync(androidProperties, "utf8").match(/^sdk\.dir=(.+)$/m)?.[1].replaceAll("\\\\", "\\")
  : undefined;
const androidEnv = sdkProperty ? { ANDROID_HOME: sdkProperty, ANDROID_SDK_ROOT: sdkProperty } : {};

function run(label, cwd, command, args, env = {}) {
  console.log(`\n== ${label}`);
  const result = spawnSync(command, args, { cwd, stdio: "inherit", env: { ...process.env, ...env } });
  if (result.status !== 0) throw new Error(`${label} failed (${result.status ?? result.error})`);
}

run("Vue packed exports", root, "node", ["tooling/check-package-exports.mjs"]);
const vueStage = mkdtempSync(join(tmpdir(), "flare-vue-consumer-"));
try {
  run("Pack tokens", join(root, "tokens"), "npm", ["pack", "--pack-destination", vueStage]);
  run("Pack Vue", join(root, "packages/vue-im-ui"), "npm", ["pack", "--pack-destination", vueStage]);
  const fixture = join(vueStage, "consumer");
  cpSync(join(root, "tests/consumers/vue"), fixture, {
    recursive: true,
    filter: (source) => !/[\\/](node_modules|dist)$/.test(source) && !source.endsWith("package-lock.json"),
  });
  const manifestPath = join(fixture, "package.json");
  const manifest = JSON.parse(readFileSync(manifestPath, "utf8"));
  const tarballs = readdirSync(vueStage).filter((name) => name.endsWith(".tgz"));
  const tokens = tarballs.find((name) => name.includes("tokens"));
  const vue = tarballs.find((name) => name.includes("vue-ui"));
  if (!tokens || !vue) throw new Error("Vue consumer tarballs were not produced");
  manifest.dependencies["@flare-im/tokens"] = `file:${join(vueStage, tokens)}`;
  manifest.dependencies["@flare-im/vue-ui"] = `file:${join(vueStage, vue)}`;
  writeFileSync(manifestPath, `${JSON.stringify(manifest, null, 2)}\n`);
  run("Vue tarball install", fixture, "npm", ["install", "--ignore-scripts"]);
  run("Vue tarball consumer build", fixture, "npm", ["run", "build"]);
} finally {
  rmSync(vueStage, { recursive: true, force: true });
}

const checks = [
  ["Flutter consumer get", join(root, "tests/consumers/flutter"), "flutter", ["pub", "get"]],
  ["Flutter consumer analyze", join(root, "tests/consumers/flutter"), "flutter", ["analyze"]],
  ["Flutter consumer build", join(root, "tests/consumers/flutter"), "flutter", ["build", "bundle"]],
  ["Compose publish local", join(root, "packages/android-im-ui"), "./gradlew", ["publishToMavenLocal"]],
  ["Compose consumer", join(root, "packages/android-im-ui"), "./gradlew", ["-p", "../../tests/consumers/android", "assembleDebug"], androidEnv],
  ["Swift consumer", root, "swift", ["build", "--package-path", "tests/consumers/swift"]],
];
for (const [label, cwd, command, args, env = {}] of checks) {
  run(label, cwd, command, args, env);
}
console.log("\nall four independent consumer fixtures passed");
