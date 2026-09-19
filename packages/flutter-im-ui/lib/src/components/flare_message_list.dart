import 'package:flutter/material.dart';

import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';

import '../models/image_gallery.dart';
import '../models/message_content.dart';
import '../models/message_data.dart';
import '../models/haptics.dart';
import '../models/locate_highlight.dart';
import '../models/message_grouping.dart';
import '../models/message_preview.dart';
import '../models/swipe_reply.dart';
import '../models/time_format.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_date_pill.dart';
import 'flare_icon.dart';
import 'flare_locate_highlight_scope.dart';
import 'flare_media_controller.dart';
import 'flare_message_bubble.dart';
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
    this.onVote,
    this.onTaskToggle,
    this.onResend,
    this.onToggleSelect,
    this.onSwipeReply,
    this.onReact,
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
  final String? conversationId;
  final bool loading;

  /// 空态文案。整块替换用 [emptyPlaceholder]，仅换文字用本参数。
  final String? emptyText;

  /// Per-message-id media download state.
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
  /// [onOpenFile] and a link to [onOpenLink]. Locations are host actions
  /// either way.
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

  /// Offered as the download key of the kit's image preview; without it the
  /// preview has no download key. A tapped picture opens the conversation's
  /// gallery, and the key saves the picture on screen with the message it
  /// belongs to.
  final void Function(FlareMessageData message, FlareMessageContent content)?
  onMediaDownload;

  /// A tapped poll option, by its index; without it polls are read-only.
  final void Function(FlareMessageData message, int optionIndex)? onVote;

  /// A tapped task checkbox, with the done state asked for; without it tasks
  /// are read-only.
  final void Function(FlareMessageData message, bool done)? onTaskToggle;
  final void Function(FlareMessageData message)? onResend;
  final void Function(FlareMessageData message)? onToggleSelect;
  final void Function(FlareMessageData message)? onSwipeReply;

  /// Reaction pill tap (toggle the current user's reaction).
  final void Function(FlareMessageData message, String emoji)? onReact;

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

  ({String id, double offset})? _visibleAnchor(Set<String> surviving) {
    final viewport = _viewportKey.currentContext?.findRenderObject();
    if (viewport is! RenderBox || !viewport.hasSize) return null;
    final top = viewport.localToGlobal(Offset.zero).dy;
    final rows = <({String id, double offset})>[];
    for (final entry in _rowKeys.entries) {
      if (!surviving.contains(entry.key)) continue;
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

  FlareMediaController get _media =>
      widget.mediaController ?? (_ownMedia ??= FlareMediaController());

  /// The first row of the lower sliver; null puts every row above the center,
  /// so offset 0 shows the newest message at the bottom.
  String? _pivotId;
  bool _requested = false;
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

  /// Rows that open a local calendar day.
  Set<int> _dayStarts = const {};
  int _unreadIndex = -1;
  int _unreadCount = 0;

  /// Day starts and the unread row, recomputed only when the host hands over
  /// a new list: one numeric calendar comparison per message, no formatting.
  void _indexTimeline() {
    final messages = widget.messages;
    if (identical(_timelineMessages, messages) &&
        _timelineUnreadId == widget.unreadFromId &&
        _timelineUserId == widget.currentUserId) {
      return;
    }
    _timelineMessages = messages;
    _timelineUnreadId = widget.unreadFromId;
    _timelineUserId = widget.currentUserId;
    final starts = <int>{};
    var previousDay = 0;
    for (var i = 0; i < messages.length; i++) {
      final sentAt = messages[i].sentAtMs;
      if (sentAt <= 0) continue;
      final time = DateTime.fromMillisecondsSinceEpoch(sentAt);
      final day = time.year * 10000 + time.month * 100 + time.day;
      if (day != previousDay) starts.add(i);
      previousDay = day;
    }
    _dayStarts = starts;
    final unreadId = widget.unreadFromId;
    _unreadIndex = unreadId == null ? -1 : _indexes[unreadId] ?? -1;
    var count = 0;
    if (_unreadIndex >= 0) {
      for (var i = _unreadIndex; i < messages.length; i++) {
        if (messages[i].senderId != widget.currentUserId) count++;
      }
    }
    _unreadCount = count;
  }

  /// Whether a separator — a date pill or the unread divider — is drawn right
  /// above row [index]. The first row's date pill has no run above it.
  bool _dividerBefore(int index) =>
      index == _unreadIndex || (index > 0 && _dayStarts.contains(index));

  /// A separator ends a sender run: the row above it closes the run and the
  /// row below it opens a new one.
  FlareMessageGroupPosition _breakRunAtDividers(
    FlareMessageGroupPosition position,
    int index,
  ) {
    var next = position;
    if (_dividerBefore(index)) {
      next = switch (next) {
        FlareMessageGroupPosition.middle => FlareMessageGroupPosition.first,
        FlareMessageGroupPosition.last => FlareMessageGroupPosition.single,
        _ => next,
      };
    }
    if (_dividerBefore(index + 1)) {
      next = switch (next) {
        FlareMessageGroupPosition.middle => FlareMessageGroupPosition.last,
        FlareMessageGroupPosition.first => FlareMessageGroupPosition.single,
        _ => next,
      };
    }
    return next;
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
    _followTail = true;
    _browseTailId = null;
    _correctPixels(0);
  }

  /// A reader who scrolled up keeps the top row in view where it is: it becomes
  /// the pivot, so rows added or resized above it grow upwards and rows below
  /// it grow downwards. The pivot's top edge is the center, drawn at viewport
  /// height + offset from the top.
  void _keepReaderInPlace(Set<String> surviving) {
    final viewport = _viewportKey.currentContext?.findRenderObject();
    final anchor = _visibleAnchor(surviving);
    if (anchor == null || viewport is! RenderBox || !viewport.hasSize) {
      if (_pivotId != null && !surviving.contains(_pivotId)) _pivotId = null;
      return;
    }
    _pivotId = anchor.id;
    _correctPixels(anchor.offset - viewport.size.height);
  }

  /// The reader's scrolling decides whether new messages keep them at the
  /// bottom; leaving it starts the count of messages below.
  void _syncFollow(ScrollMetrics metrics) {
    if (!_trackScroll) return;
    final atBottom = metrics.pixels <= metrics.minScrollExtent + _bottomSlop;
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
    setState(() {
      _pivotId = null;
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
  void didChangeDependencies() {
    super.didChangeDependencies();
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
    if (oldWidget.conversationId != widget.conversationId) {
      // Another conversation: the voice message playing belonged to the last.
      unawaited(_media.stopVoice());
      _requested = false;
      _showNewest();
    } else if (oldWidget.messages != widget.messages) {
      final appended = _appendedCount(oldWidget.messages, widget.messages);
      final ownNewest =
          appended > 0 && widget.messages.last.senderId == widget.currentUserId;
      if (oldWidget.messages.isEmpty || _followTail || ownNewest) {
        _showNewest();
      } else {
        _keepReaderInPlace(surviving);
      }
    }
    _rowKeys.removeWhere((id, _) => !surviving.contains(id));
    if (oldWidget.loadingOlder && !widget.loadingOlder ||
        oldWidget.messages.firstOrNull?.id != widget.messages.firstOrNull?.id ||
        oldWidget.olderError != widget.olderError)
      _requested = false;
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
    super.dispose();
  }

  void _requestOlder({bool retry = false}) {
    if (_requested ||
        widget.loadingOlder ||
        !widget.hasOlder ||
        widget.onLoadOlder == null ||
        (!retry && widget.olderError != null))
      return;
    setState(() => _requested = true);
    widget.onLoadOlder!();
  }

  Widget _message(int i) {
    _indexTimeline();
    final msg = widget.messages[i];
    final quotedId = msg.replyTo?.messageId;
    final groupPosition = _breakRunAtDividers(
      flareMessageGroupPosition(widget.messages, i),
      i,
    );
    final presentation = flareMessageRowPresentation(
      message: msg,
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
      groupPosition: groupPosition,
      rowPresentation: presentation,
      multiSelectMode: widget.multiSelectMode,
      selected: widget.selectedIds.contains(msg.id),
      mediaState: widget.mediaDownloadStates[msg.id],
      onLongPress: widget.onMessageLongPress,
      onAvatarTap: widget.onAvatarTap,
      onMediaAction: widget.onMediaAction,
      onOpenFile: widget.onOpenFile,
      onOpenLink: widget.onOpenLink,
      onMediaDownload: widget.onMediaDownload,
      onVote: widget.onVote,
      onTaskToggle: widget.onTaskToggle,
      onResend: widget.onResend,
      onToggleSelect: widget.onToggleSelect,
      onReact: widget.onReact,
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
        !msg.isSystem &&
        !msg.isRecalled) {
      bubble = _SwipeReplyRow(
        key: ValueKey('swipe-reply-${msg.id}'),
        onReply: () => widget.onSwipeReply!(msg),
        child: bubble,
      );
    }
    // The day comes first, then where the unread messages start inside it.
    // Both belong to the message's row, so a row stays one message for
    // scrolling and anchoring.
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
    // The rows a host handle answers for are this build's rows.
    _handle._attach(this, _locatable);
    final pivot = _pivotId == null ? null : _indexes[_pivotId];
    final split = pivot ?? widget.messages.length;
    final before = [for (var i = split - 1; i >= 0; i--) widget.messages[i].id];
    final after = widget.messages.skip(split).map((m) => m.id).toList();
    final newBelow = _newBelow;
    return FlareLocateHighlightScope(
      messageId: _locatedId,
      elapsedMs: _locateElapsed,
      reduceMotion: MediaQuery.maybeDisableAnimationsOf(context) ?? false,
      child: FlareMediaScope(
        controller: _media,
        child: FlareImageGalleryScope(
          items: _gallery(),
          download: widget.onMediaDownload == null
              ? null
              : _downloadGalleryPicture,
          child: ColoredBox(
            color: colors.bgSecondary,
            child: Column(
              children: [
                if (widget.hasOlder ||
                    widget.loadingOlder ||
                    widget.olderError != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      children: [
                        if (widget.olderError != null)
                          Text(
                            widget.olderError!,
                            style: TextStyle(color: colors.textPrimary),
                          ),
                        if (widget.loadingOlder)
                          const SizedBox(
                            height: 48,
                            child: Center(
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          )
                        else if (widget.hasOlder && widget.onLoadOlder != null)
                          TextButton(
                            onPressed: _requested
                                ? null
                                : () => _requestOlder(retry: true),
                            style: TextButton.styleFrom(
                              minimumSize: const Size(48, 48),
                            ),
                            child: Text(_loadOlderText),
                          ),
                      ],
                    ),
                  ),
                Expanded(
                  child: widget.messages.isEmpty
                      ? Center(
                          child: widget.loading
                              ? const CircularProgressIndicator()
                              : (widget.emptyPlaceholder ?? _Empty(_emptyText)),
                        )
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
                                  child: NotificationListener<ScrollNotification>(
                                    onNotification: (n) {
                                      if (n.depth != 0) return false;
                                      if (n is ScrollUpdateNotification) {
                                        if (n.dragDetails != null &&
                                            n.metrics.pixels >=
                                                n.metrics.maxScrollExtent - 160)
                                          _requestOlder();
                                        _syncFollow(n.metrics);
                                      } else if (n is ScrollEndNotification) {
                                        _syncFollow(n.metrics);
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
                            if (newBelow > 0)
                              PositionedDirectional(
                                end: FlareSizes.spacingMd,
                                bottom: FlareSizes.spacingMd,
                                child: FlareScrollToLatest(
                                  count: newBelow,
                                  onTap: _goToNewest,
                                ),
                              ),
                          ],
                        ),
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
    if (download == null) return;
    for (final message in widget.messages) {
      if (message.id == item.messageId) {
        download(message, item.image);
        return;
      }
    }
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
