import 'package:flutter/material.dart';

import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_avatar.dart';
import 'flare_call_controls.dart' show FlareCallMode;
import 'flare_icon.dart';
import 'icon_control.dart';

/// Minimized ongoing-call dock — a floating pill showing the active call. Its
/// main button (avatar, title, duration) returns to the full call; beside it
/// sit the microphone toggle, announced as on while the microphone is, and
/// hang up. Spec: Call/CallDock (`FlareCallDock`).
class FlareCallDock extends StatelessWidget {
  const FlareCallDock({
    super.key,
    required this.title,
    this.avatarUrl,
    this.durationLabel,
    this.mode = FlareCallMode.audio,
    this.muted = false,
    this.onExpand,
    this.onToggleMute,
    this.onHangup,
  });

  final String title;
  final String? avatarUrl;
  final String? durationLabel;
  final FlareCallMode mode;
  final bool muted;
  final VoidCallback? onExpand;
  final VoidCallback? onToggleMute;
  final VoidCallback? onHangup;

  static const Color _success = Color(0xFF34D17F);

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    return Container(
      // The two controls are full touch targets around 36-point discs, so the
      // pill gives back the difference to keep its size: less padding above,
      // below and after the hang-up disc.
      padding: const EdgeInsetsDirectional.fromSTEB(
        FlareSizes.spacingSm,
        FlareSizes.spacingXs,
        FlareSizes.spacingSm - _targetInset,
        FlareSizes.spacingXs,
      ),
      decoration: BoxDecoration(
        color: colors.messageOutgoingBackground,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Named for what it does, like the web dock's aria-label; the title
          // and duration it shows stay out of the name.
          FlareIconControl(
            label: strings.callReturn,
            onTap: onExpand,
            tooltip: false,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _success, width: 2),
                      ),
                    ),
                    FlareAvatar(
                      userId: title,
                      displayName: title,
                      avatarUrl: avatarUrl,
                      size: 34,
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 120),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.messageOutgoingForeground,
                          fontSize: FlareSizes.fontSizeLg,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            mode == FlareCallMode.video
                                ? Icons.videocam
                                : Icons.call,
                            size: 12,
                            color: colors.messageOutgoingForeground.withValues(
                              alpha: 0.66,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              durationLabel ?? strings.callConnected,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.messageOutgoingForeground
                                    .withValues(alpha: 0.66),
                                fontSize: FlareSizes.fontSizeSm,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                FlareIcon(
                  'expand',
                  size: 14,
                  color: colors.messageOutgoingForeground.withValues(
                    alpha: 0.5,
                  ),
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
            bg: muted
                ? colors.messageOutgoingForeground
                : colors.messageOutgoingForeground.withValues(alpha: 0.14),
            iconColor: muted
                ? colors.messageOutgoingBackground
                : colors.messageOutgoingForeground,
          ),
          _circleButton(
            icon: 'end-call',
            label: strings.hangUp,
            onTap: onHangup,
            bg: const Color(0xFFEF4444),
            iconColor: Colors.white,
          ),
        ],
      ),
    );
  }

  static const double _disc = 36;

  /// How far a control's touch target reaches past its disc on each side.
  static const double _targetInset = (FlareSizes.touchTarget - _disc) / 2;

  Widget _circleButton({
    required String icon,
    required String label,
    required VoidCallback? onTap,
    required Color bg,
    required Color iconColor,
    bool? toggled,
  }) {
    return FlareIconControl(
      label: label,
      onTap: onTap,
      toggled: toggled,
      child: Container(
        width: _disc,
        height: _disc,
        alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
        child: FlareIcon(icon, size: 18, color: iconColor),
      ),
    );
  }
}
