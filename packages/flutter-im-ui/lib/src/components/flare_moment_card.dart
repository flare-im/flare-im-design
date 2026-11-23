import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

/// Elevated for an isolated card; flat for a continuous Moments timeline;
/// [detail] for a moment opened on its own (an inbox row): the whole text, a
/// comments heading with the count, and room for a located comment.
enum FlareMomentPresentation { card, feed, detail }

/// A moment's text is folded behind Expand past this many characters or lines
/// (outside [FlareMomentPresentation.detail]); the same rule as the Vue kit.
const int flareMomentFoldChars = 280;
const int flareMomentFoldLines = 6;

/// A single moment (social-feed post): author, text, image grid, location, a
/// meta row with a ··· menu that raises a [FlareMomentActionPopover], and a
/// social panel of likes + comments. Spec: Moments/Card (`FlareMomentCard`).
///
/// People and comments are controls only when the host does something with
/// them: the author's name (with the avatar as a pointer shortcut that stays
/// out of the accessibility tree) needs [onSelectAuthor], each liker
/// [onSelectLiker], and each comment row [onSelectComment]; otherwise they are
/// plain text. Names use the accessible primary text colour.
///
/// Like and Comment are offered only when the host takes them ([onLike],
/// [onComment]); Delete / Report follow [canDelete] / [canReport]. With none
/// of them the ··· key is not drawn. Opened, the actions line up to the left
/// of the key; Escape or any action folds them and focus returns to the key.
/// Long text folds behind Expand ([flareMomentFoldChars] /
/// [flareMomentFoldLines]); comments fold past 3 lines (5 in [detail]).
class FlareMomentCard extends StatefulWidget {
  const FlareMomentCard({
    super.key,
    required this.moment,
    this.presentation = FlareMomentPresentation.card,
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
    this.focusCommentId,
  });

  final FlareMoment moment;

  /// [FlareMomentPresentation.detail]: the comment the view was opened to,
  /// unfolded, tagged and scrolled into view.
  final String? focusCommentId;

  /// Feed rows share the page surface, without a shadow, rounded frame or
  /// nested social card. A hairline separates posts instead of a card gap.
  final FlareMomentPresentation presentation;

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
  bool _expanded = false;
  final FocusNode _more = FocusNode(debugLabel: 'moment ···');

  @override
  void dispose() {
    _more.dispose();
    super.dispose();
  }

  bool get _hasActions =>
      widget.onLike != null ||
      widget.onComment != null ||
      (widget.canDelete && widget.onDelete != null) ||
      (widget.canReport && widget.onReport != null);

  bool get _longText {
    final text = widget.moment.text ?? '';
    return text.length > flareMomentFoldChars ||
        '\n'.allMatches(text).length + 1 > flareMomentFoldLines;
  }

  void _closeMenu() {
    if (!_menuOpen) return;
    setState(() => _menuOpen = false);
    _more.requestFocus();
  }

  void _run(VoidCallback? action) {
    _closeMenu();
    action?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final moment = widget.moment;
    final likes = moment.likes;
    final comments = moment.comments;
    final hasSocial = likes.isNotEmpty || comments.isNotEmpty;
    final detail = widget.presentation == FlareMomentPresentation.detail;
    // The detail view is as flat as the feed: it sits on its modal's surface.
    final inFeed =
        widget.presentation == FlareMomentPresentation.feed || detail;
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

    final strings = FlareStrings.of(context);
    final fold = !detail && _longText;
    final authorAvatar = ExcludeSemantics(
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
    );
    final authorName = selectAuthor == null
        ? name
        : FlareContentControl(
            onTap: () => selectAuthor(moment.author.id),
            child: name,
          );
    final body = <Widget>[
      if (moment.text != null && moment.text!.isNotEmpty)
        Padding(
          padding: EdgeInsets.only(
            top: detail ? FlareSizes.spacingSm : FlareSizes.spacingXs,
          ),
          child: Text(
            moment.text!,
            maxLines: fold && !_expanded ? flareMomentFoldLines : null,
            overflow: fold && !_expanded ? TextOverflow.ellipsis : null,
            style: TextStyle(
              fontSize: 15,
              height: 1.55,
              color: colors.textPrimary,
            ),
          ),
        ),
      if (fold)
        Semantics(
          expanded: _expanded,
          child: FlareContentControl(
            onTap: () => setState(() => _expanded = !_expanded),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: FlareSizes.touchTarget,
              ),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                widthFactor: 1,
                child: Text(
                  _expanded ? strings.collapse : strings.expand,
                  style: TextStyle(color: colors.primaryText),
                ),
              ),
            ),
          ),
        ),
    ];
    return Container(
      decoration: detail
          ? null
          : inFeed
          ? BoxDecoration(
              color: colors.bgPrimary,
              border: Border(bottom: BorderSide(color: colors.borderSecondary)),
            )
          : BoxDecoration(
              // The card uses a restrained theme-tinted lift in dark mode.
              color: colors.bgElevated,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? const Color(0x80000000)
                      : const Color(0x14151320),
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
      padding: EdgeInsets.symmetric(
        horizontal: FlareSizes.spacingLg,
        vertical: inFeed ? FlareSizes.spacingXl : FlareSizes.spacingLg,
      ),
      child: _layout(
        detail: detail,
        avatar: authorAvatar,
        name: authorName,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!detail) authorName,
            ...body,
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
              padding: EdgeInsets.only(
                top: inFeed ? FlareSizes.spacingXs : FlareSizes.spacing2sm,
              ),
              child: _metaRow(colors, moment),
            ),
            if (hasSocial || detail)
              Padding(
                padding: EdgeInsets.only(
                  top: inFeed ? FlareSizes.spacingXs : FlareSizes.spacing2sm,
                ),
                child: _social(colors, likes, comments),
              ),
          ],
        ),
      ),
    );
  }

  /// Feed and card put the avatar beside the whole post; the detail view puts
  /// it beside the name only, and the post runs the full width under them.
  Widget _layout({
    required bool detail,
    required Widget avatar,
    required Widget name,
    required Widget content,
  }) {
    if (detail) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              avatar,
              const SizedBox(width: FlareSizes.spacingMd),
              Expanded(child: name),
            ],
          ),
          content,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The avatar repeats the name, so it is never announced; with a
        // handled author it is a pointer shortcut to the name's action.
        avatar,
        const SizedBox(width: FlareSizes.spacingMd),
        Expanded(child: content),
      ],
    );
  }

  Widget _metaRow(FlareColors colors, FlareMoment moment) {
    final onLike = widget.onLike, onComment = widget.onComment;
    final onDelete = widget.onDelete, onReport = widget.onReport;
    final actions = FlareMomentActionPopover(
      liked: moment.likedBySelf,
      canDelete: widget.canDelete && onDelete != null,
      canReport: widget.canReport && onReport != null,
      onLike: onLike == null ? null : () => _run(onLike),
      onComment: onComment == null ? null : () => _run(onComment),
      onDelete: onDelete == null ? null : () => _run(onDelete),
      onReport: onReport == null ? null : () => _run(onReport),
    );
    final time = Text(
      moment.time ?? '',
      style: TextStyle(
        fontSize: FlareSizes.fontSizeSm,
        color: colors.textTertiary,
      ),
    );
    // The ··· key exists only while there is something behind it.
    if (!_hasActions) return time;
    return CallbackShortcuts(
      bindings: {
        if (_menuOpen)
          const SingleActivator(LogicalKeyboardKey.escape): _closeMenu,
      },
      child: Row(
        children: [
          // The actions open beside the key, towards the text, in one row
          // over the time (the Vue kit's anchored horizontal menu).
          Expanded(
            child: Stack(
              alignment: AlignmentDirectional.centerEnd,
              children: [
                Align(alignment: AlignmentDirectional.centerStart, child: time),
                if (_menuOpen) FocusTraversalGroup(child: actions),
              ],
            ),
          ),
          FlareIconControl(
            focusNode: _more,
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
    );
  }

  Widget _social(
    FlareColors colors,
    List<FlareMomentLike> likes,
    List<FlareMomentComment> comments,
  ) {
    final inFeed = widget.presentation != FlareMomentPresentation.card;
    return Container(
      width: double.infinity,
      padding: inFeed
          ? const EdgeInsets.only(top: FlareSizes.spacingSm)
          : const EdgeInsets.symmetric(
              horizontal: FlareSizes.spacingMd,
              vertical: FlareSizes.spacingSm,
            ),
      decoration: BoxDecoration(
        color: inFeed ? colors.bgPrimary : colors.bgSecondary,
        borderRadius: inFeed
            ? null
            : BorderRadius.circular(FlareSizes.radiusLg),
        border: inFeed
            ? Border(top: BorderSide(color: colors.borderSecondary))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (likes.isNotEmpty) _likes(colors, likes),
          if (widget.presentation == FlareMomentPresentation.detail) ...[
            Padding(
              padding: const EdgeInsets.only(top: FlareSizes.spacingSm),
              child: Text.rich(
                TextSpan(
                  text: FlareStrings.of(context).momentCommentsTitle,
                  style: TextStyle(
                    fontSize: FlareSizes.fontSizeMd,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                  children: [
                    TextSpan(
                      text: ' ${comments.length}',
                      style: TextStyle(
                        fontSize: FlareSizes.fontSizeSm,
                        fontWeight: FontWeight.w400,
                        color: colors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (comments.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: FlareSizes.spacingSm,
                ),
                child: Text(
                  FlareStrings.of(context).momentNoComments,
                  style: TextStyle(
                    fontSize: FlareSizes.fontSizeSm,
                    color: colors.textTertiary,
                  ),
                ),
              ),
          ] else if (likes.isNotEmpty && comments.isNotEmpty)
            if (inFeed)
              const SizedBox(height: FlareSizes.spacingXs)
            else
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
              detail: widget.presentation == FlareMomentPresentation.detail,
              focusCommentId: widget.focusCommentId,
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
