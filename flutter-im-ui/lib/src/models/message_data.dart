import '../components/flare_message_status.dart';
import 'message_content.dart';

/// Neutral, presentational data for one message in a thread — the spec's
/// `Message` type as consumed by `FlareMessageBubble` / `FlareMessageList`.
/// The host maps a core timeline-view item into this.
class FlareMessageData {
  const FlareMessageData({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    this.senderAvatarUrl,
    this.timeLabel = '',
    this.status = FlareMessageDeliveryStatus.sent,
  });

  final String id;
  final String senderId;
  final String senderName;
  final String? senderAvatarUrl;
  final FlareMessageContent content;

  /// Pre-formatted send time (e.g. "14:32").
  final String timeLabel;

  /// Delivery status; only surfaced on the current user's own messages.
  final FlareMessageDeliveryStatus status;

  /// System/notification lines render centred, without a bubble.
  bool get isSystem => content is FlareNotificationContent;
}
