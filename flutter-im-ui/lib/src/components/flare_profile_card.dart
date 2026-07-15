import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../tokens/flare_tokens.dart';
import 'flare_avatar.dart';

/// Mini profile card — the popover shown on tapping an avatar: identity,
/// presence, tags + message / voice / video.
/// Spec: Profile/ProfileCard (`FlareProfileCard`).
class FlareProfileCard extends StatelessWidget {
  const FlareProfileCard({
    super.key,
    required this.user,
    this.onMessage,
    this.onCall,
    this.onVideo,
  });

  final FlareContact user;
  final VoidCallback? onMessage;
  final VoidCallback? onCall;
  final VoidCallback? onVideo;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    return Container(
      width: 260,
      padding: const EdgeInsets.all(FlareSizes.spacingLg),
      decoration: BoxDecoration(
        color: colors.bgPrimary,
        borderRadius: BorderRadius.circular(FlareSizes.radiusXl),
        border: Border.all(color: colors.borderPrimary),
        boxShadow: const [
          BoxShadow(color: Color(0x2915131C), blurRadius: 28, offset: Offset(0, 12)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              FlareAvatar(
                userId: user.id,
                displayName: user.name,
                avatarUrl: user.avatarUrl,
                size: 56,
                presence: user.presence,
              ),
              const SizedBox(width: FlareSizes.spacingMd),
              Expanded(
                child: Text(user.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: FlareSizes.fontSize2xl,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          if (user.signature != null && user.signature!.isNotEmpty) ...[
            const SizedBox(height: FlareSizes.spacingMd),
            Text(user.signature!,
                style: TextStyle(color: colors.textSecondary, fontSize: FlareSizes.fontSizeLg)),
          ],
          const SizedBox(height: FlareSizes.spacingSm),
          Text(
            [
              'Flare ID · ${user.id}',
              if (user.region != null && user.region!.isNotEmpty) user.region!,
            ].join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colors.textTertiary, fontSize: FlareSizes.fontSizeSm),
          ),
          if (user.tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: user.tags
                  .map((t) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                        decoration: BoxDecoration(
                            color: colors.bgSelected, borderRadius: BorderRadius.circular(999)),
                        child: Text(t,
                            style: TextStyle(color: colors.primary, fontSize: FlareSizes.fontSizeXs)),
                      ))
                  .toList(),
            ),
          ],
          const SizedBox(height: FlareSizes.spacingLg),
          Row(
            children: [
              Expanded(
                child: _action(colors, Icons.chat_bubble_outline, 'Message', onMessage, primary: true),
              ),
              const SizedBox(width: FlareSizes.spacingSm),
              _action(colors, Icons.call_outlined, null, onCall),
              const SizedBox(width: FlareSizes.spacingSm),
              _action(colors, Icons.videocam_outlined, null, onVideo),
            ],
          ),
        ],
      ),
    );
  }

  Widget _action(FlareColors colors, IconData icon, String? label, VoidCallback? onTap,
      {bool primary = false}) {
    final child = Container(
      height: 38,
      width: label == null ? 44 : null,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: primary ? colors.primary : colors.bgSecondary,
        borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 17, color: primary ? Colors.white : colors.textPrimary),
          if (label != null) ...[
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    color: primary ? Colors.white : colors.textPrimary,
                    fontSize: FlareSizes.fontSizeLg,
                    fontWeight: FontWeight.w500)),
          ],
        ],
      ),
    );
    return GestureDetector(onTap: onTap, child: child);
  }
}
