#!/usr/bin/env node
// release:evidence-check — evaluates spec/release-requirements.json against the evidence
// under artifacts/release-2.0 and writes artifacts/release-2.0/evidence-manifest.json.
//
//   node tooling/check-release-evidence.mjs                 # write the manifest, print the summary
//   node tooling/check-release-evidence.mjs --require-ready # also exit 1 while any P0 is unresolved
//
// Evidence is valid only for the candidate it names. A file produced for an earlier
// candidate id is STALE, never PASS — old evidence cannot certify a new tree.
// This tool reads the repository and writes only under the gitignored artifacts/.
import { createHash } from 'node:crypto';
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { execFileSync } from 'node:child_process';
import { readinessBlockers } from './release-policy.mjs';
import { currentCandidate } from './release-candidate-id.mjs';
import { writeCriteriaReport } from './release-criteria-coverage.mjs';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const evidenceRoot = join(root, 'artifacts/release-2.0');
const spec = JSON.parse(readFileSync(join(root, 'spec/release-requirements.json'), 'utf8'));
const manualLedger = JSON.parse(readFileSync(join(root, 'spec/manual-evidence.json'), 'utf8'));
const releaseCheck = readFileSync(join(root, 'tooling/release-check.mjs'), 'utf8');
const closurePlan = readFileSync(join(root, 'docs/release/2.0-final-closure-plan.md'), 'utf8');
const candidate = currentCandidate();
const specErrors = [];

// --- consistency of the graph itself ---------------------------------------------------
const ids = spec.requirements.map((requirement) => requirement.id);
if (new Set(ids).size !== ids.length) specErrors.push('spec/release-requirements.json: duplicate requirement id');
const gateIds = new Set([...releaseCheck.matchAll(/^\s+\['([a-z0-9-]+)',/gm)].map((match) => match[1]).concat('candidate-integrity'));
for (const requirement of spec.requirements) {
  for (const dependency of requirement.dependsOn) if (!ids.includes(dependency)) specErrors.push(`${requirement.id}: unknown dependency ${dependency}`);
  for (const evidence of requirement.evidence) {
    if (!spec.evidenceChecks[evidence.check]) specErrors.push(`${requirement.id}: unknown evidence check ${evidence.check}`);
    for (const gate of evidence.gates ?? []) if (!gateIds.has(gate)) specErrors.push(`${requirement.id}: release-check has no gate ${gate}`);
  }
  if (!closurePlan.includes(requirement.id)) specErrors.push(`docs/release/2.0-final-closure-plan.md does not name ${requirement.id}`);
}
for (const entry of [...manualLedger.required, ...manualLedger.automated]) {
  if (!ids.includes(entry.id)) specErrors.push(`spec/manual-evidence.json ${entry.id} has no requirement in spec/release-requirements.json`);
}

// --- candidate-bound records this tool owns --------------------------------------------
// Per-file hashes of every committed visual baseline, so a baseline update is auditable
// file by file rather than through one aggregate fingerprint.
const listed = execFileSync('git', ['ls-files', '-z', '--cached', '--others', '--exclude-standard'], { cwd: root, maxBuffer: 32 * 1024 * 1024 })
  .toString().split('\0').filter((name) => /^(tests\/visual\/.*|packages\/flutter-im-ui\/test\/goldens\/.*)\.png$/.test(name)).sort();
const baselines = listed.map((name) => ({ path: name, sha256: createHash('sha256').update(readFileSync(join(root, name))).digest('hex') }));
mkdirSync(join(evidenceRoot, 'visual'), { recursive: true });
writeFileSync(join(evidenceRoot, 'visual/baseline-hashes.json'), `${JSON.stringify({
  candidateId: candidate.candidateId, createdAt: new Date().toISOString(), count: baselines.length,
  platforms: Object.fromEntries(['vue/baselines/darwin', 'vue/baselines/linux', 'ios', 'compose', 'flutter'].map((prefix) => [prefix, baselines.filter((entry) => entry.path.includes(prefix)).length])),
  baselines,
}, null, 2)}\n`);
// The environment the Linux visual job must run in. It records the current workflow as it
// is, including what is not pinned, so the gap is explicit rather than implied.
const workflow = readFileSync(join(root, '.github/workflows/ci.yml'), 'utf8');
const websiteJob = workflow.split(/^  website:/m)[1]?.split(/^  [a-z]+:\s*$/m)[0] ?? '';
const playwrightVersion = JSON.parse(readFileSync(join(root, 'node_modules/@playwright/test/package.json'), 'utf8')).version;
mkdirSync(join(evidenceRoot, 'ci'), { recursive: true });
writeFileSync(join(evidenceRoot, 'ci/environment.json'), `${JSON.stringify({
  candidateId: candidate.candidateId, createdAt: new Date().toISOString(),
  workflow: '.github/workflows/ci.yml', job: 'website',
  runsOn: websiteJob.match(/runs-on:\s*(\S+)/)?.[1] ?? null,
  node: websiteJob.match(/node-version:\s*(\S+)/)?.[1] ?? null,
  browserInstall: websiteJob.match(/playwright install[^\n]*/)?.[0] ?? null,
  command: websiteJob.match(/run: (npm --prefix website run test:visual[^\n]*)/)?.[1] ?? null,
  playwrightVersion,
  snapshotPathTemplate: '../tests/visual/vue/baselines/{platform}/{arg}{ext}',
  linuxBaselines: baselines.filter((entry) => entry.path.includes('vue/baselines/linux')).length,
  darwinBaselines: baselines.filter((entry) => entry.path.includes('vue/baselines/darwin')).length,
  pinned: { container: /container:/.test(websiteJob), runnerImage: !/ubuntu-latest/.test(websiteJob) },
  requiredForCertification: 'Run inside one pinned image (for example mcr.microsoft.com/playwright:v' + playwrightVersion + '-noble) so fonts and rasterization do not drift between the baseline run and later runs; ubuntu-latest plus `playwright install --with-deps` is not a fixed environment.',
}, null, 2)}\n`);

// Release-criteria §1 / §3 rows that no gate implements: measured, never assumed.
writeCriteriaReport(candidate.candidateId);

// --- evaluation ------------------------------------------------------------------------
const readJson = (path) => { try { return JSON.parse(readFileSync(join(root, path), 'utf8')); } catch { return undefined; } };
const at = (object, path) => path.split('.').reduce((value, key) => (value == null ? undefined : value[key]), object);

function evaluate(evidence) {
  const record = { ...evidence };
  if (evidence.check === 'manual-evidence') {
    const entry = [...manualLedger.required, ...manualLedger.automated].find((item) => item.id === evidence.id);
    record.ledgerStatus = entry?.status ?? null;
    if (!entry || entry.status !== 'PASS' || !entry.evidence) return { ...record, result: 'NOT_RUN', reason: `spec/manual-evidence.json status ${entry?.status ?? 'missing'}` };
    record.path = entry.evidence;
    const file = readJson(entry.evidence);
    if (!file) return { ...record, result: 'FAIL', reason: 'ledger says PASS but the evidence file is missing or not JSON' };
    if (file.candidateId !== candidate.candidateId) return { ...record, result: 'STALE', candidateId: file.candidateId ?? null };
    return { ...record, candidateId: file.candidateId, result: file.result === 'PASS' ? 'PASS' : 'FAIL' };
  }
  if (evidence.check === 'readiness') {
    const blockers = readinessBlockers(readFileSync(join(root, evidence.path), 'utf8'));
    return { ...record, blockers: blockers.length, result: blockers.length ? 'FAIL' : 'PASS' };
  }
  if (!existsSync(join(root, evidence.path))) return { ...record, result: 'NOT_RUN', reason: 'evidence file absent' };
  if (evidence.check === 'file-exists') return { ...record, result: 'PASS' };
  const file = readJson(evidence.path);
  if (!file) return { ...record, result: 'FAIL', reason: 'not JSON' };
  record.candidateId = file.candidateId ?? null;
  if (evidence.check === 'candidate-file') {
    if (file.candidateId !== candidate.candidateId || file.sourceFingerprint !== candidate.sourceFingerprint) return { ...record, result: 'STALE' };
    return { ...record, result: 'PASS' };
  }
  if (file.candidateId !== candidate.candidateId) return { ...record, result: 'STALE' };
  if (evidence.check === 'json-pass-candidate') return { ...record, result: 'PASS' };
  if (evidence.check === 'release-run') {
    if (file.scope !== 'FULL') return { ...record, result: 'FAIL', reason: `scope ${file.scope}` };
    if (file.candidateIdAfter !== file.candidateId) return { ...record, result: 'FAIL', reason: 'candidate changed during the run' };
    const wanted = evidence.gates ?? file.results.map((entry) => entry.id);
    const failing = wanted.filter((gate) => file.results.find((entry) => entry.id === gate)?.status !== 'PASS');
    return { ...record, runLabel: file.runLabel, result: failing.length ? 'FAIL' : 'PASS', ...(failing.length ? { failing } : {}) };
  }
  if (evidence.check === 'json-pass') {
    const failed = (evidence.assert ?? []).filter(([path, expected]) => at(file, path) !== expected).map(([path, expected]) => `${path}=${JSON.stringify(at(file, path))} (expected ${JSON.stringify(expected)})`);
    const verdict = at(file, evidence.resultPath ?? 'result');
    if (verdict !== 'PASS') failed.unshift(`${evidence.resultPath ?? 'result'}=${verdict}`);
    return { ...record, result: failed.length ? 'FAIL' : 'PASS', ...(failed.length ? { failed } : {}) };
  }
  return { ...record, result: 'FAIL', reason: `unhandled check ${evidence.check}` };
}

const ORDER = ['FAIL', 'STALE', 'NOT_RUN', 'PASS'];
const evaluated = spec.requirements.map((requirement) => {
  const evidence = requirement.evidence.map(evaluate);
  let result = ORDER.find((status) => evidence.some((entry) => entry.result === status)) ?? 'PASS';
  if (result === 'NOT_RUN' && requirement.externalEnvironment) result = 'BLOCKED_EXTERNAL_ENV';
  return { requirementId: requirement.id, title: requirement.title, category: requirement.category, platform: requirement.platform, priority: requirement.priority,
    dependsOn: requirement.dependsOn, evidence, result, ...(requirement.externalEnvironment ? { blocker: requirement.externalEnvironment } : {}) };
});
const byId = new Map(evaluated.map((entry) => [entry.requirementId, entry]));
for (const entry of evaluated) entry.dependenciesSatisfied = entry.dependsOn.every((id) => byId.get(id)?.result === 'PASS');

const count = (status) => evaluated.filter((entry) => entry.result === status).length;
const unresolvedP0 = evaluated.filter((entry) => entry.priority === 'P0' && (entry.result !== 'PASS' || !entry.dependenciesSatisfied));
const manifest = {
  candidateId: candidate.candidateId, sourceFingerprint: candidate.sourceFingerprint, generatedAt: new Date().toISOString(),
  specErrors,
  summary: { requirements: evaluated.length, PASS: count('PASS'), FAIL: count('FAIL'), NOT_RUN: count('NOT_RUN'), BLOCKED_EXTERNAL_ENV: count('BLOCKED_EXTERNAL_ENV'), STALE: count('STALE'), unresolvedP0: unresolvedP0.length },
  unresolvedP0: unresolvedP0.map((entry) => ({ requirementId: entry.requirementId, result: entry.result, dependenciesSatisfied: entry.dependenciesSatisfied, ...(entry.blocker ? { blocker: entry.blocker } : {}) })),
  requirements: evaluated,
};
mkdirSync(evidenceRoot, { recursive: true });
writeFileSync(join(evidenceRoot, 'evidence-manifest.json'), `${JSON.stringify(manifest, null, 2)}\n`);

if (specErrors.length) {
  console.error('release evidence spec errors:');
  for (const error of specErrors) console.error(`  ${error}`);
  process.exit(1);
}
console.log(`release evidence for ${candidate.candidateId}: ${JSON.stringify(manifest.summary)}`);
for (const entry of unresolvedP0) console.log(`  ${entry.result.padEnd(20)} ${entry.requirementId}${entry.dependenciesSatisfied ? '' : ' (dependency unresolved)'}`);
if (process.argv.includes('--require-ready') && unresolvedP0.length) process.exit(1);
