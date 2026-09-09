import { describe, expect, it } from 'vitest';
import vectors from '../../../../spec/device-layout-vectors.json';
import { paneCount } from './layout-policy';
describe('cross-platform available-width contract', () => {
  for (const v of vectors) it(JSON.stringify(v), () => expect(paneCount(v.width, v.detail, v.scale)).toBe(v.expected));
  it('reserves actual custom columns', () => expect(paneCount(1100, true, 1, 600, 400)).toBe(2));
});
