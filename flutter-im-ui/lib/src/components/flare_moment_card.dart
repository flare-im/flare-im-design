import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../tokens/flare_tokens.dart';
import 'flare_avatar.dart';
import 'flare_comment_thread.dart';
import 'flare_image_grid.dart';
import 'flare_moment_action_popover.dart';

/// A single moment (social-feed post): author, text, image grid, location, a
/// meta row with a ··· menu that raises a [FlareMomentActionPopover], and a
/// social panel of likes + comments. Spec: Moments/Card (`FlareMomentCard`).
class FlareMomentCard extends StatefulWidget {
  const FlareMomentCard({
    super.key,
    required this.moment,
    this.canDelete = false,
    this.onLike,
    this.onComment,
    this.onDelete,
    this.onOpenImage,
    this.onSelectAuthor,
    this.onSelectLiker,
    this.onSelectComment,
  });

  final FlareMoment moment;

  /// When true the ··· popover shows a destructive Delete action → [onDelete].
  final bool canDelete;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onDelete;
  final void Function(int index)? onOpenImage;
  final void Function(String id)? onSelectAuthor;
  final void Function(String id)? onSelectLiker;
  final void Function(FlareMomentComment comment)? onSelectComment;

  @override
  State<FlareMomentCard> createState() => _FlareMomentCardState();
}

class _FlareMomentCardState extends State<FlareMomentCard> {
  bool _menuOpen = false;

  void _onLike() {
    setState(() => _menuOpen = false);
    widget.onLike?.call();
  }

  void _onComment() {
    setState(() => _menuOpen = false);
    widget.onComment?.call();
  }

  void _onDelete() {
    setState(() => _menuOpen = false);
    widget.onDelete?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    final moment = widget.moment;
    final likes = moment.likes;
    final comments = moment.comments;
    final hasSocial = likes.isNotEmpty || comments.isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        // Aurora — the card floats on a violet-tinted, top-lit shadow in dark.
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0x80000000) : const Color(0x14151320),
            blurRadius: isDark ? 24 : 22,
            offset: const Offset(0, 8),
          ),
          if (isDark)
            const BoxShadow(
              color: Color(0x247C3AED),
              blurRadius: 12,
              offset: Offset(0, 2),
            ),
        ],
      ),
      padding: const EdgeInsets.all(FlareSizes.spacingLg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => widget.onSelectAuthor?.call(moment.author.id),
            behavior: HitTestBehavior.opaque,
            child: FlareAvatar(
              userId: moment.author.id,
              displayName: moment.author.name,
              avatarUrl: moment.author.avatarUrl,
              size: 42,
            ),
          ),
          const SizedBox(width: FlareSizes.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () => widget.onSelectAuthor?.call(moment.author.id),
                  behavior: HitTestBehavior.opaque,
                  child: Text(
                    moment.author.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colors.primary,
                    ),
                  ),
                ),
                if (moment.text != null && moment.text!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: FlareSizes.spacingXs),
                    child: Text(
                      moment.text!,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.55,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                if (moment.images.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: FlareImageGrid(
                      images: moment.images,
                      onOpen: (i) => widget.onOpenImage?.call(i),
                    ),
                  ),
                if (moment.location != null && moment.location!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: FlareSizes.spacingSm),
                    child: Opacity(
                      opacity: 0.8,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_on_outlined,
                              size: 13, color: colors.primary),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              moment.location!,
                              style: TextStyle(
                                  fontSize: 12, color: colors.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: _metaRow(colors, moment),
                ),
                if (hasSocial)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: _social(colors, likes, comments),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaRow(FlareColors colors, FlareMoment moment) {
    return Row(
      children: [
        Text(
          moment.time ?? '',
          style: TextStyle(fontSize: 12, color: colors.textTertiary),
        ),
        const Spacer(),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_menuOpen) ...[
              FlareMomentActionPopover(
                liked: moment.likedBySelf,
                canDelete: widget.canDelete,
                onLike: _onLike,
                onComment: _onComment,
                onDelete: _onDelete,
              ),
              const SizedBox(width: 6),
            ],
            GestureDetector(
              onTap: () => setState(() => _menuOpen = !_menuOpen),
              behavior: HitTestBehavior.opaque,
              child: Container(
                width: 30,
                height: 24,
                decoration: BoxDecoration(
                  color: _menuOpen ? colors.bgSelected : colors.bgSecondary,
                  borderRadius: BorderRadius.circular(FlareSizes.radiusSm),
                ),
                alignment: Alignment.center,
                child: Icon(
                  Icons.more_horiz,
                  size: 16,
                  color: _menuOpen ? colors.primary : colors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _social(
    FlareColors colors,
    List<FlareMomentLike> likes,
    List<FlareMomentComment> comments,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.bgSecondary,
        borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (likes.isNotEmpty) _likes(colors, likes),
          if (likes.isNotEmpty && comments.isNotEmpty)
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(vertical: 7),
              color: colors.textTertiary.withValues(alpha: 0.22),
            ),
          if (comments.isNotEmpty)
            FlareCommentThread(
              comments: comments,
              onSelect: (c) => widget.onSelectComment?.call(c),
              onSelectAuthor: (id) => widget.onSelectAuthor?.call(id),
            ),
        ],
      ),
    );
  }

  Widget _likes(FlareColors colors, List<FlareMomentLike> likes) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(Icons.favorite_border, size: 14, color: colors.error),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text.rich(
            TextSpan(
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: colors.primary,
              ),
              children: [
                for (var i = 0; i < likes.length; i++) ...[
                  TextSpan(
                    text: likes[i].name,
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => widget.onSelectLiker?.call(likes[i].id),
                  ),
                  if (i < likes.length - 1) const TextSpan(text: ', '),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
