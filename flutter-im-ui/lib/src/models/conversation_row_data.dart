import '../components/flare_avatar.dart';

/// Neutral, presentational data for one inbox row — the spec's `ConversationRow`
/// data type. The host maps a core conversation-list-view item into this; all
/// product-specific formatting (emoji/sticker inlining, i18n, group sender
/// prefix) is resolved upstream into the plain [preview] string.
class ConversationRowData {
  const ConversationRowData({
    required this.id,
    required this.title,
    this.avatarUrl,
    this.preview = '',
    this.timestampLabel = '',
    this.unreadCount = 0,
    this.pinned = false,
    this.muted = false,
    this.mentioned = false,
    this.draftPreview,
    this.presence,
  });

  /// Stable conversation id — also seeds the avatar fallback colour.
  final String id;

  /// Display title.
  final String title;

  /// Optional avatar image URL.
  final String? avatarUrl;

  /// Pre-formatted last-message preview (plain text).
  final String preview;

  /// Pre-formatted timestamp label (e.g. "14:32", "昨天").
  final String timestampLabel;

  /// Unread message count; `0` hides the badge.
  final int unreadCount;

  final bool pinned;
  final bool muted;

  /// Whether the current user is @-mentioned in the latest unread.
  final bool mentioned;

  /// When non-null/non-empty, shown with a "草稿" accent instead of [preview].
  final String? draftPreview;

  /// Optional presence for the avatar dot.
  final FlarePresence? presence;

  bool get hasUnread => unreadCount > 0;
  bool get hasDraft => draftPreview != null && draftPreview!.isNotEmpty;
}
