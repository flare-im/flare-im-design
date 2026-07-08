<template>
  <div class="md">
    <h3>发布说明 v0.2</h3>
    <p>本次更新包含 <strong>四端组件库</strong> 与 <em>设计 tokens</em> 生成器。</p>
    <ul>
      <li>新增 <code>MessageContentView</code> 内容注册表</li>
      <li>Composer 支持富文本预览</li>
    </ul>
    <pre>flareColors().bubbleSelf</pre>
  </div>
</template>

<style scoped>
.md { width: 100%; max-width: 460px; text-align: left; color: var(--flare-color-text-primary); }
.md h3 { margin: 0 0 8px; font-size: 20px; font-weight: 700; }
.md p { margin: 0 0 8px; font-size: 14px; line-height: 1.6; color: var(--flare-color-text-secondary); }
.md strong { color: var(--flare-color-text-primary); }
.md ul { margin: 0 0 8px; padding-left: 20px; }
.md li { font-size: 14px; line-height: 1.7; }
.md code { background: var(--flare-color-bg-tertiary); padding: 1px 5px; border-radius: 4px; font-size: 13px; }
.md pre { background: var(--flare-color-bg-tertiary); padding: 12px; border-radius: 6px; font-size: 13px; overflow-x: auto; }
</style>
