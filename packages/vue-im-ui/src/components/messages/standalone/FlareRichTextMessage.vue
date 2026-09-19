<script setup lang="ts">
import { computed, getCurrentInstance, provide, ref, watch } from "vue";
import { parseRichDoc } from "../../../utils/richDoc";
import { useFlareI18nOptional } from "../../../shared/i18n/useFlareI18n";
import FlareRichDocBlocks from "./FlareRichDocBlocks.vue";
import { FLARE_RICH_DOC_SPOILERS } from "./richDocContext";

/**
 * rich text — the RichDoc v2 document the core stores for a rich-text message (`docJson`), drawn as
 * headings, paragraphs, quotes, code, lists and rules with their marks, links, mentions and emoji
 * (`spec/rich-doc-vectors.json`), under the message's `title` when it has one. A document that is not
 * drawable shows `plainText`, the core's own flat text, and a message with neither shows the rich-text term. Spoilers stay covered until the
 * reader reveals them; links reach `linkClick` only when `safeExternalUrl` accepts them.
 */
const props = withDefaults(defineProps<{
  /** The document's JSON text, as the core sends it (`docJson`). */
  docJson?: string | null;
  /** The core's flat text of the same message, drawn when the document is not drawable. */
  plainText?: string;
  /** The message's own title (`RichTextContent.title`), drawn above the document. */
  title?: string;
  self?: boolean;
  selectable?: boolean;
}>(), { docJson: null, plainText: "", title: "", self: false, selectable: false });
const emit = defineEmits<{ (e: "linkClick", href: string): void }>();

const instance = getCurrentInstance();
const { t } = useFlareI18nOptional();
const blocks = computed(() => (props.docJson == null ? null : parseRichDoc(props.docJson)));
const fallback = computed(() => props.plainText.trim() || t("preview.richText"));

const revealed = ref(false);
watch(() => props.docJson, () => { revealed.value = false; });
provide(FLARE_RICH_DOC_SPOILERS, {
  revealed,
  label: computed(() => t("message.spoilerReveal")),
});

function onClick(event: MouseEvent) {
  const target = event.target as HTMLElement;
  if (target.closest("[data-flare-spoiler]")) {
    event.preventDefault();
    revealed.value = true;
    return;
  }
  const link = target.closest<HTMLAnchorElement>("a[href]");
  if (link) {
    if (instance?.vnode.props?.onLinkClick) event.preventDefault();
    emit("linkClick", link.href);
  }
}

function onKeydown(event: KeyboardEvent) {
  if (event.key !== "Enter" && event.key !== " ") return;
  if (!(event.target as HTMLElement).closest("[data-flare-spoiler]")) return;
  event.preventDefault();
  revealed.value = true;
}
</script>

<template>
  <div class="fm-rich" :class="{ 'is-self': self, selectable }" @click="onClick" @keydown="onKeydown">
    <p v-if="title.trim()" class="fm-rich__title">{{ title.trim() }}</p>
    <FlareRichDocBlocks v-if="blocks && blocks.length" :blocks="blocks" :self="self" />
    <p v-else class="fm-rich__plain">{{ fallback }}</p>
  </div>
</template>

<style scoped>
.fm-rich {
  min-width: 0;
  font-size: var(--flare-size-font-size-lg);
  line-height: 1.5;
  color: inherit;
  overflow-wrap: anywhere;
  user-select: none;
}
.fm-rich.selectable { user-select: text; }
.fm-rich__plain { margin: 0; white-space: pre-wrap; }
.fm-rich__title { margin: 0 0 0.42em; font-size: 1.12em; font-weight: 700; line-height: 1.28; }
</style>
