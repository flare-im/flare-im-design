import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';
import 'flare_icon.dart';
import 'flare_status_banner.dart';

/// Screen-share state reported by the host / RTC plugin.
///
/// * [idle] — nothing is being shared, the local user may start.
/// * [requesting] — a share was requested; waiting for the system / plugin.
/// * [sharing] — the local user is sharing.
/// * [viewing] — someone else is sharing and the local user is watching.
/// * [unavailable] — the runtime or plugin does not support screen sharing.
enum FlareScreenShareState { idle, requesting, sharing, viewing, unavailable }

enum FlareScreenShareAction { start, stop, cancel }

/// Semantic tone per state; every state also carries an icon and text, never
/// colour alone.
FlareStatusTone screenShareTone(FlareScreenShareState state) {
  switch (state) {
    case FlareScreenShareState.idle:
      return FlareStatusTone.neutral;
    case FlareScreenShareState.requesting:
      return FlareStatusTone.warning;
    case FlareScreenShareState.sharing:
      return FlareStatusTone.success;
    case FlareScreenShareState.viewing:
      return FlareStatusTone.info;
    case FlareScreenShareState.unavailable:
      return FlareStatusTone.neutral;
  }
}

/// Kit icon per state; the same semantic names resolve on Vue / iOS / Compose.
String screenShareIconName(FlareScreenShareState state) {
  switch (state) {
    case FlareScreenShareState.idle:
      return 'devices';
    case FlareScreenShareState.requesting:
      return 'refresh';
    case FlareScreenShareState.sharing:
      return 'video';
    case FlareScreenShareState.viewing:
      return 'eye';
    case FlareScreenShareState.unavailable:
      return 'block';
  }
}

/// Which actions are visible, and whether they may be pressed.
class FlareScreenShareActions {
  const FlareScreenShareActions({
    required this.start,
    required this.stop,
    required this.cancel,
    required this.enabled,
  });

  /// Visible only while idle and the host supplied a handler.
  final bool start;

  /// Visible only while sharing — a viewer can never stop someone else's share.
  final bool stop;

  /// Visible only while requesting.
  final bool cancel;

  /// false while busy: visible actions keep their place but cannot be pressed.
  final bool enabled;

  bool contains(FlareScreenShareAction action) {
    switch (action) {
      case FlareScreenShareAction.start:
        return start;
      case FlareScreenShareAction.stop:
        return stop;
      case FlareScreenShareAction.cancel:
        return cancel;
    }
  }

  bool get isEmpty => !start && !stop && !cancel;

  bool get isNotEmpty => !isEmpty;

  @override
  bool operator ==(Object other) =>
      other is FlareScreenShareActions &&
      other.start == start &&
      other.stop == stop &&
      other.cancel == cancel &&
      other.enabled == enabled;

  @override
  int get hashCode => Object.hash(start, stop, cancel, enabled);

  @override
  String toString() =>
      'FlareScreenShareActions(start: $start, stop: $stop, cancel: $cancel, enabled: $enabled)';
}

/// Actions the host may currently trigger. `viewing` and `unavailable` never
/// expose one — an unsupported runtime shows the reason instead of a button that
/// would do nothing. Visibility ignores [busy] on purpose so buttons do not
/// disappear mid-command.
FlareScreenShareActions screenShareActions(
  FlareScreenShareState state, {
  required bool hasStart,
  required bool hasStop,
  required bool hasCancel,
  bool busy = false,
}) {
  return FlareScreenShareActions(
    start: state == FlareScreenShareState.idle && hasStart,
    stop: state == FlareScreenShareState.sharing && hasStop,
    cancel: state == FlareScreenShareState.requesting && hasCancel,
    enabled: !busy,
  );
}

/// Screen-share control and status panel for an ongoing call. Capture, source
/// enumeration and encoding belong to the host / RTC plugin; this view only shows
/// the reported state and dispatches start / stop / cancel intents. Permission
/// denial is NOT handled here: the host renders
/// `FlarePermissionPrompt(kind: FlarePermissionKind.screen, state: FlarePermissionState.denied)`
/// instead. Spec: Call/ScreenShare (`FlareScreenShare`).
class FlareScreenShare extends StatelessWidget {
  const FlareScreenShare({
    super.key,
    required this.state,
    this.sourceLabel,
    this.presenterName,
    this.detail,
    this.busy = false,
    this.title = '屏幕共享',
    this.idleText = '未在共享',
    this.requestingText = '正在请求共享',
    this.sharingText = '正在共享屏幕',
    this.viewingText = '正在观看共享',
    this.unavailableText = '当前环境不支持屏幕共享',
    this.sourceRowLabel = '共享内容',
    this.presenterRowLabel = '共享者',
    this.startText = '共享屏幕',
    this.stopText = '停止共享',
    this.cancelText = '取消请求',
    this.onStart,
    this.onStop,
    this.onCancel,
  });

  final FlareScreenShareState state;

  /// What is being shared, e.g. "整个屏幕" / "Chrome 窗口"; shown while sharing.
  final String? sourceLabel;

  /// Who is sharing; shown while viewing.
  final String? presenterName;

  /// Extra host explanation, e.g. a bitrate-limited notice or why it is unavailable.
  final String? detail;

  final bool busy;
  final String title;
  final String idleText,
      requestingText,
      sharingText,
      viewingText,
      unavailableText;
  final String sourceRowLabel, presenterRowLabel;
  final String startText, stopText, cancelText;
  final VoidCallback? onStart, onStop, onCancel;

  String get _stateText {
    switch (state) {
      case FlareScreenShareState.idle:
        return idleText;
      case FlareScreenShareState.requesting:
        return requestingText;
      case FlareScreenShareState.sharing:
        return sharingText;
      case FlareScreenShareState.viewing:
        return viewingText;
      case FlareScreenShareState.unavailable:
        return unavailableText;
    }
  }

  Color _toneColor(FlareColors colors) {
    switch (screenShareTone(state)) {
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
    final active = state == FlareScreenShareState.sharing;
    // Visibility ignores busy (buttons stay in place); busy only disables them.
    final actions = screenShareActions(
      state,
      hasStart: onStart != null,
      hasStop: onStop != null,
      hasCancel: onCancel != null,
      busy: false,
    );
    final source = state == FlareScreenShareState.sharing
        ? (sourceLabel?.trim() ?? '')
        : '';
    final presenter = state == FlareScreenShareState.viewing
        ? (presenterName?.trim() ?? '')
        : '';
    final detailText = detail?.trim() ?? '';
    final meta = <(String, String)>[
      if (source.isNotEmpty) (sourceRowLabel, source),
      if (presenter.isNotEmpty) (presenterRowLabel, presenter),
    ];

    return Semantics(
      container: true,
      label: title,
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
              title,
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
                  color: tone.withValues(alpha: active ? 0.16 : 0.10),
                  borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
                  border: Border.all(
                    color: tone.withValues(alpha: active ? 0.44 : 0.24),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FlareIcon(screenShareIconName(state), size: 20, color: tone),
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
                          if (detailText.isNotEmpty) ...[
                            const SizedBox(height: FlareSizes.spacingXs),
                            Text(
                              detailText,
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
            if (state == FlareScreenShareState.requesting) ...[
              const SizedBox(height: FlareSizes.spacingMd),
              LinearProgressIndicator(
                semanticsLabel: requestingText,
                color: tone,
                backgroundColor: colors.bgSecondary,
              ),
            ],
            if (meta.isNotEmpty) ...[
              const SizedBox(height: FlareSizes.spacingMd),
              for (final (label, value) in meta)
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
            if (actions.isNotEmpty) ...[
              const SizedBox(height: FlareSizes.spacingSm),
              Wrap(
                spacing: FlareSizes.spacingSm,
                runSpacing: FlareSizes.spacingSm,
                children: [
                  if (actions.start)
                    FilledButton.icon(
                      onPressed: busy ? null : onStart,
                      style: FilledButton.styleFrom(
                        backgroundColor: colors.primary,
                        disabledBackgroundColor: colors.bgDisabled,
                        disabledForegroundColor: colors.textDisabled,
                        minimumSize: const Size(
                          FlareSizes.touchTarget,
                          FlareSizes.touchTarget,
                        ),
                      ),
                      icon: const Icon(Icons.devices_outlined, size: 16),
                      label: Text(startText),
                    ),
                  if (actions.stop)
                    OutlinedButton.icon(
                      onPressed: busy ? null : onStop,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.error,
                        disabledForegroundColor: colors.textDisabled,
                        side: BorderSide(
                          color: busy ? colors.borderPrimary : colors.error,
                        ),
                        minimumSize: const Size(
                          FlareSizes.touchTarget,
                          FlareSizes.touchTarget,
                        ),
                      ),
                      icon: const Icon(Icons.block, size: 16),
                      label: Text(stopText),
                    ),
                  if (actions.cancel)
                    OutlinedButton(
                      onPressed: busy ? null : onCancel,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colors.textPrimary,
                        disabledForegroundColor: colors.textDisabled,
                        side: BorderSide(color: colors.borderPrimary),
                        minimumSize: const Size(
                          FlareSizes.touchTarget,
                          FlareSizes.touchTarget,
                        ),
                      ),
                      child: Text(cancelText),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
