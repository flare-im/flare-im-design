#!/usr/bin/env node
// Candidate ID — the one identity every piece of 2.0 release evidence binds to.
//
//   node tooling/release-candidate-id.mjs            # print the current candidate
//   node tooling/release-candidate-id.mjs --write    # also write artifacts/release-2.0/candidate.json
//
// Two fingerprints, on purpose:
//
// * `sourceFingerprint` is exactly what release:check's candidate-integrity hashes
//   (tooling/release-candidate.mjs over the design repo, the client SDK and the
//   five examples). It covers everything and proves nothing changed DURING a run.
//
// * `candidateId` is what evidence binds to ACROSS runs and days. It hashes the same
//   files minus the release *ledgers* — the documents that record verdicts about the
//   candidate (manual-evidence status, readiness matrix, final report, closure plan,
//   external validation packet, and the inventory that counts their bytes). If those
//   were inside the id, writing down a device result would change the id and make
//   that very result stale; nothing could ever be certified. Everything that ships
//   or decides behaviour — source, tests, tokens, public API, baselines, criteria —
//   stays inside.
import { execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { lstatSync, mkdirSync, readFileSync, readlinkSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { captureCandidate } from './release-candidate.mjs';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const sdk = join(root, '../flare-im-core-client-sdk');
const app = (name) => join(sdk, 'examples', `flare-core-${name}-app`);
export const candidateRoots = [['design', root], ['sdk', sdk], ...['web', 'tauri', 'flutter', 'android', 'ios'].map((name) => [name, app(name)])];

/** Release ledgers: records of verdicts about the candidate, not part of it. */
export const LEDGER_PATHS = new Set([
  'spec/manual-evidence.json',
  'docs/2.0-readiness-matrix.md',
  'docs/repository-inventory.md',
  'docs/release/2.0-final-report.md',
  'docs/release/2.0-final-closure-plan.md',
  'docs/release/2.0-external-validation.md',
  'docs/release/2.0-manual-evidence-checklist.md',
  'docs/release/2.0-support-matrix.md',
  'docs/release/2.0-gap-analysis.md',
  'docs/release/native-gesture-matrix.md',
]);

const listFiles = (repo) => execFileSync('git', ['ls-files', '-z', '--cached', '--others', '--exclude-standard'],
  { cwd: repo, maxBuffer: 32 * 1024 * 1024 }).toString().split('\0').filter(Boolean);

function hashFiles(repo, names) {
  const hash = createHash('sha256');
  let count = 0;
  for (const name of [...new Set(names)].sort()) {
    const path = join(repo, name);
    let stat;
    try { stat = lstatSync(path); } catch (error) { if (error.code === 'ENOENT') continue; throw error; }
    if (!stat.isFile() && !stat.isSymbolicLink()) continue;
    hash.update(`${name}\0${stat.mode}\0`);
    hash.update(stat.isSymbolicLink() ? readlinkSync(path) : readFileSync(path));
    hash.update('\0');
    count += 1;
  }
  return { digest: hash.digest('hex'), files: count };
}

const gitHead = (repo) => {
  try { return execFileSync('git', ['rev-parse', 'HEAD'], { cwd: repo }).toString().trim(); } catch { return null; }
};

export function currentCandidate() {
  const design = listFiles(root);
  const pick = (predicate) => hashFiles(root, design.filter(predicate));
  const idHash = createHash('sha256');
  const scopes = {};
  for (const [label, repo] of candidateRoots) {
    const names = listFiles(repo).filter((name) => label !== 'design' || !LEDGER_PATHS.has(name));
    const scope = hashFiles(repo, names);
    scopes[label] = scope;
    idHash.update(`${label}\0${scope.digest}\0`);
  }
  const version = (path) => JSON.parse(readFileSync(join(root, path), 'utf8')).version;
  const fingerprints = {
    publicApi: pick((name) => /^packages\/vue-im-ui\/src\/(components|composables|contracts|utils)\/index\.ts$|^packages\/vue-im-ui\/src\/index\.ts$|^packages\/vue-im-ui\/package\.json$|^spec\/public-api-exceptions\.json$|^PUBLIC_API\.md$/.test(name)).digest,
    tokens: pick((name) => /^tokens\/(tokens|themes)\.json$/.test(name)).digest,
    snapshots: pick((name) => /^tests\/visual\/.*\.png$/.test(name)).digest,
    releaseCriteria: pick((name) => name === 'docs/release/2.0-release-criteria.md' || name === 'tooling/release-policy.mjs' || name === 'tooling/release-check.mjs').digest,
    componentContracts: pick((name) => name === 'spec/components.json' || name === 'spec/component-catalog.json').digest,
  };
  for (const [key, value] of Object.entries(fingerprints)) idHash.update(`${key}\0${value}\0`);
  const versions = { root: version('package.json'), vueUi: version('packages/vue-im-ui/package.json'), tokens: version('tokens/package.json') };
  idHash.update(JSON.stringify(versions));
  const source = captureCandidate(candidateRoots);
  return {
    candidateId: `flare-im-design@${versions.vueUi}+${idHash.digest('hex').slice(0, 16)}`,
    createdAt: new Date().toISOString(),
    versions,
    gitCommit: { design: gitHead(root), sdk: gitHead(sdk) },
    sourceFingerprint: source.digest,
    inventoryFingerprint: hashFiles(root, ['docs/repository-inventory.md']).digest,
    fingerprints,
    scopes,
    ledgerPathsExcludedFromId: [...LEDGER_PATHS],
    note: 'Working trees are largely uncommitted (a parallel 2.0 restructure); gitCommit names the ancestor only. candidateId and sourceFingerprint are computed from file contents, not from commits.',
  };
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const candidate = currentCandidate();
  if (process.argv.includes('--write')) {
    // Freeze record (brief §45): the working-tree state the candidate was frozen from.
    // Hashes only — the diff itself stays in git — so the record is small and comparable.
    const sha = (text) => createHash('sha256').update(text).digest('hex');
    const git = (repo, args) => { try { return execFileSync('git', args, { cwd: repo, maxBuffer: 256 * 1024 * 1024 }).toString(); } catch { return ''; } };
    candidate.freeze = Object.fromEntries(candidateRoots.map(([label, repo]) => {
      const status = git(repo, ['status', '--porcelain=v1', '--untracked-files=all']);
      return [label, { head: gitHead(repo), statusEntries: status.split('\n').filter(Boolean).length, statusSha256: sha(status), diffSha256: sha(git(repo, ['diff', '--binary', 'HEAD'])) }];
    }));
    const out = join(root, 'artifacts/release-2.0/candidate.json');
    mkdirSync(dirname(out), { recursive: true });
    writeFileSync(out, `${JSON.stringify(candidate, null, 2)}\n`);
  }
  console.log(JSON.stringify({ candidateId: candidate.candidateId, sourceFingerprint: candidate.sourceFingerprint.slice(0, 16), fingerprints: Object.fromEntries(Object.entries(candidate.fingerprints).map(([k, v]) => [k, v.slice(0, 12)])) }, null, 2));
}
