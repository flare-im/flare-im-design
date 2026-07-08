import 'package:flutter/material.dart';

import '../models/message_content.dart';
import '../models/message_data.dart';
import '../primitives/flare_surface.dart';
import '../tokens/flare_tokens.dart';
import 'flare_avatar.dart';
import 'flare_message_content_view.dart';
import 'flare_message_status.dart';

/// Conversation kind — spec union `'single' | 'group' | 'ai'`.
enum FlareConversationKind { single, group, ai }

/// One message in a thread — content, sender, grouping, delivery status.
/// Spec: Message/MessageBubble (`FlareMessageBubble`). Pure/presentational:
/// status comes from the core view (optimistic), never a network wait.
class FlareMessageBubble extends StatelessWidget {
  const FlareMessageBubble({
    super.key,
    required this.message,
    required this.currentUserId,
    this.conversationKind = FlareConversationKind.single,
    this.groupStart = true,
    this.groupEnd = true,
    this.selected = false,
    this.multiSelectMode = false,
    this.mediaState,
    this.onLongPress,
    this.onAvatarTap,
    this.onMediaAction,
    this.onResend,
    this.onToggleSelect,
  });

  final FlareMessageData message;
  final String currentUserId;
  final FlareConversationKind conversationKind;
  final bool groupStart;
  final bool groupEnd;
  final bool selected;
  final bool multiSelectMode;
  final FlareMediaDownloadState? mediaState;

  final void Function(FlareMessageData message)? onLongPress;
  final void Function(FlareMessageData message)? onAvatarTap;
  final void Function(FlareMessageData message, FlareMessageContent content)?
      onMediaAction;
  final void Function(FlareMessageData message)? onResend;
  final void Function(FlareMessageData message)? onToggleSelect;

  bool get _self => message.senderId == currentUserId;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);

    if (message.isSystem) {
      final text = (message.content as FlareNotificationContent).text;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: FlareSizes.spacingSm),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: FlareSizes.spacingMd, vertical: FlareSizes.spacingXs),
            decoration: BoxDecoration(
              color: colors.bgTertiary,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(text,
                style: TextStyle(
                    color: colors.textTertiary, fontSize: FlareSizes.fontSizeSm)),
          ),
        ),
      );
    }

    final self = _self;
    final showAvatar =
        !self && conversationKind != FlareConversationKind.single && groupStart;
    final showName = showAvatar;

    final row = Row(
      mainAxisAlignment:
          self ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!self) _leadingAvatar(showAvatar),
        Flexible(child: _bubbleColumn(context, colors, self, showName)),
        if (self) _trailingStatus(colors),
      ],
    );

    final content = multiSelectMode
        ? Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: FlareSizes.spacingSm),
                child: Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked,
                  color: selected ? colors.primary : colors.textTertiary,
                  size: 22,
                ),
              ),
              Expanded(child: row),
            ],
          )
        : row;

    return InkWell(
      onTap: multiSelectMode ? () => onToggleSelect?.call(message) : null,
      onLongPress: multiSelectMode ? null : () => onLongPress?.call(message),
      child: Container(
        color: selected ? colors.bgSelected : Colors.transparent,
        padding: EdgeInsets.only(
          left: FlareSizes.spacingMd,
          right: FlareSizes.spacingMd,
          top: groupStart ? FlareSizes.spacingSm : 2,
          bottom: groupEnd ? FlareSizes.spacingSm : 2,
        ),
        child: content,
      ),
    );
  }

  Widget _leadingAvatar(bool show) {
    if (!show) return const SizedBox(width: 34 + FlareSizes.spacingSm);
    return Padding(
      padding: const EdgeInsets.only(right: FlareSizes.spacingSm),
      child: GestureDetector(
        onTap: () => onAvatarTap?.call(message),
        child: FlareAvatar(
          userId: message.senderId,
          displayName: message.senderName,
          avatarUrl: message.senderAvatarUrl,
          size: 34,
        ),
      ),
    );
  }

  Widget _bubbleColumn(
      BuildContext context, FlareColors colors, bool self, bool showName) {
    return Column(
      crossAxisAlignment:
          self ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showName)
          Padding(
            padding: const EdgeInsets.only(bottom: 2, left: 2),
            child: Text(message.senderName,
                style: TextStyle(
                    color: colors.textTertiary, fontSize: FlareSizes.fontSizeSm)),
          ),
        _bubble(context, colors, self),
      ],
    );
  }

  Widget _bubble(BuildContext context, FlareColors colors, bool self) {
    final maxWidth = MediaQuery.of(context).size.width * 0.72;
    final bare = _isBareMedia(message.content);

    final body = FlareMessageContentView(
      content: message.content,
      self: self,
      senderName: message.senderName,
      mediaState: mediaState,
      onMediaAction:
          onMediaAction == null ? null : (c) => onMediaAction!(message, c),
    );

    // Bare media (image / sticker / emoji / video) carries its own frame.
    if (bare) {
      return ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth), child: body);
    }

    // Flare thread bubble grammar (from the reference app): radius 16 with a
    // 4px tail toward the sender, snug 14/9 padding, inline time meta.
    const radius = Radius.circular(16);
    const tail = Radius.circular(4);
    final shape = BorderRadius.only(
      topLeft: radius,
      topRight: radius,
      bottomLeft: self ? radius : tail,
      bottomRight: self ? tail : radius,
    );
    const padding = EdgeInsets.symmetric(horizontal: 14, vertical: 9);

    final content = Column(
      crossAxisAlignment:
          self ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        body,
        if (message.timeLabel.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              message.timeLabel,
              style: TextStyle(
                fontSize: FlareSizes.fontSizeXs,
                height: 1,
                color: self
                    ? Colors.white.withValues(alpha: 0.8)
                    : colors.textTertiary,
              ),
            ),
          ),
      ],
    );

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      // Received = white surface + hairline border + whisper of lift; self =
      // brand purple. Both stay theme-driven for dark mode.
      child: self
          ? Container(
              padding: padding,
              decoration:
                  BoxDecoration(color: colors.bubbleSelf, borderRadius: shape),
              child: content,
            )
          : FlareSurface(
              padding: padding,
              borderRadius: shape,
              elevated: true,
              child: content,
            ),
    );
  }

  Widget _trailingStatus(FlareColors colors) {
    if (message.status == FlareMessageDeliveryStatus.failed) {
      return Padding(
        padding: const EdgeInsets.only(left: FlareSizes.spacingXs, top: 4),
        child: GestureDetector(
          onTap: () => onResend?.call(message),
          child: const FlareMessageStatus(
            status: FlareMessageDeliveryStatus.failed,
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(left: FlareSizes.spacingXs, top: 4),
      child: FlareMessageStatus(status: message.status),
    );
  }

  static bool _isBareMedia(FlareMessageContent content) {
    return content is FlareImageContent ||
        content is FlareVideoContent ||
        content is FlareStickerContent ||
        content is FlareEmojiContent;
  }
}
