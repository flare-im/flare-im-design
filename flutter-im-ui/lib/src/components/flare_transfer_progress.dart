import 'package:flutter/material.dart';
import '../tokens/flare_tokens.dart';

enum FlareTransferState {
  queued,
  transferring,
  paused,
  failed,
  completed,
  cancelled,
}

enum FlareTransferAction { pause, resume, cancel, retry, open }

extension FlareTransferPolicy on FlareTransferState {
  List<FlareTransferAction> get actions => switch (this) {
    FlareTransferState.queued => [FlareTransferAction.cancel],
    FlareTransferState.transferring => [
      FlareTransferAction.pause,
      FlareTransferAction.cancel,
    ],
    FlareTransferState.paused => [
      FlareTransferAction.resume,
      FlareTransferAction.cancel,
    ],
    FlareTransferState.failed ||
    FlareTransferState.cancelled => [FlareTransferAction.retry],
    FlareTransferState.completed => [FlareTransferAction.open],
  };
  double? normalizedProgress(double? value) =>
      this == FlareTransferState.completed
      ? 1
      : value != null && value.isFinite
      ? value.clamp(0, 1).toDouble()
      : null;
}

/// Presentational transfer card. The host owns retries, cancellation and progress.
class FlareTransferProgress extends StatelessWidget {
  const FlareTransferProgress({
    super.key,
    required this.name,
    required this.state,
    required this.statusText,
    this.progress,
    this.actionLabels = const {},
    this.busy = false,
    this.onAction,
  });
  final String name;
  final FlareTransferState state;
  final String statusText;
  final double? progress;
  final Map<FlareTransferAction, String> actionLabels;
  final bool busy;
  final ValueChanged<FlareTransferAction>? onAction;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    final value = state.normalizedProgress(progress);
    final actions = state.actions.where(
      (a) => (actionLabels[a]?.trim().isNotEmpty ?? false) && onAction != null,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.bgPrimary,
        border: Border.all(color: colors.borderPrimary),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Semantics(
            liveRegion: true,
            child: Text(
              statusText,
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
            ),
          ),
          if (value != null || state == FlareTransferState.transferring) ...[
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: value,
              color: colors.primary,
              semanticsLabel: '$name — $statusText',
            ),
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final a in actions)
                  TextButton(
                    onPressed: busy ? null : () => onAction?.call(a),
                    style: TextButton.styleFrom(
                      minimumSize: const Size(48, 48),
                      foregroundColor: colors.textPrimary,
                    ),
                    child: Text(actionLabels[a]!),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
