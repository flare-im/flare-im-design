import DefaultTheme from "vitepress/theme";
import "./custom.css";
import "../../../tokens/dist/tokens.css";
// Real kit component styles (--im-* tokens + component CSS). Demos now render the actual
// flare-core-vue-im-ui components, so the docs can no longer drift from the shipped kit.
import "flare-core-vue-im-ui/style.css";

import AvatarDemo from "./demos/AvatarDemo.vue";
import TimeStampDemo from "./demos/TimeStampDemo.vue";
import MessageStatusDemo from "./demos/MessageStatusDemo.vue";
import ConversationRowDemo from "./demos/ConversationRowDemo.vue";
import ConversationListDemo from "./demos/ConversationListDemo.vue";
import MessageBubbleDemo from "./demos/MessageBubbleDemo.vue";
import ChatHeaderDemo from "./demos/ChatHeaderDemo.vue";
import PinnedBarDemo from "./demos/PinnedBarDemo.vue";
import ComposerDemo from "./demos/ComposerDemo.vue";
import ComposerCustomMenuDemo from "./demos/ComposerCustomMenuDemo.vue";
import ComposerChatFrame from "./demos/ComposerChatFrame.vue";
import ComposerResponsivePreview from "./demos/ComposerResponsivePreview.vue";
import ResponsivePreview from "./demos/ResponsivePreview.vue";
import AppShellFrame from "./demos/AppShellFrame.vue";
import ResponsiveLayoutFrame from "./demos/ResponsiveLayoutFrame.vue";
import StartConversationFrame from "./demos/StartConversationFrame.vue";
import MarkdownPreviewDemo from "./demos/MarkdownPreviewDemo.vue";
import ThemePlayground from "./demos/ThemePlayground.vue";
import SearchBarDemo from "./demos/SearchBarDemo.vue";
import InputDemo from "./demos/InputDemo.vue";
import EmptyStateDemo from "./demos/EmptyStateDemo.vue";
import ContactListDemo from "./demos/ContactListDemo.vue";
import ProfilePanelDemo from "./demos/ProfilePanelDemo.vue";
import CallViewDemo from "./demos/CallViewDemo.vue";
import GroupCallViewDemo from "./demos/GroupCallViewDemo.vue";
import TypingIndicatorDemo from "./demos/TypingIndicatorDemo.vue";
import UnreadDividerDemo from "./demos/UnreadDividerDemo.vue";
import ScrollToLatestDemo from "./demos/ScrollToLatestDemo.vue";
import ProfileCardDemo from "./demos/ProfileCardDemo.vue";
import GroupMemberGridDemo from "./demos/GroupMemberGridDemo.vue";
import ReactionSummaryDemo from "./demos/ReactionSummaryDemo.vue";
import ReadReceiptSheetDemo from "./demos/ReadReceiptSheetDemo.vue";
import MentionPickerDemo from "./demos/MentionPickerDemo.vue";
import MessageBatchToolbarDemo from "./demos/MessageBatchToolbarDemo.vue";
import SearchResultsDemo from "./demos/SearchResultsDemo.vue";
import SkeletonDemo from "./demos/SkeletonDemo.vue";
import QuickPhrasesDemo from "./demos/QuickPhrasesDemo.vue";
import ForwardPickerDemo from "./demos/ForwardPickerDemo.vue";
import ToastDemo from "./demos/ToastDemo.vue";
import CallDockDemo from "./demos/CallDockDemo.vue";
import AnnouncementBannerDemo from "./demos/AnnouncementBannerDemo.vue";
import DatePillDemo from "./demos/DatePillDemo.vue";
import RedPacketCardDemo from "./demos/RedPacketCardDemo.vue";
import SlashCommandMenuDemo from "./demos/SlashCommandMenuDemo.vue";
import TranslationViewDemo from "./demos/TranslationViewDemo.vue";
import QRCardDemo from "./demos/QRCardDemo.vue";
import ImageGridDemo from "./demos/ImageGridDemo.vue";
import VoiceRecordingBarDemo from "./demos/VoiceRecordingBarDemo.vue";
import PollComposerDemo from "./demos/PollComposerDemo.vue";
import ChatWallpaperPickerDemo from "./demos/ChatWallpaperPickerDemo.vue";
import VoicePlayerDemo from "./demos/VoicePlayerDemo.vue";
import EmojiPickerDemo from "./demos/EmojiPickerDemo.vue";
import StickerPanelDemo from "./demos/StickerPanelDemo.vue";
import ComponentGallery from "./demos/ComponentGallery.vue";
import ComponentApi from "./demos/ComponentApi.vue";
import IncomingCallDemo from "./demos/IncomingCallDemo.vue";
import CallControlsDemo from "./demos/CallControlsDemo.vue";

// Phase E — the remaining 16 components, so every page has a live preview
import MessageListDemo from "./demos/MessageListDemo.vue";
import MessageContentViewDemo from "./demos/MessageContentViewDemo.vue";
import ConversationDetailsDemo from "./demos/ConversationDetailsDemo.vue";
import StartConversationDialogDemo from "./demos/StartConversationDialogDemo.vue";
import RichMarkdownInputDemo from "./demos/RichMarkdownInputDemo.vue";
import MessageActionSheetDemo from "./demos/MessageActionSheetDemo.vue";
import ImagePreviewModalDemo from "./demos/ImagePreviewModalDemo.vue";
import VideoPlayerModalDemo from "./demos/VideoPlayerModalDemo.vue";
import ContactItemDemo from "./demos/ContactItemDemo.vue";
import ContactDetailDemo from "./demos/ContactDetailDemo.vue";
import NewFriendRequestsDemo from "./demos/NewFriendRequestsDemo.vue";
import GroupListDemo from "./demos/GroupListDemo.vue";
import ProfileEditorDemo from "./demos/ProfileEditorDemo.vue";
import SettingsListDemo from "./demos/SettingsListDemo.vue";
import AppShellDemo from "./demos/AppShellDemo.vue";
import ResponsiveLayoutDemo from "./demos/ResponsiveLayoutDemo.vue";
import ComposerPartsDemo from "./demos/ComposerPartsDemo.vue";
import VoiceHoldButtonDemo from "./demos/VoiceHoldButtonDemo.vue";
import ComposerActionPanelDemo from "./demos/ComposerActionPanelDemo.vue";
import ComposerSendButtonDemo from "./demos/ComposerSendButtonDemo.vue";
import ComposerReplyStripDemo from "./demos/ComposerReplyStripDemo.vue";
import HomeShowcase from "./demos/HomeShowcase.vue";

// per-type message body demos (the decomposed MessageContentView views)
import TextMessageDemo from "./demos/messages/demos/TextMessageDemo.vue";
import ImageMessageDemo from "./demos/messages/demos/ImageMessageDemo.vue";
import VideoMessageDemo from "./demos/messages/demos/VideoMessageDemo.vue";
import VoiceMessageDemo from "./demos/messages/demos/VoiceMessageDemo.vue";
import FileMessageDemo from "./demos/messages/demos/FileMessageDemo.vue";
import LocationMessageDemo from "./demos/messages/demos/LocationMessageDemo.vue";
import ContactMessageDemo from "./demos/messages/demos/ContactMessageDemo.vue";
import LinkCardMessageDemo from "./demos/messages/demos/LinkCardMessageDemo.vue";
import VoteMessageDemo from "./demos/messages/demos/VoteMessageDemo.vue";
import TaskMessageDemo from "./demos/messages/demos/TaskMessageDemo.vue";
import StickerMessageDemo from "./demos/messages/demos/StickerMessageDemo.vue";
import EmojiMessageDemo from "./demos/messages/demos/EmojiMessageDemo.vue";
import SystemMessageDemo from "./demos/messages/demos/SystemMessageDemo.vue";
import EmojiStickerPanelDemo from "./demos/EmojiStickerPanelDemo.vue";
import StatusBannerDemo from "./demos/StatusBannerDemo.vue";
import FilterTabsDemo from "./demos/FilterTabsDemo.vue";

const demos = {
  EmojiStickerPanelDemo,
  StatusBannerDemo,
  FilterTabsDemo,
  HomeShowcase,
  VoiceHoldButtonDemo,
  ComposerActionPanelDemo,
  ComposerSendButtonDemo,
  ComposerReplyStripDemo,
  TextMessageDemo,
  ImageMessageDemo,
  VideoMessageDemo,
  VoiceMessageDemo,
  FileMessageDemo,
  LocationMessageDemo,
  ContactMessageDemo,
  LinkCardMessageDemo,
  VoteMessageDemo,
  TaskMessageDemo,
  StickerMessageDemo,
  EmojiMessageDemo,
  SystemMessageDemo,
  AvatarDemo,
  TimeStampDemo,
  MessageStatusDemo,
  ConversationRowDemo,
  ConversationListDemo,
  MessageBubbleDemo,
  ChatHeaderDemo,
  PinnedBarDemo,
  ComposerDemo,
  ComposerCustomMenuDemo,
  ComposerChatFrame,
  ComposerResponsivePreview,
  ResponsivePreview,
  AppShellFrame,
  ResponsiveLayoutFrame,
  StartConversationFrame,
  MarkdownPreviewDemo,
  ThemePlayground,
  SearchBarDemo,
  InputDemo,
  EmptyStateDemo,
  ContactListDemo,
  ProfilePanelDemo,
  CallViewDemo,
  GroupCallViewDemo,
  TypingIndicatorDemo,
  UnreadDividerDemo,
  ScrollToLatestDemo,
  ProfileCardDemo,
  GroupMemberGridDemo,
  ReactionSummaryDemo,
  ReadReceiptSheetDemo,
  MentionPickerDemo,
  MessageBatchToolbarDemo,
  SearchResultsDemo,
  SkeletonDemo,
  QuickPhrasesDemo,
  ForwardPickerDemo,
  ToastDemo,
  CallDockDemo,
  AnnouncementBannerDemo,
  DatePillDemo,
  RedPacketCardDemo,
  SlashCommandMenuDemo,
  TranslationViewDemo,
  QRCardDemo,
  ImageGridDemo,
  VoiceRecordingBarDemo,
  PollComposerDemo,
  ChatWallpaperPickerDemo,
  VoicePlayerDemo,
  EmojiPickerDemo,
  StickerPanelDemo,
  ComponentGallery,
  ComponentApi,
  IncomingCallDemo,
  CallControlsDemo,
  MessageListDemo,
  MessageContentViewDemo,
  ConversationDetailsDemo,
  StartConversationDialogDemo,
  RichMarkdownInputDemo,
  MessageActionSheetDemo,
  ImagePreviewModalDemo,
  VideoPlayerModalDemo,
  ContactItemDemo,
  ContactDetailDemo,
  NewFriendRequestsDemo,
  GroupListDemo,
  ProfileEditorDemo,
  SettingsListDemo,
  AppShellDemo,
  ResponsiveLayoutDemo,
  ComposerPartsDemo,
};

export default {
  extends: DefaultTheme,
  enhanceApp({ app }) {
    for (const [name, component] of Object.entries(demos)) {
      app.component(name, component);
    }
  },
  setup() {
    if (typeof document === "undefined") return;
    // keep the Flare token theme in sync with VitePress light/dark
    const sync = () =>
      (document.documentElement.dataset.flareTheme =
        document.documentElement.classList.contains("dark") ? "dark" : "light");
    sync();
    new MutationObserver(sync).observe(document.documentElement, {
      attributes: true,
      attributeFilter: ["class"],
    });
  },
};
