import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../models/message_content.dart';
import '../models/message_data.dart';
import '../models/locate_highlight.dart';
import '../models/message_lifecycle.dart';
import '../models/message_grouping.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_avatar.dart';
import 'flare_message_content_view.dart';
import 'flare_locate_highlight_scope.dart';
import 'flare_message_meta.dart';
import 'flare_message_status.dart';
import 'flare_reaction_summary.dart';

/// Conversation kind — spec union `'single' | 'group' | 'ai'`.
/// What a conversation is, in one vocabulary for every kit (FR-056): `channel` and `system`
/// join the three that were always here, so a header never needs words of its own.
enum FlareConversationKind { single, group, channel, ai, system }

/// One message in a thread — content, sender, grouping, delivery status.
/// Spec: Message/MessageBubble (`FlareMessageBubble`). Pure/presentational:
/// status comes from host-owned lifecycle state (optimistic), never a network wait.
class FlareMessageBubble extends StatelessWidget {
  const FlareMessageBubble({
    super.key,
    required this.message,
    required this.currentUserId,
    this.conversationKind = FlareConversationKind.single,
    this.groupPosition = FlareMessageGroupPosition.single,
    this.rowPresentation = const FlareMessageRowPresentation(),
    this.selected = false,
    this.multiSelectMode = false,
    this.mediaState,
    this.onLongPress,
    this.onAvatarTap,
    this.onMediaAction,
    this.onOpenFile,
    this.onOpenLink,
    this.onResend,
    this.onToggleSelect,
    this.onReact,
    this.onLocateMessage,
    this.onVote,
    this.onTaskToggle,
    this.onMediaDownload,
  });

  final FlareMessageData message;
  final String currentUserId;
  final FlareConversationKind conversationKind;
  final FlareMessageGroupPosition groupPosition;
  final FlareMessageRowPresentation rowPresentation;
  final bool selected;
  final bool multiSelectMode;
  final FlareMediaDownloadState? mediaState;

  final void Function(FlareMessageData message)? onLongPress;
  final void Function(FlareMessageData message)? onAvatarTap;

  /// Takes every media tap. Without it the kit opens images and videos in its
  /// full-screen viewer and plays voice messages in the bubble
  /// ([FlareMessageContentView]).
  final void Function(FlareMessageData message, FlareMessageContent content)?
  onMediaAction;

  /// A file tap when there is no [onMediaAction]: the host opens the file (the
  /// kit never leaves the app), and images, videos and voice keep the kit
  /// defaults.
  final void Function(FlareMessageData message, FlareFileContent file)?
  onOpenFile;

  /// A link tapped in a text body or on a link card; the kit only reports an
  /// address that passed `safeExternalUrl` and never opens it itself.
  final void Function(FlareMessageData message, String url)? onOpenLink;
  final void Function(FlareMessageData message)? onResend;
  final void Function(FlareMessageData message)? onToggleSelect;

  /// Tapping a reaction pill toggles the current user's reaction; without it
  /// the pills are display-only.
  final void Function(FlareMessageData message, String emoji)? onReact;

  /// A tapped poll option, by its index; without it, or in multi-select mode
  /// (the body ignores taps then), the poll is read-only.
  final void Function(FlareMessageData message, int optionIndex)? onVote;

  /// A tapped task checkbox, with the done state asked for; without it, or in
  /// multi-select mode (the body ignores taps then), the task is read-only.
  final void Function(FlareMessageData message, bool done)? onTaskToggle;

  /// Offered as the download key of the kit's image preview; without it the
  /// preview has no download key.
  final void Function(FlareMessageData message, FlareMessageContent content)?
  onMediaDownload;

  /// Tapping the quote asks to show the quoted message (its
  /// [FlareReplyTarget.messageId]). Without it, without that id, or while
  /// selecting, the quote is plain text rather than a control.
  final ValueChanged<String>? onLocateMessage;

  bool get _self => message.senderId == currentUserId;

  @override
  Widget build(BuildContext context) {
    if (message.isSystem) {
      return _NoticeLine((message.content as FlareNotificationContent).text);
    }
    // A recalled message shows only who recalled it: no content, status,
    // avatar or selection.
    if (message.isRecalled) {
      final strings = FlareStrings.of(context);
      return _NoticeLine(
        _self
            ? strings.messageRecalledSelf
            : conversationKind == FlareConversationKind.group
            ? strings.messageRecalledGroupOther(message.senderName)
            : strings.messageRecalledPeer,
      );
    }

    final colors = FlareColors.of(context);
    final self = _self;
    final showAvatar = rowPresentation.showAvatar;
    final showName = rowPresentation.showSenderName;
    final groupStart =
        groupPosition == FlareMessageGroupPosition.single ||
        groupPosition == FlareMessageGroupPosition.first;
    final groupEnd =
        groupPosition == FlareMessageGroupPosition.single ||
        groupPosition == FlareMessageGroupPosition.last;

    final row = Row(
      mainAxisAlignment: self ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!self && rowPresentation.reserveAvatarSpace)
          _leadingAvatar(showAvatar),
        Flexible(child: _bubbleColumn(context, colors, self, showName)),
        if (self && rowPresentation.reserveAvatarSpace)
          _trailingAvatar(showAvatar),
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
        color: selected ? colors.messageSelectedBackground : Colors.transparent,
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

  Widget _trailingAvatar(bool show) {
    if (!show) return const SizedBox(width: 34 + FlareSizes.spacingSm);
    return Padding(
      padding: const EdgeInsets.only(left: FlareSizes.spacingSm),
      child: FlareAvatar(
        userId: message.senderId,
        displayName: message.senderName,
        avatarUrl: message.senderAvatarUrl,
        size: 34,
      ),
    );
  }

  Widget _bubbleColumn(
    BuildContext context,
    FlareColors colors,
    bool self,
    bool showName,
  ) {
    return Column(
      crossAxisAlignment: self
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showName)
          Padding(
            padding: const EdgeInsets.only(bottom: 2, left: 2),
            child: Text(
              message.senderName,
              style: TextStyle(
                color: colors.textTertiary,
                fontSize: FlareSizes.fontSizeSm,
              ),
            ),
          ),
        _bubble(context, colors, self),
        if (message.reactions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: FlareSizes.spacingXs),
            child: FlareReactionSummary(
              reactions: message.reactions,
              hideAdd: true,
              // Multi-select taps select the row; pills toggle only outside it.
              onToggle: onReact == null || multiSelectMode
                  ? null
                  : (emoji) => onReact!(message, emoji),
            ),
          ),
      ],
    );
  }

  Widget _bubble(BuildContext context, FlareColors colors, bool self) {
    final maxWidth = MediaQuery.of(context).size.width * 0.72;
    final quote = message.replyTo;
    // A quote keeps the bubble frame even around media: it needs an edge to
    // sit in.
    final bare = quote == null && _isBareMedia(message.content);

    // While selecting, a tap anywhere on the row selects it: media do not
    // open and voice does not play.
    final body = IgnorePointer(
      ignoring: multiSelectMode,
      child: FlareMessageContentView(
        content: message.content,
        self: self,
        senderName: message.senderName,
        messageId: message.id,
        mediaState: mediaState,
        onMediaAction: onMediaAction == null
            ? null
            : (c) => onMediaAction!(message, c),
        onOpenFile: onOpenFile == null
            ? null
            : (file) => onOpenFile!(message, file),
        onOpenLink: onOpenLink == null
            ? null
            : (url) => onOpenLink!(message, url),
        onVote: onVote == null ? null : (index) => onVote!(message, index),
        onTaskToggle: onTaskToggle == null
            ? null
            : (done) => onTaskToggle!(message, done),
        onMediaDownload: onMediaDownload == null
            ? null
            : (content) => onMediaDownload!(message, content),
      ),
    );

    // Bare media (image / sticker / emoji / video) carries its own frame.
    if (bare) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          crossAxisAlignment: self
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            body,
            if (message.timeLabel.isNotEmpty ||
                message.edited ||
                message.lifecycle != null ||
                self)
              Padding(
                padding: const EdgeInsets.only(top: FlareSizes.spacingXs),
                child: FlareMessageMeta(
                  timestamp: message.timeLabel,
                  edited: message.edited,
                  status: self ? message.status : null,
                  lifecycle: self ? message.lifecycle : null,
                  ephemeral:
                      message.lifecycle?.ephemeral ??
                      FlareMessageEphemeralState.none,
                  tint: null,
                  onResend: onResend == null ? null : () => onResend!(message),
                ),
              ),
          ],
        ),
      );
    }

    // Flare thread bubble grammar (from the reference app): radius 16 with a
    // 4px tail toward the sender, snug 14/9 padding, inline time meta.
    const radius = Radius.circular(16);
    const tail = Radius.circular(4);
    final groupEnd =
        groupPosition == FlareMessageGroupPosition.single ||
        groupPosition == FlareMessageGroupPosition.last;
    final shape = BorderRadius.only(
      topLeft: radius,
      topRight: radius,
      bottomLeft: self || !groupEnd ? radius : tail,
      bottomRight: !self || !groupEnd ? radius : tail,
    );
    const padding = EdgeInsets.symmetric(horizontal: 14, vertical: 9);

    final rows = <Widget>[
      body,
      // Inline meta: time + (self) delivery status, kept inside the bubble.
      if (message.timeLabel.isNotEmpty ||
          message.edited ||
          message.lifecycle != null ||
          self)
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: FlareMessageMeta(
            timestamp: message.timeLabel,
            edited: message.edited,
            status: self ? message.status : null,
            lifecycle: self ? message.lifecycle : null,
            ephemeral:
                message.lifecycle?.ephemeral ?? FlareMessageEphemeralState.none,
            tint: self
                ? (message.status == FlareMessageDeliveryStatus.read
                      ? colors.messageStatusReadOnOutgoing
                      : colors.messageStatusOnOutgoing)
                : null,
            onResend: onResend == null ? null : () => onResend!(message),
          ),
        ),
    ];
    final content = quote == null
        ? Column(
            crossAxisAlignment: self
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: rows,
          )
        : _QuoteColumn(
            end: self,
            textDirection: Directionality.of(context),
            children: [_quote(context, colors, quote), ...rows],
          );

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      // Both message surfaces follow the shared theme.
      child: _locateMark(
        context,
        colors,
        shape,
        self
            ? _selfBubble(context, colors, shape, padding, content)
            : DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.messageIncomingBackground,
                  border: Border.all(color: colors.messageIncomingBorder),
                  borderRadius: shape,
                ),
                child: Padding(padding: padding, child: content),
              ),
      ),
    );
  }

  /// The ring a row wears after a jump landed on it
  /// (`spec/locate-highlight-vectors.json`). Only the marked row listens to the
  /// clock, and only this decoration rebuilds while it runs — the bubble itself
  /// is passed through untouched.
  Widget _locateMark(
    BuildContext context,
    FlareColors colors,
    BorderRadius shape,
    Widget bubble,
  ) {
    final scope = FlareLocateHighlightScope.maybeOf(context);
    if (scope == null || scope.messageId != message.id) return bubble;
    return AnimatedBuilder(
      animation: scope.elapsedMs,
      child: bubble,
      builder: (context, child) {
        final mark = flareLocateHighlight(
          scope.elapsedMs.value,
          reduceMotion: scope.reduceMotion,
        );
        if (!mark.marked) return child!;
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: shape,
            boxShadow: [
              BoxShadow(
                color: colors.primary.withValues(alpha: mark.alpha),
                spreadRadius: mark.spread,
              ),
            ],
          ),
          child: child,
        );
      },
    );
  }

  /// Flat brand fill keeps the message text in focus.
  Widget _selfBubble(
    BuildContext context,
    FlareColors colors,
    BorderRadius shape,
    EdgeInsets padding,
    Widget content,
  ) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shape,
        color: colors.messageOutgoingBackground,
      ),
      child: Padding(padding: padding, child: content),
    );
  }

  /// The quoted message on top of the bubble: an accent bar, who said it and
  /// one line of what was said. A button that locates the original when the
  /// host can; otherwise plain grouped text.
  Widget _quote(
    BuildContext context,
    FlareColors colors,
    FlareReplyTarget quote,
  ) {
    final decoration = BoxDecoration(
      color: colors.messageReplyBackground,
      borderRadius: BorderRadius.circular(FlareSizes.radiusSm),
      border: BorderDirectional(
        start: BorderSide(color: colors.messageReplyBorder, width: 3),
      ),
    );
    final lines = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: FlareSizes.spacingSm,
        vertical: FlareSizes.spacingXs,
      ),
      child: ConstrainedBox(
        // With its padding the strip is a full touch target.
        constraints: const BoxConstraints(
          minHeight: FlareSizes.touchTarget - 2 * FlareSizes.spacingXs,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (quote.senderName.isNotEmpty)
              Text(
                quote.senderName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: FlareSizes.fontSizeSm,
                  fontWeight: FontWeight.w500,
                ),
              ),
            Text(
              quote.summary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: FlareSizes.fontSizeSm,
              ),
            ),
          ],
        ),
      ),
    );
    final id = quote.messageId;
    final locate = onLocateMessage;
    return Padding(
      padding: const EdgeInsets.only(bottom: FlareSizes.spacingXs),
      child: id == null || locate == null || multiSelectMode
          ? MergeSemantics(
              child: DecoratedBox(decoration: decoration, child: lines),
            )
          : Semantics(
              container: true,
              button: true,
              label: FlareStrings.of(
                context,
              ).quotedMessage(quote.senderName, quote.summary),
              onTap: () => locate(id),
              excludeSemantics: true,
              // Ink on a surface of its own, so the pressed state shows above
              // the bubble fill instead of under it.
              child: Material(
                type: MaterialType.transparency,
                child: Ink(
                  decoration: decoration,
                  child: InkWell(
                    onTap: () => locate(id),
                    borderRadius: BorderRadius.circular(FlareSizes.radiusSm),
                    hoverColor: colors.bgHover,
                    highlightColor: colors.bgHover,
                    focusColor: colors.focusRing,
                    child: lines,
                  ),
                ),
              ),
            ),
    );
  }

  static bool _isBareMedia(FlareMessageContent content) {
    return content is FlareImageContent ||
        content is FlareVideoContent ||
        content is FlareStickerContent ||
        content is FlareEmojiContent;
  }
}

/// Centred notice pill for system lines and recalled messages.
class _NoticeLine extends StatelessWidget {
  const _NoticeLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FlareSizes.spacingSm),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: FlareSizes.spacingMd,
            vertical: FlareSizes.spacingXs,
          ),
          decoration: BoxDecoration(
            color: colors.bgTertiary,
            borderRadius: BorderRadius.circular(FlareSizes.radiusFull),
          ),
          child: Text(
            text,
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: FlareSizes.fontSizeSm,
            ),
          ),
        ),
      ),
    );
  }
}

/// The rows of a quoting bubble. The rows after the first size the bubble and
/// the first — the quote — stretches to that width, or widens the bubble up to
/// its limit. Laid out without intrinsic measuring, which content renderers
/// (host-registered ones included) are not required to support.
class _QuoteColumn extends MultiChildRenderObjectWidget {
  const _QuoteColumn({
    required this.end,
    required this.textDirection,
    required super.children,
  });

  /// Rows sit on the end edge, as in the current user's bubbles.
  final bool end;
  final TextDirection textDirection;

  @override
  _RenderQuoteColumn createRenderObject(BuildContext context) =>
      _RenderQuoteColumn(end: end, textDirection: textDirection);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderQuoteColumn renderObject,
  ) {
    renderObject
      ..end = end
      ..textDirection = textDirection;
  }
}

class _QuoteColumnParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderQuoteColumn extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _QuoteColumnParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _QuoteColumnParentData> {
  _RenderQuoteColumn({required bool end, required TextDirection textDirection})
    : _end = end,
      _textDirection = textDirection;

  bool _end;
  set end(bool value) {
    if (value == _end) return;
    _end = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _QuoteColumnParentData) {
      child.parentData = _QuoteColumnParentData();
    }
  }

  /// Sizes every child and, unless [dry], positions it.
  Size _arrange(BoxConstraints constraints, {required bool dry}) {
    Size measure(RenderBox child, BoxConstraints childConstraints) {
      if (dry) return child.getDryLayout(childConstraints);
      child.layout(childConstraints, parentUsesSize: true);
      return child.size;
    }

    final quote = firstChild;
    if (quote == null) return constraints.smallest;
    final maxWidth = constraints.maxWidth;
    final rows = <(RenderBox, Size)>[];
    var width = 0.0;
    for (var row = childAfter(quote); row != null; row = childAfter(row)) {
      final size = measure(row, BoxConstraints(maxWidth: maxWidth));
      rows.add((row, size));
      width = math.max(width, size.width);
    }
    final quoteSize = measure(
      quote,
      BoxConstraints(minWidth: math.min(width, maxWidth), maxWidth: maxWidth),
    );
    width = math.max(width, quoteSize.width);
    var height = quoteSize.height;
    if (!dry) {
      (quote.parentData! as _QuoteColumnParentData).offset = Offset.zero;
    }
    final right = _end == (_textDirection == TextDirection.ltr);
    for (final (row, size) in rows) {
      if (!dry) {
        (row.parentData! as _QuoteColumnParentData).offset = Offset(
          right ? width - size.width : 0,
          height,
        );
      }
      height += size.height;
    }
    return constraints.constrain(Size(width, height));
  }

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) =>
      _arrange(constraints, dry: true);

  @override
  void performLayout() {
    size = _arrange(constraints, dry: false);
  }

  @override
  double computeMinIntrinsicWidth(double height) =>
      _widest((child) => child.getMinIntrinsicWidth(double.infinity));

  @override
  double computeMaxIntrinsicWidth(double height) =>
      _widest((child) => child.getMaxIntrinsicWidth(double.infinity));

  @override
  double computeMinIntrinsicHeight(double width) =>
      _total((child) => child.getMinIntrinsicHeight(width));

  @override
  double computeMaxIntrinsicHeight(double width) =>
      _total((child) => child.getMaxIntrinsicHeight(width));

  double _widest(double Function(RenderBox child) extent) {
    var result = 0.0;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      result = math.max(result, extent(child));
    }
    return result;
  }

  double _total(double Function(RenderBox child) extent) {
    var result = 0.0;
    for (var child = firstChild; child != null; child = childAfter(child)) {
      result += extent(child);
    }
    return result;
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);

  @override
  void paint(PaintingContext context, Offset offset) =>
      defaultPaint(context, offset);
}
