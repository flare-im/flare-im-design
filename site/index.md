---
layout: home
hero:
  name: Flare IM Design
  text: 跨端 IM UI 组件库
  tagline: 独立可用的跨端 IM UI 组件库 — Vue · Flutter · iOS · Android。纯展示组件：props 进、事件出，接任何 IM 后端即用；想省事可选接 Flare core，拿开箱即用的收发与多端同步。
  actions:
    - theme: brand
      text: 快速开始
      link: /guide/getting-started
    - theme: alt
      text: 浏览组件
      link: /components/
    - theme: alt
      text: 设计 Tokens
      link: /guide/tokens
features:
  - icon: '<svg viewBox="0 0 24 24" width="26" height="26" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><path d="M12 3 3 7.5l9 4.5 9-4.5z"/><path d="M3 12l9 4.5 9-4.5"/><path d="M3 16.5 12 21l9-4.5"/></svg>'
    title: 111 个组件 · 11 大类
    details: General / Conversation / Message / Composer / Media / Contacts / Profile / Call / Layout。每个组件一份框架中立契约，Vue、Flutter、iOS、Android 各自原生实现，同名同语义。
  - icon: '<svg viewBox="0 0 24 24" width="26" height="26" fill="none" stroke="currentColor" stroke-width="1.6"><circle cx="9" cy="9.8" r="4.6"/><circle cx="15" cy="9.8" r="4.6"/><circle cx="12" cy="15" r="4.6"/></svg>'
    title: 一份设计 Tokens
    details: 中立的 tokens.json 单一源，生成 Web CSS/TS、Dart、Swift、Kotlin —— 四端颜色、间距、字号、圆角完全一致，明暗双主题，运行时可换肤。
  - icon: '<svg viewBox="0 0 24 24" width="26" height="26" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"><rect x="6" y="6" width="12" height="12" rx="2.5"/><rect x="9.8" y="9.8" width="4.4" height="4.4" rx="1"/><path d="M9.5 6V3M14.5 6V3M9.5 21v-3M14.5 21v-3M6 9.5H3M6 14.5H3M21 9.5h-3M21 14.5h-3"/></svg>'
    title: 独立可用 · 接任何后端
    details: 组件是纯展示——数据用 props 传入、交互以事件抛出，不绑定任何 SDK，接你现有的 IM 后端即可跑。想省事，可选接 Flare core，直接获得可靠发送、多端同步、乐观 UI。
  - icon: '<svg viewBox="0 0 24 24" width="26" height="26" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><path d="M13 2.5 4.8 13.4H11l-.9 8.1 9.1-11.2H13z"/></svg>'
    title: 性能 & 流畅优先
    details: 乐观 UI 下一帧上屏（< 16ms）、列表虚拟化 O(visible)、媒体离主线程、缓存有界淘汰 —— 预算即设计。
  - icon: '<svg viewBox="0 0 24 24" width="26" height="26" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"><rect x="4" y="4" width="7" height="7" rx="1.4"/><rect x="13" y="4" width="7" height="7" rx="1.4"/><rect x="4" y="13" width="7" height="7" rx="1.4"/><rect x="13" y="13" width="7" height="7" rx="1.4" stroke-dasharray="2.6 2.6"/></svg>'
    title: 消息类型齐全可扩展
    details: 文本/图片/视频/文件/位置/名片/链接/投票/任务/贴纸… 内建 17 种消息体，每种一个独立组件；也可组合出自定义类型，覆盖主流 IM 的会话、聊天、输入、媒体、通话全套场景。
  - icon: '<svg viewBox="0 0 24 24" width="26" height="26" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"><path d="M6 3h8l4 4v14H6z"/><path d="M14 3v4h4"/><path d="M9 14.2l2 2 4-4.2"/></svg>'
    title: 契约即真源
    details: components.json 描述每个组件的 props/states/events + 需要的数据形状；validate 校验四端参考符号真实存在，防漂移。
---

<div class="flare-home">

<div class="flare-stats">
  <div><b>82</b><span>组件</span></div>
  <div><b>9</b><span>分类</span></div>
  <div><b>4</b><span>端原生实现</span></div>
  <div><b>1</b><span>份 tokens</span></div>
</div>

## 一个界面，四端同源

<HomeShowcase />

</div>
