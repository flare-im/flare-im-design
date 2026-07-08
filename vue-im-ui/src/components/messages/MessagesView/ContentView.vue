<script setup lang="ts">
import { computed } from "vue";
import type { ContentElem, MessageContentLike } from "../../../utils/contentElem";
import type { MessageMediaDownloadUiState } from "../MessageBubble.vue";
import { normalizeToContentElem, pickNestedPayload } from "../../../utils/contentElem";
import { messageExtraAsStrings } from "../../../utils/contentElem";
import { getContentDecodedPreview } from "../../../utils/messagePreview";
import { imageInfoIsMotion } from "../../../utils/motionImage";
import { isGifPlayAnimatedFromExtra, isStickerPlayAnimatedFromExtra } from "../../../utils/gifPlayback";
import TextView from "./views/TextView.vue";
import ImageView from "./views/ImageView.vue";
import VideoView from "./views/VideoView.vue";
import AudioView from "./views/AudioView.vue";
import FileView from "./views/FileView.vue";
import LocationView from "./views/LocationView.vue";
import CardView from "./views/CardView.vue";
import StickerView from "./views/StickerView.vue";
import EmojiView from "./views/EmojiView.vue";
import QuoteView from "./views/QuoteView.vue";
import LinkCardView from "./views/LinkCardView.vue";
import ForwardView from "./views/ForwardView.vue";
import RichTextView from "./views/RichTextView.vue";
import ImageGroupView from "./views/ImageGroupView.vue";
import SystemView from "./views/SystemView.vue";
import NotificationView from "./views/NotificationView.vue";
import InfoCardView from "./views/InfoCardView.vue";
import TaskView from "../business/FlareTaskMessageView.vue";
import ScheduleView from "../business/FlareScheduleMessageView.vue";
import VoteView from "../business/FlareVoteMessageView.vue";
import AnnouncementView from "../business/FlareAnnouncementMessageView.vue";
import MiniProgramView from "../business/FlareMiniProgramMessageView.vue";
import PlaceholderView from "./views/PlaceholderView.vue";

const CONTENT_TYPE_VIEW_KEYS: Record<string, string> = {
  image_group: "imageGroup",
  link_card: "linkCard",
  mini_program: "miniProgram",
  rich_text: "richText",
};

const props = withDefaults(
  defineProps<{
    content?: MessageContentLike | null;
    isSelf?: boolean;
    previewMode?: boolean;
    messageId?: string;
    messageExtra?: Record<string, unknown>;
    senderName?: string;
    mediaAction?: "download" | "openFolder" | null;
    mediaState?: MessageMediaDownloadUiState | null;
  }>(),
  {
    isSelf: false,
    previewMode: false,
    messageId: "",
    messageExtra: () => ({}),
    senderName: "",
    mediaAction: null,
    mediaState: null,
  },
);

const emit = defineEmits<{
  (event: "locate-message", messageId: string): void;
  (event: "media-action", action: "download" | "openFolder"): void;
}>();

const decoded = computed(() => normalizeToContentElem(props.content));

const viewType = computed(() => {
  const content = decoded.value;
  const type = content?.contentType;
  if (!type) return "";
  return CONTENT_TYPE_VIEW_KEYS[type] ?? type;
});

const extraStrings = computed(() => messageExtraAsStrings(props.messageExtra));

type ViewBaseProps = {
  content: ContentElem;
  isSelf: boolean;
  messageId?: string;
  playAnimated?: boolean;
  messageExtra?: Record<string, unknown>;
  senderName?: string;
};

const viewProps = computed((): ViewBaseProps | null => {
  const content = decoded.value;
  if (!content) return null;
  const base: ViewBaseProps = {
    content,
    isSelf: props.isSelf,
    messageExtra: props.messageExtra,
  };
  if (props.messageId) base.messageId = props.messageId;
  if (viewType.value === "image") {
    const image = pickNestedPayload(content, "image");
    const payload = Object.keys(image).length ? image : content;
    if (imageInfoIsMotion(payload as { animated?: boolean; format?: number; mimeType?: string })) {
      base.playAnimated = isGifPlayAnimatedFromExtra(extraStrings.value);
    }
  }
  if (viewType.value === "sticker") {
    base.playAnimated = isStickerPlayAnimatedFromExtra(extraStrings.value);
  }
  if (viewType.value === "emoji") {
    base.playAnimated = isGifPlayAnimatedFromExtra(extraStrings.value);
  }
  if (viewType.value === "notification" && props.senderName.trim()) {
    base.senderName = props.senderName.trim();
  }
  return base;
});

const fallbackText = computed(() => getContentDecodedPreview(decoded.value) || "[未知消息类型]");
</script>

<template>
  <div
    class="im-content-view"
    :class="{
      'im-content-view--self': isSelf,
      'im-content-view--preview': previewMode,
      [`im-content-view--${viewType}`]: Boolean(viewType),
    }"
  >
    <TextView v-if="viewType === 'text' && viewProps" v-bind="viewProps" />
    <ImageView v-else-if="viewType === 'image' && viewProps" v-bind="viewProps" />
    <VideoView v-else-if="viewType === 'video' && viewProps" v-bind="viewProps" />
    <AudioView v-else-if="viewType === 'audio' && viewProps" v-bind="viewProps" />
    <FileView
      v-else-if="viewType === 'file' && viewProps"
      v-bind="viewProps"
      :media-action="mediaAction"
      :media-state="mediaState"
      @media-action="emit('media-action', $event)"
    />
    <LocationView v-else-if="viewType === 'location' && viewProps" v-bind="viewProps" />
    <CardView v-else-if="viewType === 'card' && viewProps" v-bind="viewProps" />
    <StickerView v-else-if="viewType === 'sticker' && viewProps" v-bind="viewProps" />
    <EmojiView v-else-if="viewType === 'emoji' && viewProps" v-bind="viewProps" />
    <QuoteView
      v-else-if="viewType === 'quote' && viewProps"
      v-bind="viewProps"
      @locate-message="emit('locate-message', $event)"
    />
    <LinkCardView v-else-if="viewType === 'linkCard' && viewProps" v-bind="viewProps" />
    <ForwardView v-else-if="viewType === 'forward' && viewProps" v-bind="viewProps" />
    <RichTextView v-else-if="viewType === 'richText' && viewProps" v-bind="viewProps" />
    <ImageGroupView v-else-if="viewType === 'imageGroup' && viewProps" v-bind="viewProps" />
    <SystemView v-else-if="viewType === 'system' && viewProps" v-bind="viewProps" />
    <NotificationView v-else-if="viewType === 'notification' && viewProps" v-bind="viewProps" />
    <TaskView v-else-if="viewType === 'task' && viewProps" v-bind="viewProps" />
    <ScheduleView v-else-if="viewType === 'schedule' && viewProps" v-bind="viewProps" />
    <VoteView v-else-if="viewType === 'vote' && viewProps" v-bind="viewProps" />
    <AnnouncementView v-else-if="viewType === 'announcement' && viewProps" v-bind="viewProps" />
    <MiniProgramView v-else-if="viewType === 'miniProgram' && viewProps" v-bind="viewProps" />
    <InfoCardView
      v-else-if="['thread', 'custom'].includes(viewType) && viewProps"
      v-bind="viewProps"
      :nested-key="viewType"
    />
    <PlaceholderView v-else-if="decoded && viewProps" v-bind="viewProps" />
    <div v-else-if="decoded" class="im-content-fallback">{{ fallbackText }}</div>
  </div>
</template>

<style scoped>
.im-content-view {
  min-width: 0;
  color: inherit;
}

.im-content-view--preview {
  max-width: 100%;
}

.im-content-fallback {
  font-size: 13px;
  color: var(--im-text-secondary);
}
</style>
