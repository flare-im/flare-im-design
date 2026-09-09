import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';

/// Batch actions a host may expose over a multi-selection of conversations.
enum FlareConversationBatchAction { markRead, mute, archive, delete }

/// Host-declared capabilities; a false entry hides the action entirely.
@immutable
class FlareConversationBatchCapabilities {
  const FlareConversationBatchCapabilities({
    this.markRead = false,
    this.mute = false,
    this.archive = false,
    this.delete = false,
  });
  final bool markRead, mute, archive, delete;

  bool allows(FlareConversationBatchAction action) => switch (action) {
        FlareConversationBatchAction.markRead => markRead,
        FlareConversationBatchAction.mute => mute,
        FlareConversationBatchAction.archive => archive,
        FlareConversationBatchAction.delete => delete,
      };
}

/// One failed item of the previous batch, with a user-facing reason mapped by the host.
@immutable
class FlareConversationBatchFailure {
  const FlareConversationBatchFailure({required this.id, required this.title, required this.reason});
  final String id, title, reason;
}

/// Outcome of the previous batch as written by the host.
@immutable
class FlareConversationBatchResult {
  const FlareConversationBatchResult({this.succeeded = const [], this.failed = const []});
  final List<String> succeeded;
  final List<FlareConversationBatchFailure> failed;
}

@immutable
class FlareConversationBatchSummary {
  const FlareConversationBatchSummary({required this.succeededCount, required this.failedCount, required this.retryIds});
  final int succeededCount, failedCount;
  final List<String> retryIds;
}

/// True when the host limit is positive and the selection exceeds it.
bool batchSelectionExceeded(int selectedCount, int? maxSelection) =>
    maxSelection != null && maxSelection > 0 && selectedCount > maxSelection;

/// Actions the toolbar may offer right now: empty while busy, with nothing selected, or
/// over `maxSelection`; otherwise capability-enabled actions in canonical order.
List<FlareConversationBatchAction> batchActionsAvailable(
  List<String> selectedIds,
  FlareConversationBatchCapabilities? capabilities,
  bool busy, [
  int? maxSelection,
]) {
  if (busy || selectedIds.isEmpty || batchSelectionExceeded(selectedIds.length, maxSelection)) return const [];
  if (capabilities == null) return const [];
  return FlareConversationBatchAction.values.where(capabilities.allows).toList(growable: false);
}

/// Counts of the previous batch and the deduplicated IDs a retry should target.
FlareConversationBatchSummary summarizeBatchResult(FlareConversationBatchResult? result) {
  if (result == null) return const FlareConversationBatchSummary(succeededCount: 0, failedCount: 0, retryIds: []);
  final seen = <String>{};
  final retryIds = <String>[];
  for (final f in result.failed) {
    if (f.id.isEmpty || !seen.add(f.id)) continue;
    retryIds.add(f.id);
  }
  return FlareConversationBatchSummary(
    succeededCount: result.succeeded.length,
    failedCount: result.failed.length,
    retryIds: retryIds,
  );
}

/// Batch toolbar for the conversation list in multi-select mode. Same bar / count /
/// actions / cancel visual as [FlareMessageBatchToolbar], plus a partial-failure strip with
/// per-item reasons and a retry-failed entry. Emits intents only; the host owns `busy`,
/// `result` and the DangerConfirm step for `delete`. Spec: Conversation/ConversationBatchToolbar.
class FlareConversationBatchToolbar extends StatefulWidget {
  const FlareConversationBatchToolbar({
    super.key,
    required this.selectedIds,
    required this.capabilities,
    this.busy = false,
    this.result,
    this.maxSelection,
    this.onAction,
    this.onRetryFailed,
    this.onClearSelection,
    this.onDismissResult,
    this.selectedText = '已选',
    this.emptyText = '请选择会话',
    this.markReadText = '标为已读',
    this.muteText = '免打扰',
    this.archiveText = '归档',
    this.deleteText = '删除',
    this.cancelText = '取消选择',
    this.busyText = '处理中',
    this.succeededSummaryText = '成功 {n} 项',
    this.failedSummaryText = '{n} 项失败',
    this.retryFailedText = '重试失败项',
    this.dismissText = '关闭结果',
    this.expandText = '查看详情',
    this.collapseText = '收起',
    this.maxSelectionText = '最多可选 {n} 项',
  });

  final List<String> selectedIds;
  final FlareConversationBatchCapabilities capabilities;
  final bool busy;
  final FlareConversationBatchResult? result;
  final int? maxSelection;
  final void Function(FlareConversationBatchAction action, List<String> ids)? onAction;
  final ValueChanged<List<String>>? onRetryFailed;
  final VoidCallback? onClearSelection;
  final VoidCallback? onDismissResult;
  final String selectedText,
      emptyText,
      markReadText,
      muteText,
      archiveText,
      deleteText,
      cancelText,
      busyText,
      succeededSummaryText,
      failedSummaryText,
      retryFailedText,
      dismissText,
      expandText,
      collapseText,
      maxSelectionText;

  @override
  State<FlareConversationBatchToolbar> createState() => _FlareConversationBatchToolbarState();
}

/// Sentinel key for the retry-failed button in the pending tracker.
const _retryKey = Object();

class _FlareConversationBatchToolbarState extends State<FlareConversationBatchToolbar> {
  Object? _pending;
  bool _expanded = false;

  @override
  void didUpdateWidget(covariant FlareConversationBatchToolbar old) {
    super.didUpdateWidget(old);
    if (!widget.busy && old.busy) _pending = null;
    if (!identical(old.result, widget.result)) _expanded = false;
  }

  String _fill(String template, int n) => template.replaceFirst('{n}', '$n');

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    final count = widget.selectedIds.length;
    final exceeded = batchSelectionExceeded(count, widget.maxSelection);
    final available = batchActionsAvailable(widget.selectedIds, widget.capabilities, widget.busy, widget.maxSelection);
    final summary = summarizeBatchResult(widget.result);
    final hasResult = summary.failedCount > 0 || summary.succeededCount > 0;
    final hint = widget.busy
        ? widget.busyText
        : count == 0
            ? widget.emptyText
            : exceeded
                ? _fill(widget.maxSelectionText, widget.maxSelection!)
                : null;
    final visible = FlareConversationBatchAction.values.where(widget.capabilities.allows).toList();

    return Container(
      decoration: BoxDecoration(
        color: colors.bgPrimary,
        borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
        border: Border.all(color: colors.borderPrimary),
        boxShadow: const [BoxShadow(color: Color(0x1415131C), blurRadius: 16, offset: Offset(0, 6))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: FlareSizes.spacingMd,
              runSpacing: FlareSizes.spacingSm,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: FlareSizes.spacingMd,
                  runSpacing: FlareSizes.spacingXs,
                  children: [
                    Text.rich(
                      TextSpan(children: [
                        TextSpan(
                          text: '$count',
                          style: TextStyle(color: colors.primary, fontWeight: FontWeight.w700, fontSize: FlareSizes.fontSize2xl),
                        ),
                        TextSpan(text: ' ${widget.selectedText}', style: TextStyle(color: colors.textSecondary)),
                      ]),
                      style: const TextStyle(fontSize: FlareSizes.fontSizeMd),
                    ),
                    if (hint != null)
                      Semantics(
                        liveRegion: true,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (widget.busy)
                              _Spinner(color: colors.textTertiary)
                            else if (exceeded)
                              Icon(Icons.error_outline, size: 14, color: colors.warning),
                            if (widget.busy || exceeded) const SizedBox(width: 6),
                            Text(
                              hint,
                              style: TextStyle(
                                fontSize: FlareSizes.fontSizeSm,
                                color: exceeded && !widget.busy ? colors.warning : colors.textTertiary,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    for (final action in visible)
                      if (widget.onAction != null)
                        _button(
                          colors,
                          icon: _icon(action),
                          label: _label(action),
                          enabled: available.contains(action),
                          pending: widget.busy && _pending == action,
                          color: action == FlareConversationBatchAction.delete ? colors.error : null,
                          onTap: () {
                            setState(() => _pending = action);
                            widget.onAction!(action, List.of(widget.selectedIds));
                          },
                        ),
                    if (widget.onClearSelection != null)
                      _iconButton(colors, icon: Icons.close, label: widget.cancelText, enabled: !widget.busy, onTap: widget.onClearSelection!),
                  ],
                ),
              ],
            ),
          ),
          if (hasResult) _resultStrip(colors, summary),
        ],
      ),
    );
  }

  Widget _resultStrip(FlareColors colors, FlareConversationBatchSummary summary) {
    final failed = summary.failedCount > 0;
    return Container(
      color: colors.bgSecondary,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            liveRegion: true,
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.spaceBetween,
              spacing: FlareSizes.spacingSm,
              runSpacing: 6,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(failed ? Icons.error_outline : Icons.check_circle_outline, size: 16, color: failed ? colors.error : colors.success),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text.rich(
                        TextSpan(children: [
                          if (failed)
                            TextSpan(
                              text: _fill(widget.failedSummaryText, summary.failedCount),
                              style: TextStyle(color: colors.error, fontWeight: FontWeight.w600),
                            ),
                          if (failed && summary.succeededCount > 0) const TextSpan(text: ' · '),
                          if (summary.succeededCount > 0 || !failed)
                            TextSpan(text: _fill(widget.succeededSummaryText, summary.succeededCount)),
                        ]),
                        style: TextStyle(fontSize: FlareSizes.fontSizeMd, color: colors.textPrimary),
                      ),
                    ),
                  ],
                ),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (failed)
                      _button(
                        colors,
                        icon: _expanded ? Icons.expand_less : Icons.expand_more,
                        label: _expanded ? widget.collapseText : widget.expandText,
                        enabled: true,
                        ghost: true,
                        onTap: () => setState(() => _expanded = !_expanded),
                      ),
                    if (summary.retryIds.isNotEmpty && widget.onRetryFailed != null)
                      _button(
                        colors,
                        icon: Icons.refresh,
                        label: '${widget.retryFailedText} (${summary.retryIds.length})',
                        enabled: !widget.busy,
                        pending: widget.busy && identical(_pending, _retryKey),
                        primary: true,
                        onTap: () {
                          setState(() => _pending = _retryKey);
                          widget.onRetryFailed!(List.of(summary.retryIds));
                        },
                      ),
                    if (widget.onDismissResult != null)
                      _iconButton(colors, icon: Icons.close, label: widget.dismissText, enabled: !widget.busy, onTap: () {
                        setState(() => _expanded = false);
                        widget.onDismissResult!();
                      }),
                  ],
                ),
              ],
            ),
          ),
          if (_expanded && widget.result != null && widget.result!.failed.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: widget.result!.failed.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final item = widget.result!.failed[index];
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(color: colors.bgPrimary, borderRadius: BorderRadius.circular(FlareSizes.radiusSm)),
                      child: Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: FlareSizes.fontSizeSm, fontWeight: FontWeight.w500, color: colors.textPrimary)),
                          Text(item.reason, style: TextStyle(fontSize: FlareSizes.fontSizeSm, color: colors.textSecondary)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _icon(FlareConversationBatchAction a) => switch (a) {
        FlareConversationBatchAction.markRead => Icons.done_all,
        FlareConversationBatchAction.mute => Icons.notifications_off_outlined,
        FlareConversationBatchAction.archive => Icons.archive_outlined,
        FlareConversationBatchAction.delete => Icons.delete_outline,
      };

  String _label(FlareConversationBatchAction a) => switch (a) {
        FlareConversationBatchAction.markRead => widget.markReadText,
        FlareConversationBatchAction.mute => widget.muteText,
        FlareConversationBatchAction.archive => widget.archiveText,
        FlareConversationBatchAction.delete => widget.deleteText,
      };

  Widget _button(
    FlareColors colors, {
    required IconData icon,
    required String label,
    required bool enabled,
    required VoidCallback onTap,
    bool pending = false,
    bool ghost = false,
    bool primary = false,
    Color? color,
  }) {
    final fg = primary ? Colors.white : (enabled || pending ? (color ?? (ghost ? colors.textSecondary : colors.textPrimary)) : colors.textTertiary);
    final bg = primary ? colors.primary : (ghost ? Colors.transparent : colors.bgSecondary);
    return Semantics(
      button: true,
      enabled: enabled,
      label: pending ? '$label · ${widget.busyText}' : label,
      child: Opacity(
        opacity: enabled ? 1 : (pending ? 0.85 : 0.45),
        child: GestureDetector(
          onTap: enabled ? onTap : null,
          behavior: HitTestBehavior.opaque,
          child: Container(
            constraints: const BoxConstraints(minHeight: FlareSizes.touchTarget, minWidth: FlareSizes.touchTarget),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(FlareSizes.radiusMd)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (pending) _Spinner(color: fg) else Icon(icon, size: 16, color: fg),
                const SizedBox(width: FlareSizes.spacingXs),
                Text(label, style: TextStyle(color: fg, fontSize: FlareSizes.fontSizeMd), softWrap: false),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _iconButton(FlareColors colors, {required IconData icon, required String label, required bool enabled, required VoidCallback onTap}) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: GestureDetector(
          onTap: enabled ? onTap : null,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: FlareSizes.touchTarget,
            height: FlareSizes.touchTarget,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: colors.bgSecondary, borderRadius: BorderRadius.circular(FlareSizes.radiusMd)),
            child: Icon(icon, size: 16, color: colors.textSecondary),
          ),
        ),
      ),
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(strokeWidth: 2, color: color),
      );
}
