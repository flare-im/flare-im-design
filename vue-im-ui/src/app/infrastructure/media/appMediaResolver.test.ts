import {it,expect,vi} from 'vitest';
import {ref} from 'vue';
import {createAppMediaResolver} from './appMediaResolver';
it('coalesces in-flight media access but re-resolves settled URLs through the SDK',async()=>{
 let resolve!:(v:unknown)=>void;
 const pending=new Promise(r=>{resolve=r});
 const access=vi.fn().mockReturnValueOnce(pending).mockResolvedValue({url:'https://example.test/new-signed'});
 const resolver=createAppMediaResolver({currentUserId:ref('a'),loggedIn:ref(true),client:{media:{resolveMediaAccess:access}}} as never);
 const request={kind:'image',fileId:'id'};
 const a=resolver(request),b=resolver(request);expect(access).toHaveBeenCalledTimes(1);
 resolve({url:'https://example.test/old-signed'});await Promise.all([a,b]);
 await expect(resolver(request)).resolves.toBe('https://example.test/new-signed');expect(access).toHaveBeenCalledTimes(2);
});
it('rejects old-account media access when an account switches during resolution',async()=>{
 let resolve!:(v:unknown)=>void;const pending=new Promise(r=>{resolve=r});const currentUserId=ref('a');
 const resolver=createAppMediaResolver({currentUserId,loggedIn:ref(true),client:{media:{resolveMediaAccess:()=>pending}}} as never);
 const task=resolver({kind:'image',fileId:'id'});currentUserId.value='b';resolve({url:'https://example.test/private-a'});
 await expect(task).rejects.toThrow('媒体会话已切换');
});
