import '../components/flare_message_bubble.dart' show FlareConversationKind;

/// Neutral summary of a conversation for the details/settings panel — the
/// spec's `Conversation` type as consumed by `FlareConversationDetails`.
class FlareConversationSummary {
  const FlareConversationSummary({
    required this.id,
    required this.title,
    this.avatarUrl,
    this.kind = FlareConversationKind.single,
    this.memberCount,
    this.muted = false,
    this.pinned = false,
    this.archived = false,
  });

  final String id;
  final String title;
  final String? avatarUrl;
  final FlareConversationKind kind;
  final int? memberCount;
  final bool muted;
  final bool pinned;
  final bool archived;
}
