<template>
  <div v-if="totalCount === 0" class="im-fwd-empty" role="status">
    {{ t("forward.empty") }}
  </div>

  <!-- Single item: render inline through the content pipeline (recursive) -->
  <div
    v-else-if="singleInlineMode"
    class="im-fwd-single"
    role="article"
    :aria-label="ariaSingleLabel"
  >
    <p v-if="remark" class="im-fwd-single__remark">
      <span class="im-fwd-single__remark-k">{{ t("forward.remark") }}</span>
      {{ remark }}
    </p>
    <ContentView :content="singleItemContent" :is-self="isSelf" class="im-fwd-single__body" />
  </div>

  <!-- Merged forward: compact card in the thread + drawer with the full nested list -->
  <div v-else class="im-fwd-root">
    <button
      type="button"
      class="im-fwd-card"
      :aria-label="ariaCardLabel"
      @click="drawerOpen = true"
    >
      <span class="im-fwd-card__accent" aria-hidden="true" />
      <div class="im-fwd-card__body">
        <div class="im-fwd-card__headline">
          <span class="im-fwd-card__title">{{ headerTitle }}</span>
          <span v-if="subtitleLine" class="im-fwd-card__sub">{{ subtitleLine }}</span>
        </div>
        <p v-if="remark" class="im-fwd-card__remark">
          <span class="im-fwd-card__remark-k">{{ t("forward.remark") }}</span>
          {{ remark }}
        </p>
        <ul class="im-fwd-card__previews">
          <li
            v-for="(it, i) in compactPreviewItems"
            :key="itemKey(it, i)"
            class="im-fwd-card__line"
          >
            <span class="im-fwd-card__sender">{{ senderLabel(it) }}:</span>
            <span class="im-fwd-card__snippet">
              <PlainTextEmojiRich :text="truncateOneLine(itemPreviewLine(it), 56)" />
            </span>
          </li>
        </ul>
        <p v-if="totalCount > compactPreviewLimit" class="im-fwd-card__ellipsis">
          {{ t("forward.moreMessages", { count: totalCount - compactPreviewLimit }) }}
        </p>
        <span class="im-fwd-card__hint">{{ t("forward.viewDetail") }}</span>
      </div>
    </button>

    <n-drawer v-model:show="drawerOpen" :width="502" placement="right" display-directive="show">
      <n-drawer-content :title="drawerTitle" closable>
        <div class="im-fwd-drawer">
          <p v-if="remark" class="im-fwd-drawer__remark">
            <span class="im-fwd-drawer__remark-k">{{ t("forward.remark") }}</span>
            {{ remark }}
          </p>
          <ol class="im-fwd-list">
            <li v-for="(it, i) in allItems" :key="itemKey(it, i)" class="im-fwd-item">
              <div class="im-fwd-item__top">
                <div
                  class="im-fwd-item__avatar"
                  :style="{ '--im-fwd-hue': String(avatarHue(it)) }"
                  aria-hidden="true"
                >
                  {{ avatarInitial(it) }}
                </div>
                <div class="im-fwd-item__meta">
                  <span class="im-fwd-item__sender">{{ senderLabel(it) }}</span>
                  <span v-if="formatItemTime(it)" class="im-fwd-item__time">
                    {{ formatItemTime(it) }}
                  </span>
                </div>
              </div>
              <p class="im-fwd-item__preview">
                <PlainTextEmojiRich :text="itemPreviewLine(it)" />
              </p>
              <div v-if="shouldShowContentEmbed(it)" class="im-fwd-item__embed">
                <ContentView :content="itemContent(it)" :is-self="false" />
              </div>
            </li>
          </ol>
        </div>
      </n-drawer-content>
    </n-drawer>
  </div>
</template>

<script setup lang="ts">
import { computed, ref } from "vue";
import { NDrawer, NDrawerContent } from "naive-ui";
import type { ContentElem } from "../../../../utils/contentElem";
import { pickNestedPayload } from "../../../../utils/contentElem";
import { asRecord, readArray, readNumber, readString } from "../../../../utils/contentData";
import { getContentDecodedPreview } from "../../../../utils/messagePreview";
import { useFlareI18n } from "../../../../shared/i18n/useFlareI18n";
import ContentView from "../ContentView.vue";
import PlainTextEmojiRich from "../../../shared/PlainTextEmojiRich.vue";

type ForwardItem = Record<string, unknown>;

// The dispatcher binds shared view props (messageExtra/senderName/…) that this
// view doesn't consume; keep them off the DOM root.
defineOptions({ inheritAttrs: false });

const props = defineProps<{ content: ContentElem; isSelf: boolean }>();

const { t } = useFlareI18n();

const drawerOpen = ref(false);
const compactPreviewLimit = 3;

// Accept both the nested `forward` payload and a serde-flattened root carrying
// `items` / `mode` / `title`.
const payload = computed(() => {
  const nested = pickNestedPayload(props.content, "forward");
  return Object.keys(nested).length ? nested : (props.content as Record<string, unknown>);
});

const allItems = computed<ForwardItem[]>(() => readArray(payload.value, "items").map(asRecord));
const totalCount = computed(() => allItems.value.length);
const compactPreviewItems = computed(() => allItems.value.slice(0, compactPreviewLimit));
const mode = computed(() => readNumber(payload.value, 0, "mode"));
const remark = computed(() => readString(payload.value, "title").trim());

// ForwardMode: 1 SINGLE | 2 MERGED (0 unspecified → infer from count)
const singleInlineMode = computed(() => totalCount.value === 1 && mode.value !== 2);

const headerTitle = computed(() => {
  if (totalCount.value <= 1 && mode.value !== 2) return t("forward.defaultTitle");
  return t("forward.merged");
});

const subtitleLine = computed(() =>
  totalCount.value > 1 ? t("forward.totalMessages", { count: totalCount.value }) : "",
);

const drawerTitle = computed(() =>
  totalCount.value > 0
    ? `${headerTitle.value}${t("forward.countSuffix", { count: totalCount.value })}`
    : headerTitle.value,
);

function itemContent(it: ForwardItem): ContentElem {
  const c = asRecord(it.content);
  if (readString(c, "contentType").trim()) return c as ContentElem;
  const plain = readString(it, "plainText").trim();
  if (plain) return { contentType: "text", text: { text: plain, mentions: [] } } as ContentElem;
  return { contentType: "text", text: { text: "", mentions: [] } } as ContentElem;
}

const singleItemContent = computed<ContentElem>(() => itemContent(allItems.value[0] ?? {}));

function itemPreviewLine(it: ForwardItem): string {
  const plain = readString(it, "plainText").trim();
  if (plain) return plain;
  const c = asRecord(it.content);
  if (readString(c, "contentType").trim()) {
    const fromContent = getContentDecodedPreview(c as ContentElem).trim();
    if (fromContent) return fromContent;
  }
  return t("preview.forward");
}

function shouldShowContentEmbed(it: ForwardItem): boolean {
  const c = asRecord(it.content);
  const type = readString(c, "contentType").trim();
  if (!type) return false;
  // Text renders fully in the preview line already; embed only richer bodies.
  return type !== "text";
}

function senderLabel(it: ForwardItem): string {
  const name = readString(it, "sourceSenderName").trim();
  if (name) return name;
  const id = readString(it, "sourceSenderId").trim();
  if (id) return id.length > 12 ? `${id.slice(0, 6)}…${id.slice(-4)}` : id;
  return t("forward.unknownSender");
}

function formatItemTime(it: ForwardItem): string {
  const ms = readNumber(it, 0, "sourceMessageTimeMs");
  if (!Number.isFinite(ms) || ms <= 0) return "";
  const d = new Date(ms);
  if (Number.isNaN(d.getTime())) return "";
  const now = new Date();
  const sameDay =
    d.getFullYear() === now.getFullYear() &&
    d.getMonth() === now.getMonth() &&
    d.getDate() === now.getDate();
  const opts: Intl.DateTimeFormatOptions = sameDay
    ? { hour: "2-digit", minute: "2-digit" }
    : { month: "numeric", day: "numeric", hour: "2-digit", minute: "2-digit" };
  return new Intl.DateTimeFormat(undefined, opts).format(d);
}

function truncateOneLine(s: string, maxChars: number): string {
  const trimmed = s.replace(/\s+/g, " ").trim();
  if (trimmed.length <= maxChars) return trimmed;
  return `${trimmed.slice(0, Math.max(0, maxChars - 1))}…`;
}

function avatarInitial(it: ForwardItem): string {
  const ch = senderLabel(it).trim().charAt(0);
  return ch ? ch.toUpperCase() : "?";
}

function avatarHue(it: ForwardItem): number {
  const key = readString(it, "sourceSenderId") || senderLabel(it);
  let h = 0;
  for (let i = 0; i < key.length; i++) h = (h * 31 + key.charCodeAt(i)) >>> 0;
  return h % 360;
}

function itemKey(it: ForwardItem, index: number): string {
  const sid = readString(it, "sourceMessageId").trim();
  if (sid) return sid;
  return `${index}-${readNumber(it, 0, "sourceMessageTimeMs")}-${senderLabel(it)}`;
}

const ariaSingleLabel = computed(() => {
  const preview = itemPreviewLine(allItems.value[0] ?? {});
  return remark.value ? `${t("forward.remark")}: ${remark.value}. ${preview}` : preview;
});

const ariaCardLabel = computed(() => {
  if (remark.value) return `${headerTitle.value}, ${t("forward.remark")}: ${remark.value}`;
  return subtitleLine.value ? `${headerTitle.value}, ${subtitleLine.value}` : headerTitle.value;
});
</script>

<style scoped>
.im-fwd-empty {
  font-size: 13px;
  color: var(--im-text-secondary, #86909c);
  padding: 2px 0;
  min-width: 0;
}

.im-fwd-single {
  min-width: 0;
  max-width: 100%;
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.im-fwd-single__remark {
  margin: 0;
  font-size: 12px;
  line-height: 1.4;
  color: var(--im-text-secondary, #86909c);
}

.im-fwd-single__remark-k,
.im-fwd-card__remark-k,
.im-fwd-drawer__remark-k {
  margin-right: 6px;
  font-size: 11px;
  font-weight: 600;
  color: var(--im-text-tertiary, #8f959e);
}

.im-fwd-single__body {
  min-width: 0;
}

.im-fwd-root {
  max-width: min(320px, 100%);
  min-width: 0;
}

.im-fwd-card {
  display: flex;
  width: 100%;
  margin: 0;
  padding: 0;
  border: 1px solid var(--im-border, #e5e6eb);
  border-radius: 10px;
  background: var(--im-bg-surface, #ffffff);
  box-shadow: 0 1px 3px rgb(0 0 0 / 6%);
  cursor: pointer;
  text-align: left;
  font: inherit;
  color: inherit;
  overflow: hidden;
  transition:
    filter 0.15s ease,
    box-shadow 0.15s ease;
}

.im-fwd-card:hover {
  box-shadow: 0 2px 8px rgb(0 0 0 / 12%);
}

.im-fwd-card:focus-visible {
  outline: 2px solid var(--im-primary, #3370ff);
  outline-offset: 2px;
}

.im-fwd-card__accent {
  width: 4px;
  flex-shrink: 0;
  background: var(--im-primary, #3370ff);
}

.im-fwd-card__body {
  flex: 1;
  min-width: 0;
  padding: 10px 12px 10px 10px;
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.im-fwd-card__headline {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.im-fwd-card__title {
  font-size: 14px;
  font-weight: 700;
  color: var(--im-text-primary, #1d2129);
  line-height: 1.35;
}

.im-fwd-card__sub,
.im-fwd-card__ellipsis {
  font-size: 12px;
  color: var(--im-text-secondary, #86909c);
  margin: 0;
}

.im-fwd-card__remark {
  margin: 0;
  font-size: 12px;
  line-height: 1.4;
  color: var(--im-text-secondary, #4e5969);
}

.im-fwd-card__previews {
  margin: 4px 0 0;
  padding: 0;
  list-style: none;
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.im-fwd-card__line {
  font-size: 13px;
  line-height: 1.45;
  color: var(--im-text-secondary, #4e5969);
  display: flex;
  flex-wrap: wrap;
  gap: 4px 6px;
  min-width: 0;
}

.im-fwd-card__sender {
  font-weight: 600;
  color: var(--im-text-primary, #1d2129);
  flex-shrink: 0;
}

.im-fwd-card__snippet {
  min-width: 0;
  word-break: break-word;
}

.im-fwd-card__hint {
  font-size: 11px;
  color: var(--im-primary, #3370ff);
  font-weight: 500;
  margin-top: 2px;
}

.im-fwd-drawer__remark {
  margin: 0 0 14px;
  font-size: 13px;
  line-height: 1.45;
  color: var(--im-text-secondary, #86909c);
  padding: 8px 10px;
  border-radius: 8px;
  background: var(--im-bg-hover, rgb(0 0 0 / 4%));
  border: 1px solid var(--im-border, #e5e6eb);
}

.im-fwd-list {
  margin: 0;
  padding: 0;
  list-style: none;
  display: flex;
  flex-direction: column;
}

.im-fwd-item {
  padding: 10px 0;
  border-bottom: 1px solid var(--im-border, rgb(229 230 235 / 65%));
}

.im-fwd-item:last-of-type {
  border-bottom: none;
  padding-bottom: 2px;
}

.im-fwd-item__top {
  display: flex;
  gap: 10px;
  align-items: center;
}

.im-fwd-item__avatar {
  flex-shrink: 0;
  width: 36px;
  height: 36px;
  border-radius: 50%;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 14px;
  font-weight: 700;
  color: #fff;
  background: hsl(var(--im-fwd-hue, 210), 52%, 52%);
  box-shadow: inset 0 0 0 1px rgb(0 0 0 / 6%);
}

.im-fwd-item__meta {
  flex: 1;
  min-width: 0;
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  gap: 8px;
}

.im-fwd-item__sender {
  font-size: 13px;
  font-weight: 600;
  color: var(--im-text-primary, #1d2129);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  min-width: 0;
}

.im-fwd-item__time {
  flex-shrink: 0;
  font-size: 11px;
  color: var(--im-text-tertiary, #8f959e);
  font-variant-numeric: tabular-nums;
}

.im-fwd-item__preview {
  margin: 8px 0 0 46px;
  font-size: 13px;
  line-height: 1.45;
  color: var(--im-text-primary, #1d2129);
  display: -webkit-box;
  -webkit-box-orient: vertical;
  -webkit-line-clamp: 3;
  overflow: hidden;
  word-break: break-word;
}

.im-fwd-item__embed {
  margin: 8px 0 0 46px;
  padding-left: 10px;
  border-left: 2px solid var(--im-border, #e5e6eb);
  min-width: 0;
}

.im-fwd-item__embed :deep(.im-content-view) {
  max-width: 100%;
}
</style>
