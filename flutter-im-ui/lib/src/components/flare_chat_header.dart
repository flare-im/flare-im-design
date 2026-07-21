import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';
import 'flare_avatar.dart';

/// The active conversation's header — title, subtitle/presence, and actions.
/// Spec: Message/ChatHeader (`FlareChatHeader`). Usable as a `Scaffold.appBar`
/// (implements [PreferredSizeWidget]).
class FlareChatHeader extends StatelessWidget implements PreferredSizeWidget {
  const FlareChatHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.presence,
    this.avatarUserId,
    this.avatarUrl,
    this.onBack,
    this.onSearch,
    this.onCall,
    this.onDetails,
  });

  final String title;
  final String? subtitle;
  final FlarePresence? presence;

  /// Optional leading avatar (id seeds the fallback colour).
  final String? avatarUserId;
  final String? avatarUrl;

  final VoidCallback? onBack;
  final VoidCallback? onSearch;
  final VoidCallback? onCall;
  final VoidCallback? onDetails;

  @override
  Size get preferredSize => const Size.fromHeight(FlareSizes.headerHeight);

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    // Transparent bar — no filled surface or divider; it blends into the chat
    // canvas (no white top area). Back sits to the left of the avatar.
    return Container(
      height: FlareSizes.headerHeight,
      padding: const EdgeInsets.symmetric(horizontal: FlareSizes.spacingSm),
      child: Row(
        children: [
          if (onBack != null)
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              color: colors.textPrimary,
            ),
          if (avatarUserId != null) ...[
            FlareAvatar(
              userId: avatarUserId!,
              displayName: title,
              avatarUrl: avatarUrl,
              size: 36,
              presence: presence,
            ),
            const SizedBox(width: FlareSizes.spacingSm),
          ],
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: FlareSizes.fontSize3xl,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null && subtitle!.isNotEmpty)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: presence == FlarePresence.online
                          ? colors.success
                          : colors.textTertiary,
                      fontSize: FlareSizes.fontSizeSm,
                    ),
                  ),
              ],
            ),
          ),
          if (onSearch != null)
            _action(Icons.search_rounded, onSearch!, colors),
          if (onCall != null)
            _action(Icons.call_outlined, onCall!, colors),
          if (onDetails != null)
            _action(Icons.more_horiz_rounded, onDetails!, colors),
        ],
      ),
    );
  }

  Widget _action(IconData icon, VoidCallback onTap, FlareColors colors) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 22),
      color: colors.textSecondary,
    );
  }
}
