#!/usr/bin/env node
// Measures the release-criteria §1 rows that no release:check gate implements, so the
// certification can say PASS or FAIL for them instead of leaving them unmentioned.
//
//   node tooling/release-criteria-coverage.mjs   # writes artifacts/release-2.0/criteria/report.json
//
// This is a measurement, not a gate: it always exits 0 and records each row's result.
// Implementing the missing gates is product work tracked by the requirements
// REL-CRITERIA-COMPONENT-TESTS, REL-CRITERIA-RESPONSIVE and EXAMPLE-PARITY.
import { existsSync, mkdirSync, readFileSync, readdirSync, statSync, writeFileSync } from 'node:fs';
import { basename, dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');

function walk(dir, predicate, files = []) {
  if (!existsSync(dir)) return files;
  for (const name of readdirSync(dir)) {
    const path = join(dir, name);
    if (statSync(path).isDirectory()) { if (!['node_modules', 'build', '.build', '.dart_tool'].includes(name)) walk(path, predicate, files); }
    else if (predicate(name)) files.push(path);
  }
  return files;
}
const read = (files) => files.map((file) => readFileSync(file, 'utf8')).join('\n');
const escape = (text) => text.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

export function measureCriteria() {
  const spec = JSON.parse(readFileSync(join(root, 'spec/components.json'), 'utf8'));
  const catalog = JSON.parse(readFileSync(join(root, 'spec/component-catalog.json'), 'utf8'));
  const stable = new Set((catalog.components ?? catalog).filter((entry) => String(entry.status).toLowerCase() === 'stable').map((entry) => entry.name));

  // component — "每个 STABLE 公开组件 ≥1 组件级测试". A component counts as tested when a
  // platform test suite references its symbol (or, for Vue, imports its SFC). Website
  // preview scans (axe, productization) render every component but assert page-level
  // properties, so they are reported separately and do not count here.
  const facade = readFileSync(join(root, 'packages/vue-im-ui/src/components/index.ts'), 'utf8');
  const vueFile = new Map([...facade.matchAll(/export \{ default as (\w+) \} from "\.\/([^"]+)"/g)].map((match) => [match[1], basename(match[2], '.vue')]));
  const suites = {
    vue: read(walk(join(root, 'packages/vue-im-ui/src'), (name) => name.endsWith('.test.ts'))),
    flutter: read(walk(join(root, 'packages/flutter-im-ui/test'), (name) => name.endsWith('.dart'))),
    compose: read([...walk(join(root, 'packages/android-im-ui/src/test'), (name) => name.endsWith('.kt')), ...walk(join(root, 'packages/android-im-ui/src/androidTest'), (name) => name.endsWith('.kt'))]),
    ios: read(walk(join(root, 'packages/ios-im-ui/Tests'), (name) => name.endsWith('.swift'))),
  };
  const perPlatform = Object.fromEntries(Object.keys(suites).map((platform) => [platform, { withSymbol: 0, tested: 0 }]));
  const untested = [];
  for (const component of spec.components.filter((entry) => stable.has(entry.name))) {
    let any = false;
    for (const platform of Object.keys(suites)) {
      const symbol = component.platforms?.[platform]?.symbol;
      if (!symbol) continue;
      perPlatform[platform].withSymbol += 1;
      const file = platform === 'vue' ? vueFile.get(symbol) : null;
      const hit = new RegExp(`\\b${escape(symbol)}\\b`).test(suites[platform]) || (file && new RegExp(`[/"']${escape(file)}(\\.vue)?["']`).test(suites[platform]));
      if (hit) { perPlatform[platform].tested += 1; any = true; }
    }
    if (!any) untested.push(component.name);
  }
  const componentTests = {
    criterion: '2.0-release-criteria.md §1 component: every STABLE public component has at least one component-level test',
    stable: stable.size, testedOnAnyPlatform: stable.size - untested.length, untested, perPlatform,
    result: untested.length ? 'FAIL' : 'PASS',
  };

  // responsive — "320/360/375/390/430/768/834/1024/1280/1440 × 核心组件，横向溢出=0".
  const widths = [320, 360, 375, 390, 430, 768, 834, 1024, 1280, 1440];
  const specs = walk(join(root, 'website/tests'), (name) => name.endsWith('.spec.ts'));
  const coverage = Object.fromEntries(widths.map((width) => [width, specs.filter((file) => new RegExp(`\\b${width}\\b`).test(readFileSync(file, 'utf8'))).map((file) => basename(file))]));
  const matrixSpec = specs.find((file) => { const source = readFileSync(file, 'utf8'); return widths.every((width) => new RegExp(`\\b${width}\\b`).test(source)) && /scrollWidth|overflow/i.test(source); });
  const responsive = {
    criterion: '2.0-release-criteria.md §1 responsive: the ten widths x core components with zero horizontal overflow',
    widthsWithAnySpec: widths.filter((width) => coverage[width].length).length, widthsWithoutSpec: widths.filter((width) => !coverage[width].length),
    matrixSpec: matrixSpec ? basename(matrixSpec) : null, coverage,
    result: matrixSpec ? 'PASS' : 'FAIL',
  };

  // examples — "docs/release/example-parity.md" with the six-value vocabulary.
  const parityPath = join(root, 'docs/release/example-parity.md');
  const vocabulary = new Set(['PASS_RUNTIME', 'PASS_TEST', 'PASS_BUILD', 'SIMULATED', 'UNSUPPORTED', 'FAIL']);
  let exampleParity;
  if (!existsSync(parityPath)) {
    exampleParity = { criterion: '2.0-release-criteria.md §3', exists: false, result: 'FAIL', reason: 'docs/release/example-parity.md does not exist; docs/2.0-reference-app-feature-matrix.md uses SUPPORTED / PARTIAL / N/A, not the evidence vocabulary' };
  } else {
    const rows = readFileSync(parityPath, 'utf8').split('\n').filter((line) => line.startsWith('|') && !/^\|\s*-/.test(line)).slice(1);
    const invalid = rows.flatMap((row) => row.split('|').slice(2, -1).map((cell) => cell.trim()).filter((cell) => !vocabulary.has(cell.split(/\s/)[0])));
    exampleParity = { criterion: '2.0-release-criteria.md §3', exists: true, rows: rows.length, invalidCells: invalid.length, result: rows.length && !invalid.length && !rows.some((row) => /\|\s*FAIL\b/.test(row)) ? 'PASS' : 'FAIL' };
  }
  return { componentTests, responsive, exampleParity };
}

export function writeCriteriaReport(candidateId) {
  const items = measureCriteria();
  const report = { candidateId, createdAt: new Date().toISOString(), level: 'L1_STATIC', result: Object.values(items).every((item) => item.result === 'PASS') ? 'PASS' : 'FAIL', items };
  mkdirSync(join(root, 'artifacts/release-2.0/criteria'), { recursive: true });
  writeFileSync(join(root, 'artifacts/release-2.0/criteria/report.json'), `${JSON.stringify(report, null, 2)}\n`);
  return report;
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const { currentCandidate } = await import('./release-candidate-id.mjs');
  const report = writeCriteriaReport(currentCandidate().candidateId);
  for (const [key, item] of Object.entries(report.items)) console.log(`${item.result.padEnd(4)} ${key}`);
}
