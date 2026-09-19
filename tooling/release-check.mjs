#!/usr/bin/env node
import { spawnSync } from 'node:child_process';
import { closeSync, cpSync, existsSync, mkdirSync, openSync, readFileSync, readdirSync, rmSync, statfsSync, writeFileSync } from 'node:fs';
import { arch, cpus, loadavg, release, tmpdir, totalmem, type, version } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { readinessBlockers, releaseReady } from './release-policy.mjs';
import { captureCandidate } from './release-candidate.mjs';
import { currentCandidate } from './release-candidate-id.mjs';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const sdk = join(root, '../flare-im-core-client-sdk');
const app = (name) => join(sdk, 'examples', `flare-core-${name}-app`);
// The flare-social apps are the product-shaped consumers; a public rename they have not
// migrated off must turn this run red (their symbols are also resolved by the check gate).
const socialApp = (name) => join(root, '../flare-social/flare-social-sdk/examples/apps', `flare-social-${name}-app`);
// Filtering is diagnostic only: a partial run can never certify a release.
const filter = process.argv.find((arg) => arg.startsWith('--only='))?.slice(7);
// Release criteria §1: evidence lands in artifacts/release-2.0 (gitignored, outside the
// candidate fingerprint), one directory per run so Final Validation A and B both survive.
const evidenceRoot = join(root, 'artifacts/release-2.0');
const runLabel = process.env.FLARE_RELEASE_RUN_LABEL ?? new Date().toISOString().replace(/[-:]/g, '').replace(/\..*$/, 'Z');
const output = join(evidenceRoot, 'automation/runs', `${filter ? 'diagnostic-' : ''}${runLabel}`);
if (existsSync(output)) throw new Error(`Release run directory already exists: ${output}`);
mkdirSync(output, { recursive: true });
const candidateRoots = [['design', root], ['sdk', sdk], ...['web', 'tauri', 'flutter', 'android', 'ios'].map(name => [name, app(name)])];
const candidateBefore = currentCandidate();
// Where the evidence was produced (brief §38): a result is only reproducible with its environment.
const runtimeVersion = (command, args) => { const probe = spawnSync(command, args, { encoding: 'utf8' }); return probe.status === 0 ? (probe.stdout || probe.stderr).trim().split('\n')[0] : null; };
const environment = {
  os: `${type()} ${release()} ${arch()}`, kernel: version(), cpus: cpus().length, memoryBytes: totalmem(),
  node: process.version, npm: runtimeVersion('npm', ['-v']),
  playwright: JSON.parse(readFileSync(join(root, 'node_modules/@playwright/test/package.json'), 'utf8')).version,
  chromium: JSON.parse(readFileSync(join(root, 'node_modules/playwright-core/browsers.json'), 'utf8')).browsers.find((browser) => browser.name === 'chromium')?.browserVersion ?? null,
  flutter: runtimeVersion('flutter', ['--version']), swift: runtimeVersion('swift', ['--version']), xcode: runtimeVersion('xcodebuild', ['-version']), java: runtimeVersion('java', ['-version']),
  locale: Intl.DateTimeFormat().resolvedOptions().locale, timeZone: Intl.DateTimeFormat().resolvedOptions().timeZone,
  loadAverageAtStart: loadavg(),
};
const sourceBefore = captureCandidate(candidateRoots);
writeFileSync(join(output, 'candidate.json'), `${JSON.stringify({ ...candidateBefore, captured: sourceBefore }, null, 2)}\n`);
const checks = [
  ['release-policy', root, 'node', ['--test', 'tooling/release-policy.test.mjs', 'tooling/release-candidate.test.mjs', 'tooling/vue-doc-imports.test.mjs', 'tooling/conversation-ownership.test.mjs']],
  ['conversation-reference-ownership-check', root, 'node', ['tooling/check-conversation-ownership.mjs']],
  ['conversation-state-combination-check', root, 'node', ['tooling/check-conversation-combinations.mjs']],
  ['conversation-state-visual-check', join(root, 'website'), 'npm', ['run', 'test:visual', '--', 'tests/conversation-presentation.spec.ts', '--workers=1']],
  ['design-system', root, 'npm', ['run', 'check']],
  ['distribution', root, 'node', ['tooling/check-kit-distribution.mjs']],
  ['native-contract', root, 'node', ['tooling/check-platform-contract.mjs']],
  ['form-keyboard-contract', root, 'node', ['tooling/check-form-keyboard.mjs']],
  ['security-boundary', root, 'node', ['tooling/check-security-boundary.mjs']],
  // No dynamic code, only declared host-directed network calls, no telemetry SDKs.
  ['security-audit', root, 'node', ['tooling/release-security-audit.mjs']],
  ['api-check', root, 'node', ['tooling/check-public-api.mjs', '--strict']],
  ['duplicate-components', root, 'node', ['tooling/check-duplicate-components.mjs', '--strict']],
  ['dead-components', root, 'node', ['tooling/check-dead-components.mjs', '--strict']],
  // Release criteria §1 stub-check: no TODO/FIXME/HACK, not-implemented body or mock/stub/fake code in kit production source.
  ['stub-check', root, 'node', ['tooling/check-production-stubs.mjs']],
  ['design-source', root, 'node', ['tooling/check-design-source.mjs']],
  ['ssr-safety', root, 'node', ['tooling/check-ssr-safety.mjs']],
  // DoD 41 — the release report must keep naming every gate and every unmet
  // manual-evidence id; a gate added without a report line fails here.
  ['release-report', root, 'node', ['tooling/check-release-report.mjs']],
  // DoD 21/22 — axe over every component preview plus the reference app, and the
  // 44px hit-area probe. Reports land in website/test-results/axe-*.json.
  ['accessibility-axe', join(root, 'website'), 'npm', ['run', 'test:visual', '--', '--grep', '@a11y', '--workers=1']],
  // DoD 27 — the numeric half of the performance contract, measured against the
  // real load rather than grepped out of the source.
  ['performance-budget', join(root, 'website'), 'npm', ['run', 'test:visual', '--', '--grep', '@perf', '--workers=1']],
  ['vue-tests', join(root, 'packages/vue-im-ui'), 'npm', ['test', '--', '--maxWorkers=1', '--no-file-parallelism']],
  ['vue-build', join(root, 'packages/vue-im-ui'), 'npm', ['run', 'build']],
  ['flutter-analyze', join(root, 'packages/flutter-im-ui'), 'flutter', ['analyze', '--no-pub']],
  ['flutter-tests', join(root, 'packages/flutter-im-ui'), 'flutter', ['test', '--no-pub']],
  ['compose', join(root, 'packages/android-im-ui'), './gradlew', ['testDebugUnitTest', 'lintDebug', 'assembleRelease', 'compileDebugAndroidTestKotlin']],
  ['swift', join(root, 'packages/ios-im-ui'), 'swift', ['test']],
  ['website-interaction-visual', join(root, 'website'), 'npm', ['run', 'test:visual', '--', '--grep-invert', '@a11y|@perf', '--workers=1']],
  ['package-contents', root, 'npm', ['run', 'release:packages']],
  ['independent-consumers', root, 'npm', ['run', 'test:consumers']],
  // Packed tarballs only: reproducible pack, clean consumer typecheck/build/runtime at
  // the latest and the peer floor, and a module ledger proving tree-shaking.
  ['package-certification', root, 'node', ['tooling/release-package-certification.mjs']],
  ['reference-ownership', sdk, 'node', ['scripts/check-reference-example-ui.mjs']],
  ['reference-gate-tests', sdk, 'node', ['--test', 'scripts/reference-app-checks.test.mjs']],
  ['web-tests', app('web'), 'npm', ['test', '--', '--maxWorkers=1', '--no-file-parallelism']],
  ['web-build', app('web'), 'npm', ['run', 'build']],
  ['web-browser', app('web'), 'npx', ['playwright', 'test', '--workers=1']],
  ['web-live-sdk', sdk, 'node', ['scripts/check-release-live-web.mjs']],
  ['tauri-tests', app('tauri'), 'npm', ['test']],
  ['tauri-build', app('tauri'), 'npm', ['run', 'build']],
  ['tauri-native', app('tauri'), 'cargo', ['check', '--manifest-path', 'src-tauri/Cargo.toml']],
  ['flutter-app-analyze', app('flutter'), 'flutter', ['analyze', '--no-pub']],
  ['flutter-app-tests', app('flutter'), 'flutter', ['test', '--no-pub']],
  ['flutter-app-build', app('flutter'), 'flutter', ['build', 'macos', '--debug', '--no-pub']],
  ['android-app', app('android'), '../flare-core-flutter-app/android/gradlew', [':app:testDebugUnitTest', ':app:lintDebug', ':app:assembleDebug', ':app:compileDebugAndroidTestKotlin']],
  ['ios-app-tests', app('ios'), 'swift', ['test']],
  ['ios-app-project', app('ios'), 'xcodegen', ['generate']],
  ['ios-app-build', app('ios'), 'xcodebuild', ['-project', 'FlareImApp.xcodeproj', '-scheme', 'FlareImExampleApp', '-destination', 'generic/platform=iOS Simulator', '-derivedDataPath', join(tmpdir(), 'flare-canonical-ios-derived'), 'CODE_SIGNING_ALLOWED=NO', 'clean', 'build']],
  ['social-web-typecheck', socialApp('web'), 'npm', ['run', 'typecheck']],
  ['social-tauri-typecheck', socialApp('tauri'), 'npx', ['vue-tsc', '--noEmit']],
  ['social-flutter-analyze', socialApp('flutter'), 'flutter', ['analyze', '--no-pub']],
  ['social-android-compile', socialApp('android'), './gradlew', [':app:compileDebugKotlin']],
  // The bundled FFI archive is arm64-only, so the generic simulator build excludes x86_64.
  ['social-ios-build', socialApp('ios'), 'xcodebuild', ['-project', 'FlareSocialApp.xcodeproj', '-scheme', 'FlareSocialExampleApp', '-destination', 'generic/platform=iOS Simulator', '-derivedDataPath', join(tmpdir(), 'flare-social-ios-derived'), 'EXCLUDED_ARCHS=x86_64', 'CODE_SIGNING_ALLOWED=NO', 'build']],
  ...[root, sdk, ...['web', 'tauri', 'flutter', 'android', 'ios'].map(app)]
    .map((cwd, index) => [`diff-${index}`, cwd, 'git', ['diff', '--check']]),
];

const selected = filter ? checks.filter(([id]) => id.includes(filter)) : checks;
if (!selected.length) throw new Error(`No release checks match ${filter}`);
const results = [];
for (const [id, cwd, command, args] of selected) {
  console.log(`\n== ${id}`);
  const started = Date.now();
  const evidence = join(output, `${id}.log`);
  const disk = statfsSync(output);
  if (disk.bavail * disk.bsize < 512 * 1024 * 1024) {
    results.push({ id, status: 'FAIL', reason: 'Insufficient temporary disk space; automatic gate not executed' });
    writeFileSync(join(output, 'partial-results.json'), `${JSON.stringify(results, null, 2)}\n`);
    continue;
  }
  // Stream compiler output to disk, retaining evidence even if a compiler aborts.
  const fd = openSync(evidence, 'w');
  let result;
  try {
    result = spawnSync(command, args, {
      cwd, timeout: 20 * 60 * 1000, stdio: ['ignore', fd, fd],
      env: { ...process.env, CI: '1', ...(id === 'web-browser' ? { PLAYWRIGHT_PORT: process.env.PLAYWRIGHT_PORT ?? '1499' } : {}),
        ...(id === 'web-live-sdk' ? { FLARE_LIVE_OUTPUT_DIR: join(output, 'web-live-sdk'), FLARE_RELEASE_CANDIDATE_ID: candidateBefore.candidateId } : {}),
        ...(id === 'package-certification' ? { FLARE_PACKAGE_EVIDENCE_DIR: join(output, 'package') } : {}),
        ...(id === 'security-audit' ? { FLARE_SECURITY_EVIDENCE_DIR: join(output, 'security') } : {}),
        ...(['website-interaction-visual', 'conversation-state-visual-check'].includes(id) ? {
          PLAYWRIGHT_WEBSITE_PORT: process.env.PLAYWRIGHT_WEBSITE_PORT ?? '4191',
          PLAYWRIGHT_REFERENCE_PORT: process.env.PLAYWRIGHT_REFERENCE_PORT ?? '4192',
        } : {}),
      },
    });
  } finally { closeSync(fd); }
  const status = result.status === 0 ? 'PASS' : 'FAIL';
  results.push({ id, status, exitCode: result.status, elapsedMs: Date.now() - started, evidence });
  writeFileSync(join(output, 'partial-results.json'), `${JSON.stringify(results, null, 2)}\n`);
  console.log(`${status}: ${evidence}`);
  if (status === 'FAIL') console.log(`${readFileSync(evidence, 'utf8').slice(-6000)}\n${result.error ?? ''}`);
}
const evidenceManifest = JSON.parse(readFileSync(join(root, 'spec/manual-evidence.json'), 'utf8'));
const unresolved = [...evidenceManifest.required, ...evidenceManifest.automated].filter((entry) => entry.status !== 'PASS' || !entry.evidence);
const readiness = readFileSync(join(root, 'docs/2.0-readiness-matrix.md'), 'utf8');
const blockers = readinessBlockers(readiness);
const sourceAfter = captureCandidate(candidateRoots);
const candidateAfter = currentCandidate();
const unchanged = sourceBefore.digest === sourceAfter.digest && candidateBefore.candidateId === candidateAfter.candidateId;
results.push({ id: 'candidate-integrity', status: unchanged ? 'PASS' : 'FAIL',
  reason: unchanged ? 'Source unchanged during validation' : 'Source changed during validation; rerun the complete release gate' });
const result = {
  candidate: JSON.parse(readFileSync(join(root, 'package.json'), 'utf8')).version,
  candidateId: candidateBefore.candidateId, candidateIdAfter: candidateAfter.candidateId, runLabel,
  startedAt: candidateBefore.createdAt, finishedAt: new Date().toISOString(),
  environment: { ...environment, loadAverageAtEnd: loadavg() },
  scope: filter ? 'DIAGNOSTIC_ONLY' : 'FULL', sourceBefore, sourceAfter, results, unresolvedEvidence: unresolved, blockers,
  // Missing review evidence is not an automatic test pass.
  ready: releaseReady({ diagnostic: !!filter, results, expectedChecks: checks.length + 1, unresolved, blockers }),
};
writeFileSync(join(output, 'result.json'), `${JSON.stringify(result, null, 2)}\n`);
const passed = results.filter((entry) => entry.status === 'PASS').length;
const markdown = [
  `# Release check ${result.scope} run ${runLabel}`, '',
  `- Candidate ID: \`${result.candidateId}\`${result.candidateIdAfter === result.candidateId ? '' : ` (changed to \`${result.candidateIdAfter}\` during the run)`}`,
  `- Source fingerprint: \`${sourceBefore.digest}\``, `- Started: ${result.startedAt}`, `- Finished: ${result.finishedAt}`,
  `- Gates: ${passed}/${results.length} PASS (expected ${checks.length + 1})`,
  `- Unresolved manual evidence: ${unresolved.length}${unresolved.length ? ` (${unresolved.map((entry) => entry.id).join(', ')})` : ''}`,
  `- Readiness-matrix blockers: ${blockers.length}`, `- Result: ${result.ready ? 'RELEASE_CHECK_PASS' : 'RELEASE_CHECK_NOT_READY'}`, '',
  '| Gate | Status | Exit | Elapsed |', '|---|---|---|---|',
  ...results.map((entry) => `| ${entry.id} | ${entry.status} | ${entry.exitCode ?? ''} | ${entry.elapsedMs === undefined ? '' : `${Math.round(entry.elapsedMs / 1000)}s`} |`), '',
].join('\n');
writeFileSync(join(output, 'report.md'), markdown);
writeFileSync(join(output, 'report.json'), `${JSON.stringify(result, null, 2)}\n`);
if (!filter) {
  // Latest full run is also mirrored to the fixed evidence paths the manifest reads.
  cpSync(join(output, 'report.json'), join(evidenceRoot, 'automation/report.json'));
  cpSync(join(output, 'report.md'), join(evidenceRoot, 'automation/report.md'));
  for (const [from, to, owned] of [['web-live-sdk', 'live-sdk', /^(report\.json|report\.md|events\.json|desktop\.png|mobile\.png|failure-\d+\.png)$/], ['package', 'package', /^(package-manifest\.json|tarball-hash\.txt|consumer-smoke\.json)$/], ['security', 'security', /^report\.json$/]]) {
    const target = join(evidenceRoot, to);
    mkdirSync(target, { recursive: true });
    for (const name of readdirSync(target)) if (owned.test(name)) rmSync(join(target, name));
    if (existsSync(join(output, from))) for (const name of readdirSync(join(output, from))) if (owned.test(name)) cpSync(join(output, from, name), join(target, name));
  }
  const live = join(evidenceRoot, 'live-sdk/report.json');
  if (existsSync(live)) {
    const report = JSON.parse(readFileSync(live, 'utf8'));
    writeFileSync(join(evidenceRoot, 'live-sdk/report.md'), [`# Web live SDK evidence — ${report.result}`, '',
      `- Candidate ID: \`${report.candidateId}\``, `- Release run: ${runLabel}`, `- Run ID: ${report.runId}`, `- Site: ${report.site}`,
      `- Browser: ${report.browser ?? ''}; wasm build: ${report.wasmBuild ?? ''}`, `- Flags: ${JSON.stringify(report.flags ?? {})}`,
      `- Counts: ${JSON.stringify(report.counts ?? {})}`, `- Latency: ${JSON.stringify(report.latency ?? {})}`,
      `- Covered: ${(report.coverage ?? []).join('; ')}`, `- Not covered: ${(report.notCovered ?? []).join('; ')}`,
      ...(report.error ? [`- Failure at step ${report.lastStep}: ${report.error}`] : []),
      '- Server environment: environment.json (recorded separately; no tokens or passwords).', ''].join('\n'));
  }
}
console.log(`\nRelease evidence: ${join(output, 'report.json')}`);
console.log(result.ready ? 'RELEASE_CHECK_PASS' : 'RELEASE_CHECK_NOT_READY');
process.exitCode = result.ready ? 0 : 1;
