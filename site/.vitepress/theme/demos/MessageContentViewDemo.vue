<script setup>
// Each message type is its own standalone component (clean props, freely
// composable). MessageContentView just dispatches to the right one by type —
// but you can drop any single one into your own layout.
import FlareTextMessage from "flare-core-vue-im-ui/components/messages/standalone/FlareTextMessage.vue";
import FlareImageMessage from "flare-core-vue-im-ui/components/messages/standalone/FlareImageMessage.vue";
import FlareVideoMessage from "flare-core-vue-im-ui/components/messages/standalone/FlareVideoMessage.vue";
import FlareVoiceMessage from "flare-core-vue-im-ui/components/messages/standalone/FlareVoiceMessage.vue";
import FlareFileMessage from "flare-core-vue-im-ui/components/messages/standalone/FlareFileMessage.vue";
import FlareLocationMessage from "flare-core-vue-im-ui/components/messages/standalone/FlareLocationMessage.vue";
import FlareContactMessage from "flare-core-vue-im-ui/components/messages/standalone/FlareContactMessage.vue";
import FlareLinkCardMessage from "flare-core-vue-im-ui/components/messages/standalone/FlareLinkCardMessage.vue";
import FlareVoteMessage from "flare-core-vue-im-ui/components/messages/standalone/FlareVoteMessage.vue";
import FlareTaskMessage from "flare-core-vue-im-ui/components/messages/standalone/FlareTaskMessage.vue";
import FlareStickerMessage from "flare-core-vue-im-ui/components/messages/standalone/FlareStickerMessage.vue";
import FlareEmojiMessage from "flare-core-vue-im-ui/components/messages/standalone/FlareEmojiMessage.vue";
import FlareSystemMessage from "flare-core-vue-im-ui/components/messages/standalone/FlareSystemMessage.vue";
</script>

<template>
  <div class="canvas">
    <div class="item"><span class="tag">&lt;FlareTextMessage&gt;</span>
      <FlareTextMessage text="带链接的文本消息，点 flare.im 查看详情。" />
    </div>
    <div class="item"><span class="tag">&lt;FlareImageMessage&gt;</span>
      <FlareImageMessage />
    </div>
    <div class="item"><span class="tag">&lt;FlareVideoMessage&gt;</span>
      <FlareVideoMessage duration="00:42" />
    </div>
    <div class="item"><span class="tag">&lt;FlareVoiceMessage&gt;</span>
      <FlareVoiceMessage :seconds="7" />
    </div>
    <div class="item"><span class="tag">&lt;FlareFileMessage&gt;</span>
      <FlareFileMessage name="设计规范 v2.pdf" size="2.4 MB" ext="PDF" />
    </div>
    <div class="item"><span class="tag">&lt;FlareLocationMessage&gt;</span>
      <FlareLocationMessage title="字节跳动 · 三里屯" address="北京市朝阳区工人体育场北路" />
    </div>
    <div class="item"><span class="tag">&lt;FlareContactMessage&gt;</span>
      <FlareContactMessage name="Ivy Chen" subtitle="@ivy_chen" />
    </div>
    <div class="item"><span class="tag">&lt;FlareLinkCardMessage&gt;</span>
      <FlareLinkCardMessage title="Flare IM Design — 跨端 IM UI 组件库" domain="flare.im" />
    </div>
    <div class="item"><span class="tag">&lt;FlareVoteMessage&gt;</span>
      <FlareVoteMessage title="周会时间投票" :options="[{ text: '周四 15:00', pct: 62 }, { text: '周五 10:00', pct: 38 }]" />
    </div>
    <div class="item"><span class="tag">&lt;FlareTaskMessage&gt;</span>
      <FlareTaskMessage title="整理评审结论并同步" meta="今天 18:00 截止 · 已完成" done />
    </div>
    <div class="item"><span class="tag">&lt;FlareStickerMessage&gt;</span>
      <FlareStickerMessage emoji="🐱" />
    </div>
    <div class="item"><span class="tag">&lt;FlareEmojiMessage&gt;</span>
      <FlareEmojiMessage emoji="🎉" />
    </div>
    <div class="item"><span class="tag">&lt;FlareSystemMessage&gt;</span>
      <FlareSystemMessage text="Ivy 撤回了一条消息" />
    </div>
  </div>
</template>

<style scoped>
.canvas { width: 100%; max-width: 520px; display: flex; flex-direction: column; gap: 12px; padding: 16px; border-radius: 14px; background: var(--flare-color-bg-secondary); }
.item { display: flex; align-items: center; gap: 12px; min-width: 0; }
.tag { width: 168px; flex: none; font-size: 11px; font-family: var(--vp-font-family-mono, monospace); color: var(--flare-color-text-tertiary); white-space: nowrap; }
@media (max-width: 640px) {
  .item { flex-direction: column; align-items: flex-start; gap: 4px; }
  .tag { width: auto; }
}
</style>
