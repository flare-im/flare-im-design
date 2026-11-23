import 'package:flutter/material.dart';

import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import '../models/directory_data.dart';
import 'flare_button.dart';
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
      return 'screen-share';
    case FlareScreenShareState.requesting:
      return 'refresh';
    case FlareScreenShareState.sharing:
      return 'video';
    case FlareScreenShareState.viewing:
      return 'eye';
    case FlareScreenShareState.unavailable:
      return 'warning';
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
    this.title,
    this.idleText,
    this.requestingText,
    this.sharingText,
    this.viewingText,
    this.unavailableText,
    this.sourceRowLabel,
    this.presenterRowLabel,
    this.startText,
    this.stopText,
    this.cancelText,
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

  /// Copy overrides; null takes the `screenShare*` entries of [FlareStrings].
  final String? title;
  final String? idleText,
      requestingText,
      sharingText,
      viewingText,
      unavailableText;
  final String? sourceRowLabel, presenterRowLabel;
  final String? startText, stopText, cancelText;
  final VoidCallback? onStart, onStop, onCancel;

  String _stateText(FlareStrings strings) {
    switch (state) {
      case FlareScreenShareState.idle:
        return idleText ?? strings.screenShareIdle;
      case FlareScreenShareState.requesting:
        return requestingText ?? strings.screenShareRequesting;
      case FlareScreenShareState.sharing:
        return sharingText ?? strings.screenShareSharing;
      case FlareScreenShareState.viewing:
        return viewingText ?? strings.screenShareViewing;
      case FlareScreenShareState.unavailable:
        return unavailableText ?? strings.screenShareUnavailable;
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
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final title = this.title ?? strings.screenShareTitle;
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
      if (source.isNotEmpty)
        (sourceRowLabel ?? strings.screenShareSourceRow, source),
      if (presenter.isNotEmpty)
        (presenterRowLabel ?? strings.screenSharePresenterRow, presenter),
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
                    FlareIcon(
                      screenShareIconName(state),
                      size: FlareSizes.iconSizeMd,
                      color: tone,
                    ),
                    const SizedBox(width: FlareSizes.spacingMd),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _stateText(strings),
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
              // Reduced motion: a still half bar instead of the sweep.
              LinearProgressIndicator(
                value: MediaQuery.maybeDisableAnimationsOf(context) ?? false
                    ? .5
                    : null,
                semanticsLabel: requestingText ?? strings.screenShareRequesting,
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
                      // One row at a time (source while sharing, presenter
                      // while viewing), so no shared label column.
                      Text(
                        label,
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: FlareSizes.fontSizeMd,
                        ),
                      ),
                      const SizedBox(width: FlareSizes.spacingMd),
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
                    FlareButton(
                      label: startText ?? strings.screenShareStart,
                      icon: 'screen-share',
                      size: FlareControlSize.lg,
                      disabled: busy,
                      onPressed: onStart,
                    ),
                  if (actions.stop)
                    FlareButton(
                      label: stopText ?? strings.screenShareStop,
                      icon: 'screen-share',
                      variant: FlareButtonVariant.danger,
                      size: FlareControlSize.lg,
                      disabled: busy,
                      onPressed: onStop,
                    ),
                  if (actions.cancel)
                    FlareButton(
                      label: cancelText ?? strings.screenShareCancel,
                      variant: FlareButtonVariant.secondary,
                      size: FlareControlSize.lg,
                      disabled: busy,
                      onPressed: onCancel,
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
