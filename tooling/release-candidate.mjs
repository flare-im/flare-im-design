import { execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { lstatSync, readFileSync, readlinkSync } from 'node:fs';
import { join } from 'node:path';

// Include untracked source in dirty worktrees without hashing ignored build caches.
export function captureCandidate(roots) {
  const hash = createHash('sha256');
  const repositories = [];
  for (const [label, root] of roots) {
    const names = execFileSync('git', ['ls-files', '-z', '--cached', '--others', '--exclude-standard'],
      { cwd: root, maxBuffer: 32 * 1024 * 1024 }).toString().split('\0').filter(Boolean);
    let files = 0;
    for (const name of [...new Set(names)].sort()) {
      const path = join(root, name);
      let stat;
      try { stat = lstatSync(path); }
      catch (error) { if (error.code === 'ENOENT') continue; throw error; }
      if (!stat.isFile() && !stat.isSymbolicLink()) continue;
      hash.update(`${label}\0${name}\0${stat.mode}\0`);
      hash.update(stat.isSymbolicLink() ? readlinkSync(path) : readFileSync(path));
      hash.update('\0');
      files += 1;
    }
    repositories.push({ label, files });
  }
  return { algorithm: 'sha256', digest: hash.digest('hex'), repositories };
}
