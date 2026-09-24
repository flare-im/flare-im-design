import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'content_control.dart';
import 'flare_avatar.dart';
import 'flare_comment_thread.dart';
import 'flare_icon.dart';
import 'flare_image_grid.dart';
import 'flare_moment_action_popover.dart';
import 'icon_control.dart';

/// A single moment (social-feed post): author, text, image grid, location, a
/// meta row with a ··· menu that raises a [FlareMomentActionPopover], and a
/// social panel of likes + comments. Spec: Moments/Card (`FlareMomentCard`).
///
/// People and comments are controls only when the host does something with
/// them: the author's name (with the avatar as a pointer shortcut that stays
/// out of the accessibility tree) needs [onSelectAuthor], each liker
/// [onSelectLiker], and each comment row [onSelectComment]; otherwise they are
/// plain text. Names use the accessible primary text colour.
class FlareMomentCard extends StatefulWidget {
  const FlareMomentCard({
    super.key,
    required this.moment,
    this.canDelete = false,
    this.canReport = false,
    this.onLike,
    this.onComment,
    this.onDelete,
    this.onReport,
    this.onOpenImage,
    this.onSelectAuthor,
    this.onSelectLiker,
    this.onSelectComment,
  });

  final FlareMoment moment;

  /// When true the ··· popover shows a destructive Delete action → [onDelete].
  final bool canDelete;

  /// When true the ··· popover shows a Report action → [onReport]; mutually
  /// exclusive with [canDelete] (you do not report your own moment).
  final bool canReport;
  final VoidCallback? onLike;
  final VoidCallback? onComment;
  final VoidCallback? onDelete;
  final VoidCallback? onReport;
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

  void _onReport() {
    setState(() => _menuOpen = false);
    widget.onReport?.call();
  }

  void _onDelete() {
    setState(() => _menuOpen = false);
    widget.onDelete?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final moment = widget.moment;
    final likes = moment.likes;
    final comments = moment.comments;
    final hasSocial = likes.isNotEmpty || comments.isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selectAuthor = widget.onSelectAuthor;
    final avatar = FlareAvatar(
      userId: moment.author.id,
      displayName: moment.author.name,
      avatarUrl: moment.author.avatarUrl,
      size: 42,
    );
    final name = Text(
      moment.author.name,
      style: TextStyle(
        fontSize: FlareSizes.fontSizeXl,
        fontWeight: FontWeight.w600,
        color: colors.primaryText,
      ),
    );

    return Container(
      decoration: BoxDecoration(
        // The card uses a restrained theme-tinted lift in dark mode.
        color: colors.bgElevated,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: isDark ? const Color(0x80000000) : const Color(0x14151320),
            blurRadius: isDark ? 24 : 22,
            offset: const Offset(0, 8),
          ),
          if (isDark)
            BoxShadow(
              color: colors.primary.withValues(alpha: 0.14),
              blurRadius: 12,
              offset: Offset(0, 2),
            ),
        ],
      ),
      padding: const EdgeInsets.all(FlareSizes.spacingLg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The avatar repeats the name, so it is never announced; with a
          // handled author it is a pointer shortcut to the name's action.
          ExcludeSemantics(
            child: selectAuthor == null
                ? avatar
                : MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => selectAuthor(moment.author.id),
                      behavior: HitTestBehavior.opaque,
                      excludeFromSemantics: true,
                      child: avatar,
                    ),
                  ),
          ),
          const SizedBox(width: FlareSizes.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selectAuthor == null)
                  name
                else
                  FlareContentControl(
                    onTap: () => selectAuthor(moment.author.id),
                    child: name,
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
                    padding: const EdgeInsets.only(top: FlareSizes.spacing2sm),
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
                          Icon(
                            Icons.location_on_outlined,
                            size: 13,
                            color: colors.primaryText,
                          ),
                          const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              moment.location!,
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.primaryText,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: FlareSizes.spacing2sm),
                  child: _metaRow(colors, moment),
                ),
                if (hasSocial)
                  Padding(
                    padding: const EdgeInsets.only(top: FlareSizes.spacing2sm),
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
              canReport: widget.canReport,
                onLike: _onLike,
                onComment: _onComment,
                onDelete: _onDelete,
              onReport: _onReport,
              ),
            ],
            FlareIconControl(
              label: FlareStrings.of(context).momentActions,
              expanded: _menuOpen,
              onTap: () => setState(() => _menuOpen = !_menuOpen),
              alignment: AlignmentDirectional.centerEnd,
              child: Container(
                width: 30,
                height: 24,
                decoration: BoxDecoration(
                  color: _menuOpen ? colors.bgSelected : colors.bgSecondary,
                  borderRadius: BorderRadius.circular(FlareSizes.radiusSm),
                ),
                alignment: Alignment.center,
                child: FlareIcon(
                  'more',
                  size: FlareSizes.iconSizeSm,
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
              onSelect: widget.onSelectComment,
              onSelectAuthor: widget.onSelectAuthor,
            ),
        ],
      ),
    );
  }

  Widget _likes(FlareColors colors, List<FlareMomentLike> likes) {
    final style = TextStyle(
      fontSize: FlareSizes.fontSizeMd,
      height: 1.5,
      color: colors.primaryText,
    );
    final selectLiker = widget.onSelectLiker;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(Icons.favorite_border, size: 14, color: colors.errorText),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: selectLiker == null
              ? Text(likes.map((like) => like.name).join(', '), style: style)
              // Each liker is its own control; the comma stays with the name
              // before it so a line never starts with one.
              : Wrap(
                  children: [
                    for (var i = 0; i < likes.length; i++)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: FlareContentControl(
                              onTap: () => selectLiker(likes[i].id),
                              child: Text(likes[i].name, style: style),
                            ),
                          ),
                          if (i < likes.length - 1)
                            ExcludeSemantics(child: Text(', ', style: style)),
                        ],
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
