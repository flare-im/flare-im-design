<script setup lang="ts">
import { computed, getCurrentInstance } from "vue";
import { isMarkdown, renderMarkdown } from "../../../utils/markdown";
import {
  resolveLoneEmojiPackInText,
  splitPlainTextForEmojiDisplay,
} from "../../composer/ComposerEmojiStickerPopover/composerEmojiAssets";
import { formatEmojiPackBracket } from "../../../utils/emojiPackI18n";
import PlainTextEmojiRich from "../../shared/PlainTextEmojiRich.vue";
import { segmentTextByMentions, type FlareTextMentionSpan } from "../../../utils/textMentions";
import FlareEmojiMessage from "./FlareEmojiMessage.vue";

const props = withDefaults(defineProps<{
  text?: string;
  self?: boolean;
  selectable?: boolean;
  /** Mention runs to emphasize (plain, non-markdown text only). */
  mentions?: readonly FlareTextMentionSpan[];
}>(), { text: "", selectable: false, mentions: () => [] });
const emit = defineEmits<{ (e: "linkClick", href: string): void }>();
const instance = getCurrentInstance();
const markdown = computed(() => isMarkdown(props.text));
const loneEmoji = computed(() => markdown.value ? null : resolveLoneEmojiPackInText(props.text));
const parts = computed(() => markdown.value ? [] : splitPlainTextForEmojiDisplay(props.text.trim()));
const unknownEmoji = computed(() => parts.value.length === 1 && parts.value[0].kind === "emojiUnknown" ? parts.value[0] : null);
const hasInlineEmoji = computed(() => parts.value.some(part => part.kind === "emoji" || part.kind === "emojiUnknown"));
const mentionSegments = computed(() =>
  props.mentions.length && !markdown.value && !hasInlineEmoji.value ? segmentTextByMentions(props.text, props.mentions) : [],
);
// The shared MarkdownIt instance disables raw HTML and escapes link attributes.
const html = computed(() => renderMarkdown(props.text));
function onClick(event: MouseEvent) {
  const link = (event.target as HTMLElement).closest<HTMLAnchorElement>("a[href]");
  if (link) {
    if (instance?.vnode.props?.onLinkClick) event.preventDefault();
    emit("linkClick", link.href);
  }
}
</script>

<template>
  <div class="fm-text im-text" :class="{ 'is-self': self, selectable, 'im-text--lone-emoji': loneEmoji || unknownEmoji }" @click="onClick">
    <FlareEmojiMessage v-if="loneEmoji" class="im-lone-emoji-img" :load-src="loneEmoji.loadUrl" :alt="loneEmoji.key" animated />
    <span v-else-if="unknownEmoji" class="im-emoji-bracket">{{ formatEmojiPackBracket(unknownEmoji.key) }}</span>
    <PlainTextEmojiRich v-else-if="hasInlineEmoji" :text="text" />
    <p v-else-if="mentionSegments.length" class="fm-text__plain"><template v-for="(segment, index) in mentionSegments" :key="index"><span
      v-if="segment.mention"
      class="fm-text__mention"
      :class="{ 'is-me': segment.mention.self || segment.mention.all }"
    >{{ segment.text }}</span><template v-else>{{ segment.text }}</template></template></p>
    <div v-else v-html="html" />
  </div>
</template>

<style scoped>
/* 消息正文引用 message 角色 —— 四端同一个出处。从前 web 写 14/1.5、三端原生写 15/1.45,
   而 web 的输入框是 15:同一块界面上「打出来的字」比「读到的字」大一号。 */
.fm-text { min-width: 0; font-size: var(--flare-text-message-font-size); line-height: var(--flare-text-message-line-height); color: inherit; overflow-wrap: anywhere; user-select: none; }
.fm-text.selectable { user-select: text; }
.fm-text :deep(p) { margin: 0; line-height: inherit; white-space: pre-wrap; }
.fm-text :deep(a) { color: inherit; text-decoration: underline; text-underline-offset: 2px; }
.fm-text :deep(pre) { max-width: 100%; overflow-x: auto; white-space: pre; }
.fm-text :deep(img) { max-width: 100%; }
.fm-text__plain { margin: 0; white-space: pre-wrap; }
/* A mention reads as a name, not a link: accent colour and weight; a mention of the reader
   (or of everyone) also gets the selected ground so it is found at a glance. */
.fm-text__mention { color: var(--flare-color-primary-text); font-weight: 500; }
.fm-text__mention.is-me { padding-inline: 2px; border-radius: var(--flare-size-radius-sm); background: var(--flare-color-bg-selected); }
.fm-text.is-self .fm-text__mention { color: inherit; font-weight: 600; }
.fm-text.is-self .fm-text__mention.is-me { background: transparent; }
.im-text--lone-emoji { display: flex; align-items: center; justify-content: center; line-height: 0; }
.im-lone-emoji-img { width: min(6.3em, 34vw); height: min(6.3em, 34vw); }
.im-emoji-bracket { font-size: var(--flare-size-font-size-2xl); line-height: 1.5; }
</style>
