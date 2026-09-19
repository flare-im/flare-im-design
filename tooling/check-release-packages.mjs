#!/usr/bin/env node
import { spawnSync } from 'node:child_process';
import { existsSync, readdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const failures = [];
const forbidden = /(^|\/)(node_modules|\.dart_tool|\.gradle|\.build|test-results|playwright-report|screenshots|coverage)(\/|$)|\.(hprof|log|tmp)$|\.(test|spec)\.[cm]?[jt]sx?$/;
function run(cwd, command, args) {
  const result = spawnSync(command, args, { cwd, encoding: 'utf8', timeout: 300000, maxBuffer: 16 * 1024 * 1024 });
  if (result.status !== 0) failures.push(`${command} ${args.join(' ')}: ${result.stderr || result.stdout || result.error}`);
  return result;
}
for (const relative of ['tokens', 'packages/vue-im-ui', 'spec']) {
  // Keep lifecycle output separate from npm's machine-readable pack manifest.
  // Validation is read-only: detect an unsynced package, never repair it mid-run.
  // `npm run prepack` would rewrite src/assets/emoji-sticker/*.json inside the
  // candidate; the script's own --check mode fails instead when they have drifted.
  if (relative === 'packages/vue-im-ui') run(join(root, relative), 'node', ['scripts/sync-pack-assets.mjs', '--check']);
  const result = run(join(root, relative), 'npm', ['pack', '--dry-run', '--json', '--ignore-scripts']);
  if (result.status !== 0) continue;
  try {
    const [pack] = JSON.parse(result.stdout);
    const bad = pack.files.map((file) => file.path).filter((path) => forbidden.test(path));
    failures.push(...bad.map((path) => `${relative}: unexpected package file ${path}`));
    console.log(`${relative}: ${pack.files.length} files, ${pack.size} compressed bytes`);
  } catch (error) { failures.push(`${relative}: invalid pack manifest: ${error}`); }
}
const flutter = run(join(root, 'packages/flutter-im-ui'), 'flutter', ['pub', 'publish', '--dry-run']);
console.log(flutter.stdout);
const aarDir = join(root, 'packages/android-im-ui/build/outputs/aar');
const aars = existsSync(aarDir) ? readdirSync(aarDir).filter((name) => name.endsWith('-release.aar')) : [];
if (!aars.length) failures.push('No release AAR: run the Compose release build first');
for (const name of aars) {
  const result = run(root, 'unzip', ['-Z1', join(aarDir, name)]);
  const paths = result.stdout.split('\n');
  failures.push(...paths.filter((path) => forbidden.test(path)).map((path) => `${name}: ${path}`));
  if (!paths.includes('classes.jar') || !paths.includes('AndroidManifest.xml')) failures.push(`${name}: incomplete Android library`);
  console.log(`${name}: inspected ${paths.length} entries`);
}
// Inspect only shipped Swift sources/resources, not the local SwiftPM build cache.
function inspect(dir) {
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const path = join(dir, entry.name);
    if (forbidden.test(path)) failures.push(`Swift package source contains ${path}`);
    if (entry.isDirectory()) inspect(path);
  }
}
inspect(join(root, 'packages/ios-im-ui/Sources'));
if (failures.length) {
  console.error(failures.join('\n'));
  process.exitCode = 1;
} else console.log('Release package contents passed');
