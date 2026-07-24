import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import 'flare_avatar.dart';
import 'flare_call_controls.dart';

/// Group (multi-party) call — participant grid, speaking highlight,
/// mute / camera badges. Spec: Call/GroupCallView (`FlareGroupCallView`).
class FlareGroupCallView extends StatelessWidget {
  const FlareGroupCallView({
    super.key,
    required this.participants,
    required this.mode,
    required this.state,
    this.title,
    this.durationLabel,
    this.muted = false,
    this.cameraOn = true,
    this.speakerOn = false,
    this.onHangup,
    this.onToggleMute,
    this.onToggleCamera,
    this.onToggleSpeaker,
    this.onSwitchCamera,
    this.onMinimize,
    this.tileBuilder,
  });

  final List<FlareCallParticipant> participants;
  final FlareCallMode mode;

  /// 'calling' | 'ringing' | 'connected'
  final String state;
  final String? title;
  final String? durationLabel;
  final bool muted;
  final bool cameraOn;
  final bool speakerOn;
  final VoidCallback? onHangup;
  final VoidCallback? onToggleMute;
  final VoidCallback? onToggleCamera;
  final VoidCallback? onToggleSpeaker;
  final VoidCallback? onSwitchCamera;
  final VoidCallback? onMinimize;

  /// Host injects each participant's video track; falls back to the avatar.
  final Widget Function(FlareCallParticipant participant)? tileBuilder;

  int get _cols {
    final n = participants.length;
    if (n <= 1) return 1;
    if (n <= 4) return 2;
    if (n <= 9) return 3;
    return 4;
  }

  String get _status {
    if (state == 'connected') return durationLabel ?? 'Connected';
    if (state == 'ringing') return 'Ringing…';
    return 'Calling…';
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF211D30), Color(0xFF17131F), Color(0xFF100C17)],
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
            child: Row(
              children: [
                _circleBtn(Icons.expand_more, onMinimize),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(title ?? '群通话',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                      Text('${participants.length} 人已加入 · $_status',
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.62), fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.count(
              crossAxisCount: _cols,
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.86,
              children: participants.map(_tile).toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 36),
            child: FlareCallControls(
              muted: muted,
              cameraOn: cameraOn,
              speakerOn: speakerOn,
              mode: mode,
              onToggleMute: onToggleMute,
              onToggleCamera: onToggleCamera,
              onToggleSpeaker: onToggleSpeaker,
              onSwitchCamera: onSwitchCamera,
              onHangup: onHangup,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(FlareCallParticipant p) {
    final content = tileBuilder != null
        ? tileBuilder!(p)
        : Center(
            child: FlareAvatar(userId: p.id, displayName: p.name, avatarUrl: p.avatarUrl, size: 56),
          );
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: p.isSelf
            ? const Color(0x297C3AED)
            : Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: p.speaking ? const Color(0xFF34D17F) : Colors.transparent,
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: content),
          Positioned(
            left: 8,
            right: 8,
            bottom: 8,
            child: Row(
              children: [
                if (p.muted)
                  _badge(const Icon(Icons.mic_off, color: Colors.white, size: 12))
                else if (p.cameraOff && mode == FlareCallMode.video)
                  _badge(const Icon(Icons.videocam_off, color: Colors.white, size: 12)),
                if (p.muted || (p.cameraOff && mode == FlareCallMode.video))
                  const SizedBox(width: 5),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.42),
                        borderRadius: BorderRadius.circular(6)),
                    child: Text(p.isSelf ? '${p.name} (me)' : p.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.white, fontSize: 12)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(Widget icon) => Container(
        width: 20,
        height: 20,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.42), borderRadius: BorderRadius.circular(6)),
        child: icon,
      );

  Widget _circleBtn(IconData icon, VoidCallback? onTap) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12), shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      );
}
