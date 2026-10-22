<script setup lang="ts">
import { computed, getCurrentInstance } from "vue";
import type { ContentElem, MessageContentLike } from "../../../utils/contentElem";
import type { MessageMediaDownloadUiState } from "../MessageBubble.vue";
import { normalizeToContentElem, pickNestedPayload } from "../../../utils/contentElem";
import { messageExtraAsStrings } from "../../../utils/contentElem";
import { getContentDecodedPreview } from "../../../utils/messagePreview";
import { imageInfoIsMotion } from "../../../utils/motionImage";
import { isGifPlayAnimatedFromExtra, isStickerPlayAnimatedFromExtra } from "../../../utils/gifPlayback";
import TextView from "./views/TextView.vue";
import FlareUnknownMessage from "../FlareUnknownMessage.vue";
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
import {
  resolveFlareMessageRenderer,
  useFlareMessageRenderers,
  useFlareRenderConversation,
} from "../../../shared/message-renderers";
import { contentViewKey, messageRendererKeys } from "../../../utils/messageRendererKeys";
import type { FlareLocationValue } from "../../../shared/contracts/location";

const props = withDefaults(
  defineProps<{
    content?: MessageContentLike | null;
    isSelf?: boolean;
    previewMode?: boolean;
    messageId?: string;
    /** The id a custom renderer receives as `messageId`: the server id, else the client id. Defaults to `messageId`. */
    rendererMessageId?: string;
    /** The conversation the message is in, for custom renderers; the message list provides it when omitted. */
    conversationId?: string;
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
  (event: "vote", optionIndex: number): void;
  (event: "taskToggle", done: boolean): void;
  /** A tapped person's card, with the card's user id. Without a listener a card only displays. */
  (event: "cardOpen", userId: string): void;
  /** A tapped location card. Without a listener the card links to the web map itself. */
  (event: "locationOpen", location: FlareLocationValue): void;
}>();

// A poll or a task is a control only while the host takes its intent: forward a listener only when this view has one.
const instance = getCurrentInstance();
const voteListeners = computed(() =>
  instance?.vnode.props?.onVote ? { vote: (optionIndex: number) => emit("vote", optionIndex) } : {},
);
const taskListeners = computed(() =>
  instance?.vnode.props?.onTaskToggle ? { taskToggle: (done: boolean) => emit("taskToggle", done) } : {},
);
// A card opens a profile, and a location card the host's map, only while the host takes the intent.
const cardListeners = computed(() =>
  instance?.vnode.props?.onCardOpen ? { cardOpen: (userId: string) => emit("cardOpen", userId) } : {},
);
const locationListeners = computed(() =>
  instance?.vnode.props?.onLocationOpen
    ? { locationOpen: (location: FlareLocationValue) => emit("locationOpen", location) }
    : {},
);

const decoded = computed(() => normalizeToContentElem(props.content));
const customRenderers = useFlareMessageRenderers();

const listConversationId = useFlareRenderConversation();

const viewType = computed(() => contentViewKey(decoded.value));
const customRenderer = computed(
  () => resolveFlareMessageRenderer(customRenderers, messageRendererKeys(decoded.value))?.component,
);
// What a custom renderer is told about the message it draws: the server id when there is one (what the
// SDK and plugins key by), and the conversation — so a host need not smuggle either into the payload.
const customRendererProps = computed(() => {
  const messageId = props.rendererMessageId || props.messageId || undefined;
  const conversationId = props.conversationId || listConversationId() || undefined;
  return { ...viewProps.value, messageId, conversationId };
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

// A content type no renderer claims. The decoded preview (when the sender attached
// one) is the body; otherwise FlareUnknownMessage explains and keeps the raw type
// as a diagnostic — the bare token as a body reads as a rendering bug.
const fallbackSummary = computed(() => getContentDecodedPreview(decoded.value));
const fallbackType = computed(() => String(decoded.value?.contentType ?? ""));
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
    <component
      :is="customRenderer"
      v-if="customRenderer && viewProps"
      v-bind="customRendererProps"
      @locate-message="emit('locate-message', $event)"
      @media-action="emit('media-action', $event)"
    />
    <TextView v-else-if="viewType === 'text' && viewProps" v-bind="viewProps" />
    <ImageView
      v-else-if="viewType === 'image' && viewProps"
      v-bind="viewProps"
      :media-action="mediaAction"
      :media-state="mediaState"
      @media-action="emit('media-action', $event)"
    />
    <VideoView
      v-else-if="viewType === 'video' && viewProps"
      v-bind="viewProps"
      :media-action="mediaAction"
      :media-state="mediaState"
      @media-action="emit('media-action', $event)"
    />
    <AudioView v-else-if="viewType === 'audio' && viewProps" v-bind="viewProps" />
    <FileView
      v-else-if="viewType === 'file' && viewProps"
      v-bind="viewProps"
      :media-action="mediaAction"
      :media-state="mediaState"
      @media-action="emit('media-action', $event)"
    />
    <LocationView v-else-if="viewType === 'location' && viewProps" v-bind="viewProps" v-on="locationListeners" />
    <CardView v-else-if="viewType === 'card' && viewProps" v-bind="viewProps" v-on="cardListeners" />
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
    <TaskView v-else-if="viewType === 'task' && viewProps" v-bind="viewProps" v-on="taskListeners" />
    <ScheduleView v-else-if="viewType === 'schedule' && viewProps" v-bind="viewProps" />
    <VoteView v-else-if="viewType === 'vote' && viewProps" v-bind="viewProps" v-on="voteListeners" />
    <AnnouncementView v-else-if="viewType === 'announcement' && viewProps" v-bind="viewProps" />
    <MiniProgramView v-else-if="viewType === 'miniProgram' && viewProps" v-bind="viewProps" />
    <InfoCardView
      v-else-if="['thread', 'custom'].includes(viewType) && viewProps"
      v-bind="viewProps"
      :nested-key="viewType"
    />
    <PlaceholderView v-else-if="decoded && viewProps" v-bind="viewProps" />
    <FlareUnknownMessage
      v-else-if="decoded"
      class="im-content-fallback"
      :content-type="fallbackType"
      :summary="fallbackSummary"
      :self="isSelf"
    />
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
  color: var(--flare-color-text-secondary);
}
</style>
