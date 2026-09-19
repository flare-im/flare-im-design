import assert from 'node:assert/strict';
import { execFileSync } from 'node:child_process';
import { mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import test from 'node:test';
import { captureCandidate } from './release-candidate.mjs';

test('candidate fingerprints include untracked edits but not ignored outputs', () => {
  const root = mkdtempSync(join(tmpdir(), 'flare-candidate-test-'));
  try {
    execFileSync('git', ['init', '--quiet'], { cwd: root });
    writeFileSync(join(root, '.gitignore'), 'cache\n');
    writeFileSync(join(root, 'source.ts'), 'export const version = 1;');
    const capture = () => captureCandidate([['fixture', root]]);
    const first = capture();
    assert.equal(first.repositories[0].files, 2);
    writeFileSync(join(root, 'cache'), 'ignored build output');
    assert.equal(capture().digest, first.digest);
    writeFileSync(join(root, 'source.ts'), 'export const version = 2;');
    assert.notEqual(capture().digest, first.digest);
    const changed = capture();
    writeFileSync(join(root, 'new.ts'), 'export {};');
    assert.notEqual(capture().digest, changed.digest);
  } finally { rmSync(root, { force: true, recursive: true }); }
});

test('repository ignore rules exclude VitePress temporary bundles, not documentation source', () => {
  const root = mkdtempSync(join(tmpdir(), 'flare-candidate-site-test-'));
  try {
    execFileSync('git', ['init', '--quiet'], { cwd: root });
    writeFileSync(join(root, '.gitignore'), readFileSync(new URL('../.gitignore', import.meta.url)));
    const cache = join(root, 'website/.vitepress/.temp');
    mkdirSync(cache, { recursive: true });
    const source = join(root, 'website/index.md');
    writeFileSync(source, '# Components');
    const capture = () => captureCandidate([['fixture', root]]);
    const first = capture();
    writeFileSync(join(cache, 'bundle.js'), 'generated output');
    assert.equal(capture().digest, first.digest);
    rmSync(cache, { recursive: true });
    assert.equal(capture().digest, first.digest);
    writeFileSync(source, '# Updated components');
    assert.notEqual(capture().digest, first.digest);
  } finally { rmSync(root, { force: true, recursive: true }); }
});
