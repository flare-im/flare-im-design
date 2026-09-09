import 'package:flutter/material.dart';

import '../models/message_content.dart';
import '../models/message_data.dart';
import '../tokens/flare_tokens.dart';
import 'flare_message_bubble.dart';

/// The virtualised message thread — grouping, load-older, multi-select, media
/// state. Spec: Message/MessageList (`FlareMessageList`).
///
/// Pure/presentational and windowed via lazy slivers (O(visible)). Order
/// is oldest→newest (top→bottom); the host feeds [messages] from the timeline
/// view and drives pagination through [onLoadOlder].
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
    this.loadOlderText = "加载更早消息",
    this.conversationId,
    this.loading = false,
    this.emptyText = '暂无消息',
    this.mediaDownloadStates = const {},
    this.controller,
    this.onLoadOlder,
    this.onMessageLongPress,
    this.onAvatarTap,
    this.onMediaAction,
    this.onResend,
    this.onToggleSelect,
    this.emptyPlaceholder,
  });

  final List<FlareMessageData> messages;
  final String currentUserId;
  final FlareConversationKind conversationKind;
  final bool multiSelectMode;
  final Set<String> selectedIds;
  final bool loadingOlder;
  final bool hasOlder;
  final String? olderError;
  final String loadOlderText;
  final String? conversationId;
  final bool loading;

  /// 空态文案。整块替换用 [emptyPlaceholder]，仅换文字用本参数。
  final String emptyText;

  /// Per-message-id media download state.
  final Map<String, FlareMediaDownloadState> mediaDownloadStates;

  final ScrollController? controller;
  final VoidCallback? onLoadOlder;
  final void Function(FlareMessageData message)? onMessageLongPress;
  final void Function(FlareMessageData message)? onAvatarTap;
  final void Function(FlareMessageData message, FlareMessageContent content)?
  onMediaAction;
  final void Function(FlareMessageData message)? onResend;
  final void Function(FlareMessageData message)? onToggleSelect;
  final Widget? emptyPlaceholder;

  @override
  State<FlareMessageList> createState() => _FlareMessageListState();
}

class _FlareMessageListState extends State<FlareMessageList> {
  final _ownedController = ScrollController();
  final _centerKey = UniqueKey();
  final _viewportKey = GlobalKey();
  final _rowKeys = <String, GlobalKey>{};
  int _restoreGeneration = 0;

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

  String? _pivotId;
  bool _requested = false;
  ScrollController get _controller => widget.controller ?? _ownedController;

  @override
  void initState() {
    super.initState();
    _pivotId = widget.messages.firstOrNull?.id;
  }

  @override
  void didUpdateWidget(FlareMessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    final surviving = widget.messages.map((m) => m.id).toSet();
    final anchor = oldWidget.conversationId == widget.conversationId
        ? _visibleAnchor(surviving)
        : null;
    if (anchor != null && oldWidget.messages != widget.messages) {
      _pivotId = anchor.id;
      final generation = ++_restoreGeneration;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            generation == _restoreGeneration &&
            _controller.hasClients)
          _controller.jumpTo(-anchor.offset);
      });
    }
    _rowKeys.removeWhere((id, _) => !surviving.contains(id));
    if (oldWidget.conversationId != widget.conversationId) {
      _restoreGeneration++;
      _pivotId = widget.messages.firstOrNull?.id;
      _requested = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _controller.hasClients) _controller.jumpTo(0);
      });
    }
    if (oldWidget.loadingOlder && !widget.loadingOlder ||
        oldWidget.messages.firstOrNull?.id != widget.messages.firstOrNull?.id ||
        oldWidget.olderError != widget.olderError)
      _requested = false;
    // When a bounded host window evicts the pivot, start a new window. Hosts
    // requiring eviction anchoring should own the scroll view via the sliver API.
    if (!widget.messages.any((m) => m.id == _pivotId))
      _pivotId = widget.messages.firstOrNull?.id;
  }

  @override
  void dispose() {
    _ownedController.dispose();
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
    final msg = widget.messages[i];
    final prev = i > 0 ? widget.messages[i - 1] : null;
    final next = i + 1 < widget.messages.length ? widget.messages[i + 1] : null;
    return KeyedSubtree(
      key: ValueKey(msg.id),
      child: SizedBox(
        key: _rowKeys.putIfAbsent(msg.id, GlobalKey.new),
        child: FlareMessageBubble(
          message: msg,
          currentUserId: widget.currentUserId,
          conversationKind: widget.conversationKind,
          groupStart:
              prev == null ||
              prev.senderId != msg.senderId ||
              prev.isSystem ||
              msg.isSystem,
          groupEnd:
              next == null ||
              next.senderId != msg.senderId ||
              next.isSystem ||
              msg.isSystem,
          multiSelectMode: widget.multiSelectMode,
          selected: widget.selectedIds.contains(msg.id),
          mediaState: widget.mediaDownloadStates[msg.id],
          onLongPress: widget.onMessageLongPress,
          onAvatarTap: widget.onAvatarTap,
          onMediaAction: widget.onMediaAction,
          onResend: widget.onResend,
          onToggleSelect: widget.onToggleSelect,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    final pivot = widget.messages.indexWhere((m) => m.id == _pivotId);
    final split = pivot < 0 ? 0 : pivot;
    final before = [for (var i = split - 1; i >= 0; i--) widget.messages[i].id];
    final after = widget.messages.skip(split).map((m) => m.id).toList();
    return ColoredBox(
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
                          child: CircularProgressIndicator(strokeWidth: 2),
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
                      child: Text(widget.loadOlderText),
                    ),
                ],
              ),
            ),
          Expanded(
            child: widget.messages.isEmpty
                ? Center(
                    child: widget.loading
                        ? const CircularProgressIndicator()
                        : (widget.emptyPlaceholder ?? _Empty(widget.emptyText)),
                  )
                : NotificationListener<ScrollUpdateNotification>(
                    onNotification: (n) {
                      if (n.depth == 0 &&
                          n.dragDetails != null &&
                          n.metrics.pixels <= n.metrics.minScrollExtent + 160)
                        _requestOlder();
                      return false;
                    },
                    child: CustomScrollView(
                      key: _viewportKey,
                      controller: _controller,
                      center: _centerKey,
                      slivers: [
                        // Older messages grow upwards from a stable center. Their actual
                        // measured heights never shift the already-visible message segment.
                        SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, i) => _message(split - 1 - i),
                            childCount: before.length,
                            findChildIndexCallback: (key) {
                              final i = before.indexOf(
                                (key as ValueKey<String>).value,
                              );
                              return i < 0 ? null : i;
                            },
                          ),
                        ),
                        SliverList(
                          key: _centerKey,
                          delegate: SliverChildBuilderDelegate(
                            (context, i) => _message(split + i),
                            childCount: after.length,
                            findChildIndexCallback: (key) {
                              final i = after.indexOf(
                                (key as ValueKey<String>).value,
                              );
                              return i < 0 ? null : i;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
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
            : (emptyPlaceholder ?? const Center(child: _Empty('暂无消息'))),
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
    final colors = FlareColors.of(Theme.of(context).brightness);
    return Text(
      text,
      style: TextStyle(
        color: colors.textTertiary,
        fontSize: FlareSizes.fontSizeLg,
      ),
    );
  }
}
