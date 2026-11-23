import 'package:flutter/material.dart';

import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'call_stage.dart';
import 'flare_avatar.dart';
import 'flare_call_controls.dart' show FlareCallMode;
import 'flare_call_view.dart' show FlareCallState;
import 'flare_icon.dart';
import 'icon_control.dart';

/// Minimized ongoing-call dock — a floating pill on the call stage colour
/// showing the active call. Its main button (avatar, title, status) returns
/// to the full call; beside it sit the microphone toggle, announced as on
/// while the microphone is, and hang up. Spec: Call/CallDock
/// (`FlareCallDock`), docs/plugin-experience.md §3.5.
///
/// The status follows [state]: the duration once connected, waiting while
/// calling or ringing, a warning dot while reconnecting and the interrupted
/// text when failed; [statusDetail] replaces it.
class FlareCallDock extends StatelessWidget {
  const FlareCallDock({
    super.key,
    required this.title,
    this.avatarUrl,
    this.durationLabel,
    this.mode = FlareCallMode.audio,
    this.state = FlareCallState.connected,
    this.statusDetail,
    this.muted = false,
    this.onExpand,
    this.onToggleMute,
    this.onHangup,
  });

  final String title;
  final String? avatarUrl;
  final String? durationLabel;
  final FlareCallMode mode;
  final FlareCallState state;

  /// Host text that replaces the status line.
  final String? statusDetail;
  final bool muted;
  final VoidCallback? onExpand;
  final VoidCallback? onToggleMute;
  final VoidCallback? onHangup;

  /// §3.5: the name's widest run.
  static const double _nameMaxWidth = FlareSizes.componentCallDockNameMaxWidth;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final failed = state == FlareCallState.failed;
    // §12.17: the dock speaks in short phrases.
    final status =
        statusDetail ??
        switch (state) {
          FlareCallState.connected => durationLabel ?? strings.callConnected,
          FlareCallState.calling ||
          FlareCallState.ringing => strings.callDockWaiting,
          FlareCallState.reconnecting => strings.callReconnectingShort,
          FlareCallState.failed => strings.callInterrupted,
          FlareCallState.ended => callEndedText(strings, durationLabel),
        };
    final statusColor = failed
        ? colors.callErrorText
        : colors.callOnStageSecondary;
    return Container(
      constraints: const BoxConstraints(
        minHeight: FlareSizes.componentCallDockHeight,
      ),
      // The two controls are full touch targets around 36-point discs, so the
      // pill gives back the difference after the hang-up disc.
      padding: const EdgeInsetsDirectional.fromSTEB(
        FlareSizes.spacingXs,
        0,
        FlareSizes.spacingSm - _targetInset,
        0,
      ),
      decoration: callStageDecoration(colors).copyWith(
        borderRadius: BorderRadius.circular(FlareSizes.radiusFull),
        boxShadow: FlareShadows.of(Theme.of(context).brightness).lg,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Named for what it does, like the web dock's aria-label; the title
          // and status it shows stay out of the name.
          FlareIconControl(
            label: strings.callReturn,
            onTap: onExpand,
            tooltip: false,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // A 40 avatar; connected, the speaking-green ring breathes
                // outside it (still under reduced motion).
                CallHalo(
                  color: state == FlareCallState.connected
                      ? colors.callSpeaking
                      : Colors.transparent,
                  breathing: state == FlareCallState.connected,
                  inset: FlareSizes.spacingXs,
                  child: FlareAvatar(
                    userId: title,
                    displayName: title,
                    avatarUrl: avatarUrl,
                    size: FlareSizes.componentCallDockAvatarSize,
                  ),
                ),
                const SizedBox(width: FlareSizes.spacingSm),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _nameMaxWidth),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.callOnStage,
                          fontSize: FlareSizes.fontSizeLg,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: FlareSizes.spacing3xs),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (state == FlareCallState.reconnecting)
                            const CallPulseDot(size: FlareSizes.spacing2xs)
                          else
                            FlareIcon(
                              mode == FlareCallMode.video ? 'video' : 'phone',
                              size: FlareSizes.fontSizeSm,
                              color: statusColor,
                            ),
                          const SizedBox(width: FlareSizes.spacingXs),
                          Flexible(
                            child: Text(
                              status,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: statusColor,
                                fontSize: FlareSizes.fontSizeSm,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: FlareSizes.spacing2xs),
                FlareIcon(
                  'expand',
                  size: FlareSizes.fontSizeLg,
                  color: colors.callOnStageSecondary,
                ),
              ],
            ),
          ),
          const SizedBox(width: FlareSizes.spacingMd - _targetInset),
          _circleButton(
            icon: muted ? 'mic-off' : 'mic',
            label: strings.microphone,
            toggled: !muted,
            onTap: onToggleMute,
            bg: muted ? colors.callControlActive : colors.callControl,
            pressedBg: muted
                ? colors.callControlActive
                : colors.callControlHover,
            iconColor: muted ? colors.callOnControlActive : colors.callOnStage,
          ),
          _circleButton(
            icon: 'end-call',
            label: strings.hangUp,
            onTap: onHangup,
            bg: colors.callHangup,
            pressedBg: colors.callHangupPressed,
            iconColor: colors.callOnStage,
          ),
        ],
      ),
    );
  }

  static const double _disc = FlareSizes.componentCallDockKeySize;

  /// How far a control's touch target reaches past its disc on each side.
  static const double _targetInset = (FlareSizes.touchTarget - _disc) / 2;

  Widget _circleButton({
    required String icon,
    required String label,
    required VoidCallback? onTap,
    required Color bg,
    required Color pressedBg,
    required Color iconColor,
    bool? toggled,
  }) {
    return CallFocusRing(
      diameter: _disc,
      child: CallPressTint(
        builder: (active) => FlareIconControl(
          label: label,
          onTap: onTap,
          toggled: toggled,
          child: Container(
            width: _disc,
            height: _disc,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? pressedBg : bg,
            ),
            child: FlareIcon(
              icon,
              size: FlareSizes.iconSizeSm,
              color: iconColor,
            ),
          ),
        ),
      ),
    );
  }
}
