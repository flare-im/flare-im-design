import '../components/flare_message_status.dart';
import 'directory_data.dart' show FlareReactionGroup;
import 'message_content.dart';
import 'message_lifecycle.dart';

/// What a message replies to: the composer's reply strip before sending, the
/// quote at the top of a sent bubble after. [messageId] is the quoted
/// message's id in the core; the row drawn from that message answers to it
/// ([FlareMessageData.serverId]), so a quote locates the original without the
/// host translating anything.
class FlareReplyTarget {
  const FlareReplyTarget({
    required this.senderName,
    required this.summary,
    this.messageId,
  });
  final String senderName;
  final String summary;
  final String? messageId;
}

/// Neutral, presentational data for one message in a thread — the spec's
/// `Message` type as consumed by `FlareMessageBubble` / `FlareMessageList`.
/// The host maps authoritative message data into this presentation model.
class FlareMessageData {
  const FlareMessageData({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    this.serverId,
    this.senderAvatarUrl,
    this.timeLabel = '',
    this.sentAtMs = 0,
    this.status = FlareMessageDeliveryStatus.sent,
    this.lifecycle,
    this.edited = false,
    this.reactions = const [],
    this.replyTo,
  });

  final String id;

  /// This row's id in the core, when the host draws the row under a different
  /// [id]: a message this device sent keeps its client id as the row id across
  /// the send acknowledgement, while a quote of it carries the server id. The
  /// list matches a quote against both, so a host fills this in for every row
  /// and translates nothing; null when the row has no other id.
  final String? serverId;
  final String senderId;
  final String senderName;
  final String? senderAvatarUrl;
  final FlareMessageContent content;

  /// Pre-formatted send time (e.g. "14:32").
  final String timeLabel;
  final int sentAtMs;

  /// Delivery status; only surfaced on the current user's own messages.
  final FlareMessageDeliveryStatus status;
  final FlareMessageLifecycle? lifecycle;
  final bool edited;

  /// Aggregated reactions shown under the bubble; empty shows none.
  final List<FlareReactionGroup> reactions;

  /// The message this one quotes, drawn at the top of the bubble.
  final FlareReplyTarget? replyTo;

  /// System/notification lines render centred, without a bubble.
  bool get isSystem => content is FlareNotificationContent;

  /// A recalled message renders as a notice in place of its content (lifecycle
  /// mutation outranks everything).
  bool get isRecalled =>
      lifecycle?.mutation == FlareMessageMutationState.recalled;
}
