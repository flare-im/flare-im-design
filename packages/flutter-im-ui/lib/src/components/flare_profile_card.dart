import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_avatar.dart';
import 'icon_control.dart';

/// Mini profile card — the popover shown on tapping an avatar: identity,
/// presence, tags + message / voice / video.
/// Spec: Profile/ProfileCard (`FlareProfileCard`).
///
/// The meta line shows the public [FlareContact.flareId] (never the account
/// id) and the region, each only when set. Message, voice and video appear
/// only when the host handles them, as on `FlareContactDetail`.
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
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final meta = [
      if (user.flareId != null && user.flareId!.isNotEmpty)
        'Flare ID · ${user.flareId}',
      if (user.region != null && user.region!.isNotEmpty) user.region!,
    ];
    final actions = [
      if (onMessage != null)
        Expanded(
          child: _action(
            colors,
            Icons.chat_bubble_outline,
            strings.sendMessage,
            onMessage!,
            primary: true,
          ),
        ),
      if (onCall != null)
        _action(
          colors,
          Icons.call_outlined,
          strings.contactDetailVoice,
          onCall!,
        ),
      if (onVideo != null)
        _action(
          colors,
          Icons.videocam_outlined,
          strings.contactDetailVideo,
          onVideo!,
        ),
    ];
    return Container(
      width: 260,
      padding: const EdgeInsets.all(FlareSizes.spacingLg),
      decoration: BoxDecoration(
        color: colors.bgPrimary,
        borderRadius: BorderRadius.circular(FlareSizes.radiusXl),
        border: Border.all(color: colors.borderPrimary),
        boxShadow: const [
          BoxShadow(
            color: Color(0x2915131C),
            blurRadius: 28,
            offset: Offset(0, 12),
          ),
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
                child: Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: FlareSizes.fontSize2xl,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          if (user.signature != null && user.signature!.isNotEmpty) ...[
            const SizedBox(height: FlareSizes.spacingMd),
            Text(
              user.signature!,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: FlareSizes.fontSizeLg,
              ),
            ),
          ],
          if (meta.isNotEmpty) ...[
            const SizedBox(height: FlareSizes.spacingSm),
            Text(
              meta.join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.textTertiary,
                fontSize: FlareSizes.fontSizeSm,
              ),
            ),
          ],
          if (user.tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: user.tags
                  .map(
                    (t) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: colors.bgSelected,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        t,
                        style: TextStyle(
                          color: colors.primaryText,
                          fontSize: FlareSizes.fontSizeXs,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (actions.isNotEmpty) ...[
            // The touch targets add their own margin above the visible keys.
            const SizedBox(height: FlareSizes.spacingMd),
            Row(
              children: [
                for (var i = 0; i < actions.length; i++) ...[
                  if (i > 0) const SizedBox(width: FlareSizes.spacingSm),
                  actions[i],
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// A named control at least the touch target tall: the primary message
  /// action keeps its label, voice and video are named glyphs.
  Widget _action(
    FlareColors colors,
    IconData icon,
    String label,
    VoidCallback onTap, {
    bool primary = false,
  }) {
    final foreground = primary ? Colors.white : colors.textPrimary;
    return FlareIconControl(
      label: label,
      onTap: onTap,
      tooltip: !primary,
      child: Container(
        height: 38,
        width: primary ? null : 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: primary ? colors.primary : colors.bgSecondary,
          borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 17, color: foreground),
            if (primary) ...[
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: foreground,
                    fontSize: FlareSizes.fontSizeLg,
                    fontWeight: FontWeight.w500,
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
