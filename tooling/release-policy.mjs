export function readinessBlockers(markdown) {
  const rows = markdown.split('\n').filter((line) => line.startsWith('|'));
  if (!rows.some((row) => row.includes('Release Blocking?'))) throw new Error('Missing release matrix header');
  return rows.filter((row) => {
    const cells = row.split('|').map((cell) => cell.trim());
    return cells.at(-2) === 'Yes' && !['PASS', 'N/A'].includes(cells[3]);
  });
}

export function releaseReady({ diagnostic, results, expectedChecks, unresolved, blockers }) {
  return !diagnostic && results.length === expectedChecks && expectedChecks > 0
    && new Set(results.map((entry) => entry.id)).size === expectedChecks
    && results.every((entry) => entry.status === 'PASS')
    && unresolved.length === 0 && blockers.length === 0;
}
