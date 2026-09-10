// Desktop uses the exact same draft, permissions and feature configuration.
const desktopSwitch=document.createElement('div');desktopSwitch.className='desktop-switch';desktopSwitch.setAttribute('aria-label','布局预览');
for(const [label,value] of [['手机','mobile'],['桌面 Web','desktop']]){const b=document.createElement('button');b.textContent=label;b.setAttribute('aria-pressed',value==='desktop');b.onclick=()=>setDesktopView(value==='desktop');desktopSwitch.append(b)}$('.intro').prepend(desktopSwitch);
const railDesktop=document.createElement('nav');railDesktop.className='desktop-rail';railDesktop.setAttribute('aria-label','应用导航示意');railDesktop.innerHTML='<div class="mark">f</div><span class="rail-active" title="消息">'+icon3('chat')+'</span><span title="通讯录">'+icon3('contact')+'</span><span title="应用">'+icon3('apps')+'</span><span class="self">我</span>';
const listDesktop=document.createElement('aside');listDesktop.className='desktop-list';listDesktop.setAttribute('aria-label','会话列表示意');listDesktop.innerHTML='<div class="list-title">消息 <span style="font-size:11px;color:#aaa">3</span></div><div class="list-subtitle">最近会话</div>';
for(const [name,initial,preview,time,current] of [['林小满','林','把你的想法发给我吧，我来准备 ☕','09:42',true],['设计讨论组','设','周五分享的安排已更新','昨天',false],['产品与研发','产','本周迭代记录','周一',false]]){const row=document.createElement('div');row.className='desktop-thread'+(current?' current':'');row.innerHTML='<div class="avatar">'+initial+'</div><div class="thread-copy"><small>'+time+'</small><strong>'+name+'</strong><p>'+preview+'</p></div>';listDesktop.append(row)}listDesktop.insertAdjacentHTML('beforeend','<div class="list-foot">布局示意 · 当前体验林小满会话</div>');
const infoDesktop=document.createElement('aside');infoDesktop.className='desktop-info';infoDesktop.setAttribute('aria-label','会话资料示意');infoDesktop.innerHTML='<div class="avatar">林</div><h3>林小满</h3><p>一起把想法变成作品</p><div class="info-heading">会话资料</div><div class="info-row">共享图片 <span>—</span></div><div class="info-row">共享文件 <span>—</span></div><div class="info-row">链接 <span>—</span></div><p style="text-align:left;margin-top:24px">输入、格式、回复及更多功能可在左侧聊天区体验。</p>';
$('.stage').prepend(railDesktop,listDesktop);$('.stage').append(infoDesktop);
const shortcutDesktop=document.createElement('span');shortcutDesktop.className='desktop-shortcut';shortcutDesktop.textContent=(/Mac/.test(navigator.platform)?'⌘':'Ctrl')+' + Enter 发送';$('.send').before(shortcutDesktop);
function setDesktopView(on){document.body.classList.toggle('desktop-mode',on);desktopSwitch.querySelectorAll('button').forEach((b,i)=>b.setAttribute('aria-pressed',on?i===1:i===0));$('.meta').textContent=on?'FLARE IM / DESKTOP · Web 设计预览':'COMPOSER STUDY / V9 · 手机设计预览';layoutBudget5()}
setDesktopView(true);

const resizeDesktop=document.createElement('button');resizeDesktop.className='desktop-resize';$('.actions').prepend(resizeDesktop);
function syncRightDesktop(){const expandedNow=dock.classList.contains('expanded');resizeDesktop.setAttribute('aria-label',expandedNow?'收起 Web 编辑器':'展开 Web 编辑器');resizeDesktop.setAttribute('aria-expanded',expandedNow);resizeDesktop.innerHTML='<svg viewBox="0 0 24 24" aria-hidden="true"><path d="'+(expandedNow?'M20 9h-5V4M15 9l6-6M4 15h5v5M9 15l-6 6':'M14 4h6v6M20 4l-7 7M4 14v6h6M4 20l7-7')+'"/></svg>';const text=editor.innerText;const available=Math.max(120,dock.clientWidth-330);const canvas=document.createElement('canvas');const context=canvas.getContext('2d');context.font=getComputedStyle(editor).font;dock.classList.toggle('desktop-multiline',text.includes('\n')||context.measureText(text).width>available);}
resizeDesktop.onclick=()=>{closeTray();expanded(!dock.classList.contains('expanded'));editor.focus();syncRightDesktop()};
const rightExpanded=expanded;expanded=function(value){rightExpanded(value);syncRightDesktop()};
editor.addEventListener('input',syncRightDesktop);new MutationObserver(syncRightDesktop).observe(editor,{childList:true,subtree:true,characterData:true});new ResizeObserver(syncRightDesktop).observe(phone);syncRightDesktop();

// Desktop pickers overlay the conversation, leaving the composer geometry fixed.
function syncDesktopEmoji(){const open=document.body.classList.contains('desktop-mode')&&['emoji','mention','voice'].includes(currentPanel)&&tray.classList.contains('open');dock.classList.toggle('desktop-emoji-open',open);tray.classList.toggle('desktop-emoji-popover',open);if(open){tray.dataset.desktopPicker=currentPanel;const spacing=getComputedStyle(dock);tray.style.setProperty('--picker-left',spacing.paddingLeft);tray.style.setProperty('--picker-right',spacing.paddingRight);const top=dock.getBoundingClientRect().top;const available=Math.max(80,top-$('.chat-head').getBoundingClientRect().bottom-8);tray.style.setProperty('--emoji-space',Math.min(290,available)+'px')}}
const desktopShowEmoji=showEmoji;
showEmoji=function(stickers=false){desktopShowEmoji(stickers);syncDesktopEmoji()};
const desktopClosePicker=closeTray;
closeTray=function(){dock.classList.remove('desktop-emoji-open');tray.classList.remove('desktop-emoji-popover');desktopClosePicker()};
const mobileImageAction=$('[data-panel="image"]').onclick;
$('[data-panel="image"]').onclick=()=>{if(!document.body.classList.contains('desktop-mode')){mobileImageAction();return}if(busy||!policy9().edit){notify(policy9().message||'消息正在发送');return}closeTray();pickFile('image/*')};
document.addEventListener('pointerdown',event=>{if(!dock.classList.contains('desktop-emoji-open'))return;if(tray.contains(event.target)||dock.contains(event.target))return;closeTray()});
const desktopViewPrevious=setDesktopView;
setDesktopView=function(on){desktopViewPrevious(on);syncDesktopEmoji()};
new ResizeObserver(syncDesktopEmoji).observe(dock);

const desktopMentionPicker=showMention3;
showMention3=function(){desktopMentionPicker();syncDesktopEmoji()};
const desktopVoicePicker=showVoice3;
showVoice3=function(phase='idle'){desktopVoicePicker(phase);syncDesktopEmoji()};
