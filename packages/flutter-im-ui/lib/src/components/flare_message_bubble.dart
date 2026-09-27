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
import 'flare_upload_progress.dart';
import 'flare_message_status.dart';
import 'flare_reaction_summary.dart';

/// Conversation kind — spec union `'single' | 'group' | 'ai'`.
/// What a conversation is, in one vocabulary for every kit (FR-056): `channel` and `system`
/// join the three that were always here, so a header never needs words of its own.
enum FlareConversationKind { single, group, channel, ai, system }

/// One message in a thread — content, sender, grouping, delivery status.
/// Spec: Message/MessageBubble (`FlareMessageBubble`). Pure/presentational:
/// status comes from host-owned lifecycle state (optimistic), never a network wait.
///
/// The body sits on the sender's side, but the meta row (time and delivery
/// status) always sits on the trailing edge: at the bottom right of a framed
/// bubble, and under bare media aligned to its right edge — for everyone's
/// messages, not only the current user's.
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
    this.onMediaReveal,
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

  /// The download key of a file card, the kit's image preview and its video
  /// player; without it none of them has a download key.
  final void Function(FlareMessageData message, FlareMessageContent content)?
  onMediaDownload;

  /// The folder key that replaces the download key once [mediaState] says the
  /// media is saved on this device (`FlareMessageContentView.onMediaReveal`).
  final void Function(FlareMessageData message, FlareMessageContent content)?
  onMediaReveal;

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
    if (!show)
      return const SizedBox(
        width: FlareSizes.componentMessageAvatarSize + FlareSizes.spacingSm,
      );
    return Padding(
      padding: const EdgeInsets.only(right: FlareSizes.spacingSm),
      child: GestureDetector(
        onTap: () => onAvatarTap?.call(message),
        child: FlareAvatar(
          userId: message.senderId,
          displayName: message.senderName,
          avatarUrl: message.senderAvatarUrl,
          size: FlareSizes.componentMessageAvatarSize,
        ),
      ),
    );
  }

  Widget _trailingAvatar(bool show) {
    if (!show)
      return const SizedBox(
        width: FlareSizes.componentMessageAvatarSize + FlareSizes.spacingSm,
      );
    return Padding(
      padding: const EdgeInsets.only(left: FlareSizes.spacingSm),
      child: FlareAvatar(
        userId: message.senderId,
        displayName: message.senderName,
        avatarUrl: message.senderAvatarUrl,
        size: FlareSizes.componentMessageAvatarSize,
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
    // 气泡最大宽 = 可用宽 × 比例,再被 layout.bubbleMaxWidth 封顶。四端同一条规则:
    // 以前 iOS 完全不设上限、Android 固定 320dp、这里取屏宽(不是窗格宽)的 72%、
    // web 是 min(62%, 640) —— 同一条长消息在四端是四种宽度。
    final available = MediaQuery.of(context).size.width;
    final ratio = available < FlareSizes.navigationRailMinWidth
        ? FlareSizes.componentBubbleMaxWidthRatioCompact
        : FlareSizes.componentBubbleMaxWidthRatioRegular;
    final maxWidth = (available * ratio).clamp(0.0, FlareSizes.bubbleMaxWidth);
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
        uploading: message.uploadProgress != null,
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
        onMediaReveal: onMediaReveal == null
            ? null
            : (content) => onMediaReveal!(message, content),
      ),
    );
    final hasMeta =
        message.timeLabel.isNotEmpty ||
        message.edited ||
        message.lifecycle != null ||
        self;

    // Bare media (image / sticker / emoji / video) carries its own frame; the
    // meta row under it lines up with its trailing edge.
    if (bare) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: _BubbleColumn(
          end: self,
          trailingLast: hasMeta,
          textDirection: Directionality.of(context),
          children: [
            if (message.uploadProgress == null)
              body
            else
              Stack(
                children: [
                  body,
                  Positioned(
                    left: FlareSizes.spacingSm,
                    right: FlareSizes.spacingSm,
                    bottom: FlareSizes.spacingSm,
                    child: IgnorePointer(
                      child: FlareUploadProgress(
                        percent: message.uploadProgress!,
                        overlay: true,
                      ),
                    ),
                  ),
                ],
              ),
            if (hasMeta)
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
    const padding = EdgeInsets.symmetric(
      horizontal: FlareSizes.componentBubblePaddingX,
      vertical: FlareSizes.componentBubblePaddingY,
    );

    final rows = <Widget>[
      body,
      if (message.uploadProgress != null)
        Padding(
          padding: const EdgeInsets.only(top: 7),
          child: FlareUploadProgress(
            percent: message.uploadProgress!,
            color: self ? colors.messageStatusOnOutgoing : null,
          ),
        ),
      // Inline meta: time + (self) delivery status, kept inside the bubble at
      // its bottom right.
      if (hasMeta)
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
    final content = _BubbleColumn(
      end: self,
      quote: quote != null,
      trailingLast: hasMeta,
      textDirection: Directionality.of(context),
      children: [if (quote != null) _quote(context, colors, quote), ...rows],
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
                // Fill only: the incoming surface is a tertiary tone the chat canvas never uses,
                // so the bubble has an edge without an outline drawn around it.
                decoration: BoxDecoration(
                  color: colors.messageIncomingBackground,
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
        content is FlareEmojiContent ||
        (content is FlareTextContent &&
            content.mentions.isEmpty &&
            flareIsStandaloneEmojiMessage(content.text)) ||
        (content is FlareRichTextContent &&
            content.title.trim().isEmpty &&
            flareIsStandaloneEmojiMessage(content.plainText));
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

/// The rows of a bubble, as wide as its widest row. Content rows sit on the
/// sender's edge — the end for the current user's messages ([end]), the start
/// for everyone else's — and with [trailingLast] the last row (the meta row)
/// sits on the trailing edge for everyone, so every message's time lines up on
/// the same side. With [quote] the first row is a quote that stretches to the
/// width of the others, or widens the bubble up to its limit. Laid out without
/// intrinsic measuring, which content renderers (host-registered ones
/// included) are not required to support.
class _BubbleColumn extends MultiChildRenderObjectWidget {
  const _BubbleColumn({
    required this.end,
    required this.textDirection,
    this.quote = false,
    this.trailingLast = false,
    required super.children,
  });

  /// Rows sit on the end edge, as in the current user's bubbles.
  final bool end;
  final TextDirection textDirection;

  /// The first row is a quote that takes the bubble's full width.
  final bool quote;

  /// The last row sits on the trailing edge whatever [end] says.
  final bool trailingLast;

  @override
  _RenderBubbleColumn createRenderObject(BuildContext context) =>
      _RenderBubbleColumn(
        end: end,
        quote: quote,
        trailingLast: trailingLast,
        textDirection: textDirection,
      );

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderBubbleColumn renderObject,
  ) {
    renderObject
      ..end = end
      ..quote = quote
      ..trailingLast = trailingLast
      ..textDirection = textDirection;
  }
}

class _BubbleColumnParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderBubbleColumn extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _BubbleColumnParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _BubbleColumnParentData> {
  _RenderBubbleColumn({
    required bool end,
    required bool quote,
    required bool trailingLast,
    required TextDirection textDirection,
  }) : _end = end,
       _quote = quote,
       _trailingLast = trailingLast,
       _textDirection = textDirection;

  bool _end;
  set end(bool value) {
    if (value == _end) return;
    _end = value;
    markNeedsLayout();
  }

  bool _quote;
  set quote(bool value) {
    if (value == _quote) return;
    _quote = value;
    markNeedsLayout();
  }

  bool _trailingLast;
  set trailingLast(bool value) {
    if (value == _trailingLast) return;
    _trailingLast = value;
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
    if (child.parentData is! _BubbleColumnParentData) {
      child.parentData = _BubbleColumnParentData();
    }
  }

  /// Sizes every child and, unless [dry], positions it.
  Size _arrange(BoxConstraints constraints, {required bool dry}) {
    Size measure(RenderBox child, BoxConstraints childConstraints) {
      if (dry) return child.getDryLayout(childConstraints);
      child.layout(childConstraints, parentUsesSize: true);
      return child.size;
    }

    final first = firstChild;
    if (first == null) return constraints.smallest;
    final quote = _quote ? first : null;
    final maxWidth = constraints.maxWidth;
    final rows = <(RenderBox, Size)>[];
    var width = 0.0;
    for (
      var row = quote == null ? first : childAfter(quote);
      row != null;
      row = childAfter(row)
    ) {
      final size = measure(row, BoxConstraints(maxWidth: maxWidth));
      rows.add((row, size));
      width = math.max(width, size.width);
    }
    var top = 0.0;
    if (quote != null) {
      final quoteSize = measure(
        quote,
        BoxConstraints(minWidth: math.min(width, maxWidth), maxWidth: maxWidth),
      );
      width = math.max(width, quoteSize.width);
      top = quoteSize.height;
      if (!dry) {
        (quote.parentData! as _BubbleColumnParentData).offset = Offset.zero;
      }
    }
    final height = rows.fold(top, (sum, row) => sum + row.$2.height);
    final size = constraints.constrain(Size(width, height));
    if (dry) return size;
    final ltr = _textDirection == TextDirection.ltr;
    for (var i = 0; i < rows.length; i++) {
      final (row, rowSize) = rows[i];
      final trailing = _trailingLast && i == rows.length - 1;
      // The end edge is the right in a left-to-right layout.
      final right = (trailing || _end) == ltr;
      (row.parentData! as _BubbleColumnParentData).offset = Offset(
        right ? size.width - rowSize.width : 0,
        top,
      );
      top += rowSize.height;
    }
    return size;
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
