import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';
import 'flare_avatar.dart';
import 'flare_call_controls.dart' show FlareCallMode;

/// Minimized ongoing-call dock — a floating pill showing the active call with
/// expand / mute / hang-up controls. Spec: Call/CallDock (`FlareCallDock`).
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

  static const Color _success = Color(0xFF34C759);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A2438), Color(0xFF191320)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(color: Color(0x40000000), blurRadius: 24, offset: Offset(0, 10)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onExpand,
            behavior: HitTestBehavior.opaque,
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
                      Text(title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: FlareSizes.fontSizeLg,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            mode == FlareCallMode.video ? Icons.videocam : Icons.call,
                            size: 12,
                            color: Colors.white.withValues(alpha: 0.66),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(durationLabel ?? 'Connected',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.66),
                                    fontSize: FlareSizes.fontSizeSm)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Icon(Icons.open_in_full,
                    size: 14, color: Colors.white.withValues(alpha: 0.5)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _circleButton(
            icon: muted ? Icons.mic_off : Icons.mic,
            onTap: onToggleMute,
            bg: muted ? Colors.white : Colors.white.withValues(alpha: 0.14),
            iconColor: muted ? const Color(0xFF191320) : Colors.white,
          ),
          const SizedBox(width: 8),
          _circleButton(
            icon: Icons.call,
            onTap: onHangup,
            bg: const Color(0xFFFF453A),
            iconColor: Colors.white,
            rotation: 135 * math.pi / 180,
          ),
        ],
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required VoidCallback? onTap,
    required Color bg,
    required Color iconColor,
    double rotation = 0,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle, color: bg),
        child: Transform.rotate(
          angle: rotation,
          child: Icon(icon, size: 18, color: iconColor),
        ),
      ),
    );
  }
}
