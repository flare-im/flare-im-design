import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../models/directory_data.dart' show FlareControlSize;
import '../models/message_content.dart';
import '../models/message_data.dart';
import '../models/locate_highlight.dart';
import '../models/message_lifecycle.dart';
import '../models/message_grouping.dart';
import '../models/message_preview.dart';
import '../models/message_surface.dart';
import '../platform/flare_platform.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_action_menu.dart';
import 'flare_avatar.dart';
import 'flare_hit_slop.dart';
import 'flare_icon_button.dart';
import 'flare_message_action_sheet.dart' show flareQuickReactions;
import 'flare_message_card_shell.dart';
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

/// One message in a thread — content, sender, grouping, receipt.
/// Spec: Message/MessageBubble (`FlareMessageBubble`). Pure/presentational:
/// status comes from host-owned state (the core SDK's receipt projection),
/// never a network wait.
///
/// The row draws its content on one surface (`spec/message-surface-vectors.json`,
/// [surface], derived from the content when absent): a coloured [bubble], bare
/// media, a card — the content's own shell, with no background, border,
/// padding or tail drawn around it, so a plugin card, red packet, location or
/// contact card is one container — or a centred notice (system lines, recall
/// and delete notices).
///
/// The meta row (time and receipt) follows
/// `spec/message-meta-placement-vectors.json`: after the last line of a text
/// (or in its own row when the line is full), in its own row inside other
/// bubbles, and under bare media and cards at the trailing edge in the default
/// palette, where a failure is the key "发送失败，重试". In a group the
/// viewer's own message shows the SDK's [FlareMessageData.readSummary] ("N
/// 人未读" / "全部已读"); with [onReadReceiptOpen] it is a key. The retry and
/// summary keys answer a tap anywhere in their `layout.touchTarget` square.
///
/// The bubble is at most the pane's width (the space the row is given) times
/// the compact or regular ratio, capped by `layout.bubbleMaxWidth`; cards keep
/// their own width (`richCardWidth`).
///
/// In [multiSelectMode] the content is inert and a tap anywhere on the row
/// toggles its selection. With a fine pointer (desktop, web) a secondary click
/// opens the message menu ([onContextMenu], else [onLongPress]) and hovering
/// shows a toolbar — react, reply and more.
///
/// The row is one reading unit for screen readers: sender, content summary,
/// time and status or read summary, with custom actions for reply, the menu
/// and retry while failed.
class FlareMessageBubble extends StatelessWidget {
  const FlareMessageBubble({
    super.key,
    required this.message,
    required this.currentUserId,
    this.conversationKind = FlareConversationKind.single,
    this.conversationId,
    this.groupPosition = FlareMessageGroupPosition.single,
    this.rowPresentation = const FlareMessageRowPresentation(),
    this.surface,
    this.selected = false,
    this.multiSelectMode = false,
    this.mediaState,
    this.locale,
    this.onLongPress,
    this.onContextMenu,
    this.onAvatarTap,
    this.onMediaAction,
    this.onOpenFile,
    this.onOpenLink,
    this.onResend,
    this.onToggleSelect,
    this.onReact,
    this.onReply,
    this.onReadReceiptOpen,
    this.onLocateMessage,
    this.onVote,
    this.onTaskToggle,
    this.onCardOpen,
    this.onLocationOpen,
    this.onMediaDownload,
    this.onMediaReveal,
  });

  final FlareMessageData message;
  final String currentUserId;
  final FlareConversationKind conversationKind;

  /// The conversation the message is in; custom content builders receive it
  /// in `FlareContentContext.conversationId`. [FlareMessageList] fills it in.
  final String? conversationId;
  final FlareMessageGroupPosition groupPosition;
  final FlareMessageRowPresentation rowPresentation;

  /// The surface the row draws its content on; null derives it from the
  /// content, the quote, the recall / delete state and the content registry
  /// (`FlareContentScope.surfaceOf`). [FlareMessageList] passes the one it
  /// grouped by.
  final FlareMessageSurface? surface;
  final bool selected;
  final bool multiSelectMode;
  final FlareMediaDownloadState? mediaState;

  /// Language tag of the row's reading unit (its list separator); defaults to
  /// the app's [Localizations] locale.
  final String? locale;

  final void Function(FlareMessageData message)? onLongPress;

  /// A secondary click (fine pointers) or the hover toolbar's more key, with
  /// where the menu should open. Without it both raise [onLongPress].
  final void Function(FlareMessageData message, Offset globalPosition)?
  onContextMenu;
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
  /// the pills are display-only. The hover toolbar's react key picks one of
  /// the quick reactions through it too.
  final void Function(FlareMessageData message, String emoji)? onReact;

  /// The hover toolbar's reply key and the row's reply action for screen
  /// readers; without it neither is offered.
  final void Function(FlareMessageData message)? onReply;

  /// The read summary was tapped: the host opens the read receipt sheet for
  /// the message. Without it the summary is plain text.
  final void Function(FlareMessageData message)? onReadReceiptOpen;

  /// A tapped poll option, by its index; without it, or in multi-select mode
  /// (the body ignores taps then), the poll is read-only.
  final void Function(FlareMessageData message, int optionIndex)? onVote;

  /// A tapped task checkbox, with the done state asked for; without it, or in
  /// multi-select mode (the body ignores taps then), the task is read-only.
  final void Function(FlareMessageData message, bool done)? onTaskToggle;

  /// A tapped person's card, with its user id; without it, or in multi-select
  /// mode, the card only displays.
  final void Function(FlareMessageData message, String userId)? onCardOpen;

  /// A tapped location card; without it the platform's default map link goes
  /// to [onOpenLink].
  final void Function(FlareMessageData message, FlareLocationContent location)?
  onLocationOpen;

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

  /// The hover toolbar (tests).
  static const Key hoverToolbarKey = ValueKey('flare-message-hover-toolbar');

  /// The surface a bubble-surface row paints (tests).
  static const Key bubbleSurfaceKey = ValueKey('flare-message-bubble-surface');

  bool get _self => message.senderId == currentUserId;

  @override
  Widget build(BuildContext context) {
    final surface =
        this.surface ?? FlareContentScope.surfaceOf(context, message);
    if (surface == FlareMessageSurface.centered) {
      return _NoticeLine(_noticeText(context));
    }
    return _FlareMessageRow(bubble: this, surface: surface);
  }

  /// The words of a centred row: who recalled it, that it was deleted, or the
  /// system line itself.
  String _noticeText(BuildContext context) {
    final strings = FlareStrings.of(context);
    if (message.isRecalled) {
      return _self
          ? strings.messageRecalledSelf
          : conversationKind == FlareConversationKind.group
          ? strings.messageRecalledGroupOther(message.senderName)
          : strings.messageRecalledPeer;
    }
    if (message.isDeleted) return strings.messageDeleted;
    return switch (message.content) {
      FlareNotificationContent c => c.text,
      FlareGenericContent c when c.label.trim().isNotEmpty => c.label,
      final content => flareMessageReplySummary(content, strings),
    };
  }
}

/// A message row with its hover state (fine pointers).
class _FlareMessageRow extends StatefulWidget {
  const _FlareMessageRow({required this.bubble, required this.surface});

  final FlareMessageBubble bubble;
  final FlareMessageSurface surface;

  @override
  State<_FlareMessageRow> createState() => _FlareMessageRowState();
}

class _FlareMessageRowState extends State<_FlareMessageRow> {
  bool _hovered = false;

  FlareMessageBubble get b => widget.bubble;
  FlareMessageData get message => b.message;
  bool get _self => b._self;
  bool get _group => b.conversationKind == FlareConversationKind.group;

  /// What the receipt shows: the lifecycle's projection outranks the status.
  FlareMessageDeliveryStatus get _status =>
      message.lifecycle?.visualStatus ?? message.status;

  void _openMenuAt(Offset position) {
    final contextMenu = b.onContextMenu;
    if (contextMenu != null) {
      contextMenu(message, position);
    } else {
      b.onLongPress?.call(message);
    }
  }

  bool get _hasMenu => b.onContextMenu != null || b.onLongPress != null;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final capabilities = flareCapabilitiesOf(context);
    final self = _self;
    final presentation = b.rowPresentation;
    final groupStart =
        b.groupPosition == FlareMessageGroupPosition.single ||
        b.groupPosition == FlareMessageGroupPosition.first;
    final groupEnd =
        b.groupPosition == FlareMessageGroupPosition.single ||
        b.groupPosition == FlareMessageGroupPosition.last;

    final row = LayoutBuilder(
      builder: (context, constraints) {
        // The pane: the width this row is given (the timeline column), not
        // the screen — a two-pane window must not size bubbles by the screen.
        final pane = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        return Row(
          mainAxisAlignment: self
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!self && presentation.reserveAvatarSpace)
              _leadingAvatar(presentation.showAvatar),
            Flexible(child: _column(context, colors, pane)),
            if (self && presentation.reserveAvatarSpace)
              _trailingAvatar(presentation.showAvatar),
          ],
        );
      },
    );

    final selecting = b.multiSelectMode;
    final content = selecting
        ? Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: FlareSizes.spacingSm),
                child: Icon(
                  b.selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked,
                  color: b.selected ? colors.primary : colors.textTertiary,
                  size: 22,
                ),
              ),
              Expanded(child: row),
            ],
          )
        : row;

    final pointerMenu = capabilities.contextMenu && !selecting && _hasMenu;
    final hoverBar =
        capabilities.hover &&
        !selecting &&
        _hovered &&
        (b.onReact != null || b.onReply != null || _hasMenu);

    Widget body = Container(
      color: b.selected ? colors.messageSelectedBackground : Colors.transparent,
      padding: EdgeInsets.only(
        left: FlareSizes.spacingMd,
        right: FlareSizes.spacingMd,
        top: groupStart ? FlareSizes.spacingSm : 2,
        bottom: groupEnd ? FlareSizes.spacingSm : 2,
      ),
      child: content,
    );
    if (hoverBar) {
      body = Stack(
        children: [
          body,
          PositionedDirectional(
            top: 0,
            start: self ? FlareSizes.spacingMd : null,
            end: self ? null : FlareSizes.spacingMd,
            child: _HoverToolbar(
              key: FlareMessageBubble.hoverToolbarKey,
              onReact: b.onReact == null
                  ? null
                  : (emoji) => b.onReact!(message, emoji),
              onReply: b.onReply == null ? null : () => b.onReply!(message),
              onMore: _hasMenu ? _openMenuAt : null,
            ),
          ),
        ],
      );
    }

    Widget gestures = InkWell(
      onTap: selecting ? () => b.onToggleSelect?.call(message) : null,
      onLongPress: selecting || b.onLongPress == null
          ? null
          : () => b.onLongPress!(message),
      onSecondaryTapUp: pointerMenu
          ? (details) => _openMenuAt(details.globalPosition)
          : null,
      child: FlareHitSlopRegion(child: body),
    );
    if (capabilities.hover) {
      gestures = MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: gestures,
      );
    }
    return _semantics(context, strings, gestures);
  }

  /// One reading unit (receipt vectors → accessibility): sender, summary,
  /// time and the receipt, with reply, menu, retry and the read receipt as
  /// custom actions. The sender name and the meta row are in the label, so
  /// they are not read again; the content keeps its own nodes (links, the
  /// quote, a card's controls, an image's description), inert in multi-select.
  Widget _semantics(BuildContext context, FlareStrings strings, Widget child) {
    final locale =
        b.locale ?? Localizations.maybeLocaleOf(context)?.toLanguageTag();
    final label = flareMessageAccessibilityLabel(
      sender: message.senderName,
      preview: flareMessageReplySummary(
        message.content,
        strings,
        locale: locale,
      ),
      time: message.timeLabel,
      self: _self,
      status: _status,
      strings: strings,
      locale: locale,
      group: _group,
      readSummary: message.readSummary,
    );
    final selecting = b.multiSelectMode;
    final receipt = flareMessageReceiptPresentation(
      self: _self,
      status: _status,
      group: _group,
      readSummary: message.readSummary,
    );
    final actions = <CustomSemanticsAction, VoidCallback>{
      if (!selecting && b.onReply != null)
        CustomSemanticsAction(label: strings.messageActionReply): () =>
            b.onReply!(message),
      if (!selecting && b.onLongPress != null)
        CustomSemanticsAction(label: strings.messageActionSheetLabel): () =>
            b.onLongPress!(message),
      if (!selecting &&
          _self &&
          _status == FlareMessageDeliveryStatus.failed &&
          b.onResend != null)
        CustomSemanticsAction(label: strings.messageSendFailedRetry): () =>
            b.onResend!(message),
      if (!selecting && receipt.summary != null && b.onReadReceiptOpen != null)
        CustomSemanticsAction(label: receipt.summary!.text(strings)): () =>
            b.onReadReceiptOpen!(message),
    };
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: label,
      selected: selecting ? b.selected : null,
      customSemanticsActions: actions.isEmpty ? null : actions,
      onTap: selecting && b.onToggleSelect != null
          ? () => b.onToggleSelect!(message)
          : null,
      child: child,
    );
  }

  Widget _leadingAvatar(bool show) {
    if (!show) {
      return const SizedBox(
        width: FlareSizes.componentMessageAvatarSize + FlareSizes.spacingSm,
      );
    }
    return Padding(
      padding: const EdgeInsets.only(right: FlareSizes.spacingSm),
      child: GestureDetector(
        onTap: b.multiSelectMode ? null : () => b.onAvatarTap?.call(message),
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
    if (!show) {
      return const SizedBox(
        width: FlareSizes.componentMessageAvatarSize + FlareSizes.spacingSm,
      );
    }
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

  Widget _column(BuildContext context, FlareColors colors, double pane) {
    final self = _self;
    return Column(
      crossAxisAlignment: self
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (b.rowPresentation.showSenderName)
          Padding(
            padding: const EdgeInsets.only(bottom: 2, left: 2),
            // Read in the row's label.
            child: ExcludeSemantics(
              child: Text(
                message.senderName,
                style: TextStyle(
                  color: colors.textTertiary,
                  fontSize: FlareSizes.fontSizeSm,
                ),
              ),
            ),
          ),
        _surface(context, colors, pane),
        if (message.reactions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: FlareSizes.spacingXs),
            child: FlareReactionSummary(
              reactions: message.reactions,
              hideAdd: true,
              // Multi-select taps select the row; pills toggle only outside it.
              onToggle: b.onReact == null || b.multiSelectMode
                  ? null
                  : (emoji) => b.onReact!(message, emoji),
            ),
          ),
      ],
    );
  }

  FlareMessageContentView _content(FlareMessageSurface surface) {
    final self = _self;
    return FlareMessageContentView(
      content: message.content,
      self: self,
      surface: surface,
      failed: self && _status == FlareMessageDeliveryStatus.failed,
      selectionMode: b.multiSelectMode,
      uploading: message.uploadProgress != null,
      senderName: message.senderName,
      messageId: message.id,
      rendererMessageId: message.serverId ?? message.id,
      conversationId: b.conversationId,
      mediaState: b.mediaState,
      onMediaAction: b.onMediaAction == null
          ? null
          : (c) => b.onMediaAction!(message, c),
      onOpenFile: b.onOpenFile == null
          ? null
          : (file) => b.onOpenFile!(message, file),
      onOpenLink: b.onOpenLink == null
          ? null
          : (url) => b.onOpenLink!(message, url),
      onVote: b.onVote == null ? null : (index) => b.onVote!(message, index),
      onTaskToggle: b.onTaskToggle == null
          ? null
          : (done) => b.onTaskToggle!(message, done),
      onCardOpen: b.onCardOpen == null
          ? null
          : (userId) => b.onCardOpen!(message, userId),
      onLocationOpen: b.onLocationOpen == null
          ? null
          : (location) => b.onLocationOpen!(message, location),
      onMediaDownload: b.onMediaDownload == null
          ? null
          : (content) => b.onMediaDownload!(message, content),
      onMediaReveal: b.onMediaReveal == null
          ? null
          : (content) => b.onMediaReveal!(message, content),
    );
  }

  /// The meta row for [layout].
  Widget _meta(FlareColors colors, FlareMessageMetaLayout layout) {
    final self = _self;
    final onBubble = layout.tone == FlareMessageMetaTone.onOutgoing;
    // Read in the row's label; its keys are the row's custom actions.
    return ExcludeSemantics(
      child: FlareMessageMeta(
        timestamp: message.timeLabel,
        edited: message.edited,
        status: self ? message.status : null,
        lifecycle: self ? message.lifecycle : null,
        ephemeral:
            message.lifecycle?.ephemeral ?? FlareMessageEphemeralState.none,
        placement: layout.placement,
        readSummary: self && _group ? message.readSummary : null,
        tint: onBubble ? colors.messageStatusOnOutgoing : null,
        readTint: onBubble ? colors.messageStatusReadOnOutgoing : null,
        onResend: b.onResend == null || b.multiSelectMode
            ? null
            : () => b.onResend!(message),
        onReadReceiptOpen: b.onReadReceiptOpen == null || b.multiSelectMode
            ? null
            : () => b.onReadReceiptOpen!(message),
      ),
    );
  }

  /// Room under a below-the-surface meta that holds a key (the retry text or
  /// the read summary), so the key's `layout.touchTarget` square stays inside
  /// this row — under the last row of a run there is only the row's own
  /// padding, and a square must not reach into the next message.
  double _belowKeyRoom(FlareMessageMetaLayout layout) {
    final retry =
        layout.retry == FlareMessageRetryKind.text && b.onResend != null;
    final summary =
        b.onReadReceiptOpen != null &&
        flareMessageReceiptPresentation(
              self: _self,
              status: _status,
              group: _group,
              readSummary: message.readSummary,
            ).summary !=
            null;
    if (b.multiSelectMode || (!retry && !summary)) return 0;
    final groupEnd =
        b.groupPosition == FlareMessageGroupPosition.single ||
        b.groupPosition == FlareMessageGroupPosition.last;
    final rowPadding = groupEnd ? FlareSizes.spacingSm : 2.0;
    return math.max(
      0,
      (FlareSizes.touchTarget - FlareSizes.iconSizeSm) / 2 - rowPadding,
    );
  }

  Widget _surface(BuildContext context, FlareColors colors, double pane) {
    final self = _self;
    final surface = widget.surface;
    final ratio = pane < FlareSizes.navigationRailMinWidth
        ? FlareSizes.componentBubbleMaxWidthRatioCompact
        : FlareSizes.componentBubbleMaxWidthRatioRegular;
    final maxWidth = (pane * ratio).clamp(0.0, FlareSizes.bubbleMaxWidth);
    final quote = message.replyTo;
    final key = flareMessageContentKey(message.content);
    final layout = flareMessageMetaPlacement(
      surface: surface,
      contentType: key.contentType,
      self: self,
      status: _status,
    );
    final hasMeta =
        message.timeLabel.isNotEmpty ||
        message.edited ||
        message.lifecycle != null ||
        self;
    final body = _content(surface);

    if (surface == FlareMessageSurface.card) {
      // The content's shell is the surface: nothing is drawn around it. A
      // quote goes into the shell's quote slot.
      final card = quote == null
          ? body
          : FlareCardQuote(
              quote: _quote(context, colors, quote, onCard: true),
              child: body,
            );
      return ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: math.max(
            maxWidth,
            math.min(pane, FlareSizes.componentRichCardWidth),
          ),
        ),
        child: _BubbleColumn(
          end: self,
          trailingLast: hasMeta,
          textDirection: Directionality.of(context),
          children: [
            _locateMark(
              context,
              colors,
              BorderRadius.circular(FlareSizes.radiusLg),
              card,
            ),
            if (hasMeta)
              Padding(
                padding: EdgeInsets.only(
                  top: FlareSizes.spacingXs,
                  bottom: _belowKeyRoom(layout),
                ),
                child: _meta(colors, layout),
              ),
          ],
        ),
      );
    }

    if (surface == FlareMessageSurface.bareMedia) {
      // Bare media carries its own frame; the meta row under it lines up with
      // its trailing edge.
      return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: _BubbleColumn(
          end: self,
          trailingLast: hasMeta,
          textDirection: Directionality.of(context),
          children: [
            _locateMark(
              context,
              colors,
              BorderRadius.circular(FlareSizes.radiusCard),
              message.uploadProgress == null
                  ? body
                  : Stack(
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
            ),
            if (hasMeta)
              Padding(
                padding: EdgeInsets.only(
                  top: FlareSizes.spacingXs,
                  bottom: _belowKeyRoom(layout),
                ),
                child: _meta(colors, layout),
              ),
          ],
        ),
      );
    }

    // Flare thread bubble grammar (from the reference app): radius 16 with a
    // 4px tail toward the sender on the last of a run, snug 14/9 padding.
    const radius = Radius.circular(16);
    const tail = Radius.circular(4);
    final groupEnd =
        b.groupPosition == FlareMessageGroupPosition.single ||
        b.groupPosition == FlareMessageGroupPosition.last;
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
    final failed = self && _status == FlareMessageDeliveryStatus.failed;
    final rows = <Widget>[
      body,
      if (message.uploadProgress != null)
        Padding(
          padding: const EdgeInsets.only(top: 7),
          child: FlareUploadProgress(
            percent: message.uploadProgress!,
            color: self && !failed ? colors.messageStatusOnOutgoing : null,
          ),
        ),
      if (hasMeta) _meta(colors, layout),
    ];
    final inline =
        layout.placement == FlareMessageMetaPlacement.inline &&
        hasMeta &&
        message.uploadProgress == null;
    final content = _BubbleColumn(
      end: self,
      quote: quote != null,
      trailingLast: hasMeta,
      inlineMeta: inline,
      metaGap: hasMeta ? 3 : 0,
      textDirection: Directionality.of(context),
      children: [if (quote != null) _quote(context, colors, quote), ...rows],
    );
    // A failed bubble keeps its red edge (status has meaning); the others are
    // drawn by their fill alone, the incoming one on a tertiary tone the chat
    // canvas never uses.
    final decoration = BoxDecoration(
      color: failed
          ? colors.messageFailedBackground
          : self
          ? colors.messageOutgoingBackground
          : colors.messageIncomingBackground,
      borderRadius: shape,
      border: failed ? Border.all(color: colors.messageFailedBorder) : null,
    );
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: _locateMark(
        context,
        colors,
        shape,
        DecoratedBox(
          key: FlareMessageBubble.bubbleSurfaceKey,
          decoration: decoration,
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

  /// The quoted message on top of the bubble (or inside a card's shell): an
  /// accent bar, who said it and one line of what was said. A button that
  /// locates the original when the host can; otherwise plain grouped text.
  Widget _quote(
    BuildContext context,
    FlareColors colors,
    FlareReplyTarget quote, {
    bool onCard = false,
  }) {
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
    final locate = b.onLocateMessage;
    final strip = id == null || locate == null || b.multiSelectMode
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
          );
    if (onCard) return strip;
    return Padding(
      padding: const EdgeInsets.only(bottom: FlareSizes.spacingXs),
      child: strip,
    );
  }
}

/// The desktop hover toolbar of a message row: react (the quick reactions),
/// reply and more (the message menu), the Vue kit's set.
class _HoverToolbar extends StatelessWidget {
  const _HoverToolbar({super.key, this.onReact, this.onReply, this.onMore});

  final ValueChanged<String>? onReact;
  final VoidCallback? onReply;
  final ValueChanged<Offset>? onMore;

  static Offset _anchorOf(BuildContext context) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) return Offset.zero;
    return box.localToGlobal(box.size.bottomLeft(Offset.zero));
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    Widget key(String icon, String label, void Function(BuildContext) onTap) =>
        Builder(
          builder: (context) => FlareIconButton(
            icon: icon,
            semanticLabel: label,
            size: FlareControlSize.sm,
            onPressed: () => onTap(context),
          ),
        );
    return Material(
      type: MaterialType.transparency,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.bgElevated,
          borderRadius: BorderRadius.circular(FlareSizes.radiusMd),
          border: Border.all(color: colors.borderSecondary),
          boxShadow: FlareShadows.of(Theme.of(context).brightness).card,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onReact != null)
              key('emoji', strings.addReaction, (context) async {
                final box = context.findRenderObject() as RenderBox?;
                final picked = await FlareActionMenu.show(
                  context,
                  label: strings.addReaction,
                  anchor: box == null || !box.hasSize
                      ? null
                      : box.localToGlobal(Offset.zero) & box.size,
                  presentation: FlareActionMenuPresentation.anchored,
                  items: [
                    for (final emoji in flareQuickReactions)
                      FlareActionItem(id: emoji, label: emoji),
                  ],
                );
                if (picked != null) onReact!(picked);
              }),
            if (onReply != null)
              key('reply', strings.messageActionReply, (_) => onReply!()),
            if (onMore != null)
              key(
                'more',
                strings.more,
                (context) => onMore!(_anchorOf(context)),
              ),
          ],
        ),
      ),
    );
  }
}

/// Centred notice line for system lines, recall and delete notices: no
/// avatar, name, status, menu or selection.
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
/// the same side, [metaGap] under the row above it. With [quote] the first row
/// is a quote that stretches to the width of the others, or widens the bubble
/// up to its limit.
///
/// With [inlineMeta] (a text bubble, `spec/message-meta-placement-vectors.json`
/// `inline`) the meta row tries the end of the text's last line first: when
/// the line leaves room for it the meta sits there, bottom-aligned and never
/// over the text, and the bubble grows to fit up to its limit; otherwise it
/// drops to its own trailing row (`bubbleFooter`). Laid out without intrinsic
/// measuring, which content renderers (host-registered ones included) are not
/// required to support.
class _BubbleColumn extends MultiChildRenderObjectWidget {
  const _BubbleColumn({
    required this.end,
    required this.textDirection,
    this.quote = false,
    this.trailingLast = false,
    this.inlineMeta = false,
    this.metaGap = 0,
    required super.children,
  });

  /// Rows sit on the end edge, as in the current user's bubbles.
  final bool end;
  final TextDirection textDirection;

  /// The first row is a quote that takes the bubble's full width.
  final bool quote;

  /// The last row sits on the trailing edge whatever [end] says.
  final bool trailingLast;

  /// The last row is the meta of a text: put it after the last line if it fits.
  final bool inlineMeta;

  /// Space above the meta row when it has a row of its own.
  final double metaGap;

  @override
  _RenderBubbleColumn createRenderObject(BuildContext context) =>
      _RenderBubbleColumn(
        end: end,
        quote: quote,
        trailingLast: trailingLast,
        inlineMeta: inlineMeta,
        metaGap: metaGap,
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
      ..inlineMeta = inlineMeta
      ..metaGap = metaGap
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
    required bool inlineMeta,
    required double metaGap,
    required TextDirection textDirection,
  }) : _end = end,
       _quote = quote,
       _trailingLast = trailingLast,
       _inlineMeta = inlineMeta,
       _metaGap = metaGap,
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

  bool _inlineMeta;
  set inlineMeta(bool value) {
    if (value == _inlineMeta) return;
    _inlineMeta = value;
    markNeedsLayout();
  }

  double _metaGap;
  set metaGap(double value) {
    if (value == _metaGap) return;
    _metaGap = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
  }

  /// Whether the last layout put the meta after the text's last line (tests).
  bool debugMetaInline = false;

  /// Space between the end of the text and an inline meta.
  static const double _inlineGap = FlareSizes.spacingSm;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _BubbleColumnParentData) {
      child.parentData = _BubbleColumnParentData();
    }
  }

  /// The last paragraph drawn in [root], depth first: the text whose last
  /// line an inline meta follows.
  static RenderParagraph? _lastParagraph(RenderObject root) {
    RenderParagraph? found;
    void visit(RenderObject node) {
      if (node is RenderParagraph) found = node;
      node.visitChildren(visit);
    }

    visit(root);
    return found;
  }

  /// Where the text in [body] ends: the end of its last line and the top of
  /// that line, in [body]'s coordinates; null when there is no plain
  /// paragraph to read (a selectable text, a custom renderer) or the text
  /// runs right to left.
  ({double x, double lineTop})? _textEnd(RenderBox body) {
    if (_textDirection != TextDirection.ltr) return null;
    final paragraph = _lastParagraph(body);
    if (paragraph == null || !paragraph.hasSize) return null;
    if (paragraph.textDirection != TextDirection.ltr) return null;
    final length = paragraph.text
        .toPlainText(includeSemanticsLabels: false)
        .length;
    final caret = paragraph.getOffsetForCaret(
      TextPosition(offset: length),
      Rect.zero,
    );
    final transform = paragraph.getTransformTo(body);
    final point = MatrixUtils.transformPoint(transform, caret);
    return (x: point.dx, lineTop: point.dy);
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

    // An inline meta: after the last line of the text when there is room.
    var inline = false;
    if (!dry && _inlineMeta && _trailingLast && rows.length == 2) {
      final (body, bodySize) = rows[0];
      final (_, metaSize) = rows[1];
      final textEnd = _textEnd(body);
      if (textEnd != null) {
        final needed = textEnd.x + _inlineGap + metaSize.width;
        final lineHeight = bodySize.height - textEnd.lineTop;
        if (needed <= maxWidth && metaSize.height <= lineHeight + 0.5) {
          inline = true;
          width = math.max(width, needed);
          // Without a quote the bubble is no wider than the text and its meta.
          if (quote == null) width = math.max(bodySize.width, needed);
        }
      }
    }
    debugMetaInline = inline;

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
    final gap = _trailingLast && rows.length > 1 && !inline ? _metaGap : 0.0;
    final height = inline
        ? top + rows[0].$2.height
        : rows.fold(top, (sum, row) => sum + row.$2.height) + gap;
    final size = constraints.constrain(Size(width, height));
    if (dry) return size;
    final ltr = _textDirection == TextDirection.ltr;
    if (inline) {
      final (body, bodySize) = rows[0];
      final (meta, metaSize) = rows[1];
      // The text reads from the start edge; the meta closes its last line.
      (body.parentData! as _BubbleColumnParentData).offset = Offset(0, top);
      (meta.parentData! as _BubbleColumnParentData).offset = Offset(
        size.width - metaSize.width,
        top + bodySize.height - metaSize.height,
      );
      return size;
    }
    for (var i = 0; i < rows.length; i++) {
      final (row, rowSize) = rows[i];
      final trailing = _trailingLast && i == rows.length - 1;
      if (trailing && i > 0) top += gap;
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
