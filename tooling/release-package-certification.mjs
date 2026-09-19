#!/usr/bin/env node
// Package certification for the Vue kit and tokens, run against the packed tarballs —
// never the workspace — and bound to the candidate id.
//
//   node tooling/release-package-certification.mjs
//
// Read-only with respect to the candidate: packing uses --ignore-scripts after the
// asset --check, every consumer lives in a temp directory, and the only files written
// are evidence under the gitignored artifacts/release-2.0/package/. The candidate id is
// taken before and after; a difference fails the run.
//
// Proves, in order:
//   1. packing is reproducible (two packs, identical sha256) and the contents are clean;
//   2. a clean consumer importing primitives, an IM component, hooks, the platform
//      adapter and its type, contracts, theme, i18n, the root entry and tokens passes
//      vue-tsc, vite build and a Chromium runtime smoke;
//   3. the same consumer passes at the declared peer-dependency floor;
//   4. importing one primitive does not ship IM-layer modules (tree-shaking).
import { execFileSync, spawn, spawnSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { cpSync, existsSync, lstatSync, mkdirSync, mkdtempSync, readFileSync, readdirSync, rmSync, writeFileSync } from 'node:fs';
import { createRequire } from 'node:module';
import { createServer } from 'node:net';
import { tmpdir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { currentCandidate } from './release-candidate-id.mjs';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
// release-check points this at its run directory; standalone runs write the fixed path.
const out = process.env.FLARE_PACKAGE_EVIDENCE_DIR ?? join(root, 'artifacts/release-2.0/package');
const fixture = join(root, 'tests/consumers/vue-clean');
const packages = [['tokens', join(root, 'tokens')], ['vue-ui', join(root, 'packages/vue-im-ui')]];
const TREESHAKE = ['a-primitive-components-entry', 'b-primitive-root-entry', 'c-all-components', 'd-vue-naive-baseline'];
const forbidden = /(^|\/)(node_modules|test-results|playwright-report|coverage|__tests__|\.vite)(\/|$)|\.(test|spec)\.[cm]?[jt]sx?$|\.(log|tmp|map|hprof)$|\.DS_Store$|(^|\/)\.env/;
const failures = [];
const findings = [];

function run(cwd, command, args, { env = {}, allowFail = false } = {}) {
  const result = spawnSync(command, args, { cwd, encoding: 'utf8', env: { ...process.env, ...env }, maxBuffer: 64 * 1024 * 1024, timeout: 600000 });
  const ok = result.status === 0;
  if (!ok && !allowFail) failures.push(`${command} ${args.join(' ')} (in ${cwd}) exited ${result.status ?? result.error}: ${(result.stderr || result.stdout || '').slice(-2000)}`);
  return { ok, status: result.status, stdout: result.stdout ?? '', stderr: result.stderr ?? '' };
}
const sha256 = (path) => createHash('sha256').update(readFileSync(path)).digest('hex');
const freePort = () => new Promise((resolve) => { const server = createServer(); server.listen(0, '127.0.0.1', () => { const { port } = server.address(); server.close(() => resolve(port)); }); });

const before = currentCandidate();
const stage = mkdtempSync(join(tmpdir(), 'flare-package-cert-'));
const evidence = { candidateId: before.candidateId, sourceFingerprint: before.sourceFingerprint, createdAt: new Date().toISOString(), node: process.version };

try {
  // 1. Pack twice, compare, audit.
  run(join(root, 'packages/vue-im-ui'), 'node', ['scripts/sync-pack-assets.mjs', '--check']);
  const manifests = {};
  const tarballs = {};
  for (const pass of ['pack-1', 'pack-2']) {
    mkdirSync(join(stage, pass));
    for (const [label, dir] of packages) {
      const result = run(dir, 'npm', ['pack', '--ignore-scripts', '--json', '--pack-destination', join(stage, pass)]);
      if (!result.ok) continue;
      const [pack] = JSON.parse(result.stdout);
      const path = join(stage, pass, pack.filename);
      if (pass === 'pack-1') { manifests[label] = pack; tarballs[label] = { path, file: pack.filename, sha256: sha256(path) }; }
      else if (tarballs[label] && sha256(path) !== tarballs[label].sha256) failures.push(`${label}: npm pack is not reproducible (${tarballs[label].sha256} vs ${sha256(path)})`);
    }
  }
  const packageManifest = {};
  for (const [label, dir] of packages) {
    const pack = manifests[label];
    if (!pack) continue;
    const manifest = JSON.parse(readFileSync(join(dir, 'package.json'), 'utf8'));
    const files = pack.files.map((file) => file.path);
    for (const path of files.filter((path) => forbidden.test(path))) failures.push(`${label}: forbidden file in tarball: ${path}`);
    const extract = join(stage, `extract-${label}`);
    mkdirSync(extract);
    execFileSync('tar', ['-xzf', tarballs[label].path, '-C', extract]);
    const exportTargets = [];
    for (const [subpath, target] of Object.entries(manifest.exports ?? {})) {
      for (const file of typeof target === 'string' ? [target] : Object.values(target)) {
        exportTargets.push(`${subpath} -> ${file}`);
        if (!existsSync(join(extract, 'package', file))) failures.push(`${label}: export ${subpath} target missing from tarball: ${file}`);
      }
    }
    if (label === 'vue-ui') {
      // Shipped binary assets nothing in the shipped source references are dead weight.
      const sources = files.filter((path) => /\.(ts|vue|css)$/.test(path)).map((path) => readFileSync(join(extract, 'package', path), 'utf8')).join('\n');
      for (const path of files.filter((path) => /\.(webp|png|jpe?g|gif|svg|woff2?)$/.test(path))) {
        const name = path.split('/').pop();
        if (!sources.includes(name)) findings.push({ severity: 'P2', id: 'PKG-UNREFERENCED-ASSET', detail: `${path} (${pack.files.find((file) => file.path === path).size} bytes) ships in the tarball but no shipped source references it; the exports map does not expose it either` });
      }
    }
    packageManifest[label] = {
      name: pack.name, version: pack.version, filename: pack.filename, sha256: tarballs[label].sha256, integrity: pack.integrity,
      packedBytes: pack.size, unpackedBytes: pack.unpackedSize, fileCount: files.length,
      exports: exportTargets, peerDependencies: manifest.peerDependencies ?? {}, dependencies: manifest.dependencies ?? {},
      sideEffects: manifest.sideEffects ?? null, largestFiles: [...pack.files].sort((a, b) => b.size - a.size).slice(0, 5).map((file) => `${file.path} ${file.size}`),
      files,
    };
  }

  // 2 + 3. Clean consumer at the resolved latest and at the peer floor.
  const chromium = createRequire(join(root, 'website/package.json'))('playwright').chromium;
  const vueManifest = JSON.parse(readFileSync(join(root, 'packages/vue-im-ui/package.json'), 'utf8'));
  const floor = (range) => range.replace(/^[\^~>=\s]+/, '');
  const consumers = [
    ['latest', {}],
    ['peer-floor', Object.fromEntries(Object.entries(vueManifest.peerDependencies).map(([name, range]) => [name, floor(range)]))],
  ];
  const consumerEvidence = {};
  for (const [label, pins] of consumers) {
    const dir = join(stage, `consumer-${label}`);
    cpSync(fixture, dir, { recursive: true, filter: (source) => !/[\\/](node_modules|dist|dist-[^\\/]+)$/.test(source) && !/ledger-.*\.json$/.test(source) });
    const manifest = JSON.parse(readFileSync(join(dir, 'package.json'), 'utf8'));
    manifest.dependencies['@flare-im/tokens'] = `file:${tarballs.tokens?.path}`;
    manifest.dependencies['@flare-im/vue-ui'] = `file:${tarballs['vue-ui']?.path}`;
    Object.assign(manifest.dependencies, pins);
    writeFileSync(join(dir, 'package.json'), `${JSON.stringify(manifest, null, 2)}\n`);
    const record = { pins };
    record.install = run(dir, 'npm', ['install', '--no-audit', '--no-fund']).ok;
    if (!record.install) { consumerEvidence[label] = record; continue; }
    const lock = JSON.parse(readFileSync(join(dir, 'package-lock.json'), 'utf8')).packages;
    record.resolved = Object.fromEntries(['@flare-im/vue-ui', '@flare-im/tokens', 'vue', 'naive-ui', 'vite', 'vue-tsc', 'typescript'].map((name) => [name, lock[`node_modules/${name}`]?.version]));
    for (const name of ['@flare-im/vue-ui', '@flare-im/tokens']) {
      const installed = join(dir, 'node_modules', name);
      const fromTarball = String(lock[`node_modules/${name}`]?.resolved ?? '').endsWith('.tgz') && !lstatSync(installed).isSymbolicLink();
      if (!fromTarball) failures.push(`${label}: ${name} was not installed from the packed tarball`);
    }
    for (const [name, version] of Object.entries(pins)) if (record.resolved[name] !== version) failures.push(`${label}: ${name} resolved ${record.resolved[name]}, expected ${version}`);
    // Peers must stay peers: a second copy of the framework in the tree means the kit (or
    // one of its dependencies) bundled what the host provides.
    record.frameworkCopies = Object.fromEntries(['vue', '@vue/runtime-core', 'naive-ui'].map((name) => [name,
      [...new Set(Object.entries(lock).filter(([path]) => path === `node_modules/${name}` || path.endsWith(`/node_modules/${name}`)).map(([, entry]) => entry.version))]]));
    for (const [name, versions] of Object.entries(record.frameworkCopies)) if (versions.length !== 1) failures.push(`${label}: ${name} is installed in ${versions.length} versions (${versions.join(', ')})`);
    const typecheck = run(dir, 'npx', ['vue-tsc', '--noEmit', '-p', 'tsconfig.json']);
    record.typecheck = typecheck.ok;
    // src/migration-smoke.ts is inside the typecheck: replacements import from the entries the
    // migration guide names, removed symbols fail to import, documented props exist.
    record.migrationSmoke = existsSync(join(dir, 'src/migration-smoke.ts')) && typecheck.ok;
    if (label === 'latest') {
      // What an application installs at runtime: the kit, tokens, their dependencies and the peers.
      const audit = run(dir, 'npm', ['audit', '--omit=dev', '--json'], { allowFail: true });
      try {
        const report = JSON.parse(audit.stdout);
        record.audit = { vulnerabilities: report.metadata?.vulnerabilities ?? null, prodDependencies: report.metadata?.dependencies?.prod ?? null,
          advisories: Object.values(report.vulnerabilities ?? {}).map((entry) => `${entry.name} ${entry.severity}`) };
        if (report.error || !report.metadata) failures.push(`npm audit could not run: ${JSON.stringify(report.error ?? report).slice(0, 300)}`);
        else if (report.metadata.vulnerabilities.critical || report.metadata.vulnerabilities.high) failures.push(`runtime dependency tree has critical/high vulnerabilities: ${record.audit.advisories.join(', ')}`);
      } catch { failures.push(`npm audit output unreadable: ${(audit.stdout || audit.stderr).slice(0, 300)}`); }
    }
    record.build = run(dir, 'npx', ['vite', 'build']).ok;
    if (record.build) record.runtime = await runtimeSmoke(chromium, dir);
    if (record.runtime && !record.runtime.pass) failures.push(`${label}: runtime smoke failed: ${JSON.stringify(record.runtime)}`);
    consumerEvidence[label] = record;

    // 4. Tree-shaking, once, on the latest consumer.
    if (label === 'latest') {
      const ledgers = {};
      for (const entry of TREESHAKE) {
        if (!run(dir, 'npx', ['vite', 'build', '-c', 'treeshake/vite.config.mjs'], { env: { ENTRY: entry } }).ok) continue;
        const ledger = JSON.parse(readFileSync(join(dir, `treeshake/ledger-${entry}.json`), 'utf8'));
        ledgers[entry] = { jsBytes: ledger.jsBytes, cssBytes: ledger.cssBytes, kitModuleCount: ledger.kitModuleCount, kitRenderedBytes: ledger.kitRenderedBytes, imModuleCount: ledger.imModules.length, markdownItModules: ledger.markdownItModules, kitModules: entry.startsWith('c-') ? undefined : ledger.kitModules };
      }
      for (const entry of ['a-primitive-components-entry', 'b-primitive-root-entry']) {
        const ledger = ledgers[entry];
        if (!ledger) { failures.push(`tree-shaking: ${entry} did not build`); continue; }
        if (ledger.imModuleCount !== 0) failures.push(`tree-shaking: ${entry} ships ${ledger.imModuleCount} IM-layer modules`);
        if (ledger.markdownItModules !== 0) failures.push(`tree-shaking: ${entry} ships markdown-it`);
      }
      const all = ledgers['c-all-components'];
      if (!all || all.imModuleCount === 0) failures.push('tree-shaking: the all-components control saw no IM modules, so the ledger cannot be trusted');
      consumerEvidence.treeShaking = {
        passCondition: 'Importing one primitive (from ./components or the root entry) ships zero modules from components/{call,composer,contacts,conversation,media,message-preview,messages,moments,profile,scenes,shell} and no markdown-it; the all-components control must ship IM modules.',
        ledgers,
      };
    }
  }

  const after = currentCandidate();
  if (after.candidateId !== before.candidateId || after.sourceFingerprint !== before.sourceFingerprint) failures.push(`candidate changed during certification: ${before.candidateId} -> ${after.candidateId}`);

  mkdirSync(out, { recursive: true });
  writeFileSync(join(out, 'package-manifest.json'), `${JSON.stringify({ ...evidence, packages: packageManifest, findings }, null, 2)}\n`);
  writeFileSync(join(out, 'tarball-hash.txt'), `# candidate ${before.candidateId}\n${Object.values(tarballs).map((tarball) => `${tarball.sha256}  ${tarball.file}`).join('\n')}\n`);
  writeFileSync(join(out, 'consumer-smoke.json'), `${JSON.stringify({ ...evidence, result: failures.length ? 'FAIL' : 'PASS', reproduciblePack: !failures.some((failure) => failure.includes('reproducible')), consumers: consumerEvidence, failures, findings }, null, 2)}\n`);
} finally {
  rmSync(stage, { recursive: true, force: true });
}

async function runtimeSmoke(chromium, dir) {
  const port = await freePort();
  const server = spawn('npx', ['vite', 'preview', '--port', String(port), '--strictPort', '--host', '127.0.0.1'], { cwd: dir, stdio: 'ignore' });
  const result = { consoleErrors: [], pageErrors: [], checks: {} };
  let browser;
  try {
    const url = `http://127.0.0.1:${port}/`;
    for (let attempt = 0; attempt < 60; attempt += 1) {
      try { if ((await fetch(url)).ok) break; } catch { /* server still starting */ }
      await new Promise((resolve) => setTimeout(resolve, 500));
    }
    browser = await chromium.launch();
    const page = await browser.newPage();
    page.on('console', (message) => { if (message.type() === 'error') result.consoleErrors.push(message.text()); });
    page.on('pageerror', (error) => result.pageErrors.push(String(error)));
    await page.goto(url);
    await page.locator('#smoke').waitFor({ timeout: 20000 });
    const button = page.getByRole('button', { name: 'Consumer ready' });
    result.checks.buttonVisible = await button.isVisible();
    result.checks.conversationRows = (await page.getByText('Consumer Alice').count()) + (await page.getByText('Consumer Bob').count());
    result.checks.iconSvg = await page.locator('#smoke svg').count();
    await button.click();
    result.checks.clickHandled = (await page.locator('#selected').textContent()) === 'button';
    if (result.checks.conversationRows === 2) {
      await page.getByText('Consumer Bob').click();
      result.checks.rowSelectEmitted = (await page.locator('#selected').textContent()) === 'c2';
    }
    result.checks.tokenCustomProperty = await page.evaluate(() => [document.documentElement, ...document.querySelectorAll('#app *')].some((element) => getComputedStyle(element).getPropertyValue('--flare-color-text-primary').trim() !== ''));
    result.browser = browser.version();
  } catch (error) {
    result.error = String(error).slice(0, 500);
  } finally {
    await browser?.close();
    server.kill();
  }
  const { checks } = result;
  result.pass = !result.error && !result.consoleErrors.length && !result.pageErrors.length && checks.buttonVisible && checks.conversationRows === 2
    && checks.iconSvg > 0 && checks.clickHandled && checks.rowSelectEmitted && checks.tokenCustomProperty;
  return result;
}

if (failures.length) {
  console.error('package certification FAILED:');
  for (const failure of failures) console.error(`  ${failure}`);
  process.exit(1);
}
console.log(`package certification PASS for ${before.candidateId}: reproducible pack, clean consumer (latest + peer floor) typecheck/build/runtime, tree-shaking; ${findings.length} non-blocking finding(s); evidence in artifacts/release-2.0/package/`);
