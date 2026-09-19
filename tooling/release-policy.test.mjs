import assert from 'node:assert/strict';
import test from 'node:test';
import { readinessBlockers, releaseReady } from './release-policy.mjs';

const complete = { diagnostic: false, results: [{ id: 'test', status: 'PASS' }], expectedChecks: 1, unresolved: [], blockers: [] };
test('only the full passed closure may certify a release', () => {
  assert.equal(releaseReady(complete), true);
  for (const patch of [
    { diagnostic: true }, { results: [] }, { expectedChecks: 0 },
    { unresolved: [{ status: 'MANUAL_RELEASE_GATE' }] },
    { unresolved: [{ status: 'AUTOMATION_REQUIRED' }] }, { blockers: ['P1'] },
    { results: [{ id: 'test', status: 'FAIL' }] },
    { results: [complete.results[0], complete.results[0]], expectedChecks: 2 },
  ]) assert.equal(releaseReady({ ...complete, ...patch }), false);
});
test('matrix blocks partial and unreviewed implementation, not only failed tests', () => {
  const matrix = '| Area | Item | Status | Evidence | Priority | Owner | Action | Release Blocking? |\n'
    + ['FAIL', 'PARTIAL', 'REVIEW_REQUIRED', 'PASS', 'N/A'].map((status) => `| UI | Body | ${status} | test | P1 | kit | fix | Yes |`).join('\n');
  assert.equal(readinessBlockers(matrix).length, 3);
  assert.throws(() => readinessBlockers(''), /header/);
});
