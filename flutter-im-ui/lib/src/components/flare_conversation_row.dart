import 'package:flutter/material.dart';

import '../models/conversation_row_data.dart';
import '../primitives/flare_unread_badge.dart';
import '../tokens/flare_tokens.dart';
import 'flare_avatar.dart';
import 'flare_time_stamp.dart';

/// A single inbox row — avatar, title, preview/draft, unread badge, time, and
/// mute/pin markers. Spec: Conversation/ConversationRow (`FlareConversationRow`).
///
/// Pure/presentational: it renders [item] and raises [onSelect] / [onAction];
/// pinning, deletion, navigation etc. are the host's to wire.
class FlareConversationRow extends StatelessWidget {
  const FlareConversationRow({
    super.key,
    required this.item,
    this.active = false,
    this.avatarSize = 48,
    this.onSelect,
    this.onAction,
  });

  final ConversationRowData item;

  /// Whether this row is the open conversation (selected background).
  final bool active;

  /// Avatar diameter.
  final double avatarSize;

  /// Tap.
  final VoidCallback? onSelect;

  /// Long-press / secondary action (host shows its own menu).
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    return Material(
      color: active ? colors.bgSelected : Colors.transparent,
      child: InkWell(
        onTap: onSelect,
        onLongPress: onAction,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: FlareSizes.spacingMd,
            horizontal: FlareSizes.spacingSm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  FlareAvatar(
                    userId: item.id,
                    displayName: item.title,
                    avatarUrl: item.avatarUrl,
                    size: avatarSize,
                    presence: item.presence,
                  ),
                  if (item.pinned)
                    Positioned(
                      right: -1,
                      bottom: -1,
                      child: _PinDot(colors: colors),
                    ),
                ],
              ),
              const SizedBox(width: FlareSizes.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: FlareSizes.fontSize3xl,
                              fontWeight: item.hasUnread
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: colors.textPrimary,
                              height: 1.25,
                            ),
                          ),
                        ),
                        const SizedBox(width: FlareSizes.spacingSm),
                        FlareTimeStamp(label: item.timestampLabel),
                      ],
                    ),
                    const SizedBox(height: FlareSizes.spacingXs + 2),
                    Row(
                      children: [
                        Expanded(child: _preview(colors)),
                        if (item.hasUnread) ...[
                          const SizedBox(width: FlareSizes.spacingSm),
                          FlareUnreadBadge(count: item.unreadCount),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _preview(FlareColors colors) {
    final base = TextStyle(
      fontSize: FlareSizes.fontSizeLg,
      color: colors.textSecondary,
      height: 1.35,
    );

    final spans = <InlineSpan>[];
    if (item.hasDraft) {
      spans.add(TextSpan(
        text: '[Draft] ',
        style: base.copyWith(
          color: colors.error,
          fontWeight: FontWeight.w500,
        ),
      ));
      spans.add(TextSpan(text: item.draftPreview));
    } else {
      if (item.mentioned) {
        spans.add(TextSpan(
          text: '[@me] ',
          style: base.copyWith(
            color: colors.error,
            fontWeight: FontWeight.w600,
          ),
        ));
      }
      spans.add(TextSpan(text: item.preview));
    }

    final text = Text.rich(
      TextSpan(style: base, children: spans),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    if (!item.muted) return text;
    return Row(
      children: [
        Icon(Icons.notifications_off_outlined,
            size: 14, color: colors.textTertiary),
        const SizedBox(width: FlareSizes.spacingXs),
        Expanded(child: text),
      ],
    );
  }
}

class _PinDot extends StatelessWidget {
  const _PinDot({required this.colors});
  final FlareColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 15,
      height: 15,
      decoration: BoxDecoration(
        color: colors.bgPrimary,
        shape: BoxShape.circle,
        border: Border.all(color: colors.borderSecondary, width: 1.5),
      ),
      alignment: Alignment.center,
      child: Icon(Icons.push_pin, size: 9, color: colors.pinned),
    );
  }
}

