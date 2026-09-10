// One 24-unit icon grid, with a shared optical size across composer actions.
const v3Paths={
 smile:'M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0ZM8 9h.01M16 9h.01M8 14c2 3 6 3 8 0',
 at:'M16 8v6c0 3 5 3 5-2a9 9 0 1 0-4 7M16 12a4 4 0 1 1-8 0 4 4 0 0 1 8 0',
 mic:'M9 5a3 3 0 0 1 6 0v7a3 3 0 0 1-6 0ZM5 10v2a7 7 0 0 0 14 0v-2M12 19v3M9 22h6',
 image:'M4 3h16a1 1 0 0 1 1 1v16a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1ZM3 17l5-5 4 4 4-5 5 6M8 7h.01',
 type:'M5 5h14M12 5v15M8 20h8M5 5v3M19 5v3',
 plus:'M12 5v14M5 12h14',close:'m6 6 12 12M18 6 6 18',
 plane:'m21 3-6 18-4-8-8-4 18-6ZM11 13 21 3',
 video:'M15 9 21 6v12l-6-3M3 6h12v12H3Z',file:'M5 3h9l5 5v13H5ZM14 3v6h5M8 13h8M8 17h6',
 location:'M19 10c0 6-7 11-7 11S5 16 5 10a7 7 0 1 1 14 0ZM15 10a3 3 0 1 1-6 0 3 3 0 0 1 6 0',
 contact:'M3 4h18v16H3ZM14 9h4M14 13h4M6 16c0-4 6-4 6 0M11 9a2 2 0 1 1-4 0 2 2 0 0 1 4 0',
 calendar:'M4 5h16v16H4ZM8 3v4M16 3v4M4 10h16M8 14h2M14 14h2',
 task:'M20 12v8H4V4h10M9 10l3 3 9-9',poll:'M4 20V9h4v11M10 20V4h4v16M16 20v-7h4v7',
 link:'M10 13a5 5 0 0 0 7 0l3-3a5 5 0 0 0-7-7l-2 2M14 11a5 5 0 0 0-7 0l-3 3a5 5 0 0 0 7 7l2-2',
 apps:'M3 3h7v7H3ZM14 3h7v7h-7ZM3 14h7v7H3ZM14 14h7v7h-7Z',
 chat:'M4 4h16v12H9l-5 4V4ZM8 8h8M8 12h5',bell:'M5 17h14l-2-3V9a5 5 0 0 0-10 0v5l-2 3ZM10 21h4',
 announcement:'M4 9h5l11-5v16L9 15H4ZM7 15l2 6h3l-2-6',
 quote:'M5 7h5v6H5l-2 4M15 7h5v6h-5l-2 4',code:'m8 7-5 5 5 5M16 7l5 5-5 5M14 4l-4 16',
 heading:'M5 4v16M19 4v16M5 12h14',clear:'M4 4h12M10 4v14M7 18h6M16 15l5 6M21 15l-5 6',
 list:'M9 6h12M9 12h12M9 18h12M3 6h.01M3 12h.01M3 18h.01',
 ordered:'M10 6h11M10 12h11M10 18h11M3 4h1v5M3 9h3M3 14c0-2 3-2 3 0 0 1-3 3-3 4h3',
 more:'M5 12h.01M12 12h.01M19 12h.01',stop:'M6 6h12v12H6Z',play:'m8 4 12 8-12 8V4Z'
};
function icon3(name){return '<svg viewBox="0 0 24 24" aria-hidden="true"><path d="'+(v3Paths[name]||v3Paths.apps)+'"/></svg>'}
for(const [selector,name] of [['[data-panel="emoji"]','smile'],['[data-panel="mention"]','at'],['[data-panel="voice"]','mic'],['[data-panel="image"]','image'],['.format-toggle','type'],['[data-panel="attach"]','plus'],['.send','plane'],['[data-format="insertOrderedList"]','ordered'],['.format-more','more']])$(selector).innerHTML=icon3(name);
let currentPanel=null,recordTimer=null,recordSeconds=0,recordPhase='idle',gallerySelection=new Set();
const baseCloseTray=closeTray;
closeTray=function(){clearInterval(recordTimer);recordTimer=null;currentPanel=null;baseCloseTray();$$('[data-panel]').forEach(b=>b.setAttribute('aria-expanded','false'));$('[data-panel="attach"]').innerHTML=icon3('plus')};
const baseHeader=panelHeader;
panelHeader=function(title){const h=baseHeader(title);h.querySelector('button').innerHTML=icon3('close');return h};
function panel3(kind){closeTray();currentPanel=kind;$('#keyboard-toggle').checked=false;phone.classList.remove('has-keyboard');$('.keyboard').classList.remove('visible');tray.classList.add('open');const b=$('[data-panel="'+kind+'"]');if(b){b.classList.add('selected');b.setAttribute('aria-expanded','true')}if(kind==='attach')b.innerHTML=icon3('close')}
function allowed3(){return !busy&&!['offline','reconnecting','disabled'].includes($('#network').value)}
function showMention3(){panelHeader('提及成员');const search=document.createElement('input');search.className='panel-input';search.placeholder='搜索成员';search.setAttribute('aria-label','搜索成员');const list=document.createElement('div');list.className='member-list';function paint(){list.replaceChildren();if(!'林小满'.includes(search.value.trim())){const p=document.createElement('p');p.className='panel-copy';p.textContent='没有找到成员，试试其他名字';list.append(p);return}const b=document.createElement('button');b.className='member-row';b.innerHTML='<span class="avatar">林</span><span class="member-detail">林小满<small>当前会话成员</small></span>';b.onclick=()=>{insert('@林小满 ');notify('已提及林小满')};list.append(b)}search.oninput=paint;paint();tray.append(search,list);search.focus()}
function wave3(){return '<div class="wave">'+[9,15,22,12,25,18,10,20,25,14,8,17,23,12,6].map((n,i)=>'<i style="--h:'+n+'px;--d:'+(i%4)*.13+'s"></i>').join('')+'</div>'}
function showVoice3(phase='idle'){recordPhase=phase;panelHeader('语音消息');const view=document.createElement('div');view.className='record-view'+(phase==='recording'?' recording':'');view.innerHTML=wave3()+'<span class="record-clock">'+(phase==='idle'?'准备录音':recordSeconds+'″')+'</span><span class="record-label">'+({idle:'点按开始，录完后预览再发送',recording:'录音中 · 点按停止',preview:'录制完成 · 可重录或发送'}[phase])+'</span>';tray.append(view);const row=document.createElement('div');row.className='panel-row';const left=document.createElement('button');left.textContent=phase==='idle'?'选择音频':phase==='recording'?'取消':'重录';left.onclick=()=>{clearInterval(recordTimer);if(phase==='idle')pickFile('audio/*');else{recordSeconds=0;showVoice3('idle')}};const main=document.createElement('button');main.innerHTML=icon3(phase==='recording'?'stop':phase==='preview'?'plane':'mic')+'<span>'+({idle:'开始录音',recording:'停止录音',preview:'发送语音'}[phase])+'</span>';main.className='record-trigger';main.onclick=()=>{if(phase==='idle'){if($('#network').value==='permission'){notify('麦克风权限未开启，仍可选择音频');return}recordSeconds=0;showVoice3('recording');recordTimer=setInterval(()=>{recordSeconds++;const clock=tray.querySelector('.record-clock');if(clock)clock.textContent=recordSeconds+'″';if(recordSeconds>=60){clearInterval(recordTimer);showVoice3('preview')}},1000)}else if(phase==='recording'){clearInterval(recordTimer);recordSeconds=Math.max(1,recordSeconds);showVoice3('preview')}else{if(!allowed3()){notify('当前无法发送，语音预览已保留');return}addMessage('<div class="voice-bubble">'+icon3('mic')+'<span>'+recordSeconds+'″</span></div><small>语音交互演示 · 无真实录音</small>',$('#network').value==='failed');closeTray();notify('已模拟发送语音，文字草稿保留')}};row.append(left,main);tray.append(row);const note=document.createElement('p');note.className='record-disclaimer';note.textContent='录音流程模拟 · 不采集麦克风声音';tray.append(note)}
const gallery3=[['山间晨光','#cadbd4','#6c9587'],['午后海边','#d9e6f2','#8cb4d0'],['落日山坡','#f4dfd5','#c99592']].map(([name,bg,fg],i)=>{const svg='<svg xmlns="http://www.w3.org/2000/svg" width="240" height="180"><rect width="240" height="180" fill="'+bg+'"/><circle cx="'+(170-i*35)+'" cy="46" r="22" fill="#fff8ed"/><path d="M0 140 65 75 136 137 186 100 240 145V180H0Z" fill="'+fg+'"/><path d="M0 154Q95 110 240 163V180H0Z" fill="'+fg+'" opacity=".55"/></svg>';return {name:name+'.svg',url:'data:image/svg+xml;charset=utf-8,'+encodeURIComponent(svg),svg}});
function showImages3(){panelHeader('选择图片');const copy=document.createElement('p');copy.className='panel-copy';copy.textContent='选择示例图片，或打开本地相册';tray.append(copy);const grid=document.createElement('div');grid.className='gallery';gallery3.forEach((item,i)=>{const b=document.createElement('button');b.classList.toggle('selected',gallerySelection.has(i));b.setAttribute('aria-label',item.name);b.setAttribute('aria-pressed',gallerySelection.has(i));b.innerHTML='<img alt="'+item.name+'" src="'+item.url+'"><span class="tick">'+(gallerySelection.has(i)?'✓':'')+'</span>';b.onclick=()=>{gallerySelection.has(i)?gallerySelection.delete(i):gallerySelection.add(i);showImages3()};grid.append(b)});tray.append(grid);const row=document.createElement('div');row.className='panel-row';const local=document.createElement('button');local.textContent='本地相册';local.onclick=()=>pickFile('image/*');const add=document.createElement('button');add.textContent='添加'+(gallerySelection.size?'（'+gallerySelection.size+'）':'');add.disabled=!gallerySelection.size;add.onclick=()=>{for(const i of gallerySelection){const g=gallery3[i];attachments.push(new File([g.svg],g.name,{type:'image/svg+xml'}))}gallerySelection.clear();renderAttachments();closeTray();update();notify('图片已添加，可移除或随文字发送')};row.append(local,add);tray.append(row)}
const baseRenderAttachments=renderAttachments;
const previewURLs=new WeakMap();
renderAttachments=function(){baseRenderAttachments();attachments.forEach((f,i)=>{if(f.type?.startsWith('image/')){if(!previewURLs.has(f))previewURLs.set(f,URL.createObjectURL(f));const img=document.createElement('img');img.src=previewURLs.get(f);img.alt=f.name;$('.attachment-strip').children[i].prepend(img)}})};
const baseAddMessage3=addMessage;
addMessage=function(html,failed){baseAddMessage3(html,failed);if(html.includes('附件演示 · 未上传')){const bubble=$('.timeline').querySelector('.message:last-of-type .bubble')||Array.from($$('.timeline .bubble')).at(-1);for(const f of attachments){if(f.type?.startsWith('image/')){if(!previewURLs.has(f))previewURLs.set(f,URL.createObjectURL(f));const img=document.createElement('img');img.src=previewURLs.get(f);img.alt=f.name;img.style.cssText='display:block;width:100%;max-width:220px;border-radius:8px;margin:8px 0';bubble.append(img)}}}};
const baseShowEmoji=showEmoji;
showEmoji=function(stickers=false){baseShowEmoji(stickers);currentPanel='emoji';const b=$('[data-panel="emoji"]');b.classList.add('selected');b.setAttribute('aria-expanded','true')};
const baseShowMore=showMore;
showMore=function(){baseShowMore();const names=['video','file','mic','location','contact','calendar','task','poll','at','link','apps','chat','bell','announcement'];tray.querySelectorAll('.tile-icon').forEach((el,i)=>el.innerHTML=icon3(names[i]));const mention=Array.from(tray.querySelectorAll('.panel-grid button')).find(b=>b.textContent==='提及');if(mention)mention.onclick=()=>showMention3()};
const baseShowFormats=showFormats;
showFormats=function(){baseShowFormats();['type','heading','quote','code','code','link','clear'].forEach((name,i)=>tray.querySelectorAll('.tile-icon')[i].innerHTML=icon3(name))};
$$('[data-panel]').forEach(b=>{b.setAttribute('aria-expanded','false');b.onclick=()=>{if(busy||$('#network').value==='disabled'){notify('当前不可编辑');return}const kind=b.dataset.panel;if(currentPanel===kind){closeTray();return}if(kind==='image'&&$('#network').value==='unavailable'){notify('当前会话不支持图片');return}panel3(kind);({emoji:()=>showEmoji(),mention:showMention3,voice:()=>{recordSeconds=0;showVoice3()},image:()=>{gallerySelection.clear();showImages3()},attach:showMore,format:showFormats}[kind])()}});
$('.note:nth-of-type(2) p').textContent='所有工具等距分布，统一 20px 线性图标、44px 触控范围。选中只变色，不再出现方块。';
$('.note:nth-of-type(3) p').textContent='富文本图标收至 18px，格式文字 14px。用紫色与短标记指示当前格式，保持整行轻盈。';

// V4: keep the draft alive while the utility shelf is visible.
const peek4=document.createElement('button');peek4.className='draft-peek';peek4.setAttribute('aria-label','继续编辑草稿');dock.insertBefore(peek4,$('.actions'));
peek4.onclick=()=>{closeTray();restoreSelection()};
const closeBefore4=closeTray;
closeTray=function(){const was=dock.classList.contains('more-shelf');dock.classList.remove('more-shelf','has-draft');closeBefore4();if(was)restoreSelection()};
const moreBefore4=showMore;
showMore=function(){moreBefore4();const selection=getSelection();if(selection.rangeCount&&editor.contains(selection.anchorNode))range=selection.getRangeAt(0).cloneRange();editor.blur();dock.classList.add('more-shelf');const hasDraft=!!content()||attachments.length>0||replyActive;dock.classList.toggle('has-draft',hasDraft);peek4.replaceChildren();const text=document.createElement('span');text.textContent=content()?'草稿 · '+content().replace(/\s+/g,' '):attachments.length?'草稿 · '+attachments.length+' 个附件':'草稿 · 回复林小满';peek4.append(text);peek4.insertAdjacentHTML('beforeend',icon3('type'));const mention=Array.from(tray.querySelectorAll('.panel-grid button')).find(b=>b.textContent==='提及');if(mention)mention.onclick=()=>{panel3('mention');showMention3()}};
const strip4=$('.formatbar');
const picker4=document.createElement('button');picker4.className='block-picker';picker4.setAttribute('aria-label','段落样式');picker4.innerHTML='Aa <svg viewBox="0 0 24 24" aria-hidden="true"><path d="m7 10 5 5 5-5"/></svg>';picker4.onmousedown=e=>e.preventDefault();picker4.onclick=()=>{if(busy||$('#network').value==='disabled')return;panel3('format');showFormats()};strip4.prepend(picker4);
function addFormat4(label,icon,run){const b=document.createElement('button');b.setAttribute('aria-label',label);b.innerHTML=icon;b.onmousedown=e=>e.preventDefault();b.onclick=()=>{if(busy||$('#network').value==='disabled')return;run()};strip4.insertBefore(b,$('.format-more'))}
addFormat4('下划线','<u>U</u>',()=>{restoreSelection();document.execCommand('underline');update()});
addFormat4('引用格式',icon3('quote'),()=>formatExtra('quote'));
addFormat4('插入文字链接',icon3('link'),()=>{panel3('format');showLink()});
// Match the reference order: type, bold, strike, italic, underline, lists, quote, link.
strip4.insertBefore($('[data-format="strikeThrough"]'),$('[data-format="italic"]'));
strip4.insertBefore(strip4.querySelector('[aria-label="下划线"]'),$('[data-format="insertUnorderedList"]'));
$('.meta').textContent='COMPOSER STUDY / V4 · 交互设计预览';
$('.note:nth-of-type(2) p').textContent='点击更多，正文暂时收起。有内容时只保留一行草稿提示；点击提示或关闭面板，恢复原来的编辑状态。';
$('.note:nth-of-type(3) p').textContent='参照紧凑编辑器：14px 图标、12px 格式文字，整行无方块底色。触屏仍保留更大的点击范围。';
