import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'dart:async';

import 'package:flutter/rendering.dart' show ScrollDirection;
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';

import '../models/image_gallery.dart';
import '../models/message_content.dart';
import '../models/message_data.dart';
import '../models/haptics.dart';
import '../models/locate_highlight.dart';
import '../models/message_grouping.dart';
import '../models/message_list_paging.dart';
import '../models/message_preview.dart';
import '../models/message_surface.dart';
import '../models/swipe_reply.dart';
import '../models/time_format.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_date_pill.dart';
import 'flare_empty_state.dart';
import 'flare_icon.dart';
import 'flare_locate_highlight_scope.dart';
import 'flare_media_controller.dart';
import 'flare_message_bubble.dart';
import 'flare_message_content_view.dart';
import 'flare_action_menu.dart';
import 'flare_message_action_sheet.dart';
import 'flare_message_menu.dart';
import 'flare_scroll_to_latest.dart';
import 'flare_unread_divider.dart';

/// The virtualised message thread — grouping, load-older, multi-select, media
/// state. Spec: Message/MessageList (`FlareMessageList`).
///
/// Pure/presentational and windowed via lazy slivers (O(visible)). Order
/// is oldest→newest (top→bottom); the host feeds [messages] from the timeline
/// view and drives pagination through [onLoadOlder].
///
/// The list follows the newest message itself, the Vue kit's rule: it opens,
/// and reopens on a new [conversationId], with the newest message at the
/// bottom; a message that arrives while the reader is at the bottom (or is the
/// current user's own) keeps them there; a reader who scrolled up keeps the
/// rows they are reading and gets a [FlareScrollToLatest] counting the messages
/// that arrived below (tapping it goes to the newest); older messages and edits
/// never move the rows in view; and a list that changes height (keyboard,
/// window) keeps a reader at the bottom there. The list never animates these
/// moves, so reduced motion needs no special case. A host drives the list only
/// to show one message ([FlareMessageListController.scrollToMessage]); the
/// tail is the list's own.
///
/// A [FlareDatePill] marks the first loaded message and every message on a
/// new local calendar day ([FlareMessageData.sentAtMs]); a message without a
/// time starts no day. Every bubble shows its own time, so there is no
/// separator for a gap within a day. [unreadFromId] adds a
/// [FlareUnreadDivider] under the date pill of the same message. A sender run
/// never continues across either: the message before a separator ends its
/// run and the message after it starts a new one.
///
/// A host that has to show one particular message passes a
/// [FlareMessageListController].
///
/// Paging (`spec/message-list-paging-vectors.json`): the older end above the
/// timeline and, for a window detached from the latest ([hasNewer]), the newer
/// end below it draw a spinner while loading, else the error and the load or
/// retry button. The list asks for a page by itself ([onLoadOlder],
/// [onLoadNewer]) when the reader drags within 160 logical pixels of that edge.
/// A detached window shows [FlareScrollToLatest] without a count, which asks
/// the host for the latest window ([onJumpToLatest]); that window opens at its
/// newest message. A newer page read into a detached window keeps the reader
/// on the rows they are reading.
///
/// A window the host replaces as a whole (`windows`: [windowId] changed, the
/// latest window the reader asked for, or no row left in common) opens at its
/// newest row and keeps nothing of the reader's place in the old one; the list
/// still asks for pages only while the reader drags. A located row
/// ([FlareMessageListController.scrollToMessage], a tapped quote) stays where
/// the locate put it until the reader drags: a page that lands meanwhile grows
/// around it (`locateAfterReplace`).
class FlareMessageList extends StatefulWidget {
  const FlareMessageList({
    super.key,
    required this.messages,
    required this.currentUserId,
    this.conversationKind = FlareConversationKind.single,
    this.multiSelectMode = false,
    this.selectedIds = const {},
    this.loadingOlder = false,
    this.hasOlder = false,
    this.olderError,
    this.loadOlderText,
    this.hasNewer = false,
    this.loadingNewer = false,
    this.newerError,
    this.onLoadNewer,
    this.onJumpToLatest,
    this.windowId,
    this.onAtBottomChange,
    this.conversationId,
    this.loading = false,
    this.emptyText,
    this.mediaDownloadStates = const {},
    this.controller,
    this.onLoadOlder,
    this.onMessageLongPress,
    this.onAvatarTap,
    this.onMediaAction,
    this.onOpenFile,
    this.onOpenLink,
    this.onMediaDownload,
    this.onMediaReveal,
    this.onVote,
    this.onTaskToggle,
    this.onCardOpen,
    this.onLocationOpen,
    this.onResend,
    this.onToggleSelect,
    this.onSwipeReply,
    this.onReply,
    this.onReact,
    this.onReadReceiptOpen,
    this.menu,
    this.onLocateMessage,
    this.emptyPlaceholder,
    this.footer,
    this.showIncomingAvatar = true,
    this.showSelfAvatar = false,
    this.showGroupSenderName = true,
    this.unreadFromId,
    this.locale,
    this.mediaController,
  });

  final List<FlareMessageData> messages;
  final String currentUserId;
  final FlareConversationKind conversationKind;
  final bool multiSelectMode;
  final Set<String> selectedIds;
  final bool loadingOlder;
  final bool hasOlder;
  final String? olderError;
  final String? loadOlderText;

  /// The window is detached from the latest messages (it was opened around a
  /// message): there is newer history past its last row. The list draws its
  /// newer end below the timeline, asks for newer pages as the reader nears
  /// the bottom ([onLoadNewer]) and offers the way back to the latest
  /// ([onJumpToLatest]). Left at the defaults the list draws no newer end,
  /// never asks for newer and keeps only the new-messages key.
  final bool hasNewer;

  /// A newer page is being read: the newer end shows a spinner.
  final bool loadingNewer;

  /// The last newer page failed: the newer end shows it with a retry.
  final String? newerError;

  /// Reads the next newer page.
  final VoidCallback? onLoadNewer;

  /// The back-to-latest key of a detached window: the host replaces the
  /// window with the latest messages.
  final VoidCallback? onJumpToLatest;

  /// The host's name for the window it hands the list (the core timeline
  /// view's `viewId`). When it changes from one name to another the window was
  /// replaced as a whole, even where the two share rows. Without it a window is
  /// replaced when no row is left in common.
  final String? windowId;

  /// Whether the reader is at the bottom of the window
  /// (`spec/message-list-paging-vectors.json` `atBottom`): the end of the
  /// timeline at most 80 logical pixels below the viewport. Called when the
  /// answer changes and once after the first layout of each conversation, after
  /// the frame that decided it. A window replaced without the reader asking for
  /// it and a locate answer false until the reader scrolls the list (a drag or a
  /// wheel), goes to the newest row (the new-messages key, a message of their
  /// own) or gets the latest window they asked for. It is the bottom of the
  /// window shown, attached to the latest or not (Vue `atBottomChange`).
  final ValueChanged<bool>? onAtBottomChange;
  final String? conversationId;
  final bool loading;

  /// 空态文案。整块替换用 [emptyPlaceholder]，仅换文字用本参数。
  final String? emptyText;

  /// Per-message-id media download state: what the media's key shows — the
  /// file card's key in the timeline, and the key of an image preview or video
  /// player opened from the message, which follows it live (pressing download
  /// there turns the key into progress, then a folder, without closing).
  final Map<String, FlareMediaDownloadState> mediaDownloadStates;

  /// Coordinates voice playback across the bubbles (one voice message at a
  /// time); the list makes its own when null. Pass one to stop the thread's
  /// playback from outside, e.g. when a call starts. Playback stops when the
  /// list is disposed or covered by another screen.
  final FlareMediaController? mediaController;

  /// The host's handle on this list — its scroll position and
  /// [FlareMessageListController.scrollToMessage]. The list makes its own
  /// when this is null.
  final FlareMessageListController? controller;
  final VoidCallback? onLoadOlder;
  final void Function(FlareMessageData message)? onMessageLongPress;
  final void Function(FlareMessageData message)? onAvatarTap;

  /// Host takes every media tap; without it the kit opens images and videos
  /// and plays voice messages ([mediaController]), a file tap goes to
  /// [onOpenFile] and a link to [onOpenLink]. A location goes to
  /// [onLocationOpen], else its map link to [onOpenLink].
  final void Function(FlareMessageData message, FlareMessageContent content)?
  onMediaAction;

  /// A file tap when there is no [onMediaAction]: the host opens the file
  /// (after `safeExternalUrl` for a remote one) while images, videos and voice
  /// keep the kit defaults.
  final void Function(FlareMessageData message, FlareFileContent file)?
  onOpenFile;

  /// A link tapped in a text body or on a link card. Flutter has no URL
  /// launcher, so without this the link does nothing; the kit reports only an
  /// address that passed `safeExternalUrl` and never opens it itself.
  final void Function(FlareMessageData message, String url)? onOpenLink;

  /// The download key of a file card, the kit's image preview and its video
  /// player; without it none of them has a download key. A tapped picture
  /// opens the conversation's gallery, and the key saves the picture on screen
  /// with the message it belongs to; a video's key saves that video, a file
  /// card's that file. The host reports the download in [mediaDownloadStates].
  final void Function(FlareMessageData message, FlareMessageContent content)?
  onMediaDownload;

  /// The folder key that replaces the download key once [mediaDownloadStates]
  /// says a message's media is saved on this device (`done`): the host shows
  /// the file in the system file manager, or — when the file is gone — sets
  /// the state back to idle so the key offers the download again. Without it
  /// a saved media has no key.
  final void Function(FlareMessageData message, FlareMessageContent content)?
  onMediaReveal;

  /// A tapped poll option, by its index; without it polls are read-only.
  final void Function(FlareMessageData message, int optionIndex)? onVote;

  /// A tapped task checkbox, with the done state asked for; without it tasks
  /// are read-only.
  final void Function(FlareMessageData message, bool done)? onTaskToggle;

  /// A tapped person's card, with its user id: the host opens the profile.
  /// Without it cards only display.
  final void Function(FlareMessageData message, String userId)? onCardOpen;

  /// A tapped location card. Without it the platform's default map link goes
  /// to [onOpenLink]; without either the card only displays.
  final void Function(FlareMessageData message, FlareLocationContent location)?
  onLocationOpen;
  final void Function(FlareMessageData message)? onResend;
  final void Function(FlareMessageData message)? onToggleSelect;
  final void Function(FlareMessageData message)? onSwipeReply;

  /// The reply intent from the desktop hover toolbar and the row's reply
  /// action for screen readers; defaults to [onSwipeReply], the same intent.
  final void Function(FlareMessageData message)? onReply;

  /// Reaction pill tap (toggle the current user's reaction), and the hover
  /// toolbar's quick reactions.
  final void Function(FlareMessageData message, String emoji)? onReact;

  /// The read summary of the viewer's own group message was tapped: the host
  /// fills the read receipt sheet for it.
  final void Function(FlareMessageData message)? onReadReceiptOpen;

  /// One source for a message's long-press sheet and its pointer menu (the
  /// secondary click on a fine pointer, and the hover toolbar's more key):
  /// the list reads the host's availability snapshot, builds both menus from
  /// the same entries ([messageMenuEntries]) and hands the chosen entry to
  /// [FlareMessageMenuSource.perform] (a reaction from the sheet goes to
  /// [onReact]). It asks the host to prefetch the rows coming on screen.
  /// Without a snapshot the pointer menu shows one disabled "loading" entry
  /// and prefetches, also when the host drops the snapshot while the menu is
  /// open (the list asks again itself); a long press waits for the snapshot,
  /// then opens the sheet. With [menu] the list owns the menus and
  /// [onMessageLongPress] is not called; without it a long press and a
  /// secondary click both raise [onMessageLongPress].
  final FlareMessageMenuSource? menu;

  /// A quote was tapped whose message is not in [messages] (the host may load
  /// older history to reach it, then show it with
  /// [FlareMessageListController.scrollToMessage], which takes this same id
  /// back unchanged). A quoted message that is loaded is scrolled into view by
  /// the list itself, without calling this — loaded means some row answers to
  /// the quote's [FlareReplyTarget.messageId], by its own id or by its
  /// [FlareMessageData.serverId].
  final ValueChanged<String>? onLocateMessage;
  final Widget? emptyPlaceholder;

  /// Host content under the newest message, scrolling with the timeline — the contract's `footer` slot,
  /// as on Vue. The typing indicator lives here: it belongs to the conversation, not to the composer, and
  /// a reader scrolled up must not be told someone is typing at a row they are not looking at.
  final Widget? footer;
  final bool showIncomingAvatar;
  final bool showSelfAvatar;
  final bool showGroupSenderName;

  /// Id of the first unread message. The list draws a [FlareUnreadDivider]
  /// above it, counting the messages from others from there on, and starts a
  /// new sender run at it. Keep it fixed while the conversation stays open.
  final String? unreadFromId;

  /// Language tag the date separators follow (`zh-CN`, `en-US`); defaults to
  /// the app's [Localizations] locale, then the platform's.
  final String? locale;

  @override
  State<FlareMessageList> createState() => _FlareMessageListState();
}

/// The host's handle on one [FlareMessageList]: its scroll position
/// ([scroll]) and [scrollToMessage].
///
/// Pass one to [FlareMessageList.controller] and [dispose] it with the state
/// that made it; a list without one makes its own.
///
/// The list shows a quoted message that is loaded by itself and only reports a
/// quote it cannot reach ([FlareMessageList.onLocateMessage]).
/// [scrollToMessage] is the way back from that report: the host reads the
/// history holding the message and asks the list to show it, so the reader
/// taps the quote once.
class FlareMessageListController {
  /// The list's scroll position, for a host that reads or drives it. Made and
  /// released here; the list never takes another.
  final ScrollController scroll = ScrollController();

  /// Row index by every id the rows of the list's last build answer to, so
  /// [scrollToMessage] answers for the rows that are loaded now.
  Map<String, int> _rows = const {};

  /// The list being driven, while one is mounted.
  _FlareMessageListState? _list;

  /// Brings the message [id] into the middle of the list, the way tapping a
  /// quote of a loaded message does: no animation under reduced motion, and
  /// the list stops following the newest message. A row answers both to its
  /// own [FlareMessageData.id] and to the core id it was drawn from
  /// ([FlareMessageData.serverId]), so the id a quote reported
  /// ([FlareMessageList.onLocateMessage]) goes back in unchanged.
  ///
  /// Returns whether the list holds that row. False — and nothing moves —
  /// when the message is not in the loaded window, so a host that has just
  /// read older history can tell "shown" from "not in this conversation";
  /// false too while no list is mounted, before the first build and after the
  /// list is gone.
  bool scrollToMessage(String id) {
    final list = _list;
    final index = _rows[id];
    if (list == null || index == null) return false;
    unawaited(list._scrollToRow(index));
    return true;
  }

  /// The rows of [list]'s latest build, by every id they answer to.
  void _attach(_FlareMessageListState list, Map<String, int> rows) {
    _list = list;
    _rows = rows;
  }

  /// [list] is gone (disposed, or handed another controller): answer false
  /// again rather than scroll a list that is not there.
  void _detach(_FlareMessageListState list) {
    if (!identical(_list, list)) return;
    _list = null;
    _rows = const {};
  }

  /// Releases [scroll]. Call it from the host state's `dispose`.
  void dispose() => scroll.dispose();
}

class _FlareMessageListState extends State<FlareMessageList>
    with SingleTickerProviderStateMixin {
  /// The row a jump landed on wears a mark for one window
  /// (`spec/locate-highlight-vectors.json`). The list owns the clock; the
  /// marked row reads it. One row at a time — restarting the clock moves the
  /// mark, it never adds a second one.
  late final AnimationController _locateClock = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: flareLocateHighlightDurationMs),
  );
  late final Animation<double> _locateElapsed = _locateClock.drive(
    Tween<double>(begin: 0, end: flareLocateHighlightDurationMs.toDouble()),
  );
  String? _locatedId;

  String get _loadOlderText =>
      widget.loadOlderText ?? FlareStrings.of(context).messageListLoadOlder;
  String get _emptyText =>
      widget.emptyText ?? FlareStrings.of(context).noMessages;
  final _ownedHandle = FlareMessageListController();

  /// The scroll view runs bottom to top (`reverse`), so offset 0 puts its
  /// center at the bottom edge and a larger offset shows older rows. The
  /// center is the sliver of rows before the pivot, growing upwards from that
  /// edge; the pivot and the rows after it grow downwards from it. (A reversed
  /// view rather than `anchor: 1`: `RenderViewport.getOffsetToReveal` ignores
  /// the anchor, which breaks `ensureVisible` and screen-reader scrolling.) A
  /// global key, so a moved offset can ask for a layout.
  final _centerKey = GlobalKey();
  final _viewportKey = GlobalKey();
  final _rowKeys = <String, GlobalKey>{};

  /// How far above the newest message still counts as reading it.
  static const double _bottomSlop = 80;

  /// Whether the reader is at the newest message, so new messages keep them
  /// there. It follows the reader's scrolling.
  bool _followTail = true;

  /// The newest message when the reader left the bottom: the messages after it
  /// are the ones [FlareScrollToLatest] counts.
  String? _browseTailId;

  /// False while the list moves itself, so its own jump is not read as the
  /// reader scrolling.
  bool _trackScroll = true;

  /// The viewport height of the last layout, to keep a reader's rows in place
  /// when it changes.
  double? _viewportHeight;

  ({String id, double offset})? _visibleAnchor(
    Set<String> surviving, {
    String? only,
  }) {
    final viewport = _viewportKey.currentContext?.findRenderObject();
    if (viewport is! RenderBox || !viewport.hasSize) return null;
    final top = viewport.localToGlobal(Offset.zero).dy;
    final rows = <({String id, double offset})>[];
    for (final entry in _rowKeys.entries) {
      if (!surviving.contains(entry.key)) continue;
      if (only != null && entry.key != only) continue;
      final box = entry.value.currentContext?.findRenderObject();
      if (box is! RenderBox || !box.attached || !box.hasSize) continue;
      final y = box.localToGlobal(Offset.zero).dy - top;
      if (y < viewport.size.height && y + box.size.height > 0)
        rows.add((id: entry.key, offset: y));
    }
    rows.sort((a, b) => a.offset.compareTo(b.offset));
    return rows.firstOrNull;
  }

  FlareMediaController? _ownMedia;
  bool _onScreen = true;

  /// [FlareMessageList.mediaDownloadStates] for the viewers opened from the
  /// thread (they live in their own routes, outside this list's rebuilds).
  late final ValueNotifier<Map<String, FlareMediaDownloadState>>
  _downloadStates = ValueNotifier(Map.of(widget.mediaDownloadStates));
  bool _downloadStatesQueued = false;

  /// Hands the viewers the host's latest states after this frame: they are in
  /// other routes, which must not be marked dirty while this list builds.
  void _publishDownloadStates() {
    if (mapEquals(_downloadStates.value, widget.mediaDownloadStates) ||
        _downloadStatesQueued) {
      return;
    }
    _downloadStatesQueued = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _downloadStatesQueued = false;
      if (!mounted) return;
      _downloadStates.value = Map.of(widget.mediaDownloadStates);
    });
  }

  FlareMediaController get _media =>
      widget.mediaController ?? (_ownMedia ??= FlareMediaController());

  /// The first row of the lower sliver; null puts every row above the center,
  /// so offset 0 shows the newest message at the bottom.
  String? _pivotId;
  bool _requested = false;
  bool _requestedNewer = false;

  /// The reader asked for the latest messages: the window the host replaces
  /// this one with opens at its newest.
  bool _jumpRequested = false;

  /// The window has been detached since the rows last changed: rows appended
  /// now are a newer page.
  bool _detachedSinceRows = false;

  /// The row a locate took the reader to, until the reader drags: rows that
  /// change meanwhile keep it where the locate put it.
  String? _locatedHoldId;

  /// The window was replaced and the reader has not moved it since: the list
  /// asks for no page by itself (`locateAfterReplace`).
  bool _pagingHeld = false;

  /// The window a fill last asked for: its first and last rows and how far it
  /// overflowed. A page that brings no rows does not ask again.
  String? _fillAskedFor;

  /// Whether the reader is at the bottom (`atBottom`), as told to the host.
  final _bottom = FlareMessageListBottomReport();

  /// Answers not told yet: the host hears them after the frame that decided
  /// them, in order, so it may rebuild in response.
  final List<bool> _bottomPending = [];
  bool _bottomFlushScheduled = false;
  bool _bottomMeasureScheduled = false;

  void _tellBottom(bool? answer) {
    if (answer == null) return;
    _bottomPending.add(answer);
    if (_bottomFlushScheduled) return;
    _bottomFlushScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) => _flushBottom());
    SchedulerBinding.instance.ensureVisualUpdate();
  }

  void _flushBottom() {
    _bottomFlushScheduled = false;
    if (!mounted) return;
    final answers = List.of(_bottomPending);
    _bottomPending.clear();
    for (final answer in answers) {
      widget.onAtBottomChange?.call(answer);
    }
  }

  /// One layout or scroll, as the bottom report reads it: the view runs bottom
  /// to top, so the end of the timeline is at the smallest offset.
  void _measureBottom(ScrollMetrics metrics) {
    if (widget.messages.isEmpty) return;
    _tellBottom(
      _bottom.layout(
        (metrics.pixels - metrics.minScrollExtent).clamp(0, double.infinity),
      ),
    );
  }

  /// Reads where the list is once the frame being built is laid out: the first
  /// layout, a window placed at its newest row, rows added or removed. An empty
  /// list is at its bottom.
  void _measureBottomAfterFrame() {
    if (_bottomMeasureScheduled) return;
    _bottomMeasureScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _bottomMeasureScheduled = false;
      if (!mounted) return;
      if (widget.messages.isEmpty) {
        _tellBottom(_bottom.emptied());
        return;
      }
      final controller = _laidOutController ?? _controller;
      if (!controller.hasClients) return;
      final position = controller.position;
      if (!position.hasContentDimensions || !position.hasPixels) return;
      _measureBottom(position);
      _fill(position);
    });
  }

  FlareMessageListController get _handle => widget.controller ?? _ownedHandle;
  ScrollController get _controller => _handle.scroll;

  List<FlareMessageData>? _indexedMessages;
  Map<String, int> _indexById = const {};

  /// Row index by message id, rebuilt when the host hands over a new list.
  Map<String, int> get _indexes {
    if (!identical(_indexedMessages, widget.messages)) {
      _indexedMessages = widget.messages;
      _indexById = {
        for (var i = 0; i < widget.messages.length; i++)
          widget.messages[i].id: i,
      };
    }
    return _indexById;
  }

  List<FlareMessageData>? _locatableMessages;
  Map<String, int> _locatableById = const {};

  /// Row index by every id a row answers to: its own [FlareMessageData.id] and
  /// the core id it was drawn from ([FlareMessageData.serverId]), which differ
  /// for a message this device sent. One rule for the two readers that need
  /// it — a tapped quote, which names its message by the core's id, and
  /// [FlareMessageListController.scrollToMessage], which is handed that same
  /// id back. A row's own id outranks another row's core id.
  Map<String, int> get _locatable {
    if (!identical(_locatableMessages, widget.messages)) {
      _locatableMessages = widget.messages;
      final byRowId = _indexes;
      final byCoreId = <String, int>{};
      for (var i = 0; i < widget.messages.length; i++) {
        final coreId = widget.messages[i].serverId;
        if (coreId != null &&
            coreId.isNotEmpty &&
            !byRowId.containsKey(coreId)) {
          byCoreId[coreId] = i;
        }
      }
      _locatableById = byCoreId.isEmpty ? byRowId : (byCoreId..addAll(byRowId));
    }
    return _locatableById;
  }

  List<FlareMessageData>? _timelineMessages;
  String? _timelineUnreadId;
  String? _timelineUserId;
  int _timelineDependencies = -1;

  /// Bumped when an inherited dependency (the content scope's surfaces)
  /// changes: the surfaces are read again.
  int _dependencies = 0;

  /// The surface of each row, as grouping and the bubbles read it.
  List<FlareMessageSurface> _surfaces = const [];
  List<FlareTimelineItem> _items = const [];

  /// Rows that open a local calendar day.
  Set<int> _dayStarts = const {};
  Set<int> _breaksBefore = const {};
  int _unreadIndex = -1;
  int _unreadCount = 0;

  /// Surfaces, day starts and the unread row, recomputed only when the host
  /// hands over a new list (`spec/message-grouping-vectors.json`): one
  /// numeric calendar comparison per message, no formatting.
  void _indexTimeline() {
    final messages = widget.messages;
    if (identical(_timelineMessages, messages) &&
        _timelineUnreadId == widget.unreadFromId &&
        _timelineUserId == widget.currentUserId &&
        _timelineDependencies == _dependencies) {
      return;
    }
    _timelineMessages = messages;
    _timelineUnreadId = widget.unreadFromId;
    _timelineUserId = widget.currentUserId;
    _timelineDependencies = _dependencies;
    _surfaces = [
      for (final message in messages)
        FlareContentScope.surfaceOf(context, message),
    ];
    _items = [
      for (var i = 0; i < messages.length; i++)
        FlareTimelineItem.of(messages[i], _surfaces[i]),
    ];
    final layout = flareTimelineLayout(
      _items,
      currentUserId: widget.currentUserId,
      unreadFromId: widget.unreadFromId,
    );
    _dayStarts = layout.dayStarts;
    _breaksBefore = layout.breaksBefore;
    _unreadIndex = layout.unreadIndex;
    _unreadCount = layout.unreadCount;
  }

  String _dayLabel(FlareMessageData message) {
    final strings = FlareStrings.of(context);
    return FlareTimeFormat.timelineDate(
      DateTime.fromMillisecondsSinceEpoch(message.sentAtMs),
      today: strings.today,
      yesterday: strings.yesterday,
      locale:
          widget.locale ??
          Localizations.maybeLocaleOf(context)?.toLanguageTag() ??
          SchedulerBinding.instance.platformDispatcher.locale.toLanguageTag(),
    );
  }

  void _locate(String id) {
    final index = _locatable[id];
    if (index == null) {
      widget.onLocateMessage?.call(id);
    } else {
      _scrollToRow(index);
    }
  }

  /// Brings a loaded row into view. Rows are built lazily, so a row outside
  /// the built window is first approached by jumping over the rows in between,
  /// estimated from the heights of the rows that are built.
  Future<void> _scrollToRow(int index) async {
    if (index >= widget.messages.length) return;
    final id = widget.messages[index].id;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    for (var attempt = 0; attempt < 12 && mounted; attempt++) {
      final row = _rowKeys[id]?.currentContext;
      if (row != null) {
        _markLocated(id);
        _locatedHoldId = id;
        _tellBottom(_bottom.located());
        await Scrollable.ensureVisible(
          row,
          alignment: 0.5,
          duration: reduceMotion ? Duration.zero : FlareMotion.slow,
          curve: FlareMotion.slowCurve,
        );
        return;
      }
      final built = _builtRows();
      if (built.isEmpty || !_controller.hasClients) return;
      final nearest = index < built.first.index ? built.first : built.last;
      final rowExtent =
          built.fold(0.0, (sum, row) => sum + row.height) / built.length;
      final position = _controller.position;
      // The view runs bottom to top: older rows are at larger offsets.
      position.jumpTo(
        (position.pixels + (nearest.index - index) * rowExtent).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        ),
      );
      await WidgetsBinding.instance.endOfFrame;
    }
  }

  /// Starts the window on [id]. A second jump inside a running window moves the
  /// mark rather than adding one, which is why the clock is restarted from zero
  /// and the previous row simply stops being the marked one.
  void _markLocated(String id) {
    _announceLocated(id);
    setState(() => _locatedId = id);
    _locateClock.forward(from: 0).whenCompleteOrCancel(() {
      if (mounted && _locatedId == id) setState(() => _locatedId = null);
    });
  }

  /// What a screen reader is told when a jump lands. The ring tells everyone else; a reader who cannot
  /// see it gets the same fact in words — which row, and what it says — from the one summary a reply
  /// strip would show, so the message reads the same wherever it is named.
  void _announceLocated(String id) {
    final message = widget.messages.where((m) => m.id == id).firstOrNull;
    if (message == null || !mounted) return;
    SemanticsService.sendAnnouncement(
      View.of(context),
      flareLocatedAnnouncement(message, FlareStrings.of(context)),
      Directionality.of(context),
    );
  }

  List<({int index, double height})> _builtRows() {
    final rows = <({int index, double height})>[];
    for (final entry in _rowKeys.entries) {
      final box = entry.value.currentContext?.findRenderObject();
      final index = _indexes[entry.key];
      if (box is! RenderBox || !box.hasSize || index == null) continue;
      rows.add((index: index, height: box.size.height));
    }
    return rows..sort((a, b) => a.index.compareTo(b.index));
  }

  /// Messages [next] adds after the newest message of [previous]; none when
  /// that message is gone.
  static int _appendedCount(
    List<FlareMessageData> previous,
    List<FlareMessageData> next,
  ) {
    final newest = previous.lastOrNull?.id;
    if (newest == null) return next.length;
    for (var i = next.length - 1; i >= 0; i--) {
      if (next[i].id == newest) return next.length - 1 - i;
    }
    return 0;
  }

  /// The controller the scroll view was laid out with: during an update that
  /// swaps controllers the new one attaches after this state, and takes the
  /// old position's offset over.
  ScrollController? _laidOutController;

  /// Moves the scroll offset to [pixels] before the next layout, without a
  /// scroll notification: a running fling or drag carries on from there.
  void _correctPixels(double pixels) {
    final controller = _laidOutController ?? _controller;
    if (!controller.hasClients) return;
    final position = controller.position;
    if (!position.hasPixels) return;
    final delta = pixels - position.pixels;
    if (delta.abs() > 0.01) position.correctBy(delta);
    // An update that changes no row may skip layout; the new offset needs one.
    _centerKey.currentContext?.findRenderObject()?.markNeedsLayout();
  }

  /// Every row in the center sliver at offset 0: the newest message at the
  /// bottom.
  void _showNewest() {
    _pivotId = null;
    _locatedHoldId = null;
    _followTail = true;
    _browseTailId = null;
    _correctPixels(0);
  }

  /// A reader who scrolled up keeps the top row in view where it is: it becomes
  /// the pivot, so rows added or resized above it grow upwards and rows below
  /// it grow downwards. The pivot's top edge is the center, drawn at viewport
  /// height + offset from the top.
  void _keepReaderInPlace(Set<String> surviving) {
    if (_keepLocatedRow(surviving)) return;
    final viewport = _viewportKey.currentContext?.findRenderObject();
    final anchor = _visibleAnchor(surviving);
    if (anchor == null || viewport is! RenderBox || !viewport.hasSize) {
      if (_pivotId != null && !surviving.contains(_pivotId)) _pivotId = null;
      return;
    }
    _pivotId = anchor.id;
    _correctPixels(anchor.offset - viewport.size.height);
  }

  /// Under a locate the located row is what stays (`locateAfterReplace`): it
  /// becomes the pivot, so rows added above it grow upwards from it, and once
  /// this frame is laid out the scroll that was taking the reader there ends at
  /// once, with the row in the middle where the locate puts it — that scroll
  /// aimed at an offset measured before the rows changed. False when there is
  /// no located row, or it is gone.
  bool _keepLocatedRow(Set<String> surviving) {
    final id = _locatedHoldId;
    if (id == null || !surviving.contains(id)) return false;
    final viewport = _viewportKey.currentContext?.findRenderObject();
    final anchor = _visibleAnchor(surviving, only: id);
    if (anchor != null && viewport is RenderBox && viewport.hasSize) {
      _pivotId = id;
      _correctPixels(anchor.offset - viewport.size.height);
    }
    SchedulerBinding.instance.addPostFrameCallback((_) {
      final row = _rowKeys[id]?.currentContext;
      if (!mounted || _locatedHoldId != id || row == null) return;
      unawaited(
        Scrollable.ensureVisible(row, alignment: 0.5, duration: Duration.zero),
      );
    });
    return true;
  }

  /// The reader's scrolling decides whether new messages keep them at the
  /// bottom; leaving it starts the count of messages below.
  void _syncFollow(ScrollMetrics metrics) {
    if (!_trackScroll) return;
    // The bottom of a detached window is not the latest message: nothing
    // arrives there to follow.
    final atBottom =
        metrics.pixels <= metrics.minScrollExtent + _bottomSlop &&
        !widget.hasNewer;
    if (atBottom == _followTail) return;
    void apply() {
      if (!mounted) return;
      setState(() {
        _followTail = atBottom;
        _browseTailId = atBottom ? null : widget.messages.lastOrNull?.id;
      });
    }

    // A layout-time notification waits for the frame to finish.
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => apply());
    } else {
      apply();
    }
  }

  /// [FlareScrollToLatest]: straight to the newest message, without animation.
  void _goToNewest() {
    _tellBottom(_bottom.wentToLatest());
    setState(() {
      _pivotId = null;
      _locatedHoldId = null;
      _followTail = true;
      _browseTailId = null;
    });
    if (!_controller.hasClients) return;
    _trackScroll = false;
    try {
      _controller.jumpTo(0);
    } finally {
      _trackScroll = true;
    }
  }

  /// Messages that arrived below a reader who scrolled up.
  int get _newBelow {
    final tail = _browseTailId;
    if (_followTail || tail == null) return 0;
    final index = _indexes[tail];
    return index == null ? 0 : widget.messages.length - 1 - index;
  }

  @override
  void initState() {
    super.initState();
    _detachedSinceRows = widget.hasNewer;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _dependencies += 1;
    // Tickers stop when another screen covers this one: so does voice.
    final onScreen = TickerMode.valuesOf(context).enabled;
    if (_onScreen && !onScreen) unawaited(_media.stopVoice());
    _onScreen = onScreen;
  }

  @override
  void didUpdateWidget(FlareMessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    _laidOutController = (oldWidget.controller ?? _ownedHandle).scroll;
    // A handle the list no longer answers for reports no rows again.
    if (!identical(oldWidget.controller, widget.controller))
      oldWidget.controller?._detach(this);
    if (!identical(oldWidget.mediaController, widget.mediaController)) {
      final previous = oldWidget.mediaController ?? _ownMedia;
      if (previous != null) unawaited(previous.stopVoice());
      if (widget.mediaController != null) {
        _ownMedia?.dispose();
        _ownMedia = null;
      }
    }
    final surviving = widget.messages.map((m) => m.id).toSet();
    if (widget.hasNewer) _detachedSinceRows = true;
    if (oldWidget.conversationId != widget.conversationId) {
      // Another conversation: the voice message playing belonged to the last.
      unawaited(_media.stopVoice());
      _requested = false;
      _requestedNewer = false;
      _jumpRequested = false;
      _locatedHoldId = null;
      _pagingHeld = false;
      _fillAskedFor = null;
      _detachedSinceRows = widget.hasNewer;
      _bottom.anotherConversation();
      _showNewest();
    } else if (_replaced(oldWidget)) {
      // A new window (`windows`), and the latest one the reader asked for is
      // one: it opens at its newest message, wherever the old window was, and
      // nothing of the reader's place in the old one applies. The reader is
      // not at the bottom of a window they did not ask for until they move it.
      _tellBottom(
        _jumpRequested && !widget.hasNewer
            ? _bottom.jumpedToLatest()
            : _bottom.replaced(),
      );
      _jumpRequested = false;
      _locatedHoldId = null;
      _pagingHeld = true;
      _requested = false;
      _requestedNewer = false;
      _detachedSinceRows = widget.hasNewer;
      _showNewest();
      // The bottom of a detached window is not the latest message: nothing
      // arrives there to follow.
      if (widget.hasNewer) {
        _followTail = false;
        _browseTailId = widget.messages.lastOrNull?.id;
      }
    } else if (oldWidget.messages != widget.messages) {
      final wasDetached = _detachedSinceRows;
      _detachedSinceRows = widget.hasNewer;
      final appended = _appendedCount(oldWidget.messages, widget.messages);
      final ownNewest =
          appended > 0 && widget.messages.last.senderId == widget.currentUserId;
      if (flareMessageListNewerPage(
        [for (final m in oldWidget.messages) m.id],
        [for (final m in widget.messages) m.id],
        wasDetached: wasDetached,
      )) {
        // A newer page read into a detached window grows under the reader,
        // who stays on the rows they are reading even when it ends in one of
        // their own messages; what arrives later is counted from its last row.
        _keepReaderInPlace(surviving);
        _followTail = false;
        _browseTailId = widget.messages.last.id;
      } else if (oldWidget.messages.isEmpty || _followTail || ownNewest) {
        // A message of the reader's own takes them to the newest row: the
        // reader arriving there.
        if (ownNewest) _tellBottom(_bottom.wentToLatest());
        _showNewest();
        if (widget.hasNewer) {
          _followTail = false;
          _browseTailId = widget.messages.lastOrNull?.id;
        }
      } else {
        _keepReaderInPlace(surviving);
      }
    }
    // An attached window answers the jump the reader asked for, whatever it
    // brought.
    if (!widget.hasNewer) _jumpRequested = false;
    _rowKeys.removeWhere((id, _) => !surviving.contains(id));
    _publishDownloadStates();
    _openPendingSheet();
    _refreshPointerMenu();
    if (oldWidget.loadingOlder && !widget.loadingOlder ||
        oldWidget.messages.firstOrNull?.id != widget.messages.firstOrNull?.id ||
        oldWidget.olderError != widget.olderError)
      _requested = false;
    if (oldWidget.loadingNewer && !widget.loadingNewer ||
        oldWidget.messages.lastOrNull?.id != widget.messages.lastOrNull?.id ||
        oldWidget.newerError != widget.newerError)
      _requestedNewer = false;
  }

  /// Whether this update hands the list a new window
  /// ([flareMessageListWindowReplaced]).
  bool _replaced(FlareMessageList oldWidget) {
    final jump = _jumpRequested && !widget.hasNewer;
    if (!jump &&
        identical(oldWidget.messages, widget.messages) &&
        oldWidget.windowId == widget.windowId) {
      return false;
    }
    return flareMessageListWindowReplaced(
      [for (final m in oldWidget.messages) m.id],
      [for (final m in widget.messages) m.id],
      jumpRequested: _jumpRequested,
      hasNewer: widget.hasNewer,
      previousWindowId: oldWidget.windowId,
      windowId: widget.windowId,
    );
  }

  /// Ids of rows that came on screen this frame, handed to the host's
  /// prefetch together after the frame.
  final Set<String> _prefetchQueue = {};
  bool _prefetchScheduled = false;

  /// A long press that found no snapshot: the sheet opens when the host's
  /// snapshot for this row arrives, if it does soon.
  ({String id, DateTime at})? _pendingSheet;
  static const _pendingSheetWindow = Duration(seconds: 5);

  void _requestPrefetch(String id) {
    _prefetchQueue.add(id);
    if (_prefetchScheduled) return;
    _prefetchScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _prefetchScheduled = false;
      if (!mounted || _prefetchQueue.isEmpty) return;
      final ids = _prefetchQueue.toList();
      _prefetchQueue.clear();
      widget.menu?.prefetch?.call(ids);
    });
  }

  /// The long-press sheet, from the menu source's entries.
  void _openMenuSheet(FlareMessageData message) {
    final menu = widget.menu;
    if (menu == null) return;
    final availability = menu.availability(message);
    if (availability == null) {
      // The host reads, then the sheet opens (didUpdateWidget).
      _pendingSheet = (id: message.id, at: DateTime.now());
      menu.prefetch?.call([message.id]);
      return;
    }
    _pendingSheet = null;
    unawaited(_showMenuSheet(menu, message, availability));
  }

  Future<void> _showMenuSheet(
    FlareMessageMenuSource menu,
    FlareMessageData message,
    FlareMessageActionAvailability availability,
  ) async {
    final selection = await FlareMessageActionSheet.show(
      context,
      availability: availability,
      content: message.content,
      hiddenActions: menu.hiddenActions,
      actions: menu.extraActionsFor(message),
    );
    if (selection == null || !mounted) return;
    final actionId = selection.actionId;
    final reaction = selection.reaction;
    if (actionId != null) {
      widget.menu?.perform(message, actionId);
    } else if (reaction != null) {
      widget.onReact?.call(message, reaction);
    }
  }

  /// The items of the open pointer menu, and the message it is open for: the
  /// host's snapshot can arrive or change while the menu is open, and the menu
  /// follows it in place (see [_refreshPointerMenu]).
  final ValueNotifier<List<FlareActionItem>> _pointerItems = ValueNotifier(
    const [],
  );
  FlareMessageData? _pointerMessage;

  /// Whether the open pointer menu has asked the host for its message's
  /// snapshot since it last showed entries: it asks once each time it is left
  /// without one, and not again on every rebuild that still finds none.
  bool _pointerAsked = false;

  /// The pointer menu where the secondary click landed: the same entries as
  /// the sheet, or one disabled "loading" entry while there is no snapshot.
  void _openPointerMenu(FlareMessageData message, Offset position) {
    final menu = widget.menu;
    if (menu == null) return;
    final strings = FlareStrings.of(context);
    final entries = menu.entriesFor(message, strings);
    if (entries == null) menu.prefetch?.call([message.id]);
    final items = flareMessagePointerMenuItems(entries, strings);
    _pointerMessage = message;
    _pointerAsked = entries == null;
    _pointerItems.value = items;
    unawaited(
      FlareActionMenu.show(
        context,
        label: strings.messageActionSheetLabel,
        anchor: Rect.fromLTWH(position.dx, position.dy, 0, 0),
        presentation: FlareActionMenuPresentation.anchored,
        items: items,
        updates: _pointerItems,
      ).then((picked) {
        // The message as the menu last drew it: the host may have replaced it.
        final current = _pointerMessage ?? message;
        if (_pointerMessage?.id == message.id) {
          _pointerMessage = null;
          _pointerAsked = false;
        }
        if (picked == null ||
            picked == FlareMessageMenuSource.loadingEntryId ||
            !mounted) {
          return;
        }
        widget.menu?.perform(current, picked);
      }),
    );
  }

  /// The open pointer menu follows the host: when the snapshot of its message
  /// arrives or changes, its items become that snapshot's entries in place
  /// (the loading entry gives way to the entries; an action the core no longer
  /// allows leaves; a host entry it disables is drawn disabled), without
  /// closing or moving the menu.
  ///
  /// When the host drops that snapshot while the menu is open (the message
  /// moved, or the snapshot grew old), the menu shows the loading entry and the
  /// list asks the host for the message again — once, until a snapshot is
  /// back; the host only drops snapshots and answers prefetch.
  void _refreshPointerMenu() {
    final open = _pointerMessage;
    final menu = widget.menu;
    if (open == null || menu == null) return;
    final listed = widget.messages.where((m) => m.id == open.id).firstOrNull;
    final message = listed ?? open;
    _pointerMessage = message;
    final strings = FlareStrings.of(context);
    final entries = menu.entriesFor(message, strings);
    if (entries != null) {
      _pointerAsked = false;
    } else if (!_pointerAsked && listed != null) {
      _pointerAsked = true;
      _requestPrefetch(message.id);
    }
    final items = flareMessagePointerMenuItems(entries, strings);
    if (listEquals(items, _pointerItems.value)) return;
    // The menu is a route of its own, outside this subtree: it rebuilds on the
    // next frame rather than in the middle of this one.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted && _pointerMessage?.id == open.id) {
        _pointerItems.value = items;
      }
    });
  }

  /// Opens the sheet a long press asked for once its snapshot is there.
  void _openPendingSheet() {
    final pending = _pendingSheet;
    final menu = widget.menu;
    if (pending == null || menu == null) return;
    if (DateTime.now().difference(pending.at) > _pendingSheetWindow) {
      _pendingSheet = null;
      return;
    }
    final message = widget.messages
        .where((m) => m.id == pending.id)
        .firstOrNull;
    if (message == null) {
      _pendingSheet = null;
      return;
    }
    final availability = menu.availability(message);
    if (availability == null) return;
    _pendingSheet = null;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_showMenuSheet(menu, message, availability));
    });
  }

  @override
  void dispose() {
    _locateClock.dispose();
    _handle._detach(this);
    _ownedHandle.dispose();
    // Leaving the thread stops its voice message; a host controller outlives
    // the list, the list's own does not.
    final hostMedia = widget.mediaController;
    if (hostMedia != null) unawaited(hostMedia.stopVoice());
    _ownMedia?.dispose();
    _downloadStates.dispose();
    _pointerItems.dispose();
    super.dispose();
  }

  /// The two ends of the window (`spec/message-list-paging-vectors.json`):
  /// one rule above and below the timeline.
  FlareMessageListEnd get _olderEnd => FlareMessageListEnd(
    has: widget.hasOlder,
    loading: widget.loadingOlder,
    error: widget.olderError,
    handled: widget.onLoadOlder != null,
  );
  FlareMessageListEnd get _newerEnd => FlareMessageListEnd(
    has: widget.hasNewer,
    loading: widget.loadingNewer,
    error: widget.newerError,
    handled: widget.onLoadNewer != null,
  );

  void _requestOlder({bool retry = false}) {
    if (_requested ||
        widget.loadingOlder ||
        !widget.hasOlder ||
        widget.onLoadOlder == null ||
        (!retry && _olderEnd.failed))
      return;
    setState(() => _requested = true);
    widget.onLoadOlder!();
  }

  /// Rows read in below the window grow under the reader, so nothing has to
  /// be anchored first.
  void _requestNewer({bool retry = false}) {
    if (_requestedNewer ||
        widget.loadingNewer ||
        !widget.hasNewer ||
        widget.onLoadNewer == null ||
        (!retry && _newerEnd.failed))
      return;
    setState(() => _requestedNewer = true);
    widget.onLoadNewer!();
  }

  /// Pages are asked for within the shared distance of either edge while the
  /// reader drags. The view runs bottom to top, so the top is the far end.
  void _askForPages(ScrollMetrics metrics) {
    final wanted = flareMessageListRequests(
      fromTop: (metrics.maxScrollExtent - metrics.pixels).clamp(
        0,
        double.infinity,
      ),
      fromBottom: (metrics.pixels - metrics.minScrollExtent).clamp(
        0,
        double.infinity,
      ),
      older: _olderEnd,
      newer: _newerEnd,
    );
    if (wanted.older) _requestOlder();
    if (wanted.newer) _requestNewer();
  }

  /// A window that fits the viewport or barely overflows it cannot be dragged
  /// far enough to ask for a page (one that fits does not scroll at all under
  /// clamping physics), so it asks by itself until it overflows or there is
  /// nothing more (`fill`). Read after a layout, never during one.
  void _fill(ScrollMetrics metrics) {
    if (_pagingHeld ||
        widget.messages.isEmpty ||
        metrics.viewportDimension <= 0) {
      return;
    }
    final overflow = (metrics.maxScrollExtent - metrics.minScrollExtent).clamp(
      0.0,
      double.infinity,
    );
    final fromTop = (metrics.maxScrollExtent - metrics.pixels).clamp(
      0.0,
      overflow,
    );
    final fromBottom = overflow - fromTop;
    if (!flareMessageListFillsViewport(
      fromTop: fromTop,
      fromBottom: fromBottom,
    )) {
      return;
    }
    final wanted = flareMessageListRequests(
      fromTop: fromTop,
      fromBottom: fromBottom,
      older: _olderEnd,
      newer: _newerEnd,
    );
    if (!wanted.older && !wanted.newer) return;
    final shown =
        '${widget.messages.first.id}|${widget.messages.last.id}|${overflow.round()}';
    if (shown == _fillAskedFor) return;
    _fillAskedFor = shown;
    if (wanted.older) _requestOlder();
    if (wanted.newer) _requestNewer();
  }

  /// The floating key: back to the latest messages for a detached window,
  /// else straight to the newest message.
  void _onLatestKey(FlareMessageListLatestAction? action) {
    if (action == FlareMessageListLatestAction.jumpToLatest) {
      _jumpRequested = true;
      widget.onJumpToLatest?.call();
    } else {
      _goToNewest();
    }
  }

  /// One end of the window: the spinner while a page loads, else the error and
  /// the load or retry button.
  Widget _endBand(
    FlareMessageListEdge edge, {
    required String? error,
    required String label,
    required bool requested,
    required VoidCallback load,
    required FlareColors colors,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          if (edge.error && error != null)
            Text(error, style: TextStyle(color: colors.textPrimary)),
          if (edge.spinner)
            const SizedBox(
              height: 48,
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else if (edge.button)
            TextButton(
              onPressed: requested ? null : load,
              style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
              child: Text(label),
            ),
        ],
      ),
    );
  }

  Widget _emptyWindow() {
    if (widget.loading || widget.loadingOlder || widget.loadingNewer) {
      return const CircularProgressIndicator();
    }
    if (widget.emptyPlaceholder case final placeholder?) {
      return placeholder;
    }
    if (!widget.hasOlder &&
        !widget.hasNewer &&
        widget.olderError == null &&
        widget.newerError == null) {
      return _Empty(_emptyText);
    }

    // A window with more history has not proved that this conversation is
    // empty. Keep the failure recoverable without automatically requesting it.
    final strings = FlareStrings.of(context);
    final older = widget.hasOlder;
    final handled = older
        ? widget.onLoadOlder != null
        : widget.hasNewer && widget.onLoadNewer != null;
    final requested = older ? _requested : _requestedNewer;
    return FlareEmptyState(
      title:
          widget.olderError ??
          widget.newerError ??
          strings.conversationWorkspaceChatFailure,
      tone: FlareEmptyStateTone.error,
      actionText: handled ? strings.retry : null,
      onAction: !handled || requested
          ? null
          : () =>
                older ? _requestOlder(retry: true) : _requestNewer(retry: true),
    );
  }

  Widget _message(int i) {
    _indexTimeline();
    final msg = widget.messages[i];
    final quotedId = msg.replyTo?.messageId;
    final surface = _surfaces[i];
    final groupPosition = flareMessageGroupPosition(
      _items,
      i,
      breaksBefore: _breaksBefore,
    );
    final presentation = flareMessageRowPresentation(
      item: _items[i],
      position: groupPosition,
      currentUserId: widget.currentUserId,
      groupConversation: widget.conversationKind == FlareConversationKind.group,
      showIncomingAvatar: widget.showIncomingAvatar,
      showSelfAvatar: widget.showSelfAvatar,
      showGroupSenderName: widget.showGroupSenderName,
    );
    Widget bubble = FlareMessageBubble(
      message: msg,
      currentUserId: widget.currentUserId,
      conversationKind: widget.conversationKind,
      conversationId: widget.conversationId,
      groupPosition: groupPosition,
      rowPresentation: presentation,
      surface: surface,
      locale: widget.locale,
      multiSelectMode: widget.multiSelectMode,
      selected: widget.selectedIds.contains(msg.id),
      mediaState: widget.mediaDownloadStates[msg.id],
      onLongPress: widget.menu == null
          ? widget.onMessageLongPress
          : _openMenuSheet,
      onContextMenu: widget.menu == null ? null : _openPointerMenu,
      onAvatarTap: widget.onAvatarTap,
      onMediaAction: widget.onMediaAction,
      onOpenFile: widget.onOpenFile,
      onOpenLink: widget.onOpenLink,
      onMediaDownload: widget.onMediaDownload,
      onMediaReveal: widget.onMediaReveal,
      onVote: widget.onVote,
      onTaskToggle: widget.onTaskToggle,
      onCardOpen: widget.onCardOpen,
      onLocationOpen: widget.onLocationOpen,
      onResend: widget.onResend,
      onToggleSelect: widget.onToggleSelect,
      onReact: widget.onReact,
      onReply: widget.onReply ?? widget.onSwipeReply,
      onReadReceiptOpen: widget.onReadReceiptOpen,
      // Loaded quotes scroll here; others go to the host when it can load them.
      onLocateMessage:
          quotedId != null &&
              (widget.onLocateMessage != null ||
                  _locatable.containsKey(quotedId))
          ? _locate
          : null,
    );
    // Notices (system lines, recalled messages) carry no message actions; the
    // bubble itself wires no long-press for them.
    if (widget.onSwipeReply != null &&
        !widget.multiSelectMode &&
        surface != FlareMessageSurface.centered) {
      bubble = _SwipeReplyRow(
        key: ValueKey('swipe-reply-${msg.id}'),
        onReply: () => widget.onSwipeReply!(msg),
        child: bubble,
      );
    }
    // The day comes first, then where the unread messages start inside it.
    // Both belong to the message's row, so a row stays one message for
    // scrolling and anchoring.
    if (widget.menu?.prefetch != null &&
        surface != FlareMessageSurface.centered) {
      bubble = _OnScreen(
        onMounted: () => _requestPrefetch(msg.id),
        child: bubble,
      );
    }
    return KeyedSubtree(
      key: ValueKey(msg.id),
      child: SizedBox(
        key: _rowKeys.putIfAbsent(msg.id, GlobalKey.new),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_dayStarts.contains(i))
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: FlareSizes.spacingXs,
                ),
                child: FlareDatePill(label: _dayLabel(msg)),
              ),
            if (i == _unreadIndex) FlareUnreadDivider(count: _unreadCount),
            KeyedSubtree(key: const ValueKey('bubble'), child: bubble),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    _indexTimeline();
    // The rows a host handle answers for are this build's rows.
    _handle._attach(this, _locatable);
    _measureBottomAfterFrame();
    final pivot = _pivotId == null ? null : _indexes[_pivotId];
    final split = pivot ?? widget.messages.length;
    final before = [for (var i = split - 1; i >= 0; i--) widget.messages[i].id];
    final after = widget.messages.skip(split).map((m) => m.id).toList();
    final newBelow = _newBelow;
    final emptyWindow = widget.messages.isEmpty;
    final olderEdge = flareMessageListEdge(_olderEnd);
    final newerEdge = flareMessageListEdge(_newerEnd);
    final latest = flareMessageListLatestEntry(
      hasNewer: widget.hasNewer,
      handled: widget.onJumpToLatest != null,
      belowCount: newBelow,
    );
    return FlareLocateHighlightScope(
      messageId: _locatedId,
      elapsedMs: _locateElapsed,
      reduceMotion: MediaQuery.maybeDisableAnimationsOf(context) ?? false,
      child: FlareMediaScope(
        controller: _media,
        downloadStates: _downloadStates,
        child: FlareImageGalleryScope(
          items: _gallery(),
          download: widget.onMediaDownload == null
              ? null
              : _downloadGalleryPicture,
          reveal: widget.onMediaReveal == null ? null : _revealGalleryPicture,
          downloadStateOf: _galleryPictureState,
          child: ColoredBox(
            color: colors.bgSecondary,
            child: Column(
              children: [
                if (olderEdge.visible && !emptyWindow)
                  _endBand(
                    olderEdge,
                    error: widget.olderError,
                    label: _loadOlderText,
                    requested: _requested,
                    load: () => _requestOlder(retry: true),
                    colors: colors,
                  ),
                Expanded(
                  child: widget.messages.isEmpty
                      ? Center(child: _emptyWindow())
                      : Stack(
                          children: [
                            Positioned.fill(
                              child: Align(
                                alignment: Alignment.topCenter,
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: FlareSizes
                                        .messageTimelineContentMaxWidth,
                                  ),
                                  child: NotificationListener<Notification>(
                                    onNotification: (n) {
                                      // Content that grew or shrank without a
                                      // scroll moves the end of the timeline.
                                      if (n is ScrollMetricsNotification) {
                                        if (n.depth == 0) {
                                          _measureBottom(n.metrics);
                                          _fill(n.metrics);
                                        }
                                        return false;
                                      }
                                      if (n is! ScrollNotification ||
                                          n.depth != 0)
                                        return false;
                                      // The reader's own drag: the place is
                                      // theirs again, not the located row's.
                                      if (n is ScrollStartNotification &&
                                          n.dragDetails != null) {
                                        _locatedHoldId = null;
                                        _pagingHeld = false;
                                      }
                                      // The reader scrolling the list (a drag or
                                      // a wheel) ends a hold on the answer.
                                      if (n is UserScrollNotification &&
                                          n.direction != ScrollDirection.idle) {
                                        _pagingHeld = false;
                                        _tellBottom(_bottom.readerMoved());
                                      }
                                      if (n is ScrollUpdateNotification) {
                                        if (n.dragDetails != null)
                                          _askForPages(n.metrics);
                                        _syncFollow(n.metrics);
                                        _measureBottom(n.metrics);
                                      } else if (n is ScrollEndNotification) {
                                        _syncFollow(n.metrics);
                                        _measureBottom(n.metrics);
                                      }
                                      return false;
                                    },
                                    child: LayoutBuilder(
                                      builder: (context, constraints) {
                                        final height = constraints.maxHeight;
                                        final previous = _viewportHeight;
                                        _viewportHeight = height;
                                        // The center is at the bottom, so a reader at
                                        // the newest message stays there by itself; a
                                        // reader who scrolled up keeps the top rows.
                                        if (previous != null &&
                                            previous != height &&
                                            !_followTail &&
                                            _controller.hasClients &&
                                            _controller.position.hasPixels) {
                                          _controller.position.correctBy(
                                            previous - height,
                                          );
                                        }
                                        final footerOffset =
                                            widget.footer == null ? 0 : 1;
                                        return CustomScrollView(
                                          key: _viewportKey,
                                          controller: _controller,
                                          reverse: true,
                                          center: _centerKey,
                                          slivers: [
                                            // The pivot and newer rows, below the
                                            // center: they grow downwards, so rows
                                            // added here never shift the rows above.
                                            SliverList(
                                              delegate:
                                                  SliverChildBuilderDelegate(
                                                    (context, i) =>
                                                        _message(split + i),
                                                    childCount: after.length,
                                                    findChildIndexCallback:
                                                        (key) {
                                                          final i = after.indexOf(
                                                            (key
                                                                    as ValueKey<
                                                                      String
                                                                    >)
                                                                .value,
                                                          );
                                                          return i < 0
                                                              ? null
                                                              : i;
                                                        },
                                                  ),
                                            ),
                                            // Older rows grow upwards from the
                                            // center: their measured heights never
                                            // shift the rows below them.
                                            //
                                            // The `footer` slot is item 0 of this sliver rather than a
                                            // sliver of its own: everything before the centre sits at a
                                            // negative scroll offset, which this viewport is anchored past,
                                            // so a footer put there is laid out and never seen. Item 0 of
                                            // the centre is the bottom-most row, which is where "under the
                                            // newest message" actually is.
                                            SliverList(
                                              key: _centerKey,
                                              delegate: SliverChildBuilderDelegate(
                                                (context, i) =>
                                                    footerOffset == 1 && i == 0
                                                    ? widget.footer!
                                                    : _message(
                                                        split -
                                                            1 -
                                                            (i - footerOffset),
                                                      ),
                                                childCount:
                                                    before.length +
                                                    footerOffset,
                                                findChildIndexCallback: (key) {
                                                  final i = before.indexOf(
                                                    (key as ValueKey<String>)
                                                        .value,
                                                  );
                                                  return i < 0
                                                      ? null
                                                      : i + footerOffset;
                                                },
                                              ),
                                            ),
                                          ],
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (latest.shown)
                              PositionedDirectional(
                                end: FlareSizes.spacingMd,
                                bottom: FlareSizes.spacingMd,
                                child: FlareScrollToLatest(
                                  count: latest.count,
                                  onTap: () => _onLatestKey(latest.action),
                                ),
                              ),
                          ],
                        ),
                ),
                if (newerEdge.visible && !emptyWindow)
                  _endBand(
                    newerEdge,
                    error: widget.newerError,
                    label: FlareStrings.of(context).messageListLoadNewer,
                    requested: _requestedNewer,
                    load: () => _requestNewer(retry: true),
                    colors: colors,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<FlareImageGalleryItem>? _galleryItems;
  List<FlareMessageData>? _galleryMessages;

  /// Saves a picture of the gallery with the message it belongs to.
  void _downloadGalleryPicture(FlareImageGalleryItem item) {
    final download = widget.onMediaDownload;
    final message = _galleryMessage(item);
    if (download != null && message != null) download(message, item.image);
  }

  /// Shows a saved picture of the gallery in its folder.
  void _revealGalleryPicture(FlareImageGalleryItem item) {
    final reveal = widget.onMediaReveal;
    final message = _galleryMessage(item);
    if (reveal != null && message != null) reveal(message, item.image);
  }

  /// The live download state of a gallery picture: an image message's own.
  /// An album's pictures share one message, so a state for it cannot say which
  /// picture is saved; they keep the plain download key.
  ValueListenable<FlareMediaDownloadState?>? _galleryPictureState(
    FlareImageGalleryItem item,
  ) {
    final message = _galleryMessage(item);
    if (message == null || message.content is! FlareImageContent) return null;
    return flareMediaDownloadEntry(_downloadStates, item.messageId);
  }

  FlareMessageData? _galleryMessage(FlareImageGalleryItem item) {
    final index = _indexes[item.messageId];
    return index == null ? null : widget.messages[index];
  }

  /// The gallery of the rows on screen, rebuilt only when the host passes new rows.
  List<FlareImageGalleryItem> _gallery() {
    if (!identical(_galleryMessages, widget.messages)) {
      _galleryMessages = widget.messages;
      _galleryItems = flareImageGalleryItems(widget.messages);
    }
    return _galleryItems!;
  }
}

/// The message thread as a **sliver**, for chat screens that drive their own
/// [CustomScrollView] (tail-following scroll controller, pull-to-refresh,
/// near-top load-older) and build each row themselves — so a rich per-message
/// row (multi-select, reply, edit, media) stays owned by the host while the kit
/// standardises the padded list / empty / loading sliver treatment. Order is
/// oldest→newest (top→bottom); [keys] are stable message keys.
///
/// Complements [FlareMessageList] (the self-contained `ListView` variant that
/// renders [FlareMessageBubble]s from [FlareMessageData]): reach for this when
/// the host owns the row visuals/affordances and the surrounding scroll view.
class FlareMessageSliverList extends StatelessWidget {
  const FlareMessageSliverList({
    super.key,
    required this.keys,
    required this.rowBuilder,
    this.loading = false,
    this.emptyPlaceholder,
    this.padding = const EdgeInsets.symmetric(
      horizontal: FlareSizes.spacingLg,
      vertical: FlareSizes.spacingSm,
    ),
  });

  /// Stable message keys in display order (oldest→newest); the host owns
  /// ordering / paging / grouping.
  final List<String> keys;

  /// Builds one row for [key]. Return a widget that subscribes to just that
  /// message so a single message update rebuilds only its row.
  final Widget Function(BuildContext context, String key) rowBuilder;

  /// Initial-load spinner (shown only when [keys] is empty).
  final bool loading;

  /// Shown (filling the viewport) when [keys] is empty and not loading. The host
  /// supplies its own layout/padding; falls back to a plain default.
  final Widget? emptyPlaceholder;

  /// Padding around the row list.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    if (keys.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : (emptyPlaceholder ??
                  Center(child: _Empty(FlareStrings.of(context).noMessages))),
      );
    }
    return SliverPadding(
      padding: padding,
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => KeyedSubtree(
            key: ValueKey(keys[index]),
            child: rowBuilder(context, keys[index]),
          ),
          findChildIndexCallback: (key) {
            final index = keys.indexOf((key as ValueKey<String>).value);
            return index < 0 ? null : index;
          },
          childCount: keys.length,
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    return Text(
      text,
      style: TextStyle(
        color: colors.textTertiary,
        fontSize: FlareSizes.fontSizeLg,
      ),
    );
  }
}

/// A message row that starts a reply when it is dragged towards the trailing
/// edge and let go. The rule lives in [flareSwipeReplyGesture] so this kit,
/// SwiftUI and Compose all arm at the same distance and give way to a vertical
/// scroll in the same place; this widget only draws it. The gesture is never
/// the only way to reply — the message menu carries the same intent — so it
/// adds no semantics of its own.
class _SwipeReplyRow extends StatefulWidget {
  const _SwipeReplyRow({super.key, required this.onReply, required this.child});

  final VoidCallback onReply;
  final Widget child;

  @override
  State<_SwipeReplyRow> createState() => _SwipeReplyRowState();
}

class _SwipeReplyRowState extends State<_SwipeReplyRow> {
  double _dx = 0;
  double _dy = 0;
  bool _dragging = false;
  FlareSwipeReplyGesture _gesture = FlareSwipeReplyGesture.none;

  void _reset() {
    _dx = 0;
    _dy = 0;
    _dragging = false;
    _gesture = FlareSwipeReplyGesture.none;
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final progress = (_gesture.travel / flareSwipeReplyArmDistance).clamp(
      0.0,
      1.0,
    );
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: (_) => setState(_reset),
      onHorizontalDragUpdate: (details) => setState(() {
        _dx += details.delta.dx;
        _dy += details.delta.dy;
        _dragging = true;
        final next = flareSwipeReplyGesture(_dx, _dy, rtl: rtl);
        // Crossing the arming distance changes what letting go means, so it is felt as well as seen.
        if (flareHapticCrossed(was: _gesture.armed, now: next.armed)) {
          flareHapticTick();
        }
        _gesture = next;
      }),
      onHorizontalDragCancel: () => setState(_reset),
      onHorizontalDragEnd: (_) {
        final armed = _gesture.armed;
        setState(_reset);
        if (armed) widget.onReply();
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: FlareSizes.spacingMd,
                  ),
                  child: Opacity(
                    key: const ValueKey('swipe-reply-affordance'),
                    // Full strength exactly at the arming distance: the reader
                    // sees that one more millimetre replies before letting go.
                    opacity: progress,
                    child: FlareIcon(
                      'reply',
                      size: FlareSizes.iconSizeMd,
                      color: colors.textTertiary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(end: _gesture.travel),
            // Following a finger is direct manipulation, not an animation; only
            // the spring back to rest is animated, and not under Reduce Motion.
            duration: _dragging || reduceMotion
                ? Duration.zero
                : FlareMotion.fast,
            curve: FlareMotion.fastCurve,
            builder: (context, travel, child) => Transform.translate(
              offset: Offset(rtl ? -travel : travel, 0),
              child: child,
            ),
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

/// Calls [onMounted] once each time its row is built into the list's
/// viewport (or its cache), not on every rebuild: a row scrolled away and
/// back counts again.
class _OnScreen extends StatefulWidget {
  const _OnScreen({required this.onMounted, required this.child});

  final VoidCallback onMounted;
  final Widget child;

  @override
  State<_OnScreen> createState() => _OnScreenState();
}

class _OnScreenState extends State<_OnScreen> {
  @override
  void initState() {
    super.initState();
    widget.onMounted();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
