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
    this.draftLabel = '[Draft] ',
    this.mentionLabel = '[@me] ',
    this.onSelect,
    this.onAction,
    this.previewSpansBuilder,
  });

  final ConversationRowData item;

  /// Optional host-provided rich preview body. When non-null (and the row has no
  /// draft), the kit renders these spans as the last-message preview instead of
  /// the plain [ConversationRowData.preview] text — letting a host inline emoji /
  /// sticker [WidgetSpan]s while the kit keeps owning the draft / mention prefix,
  /// muted icon, styling and single-line ellipsis. Return spans styled from the
  /// supplied [baseStyle] so they match the row. `null` ⇒ plain-text preview.
  final List<InlineSpan> Function(BuildContext context, TextStyle baseStyle)?
      previewSpansBuilder;

  /// Whether this row is the open conversation (selected background).
  final bool active;

  /// Avatar diameter.
  final double avatarSize;

  /// Prefix shown when the row has an unsent draft.
  final String draftLabel;

  /// Prefix shown when the row has an unread @-mention.
  final String mentionLabel;

  /// Tap.
  final VoidCallback? onSelect;

  /// Long-press / secondary action (host shows its own menu).
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    // Pinned rows read as a group via a whisper of violet tint; active wins.
    final rowColor = active
        ? colors.bgSelected
        : (item.pinned ? colors.primary.withValues(alpha: 0.05) : Colors.transparent);
    return Material(
      color: rowColor,
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
                        if (item.tags.isNotEmpty) ...[
                          const SizedBox(width: FlareSizes.spacingSm),
                          _tagStrip(colors),
                        ],
                        const SizedBox(width: FlareSizes.spacingSm),
                        FlareTimeStamp(label: item.timestampLabel),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(child: _preview(context, colors)),
                        if (item.hasUnread) ...[
                          const SizedBox(width: FlareSizes.spacingSm),
                          // Muted conversations don't shout — a quiet neutral dot
                          // instead of the loud violet badge.
                          if (item.muted)
                            Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                color: colors.textTertiary,
                                shape: BoxShape.circle,
                              ),
                            )
                          else
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

  /// Small inline tags after the title (Group / Bot / Official …): tinted
  /// capsule, 5×1 inset, xs semibold — identical across iOS/Android.
  Widget _tagStrip(FlareColors colors) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < item.tags.length; i++) ...[
          if (i > 0) const SizedBox(width: 4),
          _tagChip(item.tags[i], colors),
        ],
      ],
    );
  }

  Widget _tagChip(ConversationRowTag tag, FlareColors colors) {
    final tint = switch (tag.tone) {
      FlareTagTone.info => colors.info,
      FlareTagTone.warning => colors.warning,
      FlareTagTone.neutral => colors.textTertiary,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(FlareSizes.radiusFull),
      ),
      child: Text(
        tag.text,
        maxLines: 1,
        style: TextStyle(
          color: tint,
          fontSize: FlareSizes.fontSizeXs,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _preview(BuildContext context, FlareColors colors) {
    final base = TextStyle(
      fontSize: FlareSizes.fontSizeLg,
      color: colors.textSecondary,
      height: 1.35,
    );

    final spans = <InlineSpan>[];
    if (item.hasDraft) {
      spans.add(TextSpan(
        text: draftLabel,
        style: base.copyWith(
          color: colors.error,
          fontWeight: FontWeight.w500,
        ),
      ));
      spans.add(TextSpan(text: item.draftPreview));
    } else {
      if (item.mentioned) {
        spans.add(TextSpan(
          text: mentionLabel,
          style: base.copyWith(
            color: colors.error,
            fontWeight: FontWeight.w600,
          ),
        ));
      }
      // Host may inline emoji / sticker WidgetSpans; else plain preview text.
      final richBody = previewSpansBuilder?.call(context, base);
      if (richBody != null) {
        spans.addAll(richBody);
      } else {
        spans.add(TextSpan(text: item.preview));
      }
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
        border: Border.all(color: colors.borderSecondary, width: 1),
      ),
      alignment: Alignment.center,
      child: Icon(Icons.push_pin, size: 9, color: colors.pinned),
    );
  }
}

