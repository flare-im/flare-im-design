import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';
import 'flare_status_banner.dart';

/// Connection / session state supplied by the host; the UI never opens or
/// closes a connection.
enum FlareConnectionState {
  connected,
  connecting,
  reconnecting,
  offline,
  sessionExpired,
  kicked,
  sdkUnready,
}

enum FlareConnectionAction { reconnect, reauth, copyDiagnostics }

/// Semantic tone per state; every state also carries an icon and text, never
/// colour alone.
FlareStatusTone connectionTone(FlareConnectionState state) {
  switch (state) {
    case FlareConnectionState.connected:
      return FlareStatusTone.success;
    case FlareConnectionState.connecting:
    case FlareConnectionState.reconnecting:
      return FlareStatusTone.warning;
    case FlareConnectionState.offline:
    case FlareConnectionState.sessionExpired:
    case FlareConnectionState.kicked:
      return FlareStatusTone.danger;
    case FlareConnectionState.sdkUnready:
      return FlareStatusTone.neutral;
  }
}

/// States that show an indeterminate progress indicator.
bool connectionInProgress(FlareConnectionState state) =>
    state == FlareConnectionState.connecting ||
    state == FlareConnectionState.reconnecting;

/// Actions the host may currently trigger. `reconnect` only while
/// offline/reconnecting, `reauth` only after sessionExpired/kicked,
/// `copyDiagnostics` only with non-blank diagnostics. `sdkUnready` never
/// exposes an action; `busy` disables everything.
List<FlareConnectionAction> availableConnectionActions(
  FlareConnectionState state, {
  required bool hasReconnect,
  required bool hasReauth,
  required bool hasDiagnostics,
  required bool busy,
}) {
  if (busy || state == FlareConnectionState.sdkUnready) return const [];
  final actions = <FlareConnectionAction>[];
  if (hasReconnect &&
      (state == FlareConnectionState.offline ||
          state == FlareConnectionState.reconnecting)) {
    actions.add(FlareConnectionAction.reconnect);
  }
  if (hasReauth &&
      (state == FlareConnectionState.sessionExpired ||
          state == FlareConnectionState.kicked)) {
    actions.add(FlareConnectionAction.reauth);
  }
  if (hasDiagnostics) actions.add(FlareConnectionAction.copyDiagnostics);
  return actions;
}

/// Connection / session details panel — opened from a StatusBanner or shown on
/// the "network & connection" settings page. The host owns the state; this view
/// only presents it and dispatches reconnect / reauth / copyDiagnostics.
/// Spec: General/ConnectionDetails (`FlareConnectionDetails`).
class FlareConnectionDetails extends StatefulWidget {
  const FlareConnectionDetails({
    super.key,
    required this.state,
    this.transport,
    this.endpoint,
    this.lastSyncAt,
    this.reason,
    this.diagnostics,
    this.busy = false,
    this.title = '连接详情',
    this.connectedText = '已连接',
    this.connectingText = '正在连接',
    this.reconnectingText = '正在重新连接',
    this.offlineText = '离线',
    this.sessionExpiredText = '登录已过期',
    this.kickedText = '已在其他设备登录',
    this.sdkUnreadyText = '客户端尚未就绪',
    this.transportLabel = '传输协议',
    this.endpointLabel = '服务地址',
    this.lastSyncLabel = '上次同步',
    this.diagnosticsLabel = '诊断信息',
    this.reconnectText = '重新连接',
    this.reauthText = '重新登录',
    this.copyDiagnosticsText = '复制诊断信息',
    this.onReconnect,
    this.onReauth,
    this.onCopyDiagnostics,
  });

  final FlareConnectionState state;
  final String? transport, endpoint, lastSyncAt, reason, diagnostics;
  final bool busy;
  final String title;
  final String connectedText,
      connectingText,
      reconnectingText,
      offlineText,
      sessionExpiredText,
      kickedText,
      sdkUnreadyText;
  final String transportLabel, endpointLabel, lastSyncLabel, diagnosticsLabel;
  final String reconnectText, reauthText, copyDiagnosticsText;
  final VoidCallback? onReconnect, onReauth, onCopyDiagnostics;

  @override
  State<FlareConnectionDetails> createState() => _FlareConnectionDetailsState();
}

class _FlareConnectionDetailsState extends State<FlareConnectionDetails> {
  bool _diagnosticsOpen = false;

  String get _stateText {
    switch (widget.state) {
      case FlareConnectionState.connected:
        return widget.connectedText;
      case FlareConnectionState.connecting:
        return widget.connectingText;
      case FlareConnectionState.reconnecting:
        return widget.reconnectingText;
      case FlareConnectionState.offline:
        return widget.offlineText;
      case FlareConnectionState.sessionExpired:
        return widget.sessionExpiredText;
      case FlareConnectionState.kicked:
        return widget.kickedText;
      case FlareConnectionState.sdkUnready:
        return widget.sdkUnreadyText;
    }
  }

  IconData get _stateIcon {
    switch (widget.state) {
      case FlareConnectionState.connected:
        return Icons.check_circle_outline;
      case FlareConnectionState.connecting:
      case FlareConnectionState.reconnecting:
        return Icons.sync;
      case FlareConnectionState.offline:
        return Icons.error_outline;
      case FlareConnectionState.sessionExpired:
        return Icons.lock_outline;
      case FlareConnectionState.kicked:
        return Icons.devices;
      case FlareConnectionState.sdkUnready:
        return Icons.info_outline;
    }
  }

  Color _toneColor(FlareColors colors) {
    switch (connectionTone(widget.state)) {
      case FlareStatusTone.success:
        return colors.success;
      case FlareStatusTone.warning:
        return colors.warning;
      case FlareStatusTone.danger:
        return colors.error;
      case FlareStatusTone.info:
        return colors.info;
      case FlareStatusTone.neutral:
        return colors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    final tone = _toneColor(colors);
    final hasDiagnostics = widget.diagnostics?.trim().isNotEmpty ?? false;
    // Visibility ignores busy (buttons stay in place); busy only disables them.
    final visible = availableConnectionActions(
      widget.state,
      hasReconnect: widget.onReconnect != null,
      hasReauth: widget.onReauth != null,
      hasDiagnostics: hasDiagnostics && widget.onCopyDiagnostics != null,
      busy: false,
    );
    final meta = <(String, String, bool)>[
      if (widget.transport != null)
        (widget.transportLabel, widget.transport!, false),
      if (widget.endpoint != null) (widget.endpointLabel, widget.endpoint!, true),
      if (widget.lastSyncAt != null)
        (widget.lastSyncLabel, widget.lastSyncAt!, false),
    ];
    return Semantics(
      container: true,
      label: widget.title,
      child: Container(
        padding: const EdgeInsets.all(FlareSizes.spacingLg),
        decoration: BoxDecoration(
          color: colors.bgPrimary,
          borderRadius: BorderRadius.circular(FlareSizes.radiusXl),
          border: Border.all(color: colors.borderPrimary),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: FlareSizes.fontSize2xl,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: FlareSizes.spacingMd),
            Semantics(
              liveRegion: true,
              child: Container(
                padding: const EdgeInsets.all(FlareSizes.spacingMd),
                decoration: BoxDecoration(
                  color: tone.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
                  border: Border.all(color: tone.withValues(alpha: 0.24)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(_stateIcon, size: 20, color: tone),
                    const SizedBox(width: FlareSizes.spacingMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _stateText,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: FlareSizes.fontSizeLg,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (widget.reason != null) ...[
                            const SizedBox(height: FlareSizes.spacingXs),
                            Text(
                              widget.reason!,
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: FlareSizes.fontSizeMd,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (connectionInProgress(widget.state)) ...[
              const SizedBox(height: FlareSizes.spacingMd),
              LinearProgressIndicator(
                semanticsLabel: _stateText,
                color: tone,
                backgroundColor: colors.bgSecondary,
              ),
            ],
            if (meta.isNotEmpty) ...[
              const SizedBox(height: FlareSizes.spacingMd),
              for (final (label, value, ellipsis) in meta)
                Padding(
                  padding: const EdgeInsets.only(bottom: FlareSizes.spacingSm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 88,
                        child: Text(
                          label,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: FlareSizes.fontSizeMd,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          value,
                          maxLines: ellipsis ? 1 : null,
                          overflow: ellipsis ? TextOverflow.ellipsis : null,
                          semanticsLabel: ellipsis ? value : null,
                          textDirection: ellipsis ? TextDirection.ltr : null,
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontSize: FlareSizes.fontSizeMd,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            if (visible.isNotEmpty) ...[
              const SizedBox(height: FlareSizes.spacingSm),
              Wrap(
                spacing: FlareSizes.spacingSm,
                runSpacing: FlareSizes.spacingSm,
                children: [
                  if (visible.contains(FlareConnectionAction.reconnect))
                    FilledButton(
                      onPressed: widget.busy ? null : widget.onReconnect,
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.primary,
                        minimumSize:
                            const Size(FlareSizes.touchTarget, FlareSizes.touchTarget),
                      ),
                      child: Text(widget.reconnectText),
                    ),
                  if (visible.contains(FlareConnectionAction.reauth))
                    FilledButton(
                      onPressed: widget.busy ? null : widget.onReauth,
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.primary,
                        minimumSize:
                            const Size(FlareSizes.touchTarget, FlareSizes.touchTarget),
                      ),
                      child: Text(widget.reauthText),
                    ),
                  if (visible.contains(FlareConnectionAction.copyDiagnostics))
                    OutlinedButton.icon(
                      onPressed: widget.busy ? null : widget.onCopyDiagnostics,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.textPrimary,
                        side: BorderSide(color: colors.borderPrimary),
                        minimumSize:
                            const Size(FlareSizes.touchTarget, FlareSizes.touchTarget),
                      ),
                      icon: const Icon(Icons.copy_outlined, size: 16),
                      label: Text(widget.copyDiagnosticsText),
                    ),
                ],
              ),
            ],
            if (hasDiagnostics) ...[
              const SizedBox(height: FlareSizes.spacingSm),
              Semantics(
                button: true,
                expanded: _diagnosticsOpen,
                child: TextButton.icon(
                  onPressed: () =>
                      setState(() => _diagnosticsOpen = !_diagnosticsOpen),
                  style: TextButton.styleFrom(
                    foregroundColor: colors.textSecondary,
                    alignment: Alignment.centerLeft,
                    minimumSize:
                        const Size(FlareSizes.touchTarget, FlareSizes.touchTarget),
                  ),
                  icon: Icon(
                    _diagnosticsOpen ? Icons.expand_more : Icons.chevron_right,
                    size: 16,
                  ),
                  label: Text(widget.diagnosticsLabel),
                ),
              ),
              if (_diagnosticsOpen)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 240),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(FlareSizes.spacingMd),
                    decoration: BoxDecoration(
                      color: colors.bgSecondary,
                      borderRadius: BorderRadius.circular(FlareSizes.radiusMd),
                    ),
                    child: SingleChildScrollView(
                      child: SelectableText(
                        widget.diagnostics!,
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: FlareSizes.fontSizeSm,
                          height: FlareSizes.lineHeightNormal,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
