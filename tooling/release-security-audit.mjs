#!/usr/bin/env node
// Security and privacy audit of what the four kits ship, bound to the candidate id.
//
//   node tooling/release-security-audit.mjs
//
// check-security-boundary.mjs owns rendering (v-html, anchors, markdown). This gate owns
// the rest of the release security questions:
//   1. no dynamic code execution in the Vue kit (eval / new Function / document.write);
//   2. every network call a kit makes is a declared, host-directed fetch — the kit
//      loads URLs the host handed it and never contacts a destination of its own;
//   3. no telemetry, crash-reporting or analytics SDK in any kit's dependency manifest.
// Dependency vulnerabilities are audited on the clean consumer's runtime tree in
// release-package-certification.mjs, which is what an application actually installs.
// Evidence: artifacts/release-2.0/security/report.json (gitignored, outside the candidate).
import { mkdirSync, readFileSync, readdirSync, statSync, writeFileSync } from 'node:fs';
import { dirname, join, relative } from 'node:path';
import { fileURLToPath } from 'node:url';
import { currentCandidate } from './release-candidate-id.mjs';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const out = process.env.FLARE_SECURITY_EVIDENCE_DIR ?? join(root, 'artifacts/release-2.0/security');
const errors = [];

function walk(dir, extensions, files = []) {
  for (const name of readdirSync(dir)) {
    const path = join(dir, name);
    if (statSync(path).isDirectory()) { if (!['node_modules', 'build', '.build', '.dart_tool', 'Resources'].includes(name)) walk(path, extensions, files); }
    else if (extensions.some((extension) => name.endsWith(extension)) && !/\.(test|spec)\.[jt]s$/.test(name)) files.push(path);
  }
  return files;
}
function scan(files, pattern) {
  const hits = [];
  for (const file of files) {
    readFileSync(file, 'utf8').split('\n').forEach((line, index) => {
      if (/^\s*(\/\/|\*|#)/.test(line)) return;
      if (pattern.test(line)) hits.push({ file: relative(root, file), line: index + 1, text: line.trim().slice(0, 160) });
    });
  }
  return hits;
}

const kits = {
  vue: walk(join(root, 'packages/vue-im-ui/src'), ['.ts', '.vue']),
  ios: walk(join(root, 'packages/ios-im-ui/Sources'), ['.swift']),
  android: walk(join(root, 'packages/android-im-ui/src/main'), ['.kt']),
  flutter: walk(join(root, 'packages/flutter-im-ui/lib'), ['.dart']),
};

// 1. Dynamic code execution.
const dynamicCode = scan(kits.vue, /\beval\s*\(|\bnew\s+Function\s*\(|document\.write\s*\(/);
for (const hit of dynamicCode) errors.push(`${hit.file}:${hit.line}: dynamic code execution: ${hit.text}`);

// 2. Network call sites. Each declared site states whose URL it loads; a new site fails
// until someone writes down why the kit, not the host, makes that request.
const NETWORK = {
  vue: /\bfetch\s*\(|\bXMLHttpRequest\b|\bsendBeacon\b|\bnew\s+WebSocket\b|\bnew\s+EventSource\b/,
  ios: /\bURLSession\s*\(|\bURLSession\.shared\b|\bURLRequest\s*\(/,
  android: /\bHttpURLConnection\b|\bOkHttpClient\b|\bRetrofit\b|\bio\.ktor\b/,
  flutter: /package:http\/|package:dio\/|\bHttpClient\s*\(/,
};
const DECLARED_NETWORK_SITES = {
  'packages/vue-im-ui/src/utils/browserDownload.ts': 'Downloads the file URL the host put on a message when the user asks to save it.',
  'packages/vue-im-ui/src/components/composer/FrozenStickerThumb/freezeStickerFrame.ts': 'Reads the sticker asset URL the host supplied to freeze its first frame as a thumbnail.',
  'packages/ios-im-ui/Sources/FlareIMUI/EmojiSticker/AnimatedImageDownload.swift': 'Loads the animated emoji/sticker URL the host supplied for display.',
};
const networkSites = Object.entries(NETWORK).flatMap(([kit, pattern]) => scan(kits[kit], pattern).map((hit) => ({ kit, ...hit })));
for (const hit of networkSites) if (!DECLARED_NETWORK_SITES[hit.file]) errors.push(`${hit.file}:${hit.line}: undeclared network call in a kit: ${hit.text}`);
for (const file of Object.keys(DECLARED_NETWORK_SITES)) if (!networkSites.some((hit) => hit.file === file)) errors.push(`${file}: declared network site no longer makes a request — remove the declaration`);

// 3. Telemetry / crash reporting / analytics dependencies.
const TELEMETRY = /firebase|crashlytics|sentry|amplitude|mixpanel|segment\.(io|com)|@segment\/|posthog|datadog|bugsnag|appcenter|newrelic|google-analytics|gtag|hotjar|flurry|umeng|bugly/i;
const manifests = {
  'packages/vue-im-ui/package.json': Object.keys({ ...JSON.parse(readFileSync(join(root, 'packages/vue-im-ui/package.json'), 'utf8')).dependencies, ...JSON.parse(readFileSync(join(root, 'packages/vue-im-ui/package.json'), 'utf8')).peerDependencies }),
  'tokens/package.json': Object.keys(JSON.parse(readFileSync(join(root, 'tokens/package.json'), 'utf8')).dependencies ?? {}),
  'packages/flutter-im-ui/pubspec.yaml': [...(readFileSync(join(root, 'packages/flutter-im-ui/pubspec.yaml'), 'utf8').split(/^dev_dependencies:/m)[0].matchAll(/^\s{2}([a-z_0-9]+):/gm))].map((match) => match[1]),
  'packages/android-im-ui/build.gradle.kts': [...readFileSync(join(root, 'packages/android-im-ui/build.gradle.kts'), 'utf8').matchAll(/^\s*(?:implementation|api)\("([^"]+)"\)/gm)].map((match) => match[1]),
  'packages/ios-im-ui/Package.swift': [...readFileSync(join(root, 'packages/ios-im-ui/Package.swift'), 'utf8').matchAll(/\.package\(url:\s*"([^"]+)"/g)].map((match) => match[1]),
};
const telemetry = Object.entries(manifests).flatMap(([manifest, deps]) => deps.filter((dep) => TELEMETRY.test(dep)).map((dep) => `${manifest}: ${dep}`));
for (const hit of telemetry) errors.push(`telemetry/analytics dependency: ${hit}`);

const candidate = currentCandidate();
mkdirSync(out, { recursive: true });
writeFileSync(join(out, 'report.json'), `${JSON.stringify({
  candidateId: candidate.candidateId, sourceFingerprint: candidate.sourceFingerprint, createdAt: new Date().toISOString(),
  result: errors.length ? 'FAIL' : 'PASS', level: 'L1_STATIC',
  scanned: Object.fromEntries(Object.entries(kits).map(([kit, files]) => [kit, files.length])),
  dynamicCode, networkSites: networkSites.map((hit) => ({ ...hit, purpose: DECLARED_NETWORK_SITES[hit.file] ?? null })),
  dependencyManifests: manifests, telemetryDependencies: telemetry, errors,
  scope: 'Kit source and dependency manifests. Rendering sanitization: check-security-boundary.mjs. Dependency CVEs: artifacts/release-2.0/package/consumer-smoke.json#consumers.latest.audit.',
}, null, 2)}\n`);

if (errors.length) {
  console.error('security audit failed:');
  for (const error of errors) console.error(`  ${error}`);
  process.exit(1);
}
console.log(`security audit passed for ${candidate.candidateId}: ${Object.values(kits).reduce((sum, files) => sum + files.length, 0)} kit source files, 0 dynamic-code sites, ${networkSites.length} declared host-directed network sites, 0 telemetry dependencies`);
