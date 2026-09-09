import { describe,it,expect,vi } from 'vitest';
import { effectScope } from 'vue';
import { useFlareCoreClient } from './useFlareCoreClient';
function deferred(){let resolve!:(v:any)=>void;let reject!:(e:Error)=>void;const promise=new Promise<any>((a,b)=>{resolve=a;reject=b});return {promise,resolve,reject};}
describe('active search response ownership',()=>{
 it('invalidates pending search when the active conversation changes',async()=>{
  const pending=deferred();const scope=effectScope();
  const sdk=scope.run(()=>useFlareCoreClient({createClient:()=>({
   events:{onTypingAggregateChanged:()=>({unsubscribe(){}}),addEventListener:()=>({unsubscribe(){}}),subscribeEvents:async()=>{}},
   messages:{searchMessagesByQuery:()=>pending.promise},
  } as never)}))!;
  const search=sdk.searchActiveMessages('old conversation',[]);
  // Entering an uncached conversation may fail in this minimal fixture. The
  // ownership guard must still invalidate the previous request synchronously.
  await sdk.selectConversation('different');
  pending.resolve({messages:[{serverId:'stale'}]});await search;
  expect(sdk.activeConversationId.value).toBe('different');
  expect(sdk.messageSearchResults.value).toEqual([]);scope.stop();
 });
 it('only publishes the latest response and clearing invalidates pending results',async()=>{
  const first=deferred(),second=deferred(),third=deferred();
  const search=vi.fn().mockReturnValueOnce(first.promise).mockReturnValueOnce(second.promise).mockReturnValueOnce(third.promise);
  const scope=effectScope();
  const sdk=scope.run(()=>useFlareCoreClient({createClient:()=>({events:{onTypingAggregateChanged:()=>({unsubscribe(){}}),addEventListener:()=>({unsubscribe(){}}),subscribeEvents:async()=>{}},messages:{searchMessagesByQuery:search}} as never)}))!;
  const a=sdk.searchActiveMessages('old',[]);const b=sdk.searchActiveMessages('new',[]);
  second.resolve({messages:[{serverId:'new'}]});await b;
  first.resolve({messages:[{serverId:'old'}]});await a;
  expect(sdk.messageSearchResults.value.map(m=>m.serverId)).toEqual(['new']);
  const c=sdk.searchActiveMessages('late',[]);await sdk.searchActiveMessages('',[]);
  third.resolve({messages:[{serverId:'late'}]});await c;
  expect(sdk.messageSearchResults.value).toEqual([]);scope.stop();
 });
 it('suppresses superseded failures but preserves current request failures',async()=>{
  const first=deferred(),second=deferred();const search=vi.fn().mockReturnValueOnce(first.promise).mockReturnValueOnce(second.promise);
  const scope=effectScope();const sdk=scope.run(()=>useFlareCoreClient({createClient:()=>({events:{onTypingAggregateChanged:()=>({unsubscribe(){}}),addEventListener:()=>({unsubscribe(){}}),subscribeEvents:async()=>{}},messages:{searchMessagesByQuery:search}} as never)}))!;
  const a=sdk.searchActiveMessages('old',[]);const b=sdk.searchActiveMessages('new',[]);first.reject(Error('old failed'));await expect(a).resolves.toBeUndefined();second.reject(Error('new failed'));await expect(b).rejects.toThrow('new failed');scope.stop();
 });
});
