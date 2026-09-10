// V9 prototype configuration: capability lists and composer restrictions.
$('.sheet-head > span').remove();
$('.collapse').innerHTML='<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M20 9h-5V4M15 9l6-6M4 15h5v5M9 15l-6 6"/></svg>';
$('.collapse').title='收起编辑器';
const statePolicies9={
 online:{edit:true,send:true,message:''},
 failed:{edit:true,send:true,message:''},
 disabled:{edit:false,send:false,message:'你已被禁言，暂时无法发送消息。草稿已保留。'},
 allMuted:{edit:false,send:false,message:'全员禁言中，仅管理员可发言。草稿已保留。'},
 readOnly:{edit:false,send:false,message:'当前会话为只读，无法发送消息。'},
 removed:{edit:false,send:false,message:'你已不在此会话中，无法继续发送消息。'},
 offline:{edit:true,send:false,message:'网络已断开，可以继续编辑，连接恢复后再发送。'},
 reconnecting:{edit:true,send:false,message:'正在重新连接，草稿已保留。'},
 slowMode:{edit:true,send:false,message:'发言间隔限制中，请稍后再试。'},
 permission:{edit:true,send:true,message:'麦克风权限未开启，仍可发送文字和图片。'},
 unavailable:{edit:true,send:true,message:'当前会话不支持附件，仍可发送文字。'}
};
const stateSelect9=$('#network');
for(const [value,label] of [['allMuted','全员禁言'],['readOnly','只读会话'],['removed','已离开会话'],['slowMode','发言间隔限制']]){const option=document.createElement('option');option.value=value;option.textContent=label;stateSelect9.append(option)}
let currentState9=stateSelect9.value;
function policy9(){return statePolicies9[currentState9]}
function applyState9(){const p=policy9();editor.contentEditable=p.edit&&!busy?'true':'false';editor.setAttribute('aria-readonly',String(!p.edit));editor.setAttribute('aria-disabled',String(!p.edit));dock.classList.toggle('restricted',!p.edit);dock.classList.toggle('send-blocked',!p.send);$('.notice').textContent=p.message;$('.notice').classList.toggle('visible',!!p.message);$('.notice').setAttribute('role','status');send.disabled=busy||!p.send||(!content()&&!attachments.length);send.setAttribute('aria-disabled',String(send.disabled));send.title=!p.send?p.message:!content()&&!attachments.length?'输入内容后发送':'发送消息';$$('.actions button:not(.send),.formatbar button').forEach(b=>b.setAttribute('aria-disabled',String(!p.edit)));}
const baseUpdate9=update;update=function(){baseUpdate9();applyState9()};
function setComposerState9(value){if(!Object.hasOwn(statePolicies9,value))throw new TypeError('Unknown composer state');if(busy){stateSelect9.value=currentState9;notify('当前消息正在发送，请稍后切换演示状态');return}closeTray();currentState9=value;stateSelect9.value=value;update();}
stateSelect9.onchange=()=>setComposerState9(stateSelect9.value);
// All editing entry points share the same policy, including already-open panels.
dock.addEventListener('click',e=>{const b=e.target.closest('button');if(!b)return;const p=policy9();const navigation=b.matches('.collapse,.expand,.draft-peek,.desktop-resize,[data-v=back]');if(!p.edit&&!navigation){e.preventDefault();e.stopImmediatePropagation();notify(p.message);return}if(!p.send&&(b.matches('.send')||b.textContent.includes('发送')||b.getAttribute('aria-label')?.startsWith('发送'))){e.preventDefault();e.stopImmediatePropagation();notify(p.message)}},true);
const baseAllowed9=allowed3;allowed3=()=>policy9().send&&baseAllowed9();
const basePick9=pickFile;pickFile=function(accept){if(!policy9().edit){notify(policy9().message);return}basePick9(accept)};
$('.timeline').addEventListener('click',e=>{if(!policy9().send&&e.target.closest('.failure button')?.textContent==='重试'){e.preventDefault();e.stopImmediatePropagation();notify(policy9().message)}},true);

const initialActions9=composerActions5.map(a=>({...a}));
function configureActions9(actions){if(!Array.isArray(actions))throw new TypeError('actions must be an array');const ids=new Set();const next=actions.map(a=>{if(!a||typeof a.id!=='string'||!a.id||ids.has(a.id)||typeof a.label!=='string'||!a.label)throw new TypeError('Action requires a unique id and label');ids.add(a.id);if(a.panel&&!['voice','mention'].includes(a.panel))throw new TypeError('Unsupported action panel');if(a.onAction!==undefined&&typeof a.onAction!=='function')throw new TypeError('onAction must be a function');if(!a.reason&&!a.panel&&a.accept===undefined&&!a.onAction)throw new TypeError('Action requires a handler or unavailable reason');return {id:a.id,label:a.label,icon:Object.hasOwn(v3Paths,a.icon)?a.icon:'apps',group:a.group||'custom',...(a.reason?{reason:String(a.reason)}:{}),...(a.panel?{panel:a.panel}:{}),...(a.accept!==undefined?{accept:String(a.accept)}:{}),...(a.onAction?{onAction:a.onAction}:{})}});composerActions5.splice(0,composerActions5.length,...next);shelfPage6=Math.min(shelfPage6,Math.max(0,Math.ceil(next.length/8)-1));if(currentPanel==='attach')renderShelf6();}
const renderBefore9=renderShelf6;
renderShelf6=function(){renderBefore9();if(composerActions5.length<=8){const pager=tray.querySelector('.shelf-pages');pager?.remove();const header=tray.querySelector('.minimal-header');header?.remove()}if(!composerActions5.length){tray.querySelector('.capability-reason').textContent='当前没有可用的扩展功能';}}
const actionControl9=document.createElement('label');actionControl9.className='action-preset';const text=document.createElement('span');text.textContent='更多功能组合';const select=document.createElement('select');select.setAttribute('aria-label','更多功能组合');for(const [value,label] of [['all','完整功能'],['media','仅媒体'],['custom','自定义顺序'],['empty','无扩展功能']]){const option=document.createElement('option');option.value=value;option.textContent=label;select.append(option)}select.onchange=()=>{const presets={all:initialActions9,media:initialActions9.filter(a=>['file','video','audio'].includes(a.id)),custom:[initialActions9.find(a=>a.id==='poll'),{id:'quickReply',label:'快捷回复',icon:'chat',onAction:()=>{closeTray();insert('收到，我稍后回复。')}},initialActions9.find(a=>a.id==='file')],empty:[]};configureActions9(presets[select.value])};actionControl9.append(text,select);controls7.append(actionControl9);
const configureBefore9=window.flareComposerDemo.configure;
window.flareComposerDemo={configure:patch=>{if(patch.actions!==undefined)configureActions9(patch.actions);if(patch.state!==undefined)setComposerState9(patch.state);configureBefore9(patch)},getOptions:()=>({...panelOptions7,state:currentState9,actions:composerActions5.map(a=>({...a}))})};
$('.meta').textContent='COMPOSER STUDY / V9 · 状态与动态功能';
$('.note:nth-of-type(2) p').textContent='更多功能可按业务动态增删、排序和替换。单页不显示分页，空列表有明确提示。';
$('.note:nth-of-type(3) p').textContent='展开区仅保留收起图标。禁言、只读和离线分别显示原因，草稿保留，发送受统一状态控制。';
update();
