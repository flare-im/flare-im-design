import { expect, it } from 'vitest';
import { transferActions, transferProgress } from './transfer';
it('offers recovery only in recoverable states and open only after completion', () => {
  expect(transferActions.failed).toEqual(['retry']);
  expect(transferActions.completed).toEqual(['open']);
  expect(transferActions.transferring).toEqual(['pause', 'cancel']);
  expect(transferActions.paused).toEqual(['resume', 'cancel']);
  expect(transferActions.queued).toEqual(['cancel']);
  expect(transferActions.cancelled).toEqual(['retry']);
});
it('distinguishes zero from unknown and sanitizes invalid adapter progress', () => {
  expect(transferProgress('transferring', 0)).toBe(0);
  for (const v of [undefined, null, NaN, Infinity]) expect(transferProgress('transferring', v)).toBeNull();
  expect(transferProgress('paused', -.2)).toBe(0);
  expect(transferProgress('transferring', 1.2)).toBe(1);
  expect(transferProgress('completed', null)).toBe(1);
});
