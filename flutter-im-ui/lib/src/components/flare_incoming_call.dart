import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';
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
                FlareAvatar(userId: callerName, displayName: callerName, avatarUrl: callerAvatarUrl, size: 104),
                const SizedBox(height: FlareSizes.spacingLg),
                Text(callerName,
                    style: const TextStyle(
                        color: Colors.white, fontSize: FlareSizes.fontSize4xl, fontWeight: FontWeight.w600)),
                const SizedBox(height: FlareSizes.spacingXs),
                Text(mode == FlareCallMode.video ? '邀请你视频通话' : '邀请你语音通话',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: FlareSizes.fontSizeLg)),
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
                _action(Icons.call_end, '拒绝', const Color(0xFFEF4444), onReject),
                _action(mode == FlareCallMode.video ? Icons.videocam_outlined : Icons.call_outlined, '接听',
                    const Color(0xFF22C55E), onAccept),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _action(IconData icon, String label, Color color, VoidCallback? onTap) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white),
          ),
        ),
        const SizedBox(height: FlareSizes.spacingSm),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 13)),
      ],
    );
  }
}
