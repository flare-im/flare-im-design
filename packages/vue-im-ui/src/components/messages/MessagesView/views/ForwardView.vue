<template>
  <div v-if="record.layout === 'empty'" class="im-fwd-empty" role="status">
    {{ t("forward.empty") }}
  </div>

  <!-- Single item: render inline through the content pipeline (recursive). The items are someone else's messages
       whoever forwarded the record (spec rules.palette), here and in the drawer. -->
  <div
    v-else-if="record.layout === 'single'"
    class="im-fwd-single"
    role="article"
    :aria-label="ariaSingleLabel"
  >
    <ContentView :content="singleItemContent" :is-self="false" class="im-fwd-single__body" />
  </div>

  <!-- Merged forward: compact card in the thread + drawer with the full nested list -->
  <div v-else class="im-fwd-root">
    <button
      type="button"
      class="im-fwd-card"
      :aria-label="record.label"
      :disabled="selecting() || undefined"
      @click="drawerOpen = true"
    >
      <span class="im-fwd-card__accent" aria-hidden="true" />
      <div class="im-fwd-card__body">
        <div class="im-fwd-card__headline">
          <span class="im-fwd-card__title">{{ record.title }}</span>
          <span v-if="record.subtitle" class="im-fwd-card__sub">{{ record.subtitle }}</span>
        </div>
        <ul class="im-fwd-card__previews">
          <li
            v-for="(line, i) in record.previews"
            :key="itemKey(record.items[i] ?? {}, i)"
            class="im-fwd-card__line"
          >
            <span class="im-fwd-card__sender">{{ line.sender }}:</span>
            <span class="im-fwd-card__snippet">
              <PlainTextEmojiRich :text="truncateOneLine(line.text, 56)" />
            </span>
          </li>
        </ul>
        <p v-if="record.more" class="im-fwd-card__ellipsis">{{ record.more }}</p>
        <span class="im-fwd-card__hint">{{ record.hint }}</span>
      </div>
    </button>

    <!-- 合并转发的完整列表:kit 自己的侧边抽屉(遮罩、焦点、Escape 与平台返回键都由它负责),
         宽度取 sheetWidth token。 -->
    <FlareDrawer :open="drawerOpen" :title="record.drawerTitle" @close="drawerOpen = false">
      <div class="im-fwd-drawer">
        <ol class="im-fwd-list">
          <li v-for="(it, i) in record.items" :key="itemKey(it, i)" class="im-fwd-item">
            <div class="im-fwd-item__top">
              <div
                class="im-fwd-item__avatar"
                :style="{ '--flare-component-fwd-hue': String(avatarHue(it)) }"
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
              <PlainTextEmojiRich :text="previewLine(it)" />
            </p>
            <div v-if="shouldShowContentEmbed(it)" class="im-fwd-item__embed">
              <ContentView :content="flareForwardItemContent(it)" :is-self="false" />
            </div>
          </li>
        </ol>
      </div>
    </FlareDrawer>
  </div>
</template>

<script setup lang="ts">
import { computed, ref } from "vue";
import type { ContentElem } from "../../../../utils/contentElem";
import { asRecord, readNumber, readString } from "../../../../utils/contentData";
import {
  flareForwardItemContent,
  flareForwardPreviewLine,
  flareForwardRecordView,
  flareForwardSender,
  flareForwardSenderInitial,
  type FlareForwardItemRecord,
} from "../../../../utils/forwardRecord";
import { useFlareI18n } from "../../../../shared/i18n/useFlareI18n";
import { useFlareContentSelection } from "../../../../shared/message-renderers";
import FlareDrawer from "../../../general/FlareDrawer.vue";
import ContentView from "../ContentView.vue";
import PlainTextEmojiRich from "../../../shared/PlainTextEmojiRich.vue";

// The dispatcher binds shared view props (isSelf/messageExtra/senderName/…) that
// this view doesn't consume — who forwarded the record never colours its items;
// keep them off the DOM root.
defineOptions({ inheritAttrs: false });

const props = defineProps<{ content: ContentElem }>();

const { t, locale } = useFlareI18n();
// In multi-select the card is inert: a tap belongs to the row.
const selecting = useFlareContentSelection();

// 平台返回键由 FlareDrawer 自己认领(它听得到这里的 @close),这里不再另外认领一次。
const drawerOpen = ref(false);

// The record's shape and copy (spec/message-forward-vectors.json), shared with the native kits.
const record = computed(() => flareForwardRecordView(props.content, locale.value));

const singleItemContent = computed<ContentElem>(() => flareForwardItemContent(record.value.items[0] ?? {}));
const ariaSingleLabel = computed(() => previewLine(record.value.items[0] ?? {}));

const senderLabel = (it: FlareForwardItemRecord) => flareForwardSender(it, locale.value);
const previewLine = (it: FlareForwardItemRecord) => flareForwardPreviewLine(it, locale.value);

function shouldShowContentEmbed(it: FlareForwardItemRecord): boolean {
  const c = asRecord(it.content);
  const type = readString(c, "contentType").trim();
  if (!type) return false;
  // Text renders fully in the preview line already; embed only richer bodies.
  return type !== "text";
}

function formatItemTime(it: FlareForwardItemRecord): string {
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
  return new Intl.DateTimeFormat(locale.value, opts).format(d);
}

function truncateOneLine(s: string, maxChars: number): string {
  const trimmed = s.replace(/\s+/g, " ").trim();
  if (trimmed.length <= maxChars) return trimmed;
  return `${trimmed.slice(0, Math.max(0, maxChars - 1))}…`;
}

const avatarInitial = (it: FlareForwardItemRecord) => flareForwardSenderInitial(it);

function avatarHue(it: FlareForwardItemRecord): number {
  const key = readString(it, "sourceSenderId") || senderLabel(it);
  let h = 0;
  for (let i = 0; i < key.length; i++) h = (h * 31 + key.charCodeAt(i)) >>> 0;
  return h % 360;
}

function itemKey(it: FlareForwardItemRecord, index: number): string {
  const sid = readString(it, "sourceMessageId").trim();
  if (sid) return sid;
  return `${index}-${readNumber(it, 0, "sourceMessageTimeMs")}-${senderLabel(it)}`;
}
</script>

<style scoped>
.im-fwd-empty {
  font-size: 13px;
  color: var(--flare-color-text-secondary);
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
  border: 1px solid var(--flare-color-border-primary);
  border-radius: 10px;
  background: var(--flare-color-bg-primary);
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
  outline: 2px solid var(--flare-color-border-selected);
  outline-offset: 2px;
}

.im-fwd-card__accent {
  width: 4px;
  flex-shrink: 0;
  background: var(--flare-color-primary);
}

.im-fwd-card__body {
  flex: 1;
  min-width: 0;
  padding: var(--flare-size-spacing-2sm) 12px var(--flare-size-spacing-2sm) var(--flare-size-spacing-2sm);
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
  color: var(--flare-color-text-primary);
  line-height: 1.35;
}

.im-fwd-card__sub,
.im-fwd-card__ellipsis {
  font-size: 12px;
  color: var(--flare-color-text-secondary);
  margin: 0;
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
  color: var(--flare-color-text-secondary);
  display: flex;
  flex-wrap: wrap;
  gap: 4px 6px;
  min-width: 0;
}

.im-fwd-card__sender {
  font-weight: 600;
  color: var(--flare-color-text-primary);
  flex-shrink: 0;
}

.im-fwd-card__snippet {
  min-width: 0;
  word-break: break-word;
}

.im-fwd-card__hint {
  font-size: 11px;
  color: var(--flare-color-primary-text);
  font-weight: 500;
  margin-top: 2px;
}


.im-fwd-drawer {
  padding: 0 var(--flare-size-spacing-lg) var(--flare-size-spacing-lg);
}

.im-fwd-list {
  margin: 0;
  padding: 0;
  list-style: none;
  display: flex;
  flex-direction: column;
}

.im-fwd-item {
  padding: var(--flare-size-spacing-2sm) 0;
  border-bottom: 1px solid var(--flare-color-border-primary);
}

.im-fwd-item:last-of-type {
  border-bottom: none;
  padding-bottom: 2px;
}

.im-fwd-item__top {
  display: flex;
  gap: var(--flare-size-spacing-2sm);
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
  background: hsl(var(--flare-component-fwd-hue, 210), 52%, 52%);
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
  color: var(--flare-color-text-primary);
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
  min-width: 0;
}

.im-fwd-item__time {
  flex-shrink: 0;
  font-size: 11px;
  color: var(--flare-color-text-tertiary);
  font-variant-numeric: tabular-nums;
}

.im-fwd-item__preview {
  margin: 8px 0 0 46px;
  font-size: 13px;
  line-height: 1.45;
  color: var(--flare-color-text-primary);
  display: -webkit-box;
  -webkit-box-orient: vertical;
  -webkit-line-clamp: 3;
  overflow: hidden;
  word-break: break-word;
}

.im-fwd-item__embed {
  margin: 8px 0 0 46px;
  padding-left: var(--flare-size-spacing-2sm);
  border-left: 2px solid var(--flare-color-border-primary);
  min-width: 0;
}

.im-fwd-item__embed :deep(.im-content-view) {
  max-width: 100%;
}
</style>
