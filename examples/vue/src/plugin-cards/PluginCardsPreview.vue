<script setup lang="ts">
import { computed, ref } from "vue";
import { FlareUiProvider, FlareButton, FlareIcon, FlareAvatar, FlarePluginView, FlarePluginDetailSheet, type FlarePluginActionPayload, type FlarePluginViewModel } from "@flare-im/vue-ui";
import { cardExamples, type CardExample } from "./fixtures";

const examples = ref(cardExamples());
const dark = ref(false), narrow = ref(false), active = ref("all");
const detail = ref<CardExample>();
const feedback = ref(""), failNext = ref(false);
const busy = ref<Record<string, string>>({}), errors = ref<Record<string, string>>({});
const settle = ref(0);
const visible = computed(() => active.value === "all" ? examples.value : examples.value.filter(card => card.id === active.value));
function reset() { examples.value = cardExamples(); errors.value = {}; feedback.value = "示例状态已重置"; detail.value = undefined; }
async function act(card: CardExample, id: string, payload: FlarePluginActionPayload) {
  busy.value[card.id] = id; errors.value[card.id] = "";
  await new Promise(resolve => setTimeout(resolve, 450));
  if (failNext.value) {
    failNext.value = false; errors.value[card.id] = "示例网络暂不可用，请重试。";
  } else {
    const view = structuredClone(JSON.parse(JSON.stringify(card.view))) as FlarePluginViewModel;
    if (id === "join") {
      view.blocks = view.blocks?.map(block => block.kind === "entries" ? { ...block, total: block.total + 1, items: [...block.items, { index: block.total + 1, name: "你", text: String(payload.formValues?.entry ?? "") }] } : block);
      feedback.value = "已加入示例接龙";
    } else if (id === "vote") {
      view.blocks = view.blocks?.map(block => block.kind === "choices" ? { ...block, voted: true, showResults: true, options: block.options.map(option => ({ ...option, selected: payload.selection?.includes(option.index) ?? false, count: payload.selection?.includes(option.index) ? 1 : 0, percent: payload.selection?.includes(option.index) ? 100 : 0 })) } : block);
      feedback.value = "示例投票已更新";
    } else {
      const label = ({ end: "已结束", complete: "已完成", confirm: "已确认", accept: "已接受", decline: "已婉拒" } as Record<string, string>)[id] ?? "已更新";
      view.actions = []; view.menuActions = [];
      view.blocks = [...(view.blocks ?? []).map(block => block.kind === "progress" && id === "complete" ? { ...block, value: block.total, percent: 100 } : block), { kind: "status", text: label, tone: id === "end" || id === "decline" ? "neutral" : "success" }];
      feedback.value = `示例${card.view.title}${label}`;
    }
    card.view = view;
  }
  busy.value[card.id] = ""; settle.value++;
}
</script>

<template>
  <FlareUiProvider :theme-mode="dark ? 'dark' : 'light'" locale="zh-CN">
    <main class="preview">
      <aside class="preview__side">
        <a class="preview__brand" href="/plugin-cards.html"><FlareIcon name="comment" :size="22" /><strong>Flare</strong></a>
        <p class="preview__eyebrow">VUE 组件库 · 设计预览</p>
        <h1>让内容更突出<br>让操作更轻巧</h1>
        <p class="preview__intro">在对话里读懂一件事，<br>用一个清晰的动作继续。</p>
        <nav aria-label="消息类型" class="preview__nav">
          <button :class="{ 'is-active': active === 'all' }" :aria-pressed="active === 'all'" @click="active = 'all'"><FlareIcon name="comment" :size="17" /><span>全部消息</span></button>
          <button v-for="card in examples" :key="card.id" :class="{ 'is-active': active === card.id }" :aria-pressed="active === card.id" @click="active = card.id"><FlareIcon :name="card.icon" :size="17" /><span>{{ card.id === 'closed' ? '已结束' : card.id === 'unavailable' ? '服务异常' : card.view.title }}</span></button>
        </nav>
        <div class="preview__principles"><span>内容优先</span><p>类型、正文、进度各有层级。</p><span>一行操作</span><p>文字操作，详情就近可达。</p><span>明确反馈</span><p>保留确认、加载和失败恢复。</p></div>
      </aside>
      <section class="preview__workspace">
        <header class="preview__toolbar"><span>消息卡片 / <b>紧凑布局</b></span><div><FlareButton size="sm" variant="quiet" :label="narrow ? '桌面视图' : '窄屏视图'" @click="narrow = !narrow" /><FlareButton size="sm" variant="quiet" :label="dark ? '浅色' : '深色'" @click="dark = !dark" /><FlareButton size="sm" variant="secondary" label="重置示例" @click="reset" /></div></header>
        <nav class="preview__mobile-nav" aria-label="筛选消息类型">
          <FlareButton size="sm" :variant="active === 'all' ? 'text' : 'quiet'" :aria-pressed="active === 'all'" label="全部" @click="active = 'all'" />
          <FlareButton v-for="card in examples" :key="card.id" size="sm" :variant="active === card.id ? 'text' : 'quiet'" :aria-pressed="active === card.id" :label="card.id === 'closed' ? '已结束' : card.id === 'unavailable' ? '异常' : card.view.title" @click="active = card.id" />
        </nav>
        <div class="preview__canvas">
          <section class="preview__chat" :class="{ 'is-narrow': narrow }" aria-label="插件消息示例对话">
            <header class="preview__chat-head"><FlareAvatar display-name="产品协作群" user-id="demo-group" :size="36" /><div><strong>产品协作群</strong><small>组件演示 · 以下均为示例数据</small></div><FlareIcon name="more" :size="20" /></header>
            <div class="preview__messages">
              <p class="preview__date">今天</p>
              <article v-for="card in visible" :key="card.id" class="preview__message" :class="{ 'is-self': card.self }" :data-example="card.id">
                <FlareAvatar v-if="!card.self" :display-name="card.sender" :user-id="card.sender" :size="30" />
                <div class="preview__message-main"><small class="preview__sender">{{ card.sender }}</small>
                  <FlarePluginView :view="card.view" :icon="card.icon" :display-name="card.view.title" :busy-action-id="busy[card.id]" :error="errors[card.id]" :settle-token="settle" @action="(id, payload) => act(card, id, payload)" @open-detail="detail = card" />
                  <small class="preview__meta">{{ card.time }}<template v-if="card.self"> · 已读</template></small>
                </div>
              </article>
            </div>
            <footer class="preview__composer"><FlareIcon name="add" :size="20" /><span>这是组件预览，不会发送真实消息</span><FlareIcon name="send" :size="18" /></footer>
          </section>
        </div>
        <footer class="preview__status"><span role="status">{{ feedback || '可体验参与接龙、标记完成、投票和查看详情' }}</span><label><input v-model="failNext" type="checkbox" />下一次操作模拟失败</label></footer>
      </section>
      <FlarePluginDetailSheet :open="Boolean(detail)" :view="detail?.view" :busy-action-id="detail ? busy[detail.id] : undefined" :action-error="detail ? errors[detail.id] : undefined" :settle-token="settle" @close="detail = undefined" @action="(id, payload) => detail && act(detail, id, payload)" />
    </main>
  </FlareUiProvider>
</template>

<style scoped>
.preview { display: flex; width: 100%; height: 100dvh; background: var(--flare-color-bg-secondary); color: var(--flare-color-text-primary); font: var(--flare-size-font-size-md)/var(--flare-size-line-height-normal) var(--flare-font-family, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif); }
.preview__side { flex: 0 0 224px; padding: var(--flare-size-spacing-xl); box-sizing: border-box; border-right: 1px solid var(--flare-color-border-secondary); background: var(--flare-color-bg-primary); overflow-y: auto; }
.preview__brand { display: flex; align-items: center; gap: var(--flare-size-spacing-sm); text-decoration: none; color: var(--flare-color-primary-text); font-size: var(--flare-size-font-size-xl); }
.preview__eyebrow { margin: var(--flare-size-spacing-2xl) 0 var(--flare-size-spacing-sm); color: var(--flare-color-text-tertiary); font-size: var(--flare-size-font-size-xs); letter-spacing: .04em; }
h1 { margin: 0; font-size: var(--flare-size-font-size-xl); line-height: var(--flare-size-line-height-relaxed); font-weight: var(--flare-size-font-weight-semibold); }
.preview__intro { margin-block: var(--flare-size-spacing-sm) var(--flare-size-spacing-xl); color: var(--flare-color-text-secondary); }
.preview__nav { display: grid; gap: var(--flare-size-spacing-xs); }
.preview__nav button { display: flex; align-items: center; gap: var(--flare-size-spacing-sm); min-height: var(--flare-size-layout-touch-target); padding-inline: var(--flare-size-spacing-sm); border: 0; border-radius: var(--flare-size-radius-md); color: var(--flare-color-text-secondary); background: transparent; font: inherit; text-align: start; cursor: pointer; }
.preview__nav button:hover { background: var(--flare-color-bg-hover); }
.preview__nav button.is-active { background: var(--flare-color-bg-selected); color: var(--flare-color-primary-text); font-weight: var(--flare-size-font-weight-semibold); }
.preview__nav button:focus-visible { outline: none; background: var(--flare-color-bg-selected); font-weight: var(--flare-size-font-weight-bold); }
@media (forced-colors: active) {
  .preview__nav button.is-active { background: Highlight; color: HighlightText; }
  .preview__nav button:focus-visible { outline: 2px solid Highlight; outline-offset: -2px; }
}
.preview__principles { margin-top: var(--flare-size-spacing-xl); padding-top: var(--flare-size-spacing-lg); border-top: 1px solid var(--flare-color-border-secondary); font-size: var(--flare-size-font-size-sm); }
.preview__principles span { font-weight: var(--flare-size-font-weight-medium); }
.preview__principles p { margin: var(--flare-size-spacing-2xs) 0 var(--flare-size-spacing-md); color: var(--flare-color-text-tertiary); }
.preview__workspace { flex: 1; min-width: 0; display: flex; flex-direction: column; }
.preview__toolbar { display: flex; align-items: center; justify-content: space-between; gap: var(--flare-size-spacing-md); min-height: 64px; padding: 0 var(--flare-size-spacing-xl); border-bottom: 1px solid var(--flare-color-border-secondary); background: var(--flare-color-bg-primary); }
.preview__toolbar > span { color: var(--flare-color-text-secondary); }
.preview__toolbar b { color: var(--flare-color-text-primary); font-weight: var(--flare-size-font-weight-medium); }
.preview__toolbar > div { display: flex; gap: var(--flare-size-spacing-sm); }
.preview__mobile-nav { display: none; }
.preview__canvas { display: flex; flex: 1; justify-content: center; min-height: 0; padding: var(--flare-size-spacing-xl); }
.preview__chat { display: flex; flex-direction: column; width: 100%; max-width: 820px; min-width: 0; border: 1px solid var(--flare-color-border-secondary); border-radius: var(--flare-size-radius-lg); background: var(--flare-color-bg-primary); overflow: hidden; }
.preview__chat.is-narrow { max-width: 375px; }
.preview__chat-head { display: flex; align-items: center; gap: var(--flare-size-spacing-sm); flex: none; padding: var(--flare-size-spacing-md) var(--flare-size-spacing-lg); border-bottom: 1px solid var(--flare-color-border-secondary); }
.preview__chat-head > div { flex: 1; display: grid; gap: var(--flare-size-spacing-3xs); }
.preview__chat-head strong { font-size: var(--flare-size-font-size-lg); font-weight: var(--flare-size-font-weight-semibold); }
.preview__chat-head small { color: var(--flare-color-text-tertiary); font-size: var(--flare-size-font-size-sm); }
.preview__messages { flex: 1; overflow-y: auto; min-height: 0; padding: var(--flare-size-spacing-lg); scrollbar-gutter: stable; }
.preview__date { margin: 0 0 var(--flare-size-spacing-xl); color: var(--flare-color-text-tertiary); font-size: var(--flare-size-font-size-xs); text-align: center; }
.preview__message { min-width: 0; display: flex; align-items: flex-start; gap: var(--flare-size-spacing-sm); margin-block-end: var(--flare-size-spacing-xl); }
.preview__message.is-self { justify-content: flex-end; }
.preview__message-main { display: grid; grid-template-columns: minmax(0, 1fr); max-width: 100%; min-width: 0; gap: var(--flare-size-spacing-xs); }
.preview__sender { color: var(--flare-color-text-secondary); font-size: var(--flare-size-font-size-xs); }
.is-self .preview__sender { display: none; }
.preview__meta { color: var(--flare-color-text-tertiary); font-size: var(--flare-size-font-size-xs); }
.is-self .preview__meta { text-align: end; }
.preview__composer { display: flex; flex: none; align-items: center; gap: var(--flare-size-spacing-md); min-height: 56px; padding-inline: var(--flare-size-spacing-lg); border-top: 1px solid var(--flare-color-border-secondary); color: var(--flare-color-text-tertiary); font-size: var(--flare-size-font-size-sm); }
.preview__composer span { flex: 1; }
.preview__status { display: flex; justify-content: space-between; align-items: center; gap: var(--flare-size-spacing-md); min-height: 44px; padding-inline: var(--flare-size-spacing-xl); color: var(--flare-color-text-secondary); font-size: var(--flare-size-font-size-sm); }
.preview__status label { display: inline-flex; align-items: center; gap: var(--flare-size-spacing-xs); white-space: nowrap; }
@media (max-width: 760px) { .preview__mobile-nav { display: flex; gap: var(--flare-size-spacing-sm); flex: none; padding: var(--flare-size-spacing-xs) var(--flare-size-spacing-md); overflow-x: auto; border-bottom: 1px solid var(--flare-color-border-secondary); } .preview__mobile-nav > * { flex: none; }  .preview__side { display: none; } .preview__toolbar { padding-inline: var(--flare-size-spacing-md); } .preview__toolbar > span { display: none; } .preview__toolbar > div { width: 100%; justify-content: flex-end; } .preview__canvas { padding: var(--flare-size-spacing-sm); } .preview__status { flex-wrap: wrap; padding: var(--flare-size-spacing-sm) var(--flare-size-spacing-md); } .preview__messages { padding: var(--flare-size-spacing-2sm); } }
</style>
<style>html, body, #app { margin: 0; min-height: 100%; } * { box-sizing: border-box; }</style>
