import 'package:flutter/material.dart';
import 'flare_transfer_progress.dart';
import 'flare_status_banner.dart';

@immutable
class FlareTransferQueueItem {
  const FlareTransferQueueItem({
    required this.id,
    required this.name,
    required this.state,
    required this.statusText,
    this.progress,
    this.actionLabels = const {},
    this.busy = false,
  });
  final String id, name, statusText;
  final FlareTransferState state;
  final double? progress;
  final Map<FlareTransferAction, String> actionLabels;
  final bool busy;
}

List<String> retryableTransferIds(List<FlareTransferQueueItem> items) => items
    .where(
      (i) =>
          i.state == FlareTransferState.failed &&
          !i.busy &&
          (i.actionLabels[FlareTransferAction.retry]?.trim().isNotEmpty ??
              false),
    )
    .map((i) => i.id)
    .toList();

/// Place in a bounded-height parent. The host owns tasks and all network operations.
class FlareTransferQueue extends StatelessWidget {
  const FlareTransferQueue({
    super.key,
    required this.items,
    this.loading = false,
    this.error,
    this.title = '传输队列',
    this.emptyText = '暂无传输任务',
    this.retryFailedText = '重试失败任务',
    this.reloadText = '重新加载',
    this.onAction,
    this.onRetryFailed,
    this.onReload,
  });
  final List<FlareTransferQueueItem> items;
  final bool loading;
  final String? error;
  final String title, emptyText, retryFailedText, reloadText;
  final void Function(String id, FlareTransferAction action)? onAction;
  final ValueChanged<List<String>>? onRetryFailed;
  final VoidCallback? onReload;
  @override
  Widget build(BuildContext context) {
    final ids = retryableTransferIds(items);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '$title · ${items.length}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (ids.isNotEmpty && onRetryFailed != null)
              TextButton(
                onPressed: () => onRetryFailed!(List.of(ids)),
                style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
                child: Text('$retryFailedText (${ids.length})'),
              ),
          ],
        ),
        if (loading) LinearProgressIndicator(semanticsLabel: title),
        if (error != null)
          FlareStatusBanner(
            text: error!,
            tone: FlareStatusTone.danger,
            actionText: reloadText,
            onAction: loading ? null : onReload,
          ),
        if (items.isEmpty && !loading && error == null)
          Padding(padding: const EdgeInsets.all(16), child: Text(emptyText)),
        Expanded(
          child: ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final item = items[index];
              return FlareTransferProgress(
                key: ValueKey(item.id),
                name: item.name,
                state: item.state,
                statusText: item.statusText,
                progress: item.progress,
                actionLabels: item.actionLabels,
                busy: item.busy,
                onAction: onAction == null
                    ? null
                    : (a) => onAction!(item.id, a),
              );
            },
          ),
        ),
      ],
    );
  }
}
