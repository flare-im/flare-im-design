import 'package:flutter/material.dart';

import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'action_icon.dart';
import 'flare_avatar.dart';
import 'flare_call_controls.dart';

/// Incoming call / invite — caller avatar/name, audio/video kind, accept &
/// reject. Spec: Call/IncomingCall (`FlareIncomingCall`).
class FlareIncomingCall extends StatelessWidget {
  const FlareIncomingCall({
    super.key,
    required this.callerName,
    required this.mode,
    this.callerAvatarUrl,
    this.onAccept,
    this.onReject,
  });

  final String callerName;
  final FlareCallMode mode;
  final String? callerAvatarUrl;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  @override
  Widget build(BuildContext context) {
    final strings = FlareStrings.of(context);
    final colors = FlareColors.of(context);
    return Container(
      color: const Color(0xFF111318),
      child: Stack(
        children: [
          Positioned(
            top: 96,
            left: 0,
            right: 0,
            child: Column(
              children: [
                FlareAvatar(
                  userId: callerName,
                  displayName: callerName,
                  avatarUrl: callerAvatarUrl,
                  size: 104,
                ),
                const SizedBox(height: FlareSizes.spacingLg),
                Text(
                  callerName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: FlareSizes.fontSize4xl,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: FlareSizes.spacingXs),
                Text(
                  mode == FlareCallMode.video
                      ? strings.incomingVideoCall
                      : strings.incomingVoiceCall,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: FlareSizes.fontSizeLg,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 56,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _action(
                  flareIconGlyph('end-call'),
                  strings.reject,
                  colors.error,
                  onReject,
                ),
                _action(
                  flareIconGlyph(
                    mode == FlareCallMode.video ? 'video' : 'phone',
                  ),
                  strings.accept,
                  colors.success,
                  onAccept,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _action(
    IconData icon,
    String label,
    Color color,
    VoidCallback? onTap,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          button: true,
          enabled: onTap != null,
          label: label,
          child: Material(
            color: color,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: SizedBox(
                width: 64,
                height: 64,
                child: Icon(icon, color: Colors.white),
              ),
            ),
          ),
        ),
        const SizedBox(height: FlareSizes.spacingSm),
        ExcludeSemantics(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
