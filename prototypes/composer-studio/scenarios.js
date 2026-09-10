// V5: capability registration and transition policy for the design prototype.
const composerActions5=[
 {id:'video',label:'视频',icon:'video',group:'media',accept:'video/*'},
 {id:'file',label:'文件',icon:'file',group:'media',accept:''},
 {id:'audio',label:'音频',icon:'mic',group:'media',panel:'voice'},
 {id:'mention',label:'提及',icon:'at',group:'media',panel:'mention'},
 {id:'location',label:'位置',icon:'location',group:'work',reason:'位置分享尚未接入此演示'},
 {id:'contact',label:'名片',icon:'contact',group:'work',reason:'名片选择尚未接入此演示'},
 {id:'calendar',label:'日程',icon:'calendar',group:'work',reason:'日程创建尚未接入此演示'},
 {id:'task',label:'任务',icon:'task',group:'work',reason:'任务创建尚未接入此演示'},
 {id:'poll',label:'投票',icon:'poll',group:'work',reason:'投票创建尚未接入此演示'},
 {id:'link',label:'链接卡片',icon:'link',group:'apps',reason:'当前版本暂不支持链接卡片'},
 {id:'mini',label:'小程序',icon:'apps',group:'apps',reason:'当前版本暂不支持小程序'},
 {id:'topic',label:'话题',icon:'chat',group:'apps',reason:'当前版本暂不支持话题'},
 {id:'notice',label:'通知',icon:'bell',group:'apps',reason:'当前版本暂不支持通知'},
 {id:'announce',label:'公告',icon:'announcement',group:'apps',reason:'当前版本暂不支持公告'}
];
let moreGroup5='media',moreSearch5='',voiceDraft5=null;
const groups5=[['media','常用'],['work','协作'],['apps','应用']];
const morePrevious5=showMore;
showMore=function(){morePrevious5();panelHeader('更多');const h=tray.querySelector('.panel-head');const tabs=document.createElement('div');tabs.className='panel-tabs';tabs.setAttribute('role','tablist');tabs.setAttribute('aria-label','功能分组');h.querySelector('span').replaceWith(tabs);const search=document.createElement('input');search.className='panel-input tool-search';search.type='search';search.placeholder='搜索功能';search.setAttribute('aria-label','搜索功能');search.value=moreSearch5;
 const grid=document.createElement('div');grid.className='panel-grid';grid.setAttribute('role','tabpanel');const message=document.createElement('p');message.className='capability-reason';message.setAttribute('role','status');
 function paint(){tabs.replaceChildren();for(const [key,label] of groups5){const b=document.createElement('button');b.textContent=label;b.classList.toggle('active',key===moreGroup5);b.setAttribute('role','tab');b.setAttribute('aria-selected',key===moreGroup5);b.onclick=()=>{moreGroup5=key;moreSearch5='';search.value='';message.textContent='';paint()};tabs.append(b)}grid.replaceChildren();const matches=composerActions5.filter(a=>moreSearch5?a.label.includes(moreSearch5):a.group===moreGroup5);if(!matches.length){message.textContent='没有找到功能，换个关键词试试';return}message.textContent='';for(const action of matches){const b=document.createElement('button');b.innerHTML='<span class="tile-icon">'+icon3(action.icon)+'</span><span>'+action.label+'</span>'+(action.reason?'<small>暂不可用</small>':'');b.setAttribute('aria-label',action.label+(action.reason?'，暂不可用':''));b.onclick=()=>{if(action.reason){message.textContent=action.reason;return}if(action.panel==='voice')openVoice5();else if(action.panel==='mention'){panel3('mention');showMention3()}else if(action.onAction)action.onAction();else pickFile(action.accept)};grid.append(b)}}
 search.oninput=()=>{moreSearch5=search.value.trim();paint()};tray.append(search,grid,message);paint()};

// Recording never silently disappears when another tool is opened.
const closePrevious5=closeTray;
closeTray=function(){if(currentPanel==='voice'&&recordPhase==='recording'){voiceDraft5={seconds:Math.max(1,recordSeconds),phase:'preview'};notify('录音已暂停，返回语音可继续处理')}else if(currentPanel==='voice'&&recordPhase==='preview'){voiceDraft5={seconds:recordSeconds,phase:'preview'}}closePrevious5();updateVoiceBadge5()};
function updateVoiceBadge5(){const b=$('[data-panel="voice"]');b.classList.toggle('has-pending',!!voiceDraft5);b.setAttribute('aria-label',voiceDraft5?'语音消息，有未发送录音':'语音消息')}
function openVoice5(){if(busy||$('#network').value==='disabled'){notify('当前不可编辑');return}if(currentPanel==='voice'){closeTray();return}panel3('voice');recordSeconds=voiceDraft5?.seconds||0;showVoice3(voiceDraft5?'preview':'idle')}
$('[data-panel="voice"]').onclick=openVoice5;
const voicePrevious5=showVoice3;
showVoice3=function(phase='idle'){if(phase==='idle')voiceDraft5=null;voicePrevious5(phase);updateVoiceBadge5();if(phase==='preview'){const row=tray.querySelector('.panel-row');const discard=document.createElement('button');discard.textContent='删除录音';discard.onclick=()=>{voiceDraft5=null;recordPhase='idle';recordSeconds=0;closeTray();notify('录音已删除，文字草稿保留')};row.prepend(discard)}};
const addPrevious5=addMessage;
addMessage=function(html,failed){if(html.includes('语音交互演示')){voiceDraft5=null;recordPhase='idle';updateVoiceBadge5()}addPrevious5(html,failed)};
$('[data-panel="image"]').onclick=()=>{if(busy||$('#network').value==='disabled')return;if($('#network').value==='unavailable'){notify('当前会话不支持图片');return}if(currentPanel==='image'){closeTray();return}panel3('image');showImages3()};

// One viewport budget, rather than independent fixed heights stacked together.
function layoutBudget5(){const height=phone.clientHeight;const usable=height-$('.status').offsetHeight-$('.chat-head').offsetHeight-$('.safe').offsetHeight;const keyboard=$('.keyboard').classList.contains('visible')?$('.keyboard').offsetHeight:0;phone.style.setProperty('--tray-budget',Math.max(100,Math.min(236,(usable-keyboard)*.42))+'px');$('.caption').textContent=phone.dataset.platform+' · '+phone.offsetWidth+' × '+phone.offsetHeight+' · Web 交互预览'}
new ResizeObserver(layoutBudget5).observe(phone);layoutBudget5();
// Single escape policy: dismiss a panel first, then collapse the editor.
document.addEventListener('keydown',e=>{if(e.key!=='Escape')return;if(currentPanel){e.preventDefault();e.stopImmediatePropagation();closeTray();return}if(dock.classList.contains('expanded')){e.preventDefault();e.stopImmediatePropagation();expanded(false);editor.focus()}},true);
// Preserve the reader's position when a utility panel changes the chat height.
const timeline5=$('.timeline');let readAnchor5=null;
timeline5.addEventListener('scroll',()=>{const rect=timeline5.getBoundingClientRect();const item=Array.from(timeline5.children).find(e=>e.getBoundingClientRect().bottom>rect.top);readAnchor5=item?{node:item,offset:item.getBoundingClientRect().top-rect.top}:null},{passive:true});
const panelPrevious5=panel3;
panel3=function(kind){const atBottom=timeline5.scrollHeight-timeline5.scrollTop-timeline5.clientHeight<24;panelPrevious5(kind);requestAnimationFrame(()=>{layoutBudget5();if(atBottom)timeline5.scrollTop=timeline5.scrollHeight;else if(readAnchor5?.node.isConnected){const delta=readAnchor5.node.getBoundingClientRect().top-timeline5.getBoundingClientRect().top-readAnchor5.offset;timeline5.scrollTop+=delta}})};
// A compact preview can actually exercise short and tall layouts.
const density5=document.createElement('div');density5.className='preview-sizes';density5.setAttribute('aria-label','预览高度');for(const [label,height] of [['标准',790],['矮屏',620]]){const b=document.createElement('button');b.textContent=label;b.setAttribute('aria-pressed',height===790);b.onclick=()=>{phone.style.height=height+'px';density5.querySelectorAll('button').forEach(x=>x.setAttribute('aria-pressed',x===b));layoutBudget5()};density5.append(b)}$('.choices').after(density5);
$('.meta').textContent='COMPOSER STUDY / V5 · 场景与扩展';
$('.note:nth-of-type(2) p').textContent='更多按常用、协作、应用分组，可搜索。新能力进入分组，不继续挤占底部工具栏。';
$('.note:nth-of-type(3) p').textContent='切换工具保留图片选择；未发录音暂存为预览。先关闭面板，再收起长文，返回路径保持一致。';
$('.note:nth-of-type(2) h3').innerHTML='<i></i>功能增多，布局不拥挤';
$('.note:nth-of-type(3) h3').innerHTML='<i></i>离开工具，保留进度';

// V6: the default shelf spends its height on actions, not navigation chrome.
let shelfPage6=0,shelfSearch6=false;
const panelOptions7={showSearch:false,showTitle:false,showClose:false};
showMore=function(){morePrevious5();renderShelf6()};
function renderShelf6(){tray.replaceChildren();const header=document.createElement('div');header.className='shelf-header';const grid=document.createElement('div');grid.className='panel-grid shelf-grid';const feedback=document.createElement('p');feedback.className='capability-reason';feedback.setAttribute('role','status');
 const close=document.createElement('button');close.setAttribute('aria-label','关闭功能面板');close.innerHTML=icon3('close');close.onclick=closeTray;
 const search=document.createElement('button');search.setAttribute('aria-label',shelfSearch6?'退出功能搜索':'搜索更多功能');search.innerHTML=shelfSearch6?'<svg viewBox="0 0 24 24" aria-hidden="true"><path d="m14 5-7 7 7 7"/></svg>':'<svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="10" cy="10" r="6"/><path d="m15 15 5 5"/></svg>';search.onclick=()=>{shelfSearch6=!shelfSearch6;renderShelf6();if(shelfSearch6)tray.querySelector('input').focus()};
 function paint(items){grid.replaceChildren();feedback.textContent='';if(!items.length){feedback.textContent='没有找到功能，换个关键词试试';return}for(const action of items){const b=document.createElement('button');b.innerHTML='<span class="tile-icon">'+icon3(action.icon)+'</span><span>'+action.label+'</span>';b.setAttribute('aria-label',action.label+(action.reason?'，暂不可用':''));if(action.reason)b.classList.add('unavailable-action');b.onclick=()=>{if(action.reason){feedback.textContent=action.reason;return}if(action.panel==='voice')openVoice5();else if(action.panel==='mention'){panel3('mention');showMention3()}else if(action.onAction)action.onAction();else pickFile(action.accept)};grid.append(b)}}
 if(panelOptions7.showSearch)header.append(search);if(shelfSearch6){const input=document.createElement('input');input.type='search';input.className='shelf-search';input.placeholder='搜索功能';input.setAttribute('aria-label','搜索功能');input.oninput=()=>paint(composerActions5.filter(a=>a.label.includes(input.value.trim())));header.append(input);paint(composerActions5)}else{const title=document.createElement('span');title.className='shelf-title';title.textContent='更多功能';if(panelOptions7.showTitle)header.append(title);const nav=document.createElement('div');nav.className='shelf-pages';const pages=Math.ceil(composerActions5.length/8);for(let i=0;i<pages;i++){const b=document.createElement('button');b.setAttribute('aria-label','第 '+(i+1)+' 页功能');b.setAttribute('aria-pressed',shelfPage6===i);b.innerHTML='<span></span>';b.onclick=()=>{shelfPage6=i;renderShelf6()};nav.append(b)}nav.classList.toggle('pager-only',!panelOptions7.showSearch&&!panelOptions7.showTitle&&!panelOptions7.showClose);header.append(nav);paint(composerActions5.slice(shelfPage6*8,shelfPage6*8+8))}if(panelOptions7.showClose)header.append(close);const pagerOnly=!panelOptions7.showSearch&&!panelOptions7.showTitle&&!panelOptions7.showClose;header.classList.toggle('minimal-header',pagerOnly);if(pagerOnly)tray.append(grid,header,feedback);else tray.append(header,grid,feedback)}
$('.meta').textContent='COMPOSER STUDY / V6 · 轻量功能面板';
$('.note:nth-of-type(2) p').textContent='默认直接展示功能，两行一页。分类和搜索框不再常驻；需要查找时，再点放大镜。';


// V7: chrome is optional; the toolbar close action is invariant.
function configureComposer7(patch){for(const key of Object.keys(panelOptions7)){if(typeof patch[key]==='boolean')panelOptions7[key]=patch[key]}if(!panelOptions7.showSearch)shelfSearch6=false;if(currentPanel==='attach')renderShelf6();document.querySelectorAll('[data-option7]').forEach(input=>input.checked=panelOptions7[input.dataset.option7])}
const controls7=document.createElement('details');controls7.className='panel-config';controls7.innerHTML='<summary>面板显示选项</summary>';
for(const [key,label] of [['showSearch','显示搜索入口'],['showTitle','显示面板标题'],['showClose','显示面板关闭按钮']]){const row=document.createElement('label');const name=document.createElement('span');name.textContent=label;const input=document.createElement('input');input.type='checkbox';input.dataset.option7=key;input.checked=panelOptions7[key];input.onchange=()=>configureComposer7({[key]:input.checked});row.append(name,input);controls7.append(row)}
$('.preview-sizes').after(controls7);
const formatPrevious7=showFormats;
showFormats=function(){formatPrevious7();tray.classList.add('format-picker-compact')};
const closePrevious7=closeTray;
closeTray=function(){tray.classList.remove('format-picker-compact');closePrevious7()};
window.flareComposerDemo={configure:configureComposer7,getOptions:()=>({...panelOptions7})};
$('.meta').textContent='COMPOSER STUDY / V7 · 可配置的轻量面板';
$('.note:nth-of-type(2) p').textContent='默认隐藏搜索、标题与重复关闭按钮，只保留功能和分页。需要时可在“面板显示选项”分别开启。';
$('.note:nth-of-type(3) p').textContent='富文本栏进一步收紧，段落样式面板改为紧凑横排。触屏仍保留 44px 点击范围。';

// V8: all formatting commands live on one horizontally scrollable rail.
const formatCommands8=[
 ['正文','type','body'],['标题','heading','heading'],
 ['加粗','<b>B</b>','bold'],['删除线','<s>S</s>','strikeThrough'],['斜体','<i>I</i>','italic'],['下划线','<u>U</u>','underline'],
 ['无序列表','list','insertUnorderedList'],['有序列表','ordered','insertOrderedList'],
 ['引用','quote','quote'],['代码块','code','code'],['行内代码','&lt;/&gt;','inlineCode'],['链接','link','link'],['清除格式','clear','clear']
];
strip4.replaceChildren();strip4.setAttribute('role','toolbar');strip4.setAttribute('aria-label','文字格式，可左右滚动');
for(const [label,icon,command] of formatCommands8){const b=document.createElement('button');b.title=label;b.setAttribute('aria-label',label);b.innerHTML=v3Paths[icon]?icon3(icon):icon;
 const native=['bold','italic','underline','strikeThrough','insertUnorderedList','insertOrderedList'].includes(command);
 if(native){b.dataset.format=command;b.setAttribute('aria-pressed','false')}
 b.onmousedown=e=>e.preventDefault();b.onclick=()=>{if(busy||$('#network').value==='disabled')return;if(native){restoreSelection();document.execCommand(command);update()}else if(command==='link'){panel3('format');showLink()}else formatExtra(command)};
 b.onfocus=()=>b.scrollIntoView({block:'nearest',inline:'nearest',behavior:'instant'});strip4.append(b)
}
strip4.addEventListener('wheel',e=>{if(strip4.scrollWidth<=strip4.clientWidth)return;if(Math.abs(e.deltaY)>Math.abs(e.deltaX)){const before=strip4.scrollLeft;strip4.scrollLeft+=e.deltaY;if(before!==strip4.scrollLeft)e.preventDefault()}},{passive:false});
strip4.addEventListener('keydown',e=>{if(!['ArrowLeft','ArrowRight','Home','End'].includes(e.key))return;const items=Array.from(strip4.querySelectorAll('button'));const index=items.indexOf(document.activeElement);if(index<0)return;e.preventDefault();const next=e.key==='Home'?0:e.key==='End'?items.length-1:Math.max(0,Math.min(items.length-1,index+(e.key==='ArrowRight'?1:-1)));items[next].focus()});
function formatScrollHint8(){strip4.classList.toggle('more-left',strip4.scrollLeft>2);strip4.classList.toggle('more-right',strip4.scrollLeft+strip4.clientWidth<strip4.scrollWidth-2)}
strip4.addEventListener('scroll',formatScrollHint8,{passive:true});new ResizeObserver(formatScrollHint8).observe(strip4);
document.addEventListener('selectionchange',()=>{strip4.querySelectorAll('[data-format]').forEach(b=>b.setAttribute('aria-pressed',document.queryCommandState(b.dataset.format)))});
$('.meta').textContent='COMPOSER STUDY / V8 · 横向格式工具栏';
$('.note:nth-of-type(3) p').textContent='格式全部平铺在同一行，左右滑动即可找到。没有“更多”或段落下拉菜单，选中的格式仍只变色。';
$('.note:nth-of-type(4) p').textContent='正文、标题、列表、引用、代码与链接都在同一条格式栏。收起工具不改变草稿或已写格式。';
