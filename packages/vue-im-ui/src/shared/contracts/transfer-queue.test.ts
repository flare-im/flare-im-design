import { describe,it,expect } from 'vitest';
import { retryableTransferIds,type TransferQueueItem } from './transfer';
describe('retry failed batch',()=>{it('excludes busy, cancelled, successful and unsupported tasks',()=>{
 const items:TransferQueueItem[]=[
  {id:'failed',state:'failed'}, {id:'busy',state:'failed',busy:true}, {id:'cancelled',state:'cancelled'}, {id:'completed',state:'completed'}, {id:'unsupported',state:'failed',actionLabels:{retry:' '}}
 ].map(i=>({name:i.id,statusText:i.id,actionLabels:{retry:'重试'},...i})) as TransferQueueItem[];
 expect(retryableTransferIds(items)).toEqual(['failed']);
 expect(items[0].state).toBe('failed');
 expect(retryableTransferIds([])).toEqual([]);
});});
