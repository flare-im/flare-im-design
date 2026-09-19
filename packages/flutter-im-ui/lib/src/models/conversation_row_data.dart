import '../components/flare_avatar.dart';

/// Tone for a small inline row tag (group / bot / official / mention markers).
enum FlareTagTone { info, warning, neutral }

/// A small inline label rendered next to a conversation title (e.g. "Group",
/// "Bot", "Official", "@"). Product decides the text/tone; the kit renders it.
class ConversationRowTag {
  const ConversationRowTag(this.text, {this.tone = FlareTagTone.neutral});

  final String text;
  final FlareTagTone tone;
}

/// Neutral, presentational data for one inbox row — the spec's `ConversationRow`
/// data type. The host maps authoritative conversation data into this; all
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
    this.tags = const [],
    this.typing = false,
    this.failed = false,
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
  final bool typing;
  final bool failed;

  /// When non-null/non-empty, shown with a "草稿" accent instead of [preview].
  final String? draftPreview;

  /// Optional presence for the avatar dot.
  final FlarePresence? presence;

  /// Small inline tags shown after the title (e.g. "Group", "Official").
  final List<ConversationRowTag> tags;


  /// The facts a host feeds a row after the core built it: the draft this device is holding for the
  /// conversation, whether anyone is typing in it, and the peer's presence. Everything else on a row comes
  /// from the core's own summary and is not the host's to rewrite. Kotlin gets this from `data class`;
  /// Dart and Swift need it written, and without it an app cannot feed [typing] at all — which is why the
  /// `typing` branch of [previewKind] sat on four kits for rounds with nothing ever setting it.
  ///
  /// Each argument left out keeps what the row had. Presence in particular is only ever *set* here: a
  /// presence nobody could look up stays null, and a null presence draws no dot — unknown is not offline.
  ConversationRowData hostFacts({String? draftPreview, bool? typing, FlarePresence? presence}) => ConversationRowData(
    id: id,
    title: title,
    avatarUrl: avatarUrl,
    preview: preview,
    timestampLabel: timestampLabel,
    unreadCount: unreadCount,
    pinned: pinned,
    muted: muted,
    mentioned: mentioned,
    draftPreview: draftPreview ?? this.draftPreview,
    presence: presence ?? this.presence,
    tags: tags,
    typing: typing ?? this.typing,
    failed: failed,
  );

  bool get hasUnread => unreadCount > 0;
  bool get hasDraft => draftPreview?.trim().isNotEmpty ?? false;
  String get previewKind => failed
      ? 'failed'
      : hasDraft
      ? 'draft'
      : typing
      ? 'typing'
      : mentioned
      ? 'mention'
      : 'normal';
  /// Title weight tier: strong only when unread and not quiet (muted without a mention).
  String get titleEmphasis =>
      hasUnread && !(muted && !mentioned) ? 'strong' : 'quiet';
  String get unreadLabel =>
      unreadCount > 999 ? '999+' : '${unreadCount.clamp(0, 999)}';
}
