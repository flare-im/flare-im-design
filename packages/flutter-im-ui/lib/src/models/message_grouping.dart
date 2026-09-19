import 'message_data.dart';

enum FlareMessageGroupPosition { single, first, middle, last }

enum FlareAvatarPlacement { leading, trailing }

class FlareMessageRowPresentation {
  const FlareMessageRowPresentation({
    this.showAvatar = false,
    this.reserveAvatarSpace = false,
    this.showSenderName = false,
    this.avatarPlacement = FlareAvatarPlacement.leading,
  });

  final bool showAvatar;
  final bool reserveAvatarSpace;
  final bool showSenderName;
  final FlareAvatarPlacement avatarPlacement;
}

bool flareMessagesShareGroup(
  FlareMessageData? previous,
  FlareMessageData? current, {
  int timeGapMs = 300000,
}) {
  // Notices (system lines, recalled messages) stand alone and end a sender's run.
  if (previous == null ||
      current == null ||
      previous.isSystem ||
      current.isSystem ||
      previous.isRecalled ||
      current.isRecalled)
    return false;
  if (previous.senderId != current.senderId) return false;
  if (previous.sentAtMs <= 0 || current.sentAtMs <= 0) return true;
  return (current.sentAtMs - previous.sentAtMs).abs() <= timeGapMs;
}

FlareMessageGroupPosition flareMessageGroupPosition(
  List<FlareMessageData> messages,
  int index, {
  int timeGapMs = 300000,
}) {
  final current = messages[index];
  if (current.isSystem || current.isRecalled) {
    return FlareMessageGroupPosition.single;
  }
  final previous = index > 0 ? messages[index - 1] : null;
  final next = index + 1 < messages.length ? messages[index + 1] : null;
  final joinsPrevious = flareMessagesShareGroup(
    previous,
    current,
    timeGapMs: timeGapMs,
  );
  final joinsNext = flareMessagesShareGroup(
    current,
    next,
    timeGapMs: timeGapMs,
  );
  if (!joinsPrevious && !joinsNext) return FlareMessageGroupPosition.single;
  if (!joinsPrevious) return FlareMessageGroupPosition.first;
  if (!joinsNext) return FlareMessageGroupPosition.last;
  return FlareMessageGroupPosition.middle;
}

FlareMessageRowPresentation flareMessageRowPresentation({
  required FlareMessageData message,
  required FlareMessageGroupPosition position,
  required String currentUserId,
  required bool groupConversation,
  bool showIncomingAvatar = true,
  bool showSelfAvatar = false,
  bool showGroupSenderName = true,
}) {
  final self = message.senderId == currentUserId;
  final edge =
      position == FlareMessageGroupPosition.single ||
      position == FlareMessageGroupPosition.first;
  return FlareMessageRowPresentation(
    showAvatar: (self ? showSelfAvatar : showIncomingAvatar) && edge,
    reserveAvatarSpace: self ? showSelfAvatar : showIncomingAvatar,
    showSenderName: !self && groupConversation && showGroupSenderName && edge,
    avatarPlacement: self
        ? FlareAvatarPlacement.trailing
        : FlareAvatarPlacement.leading,
  );
}
