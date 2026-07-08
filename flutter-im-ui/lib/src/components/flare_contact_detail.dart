import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../tokens/flare_tokens.dart';
import 'flare_avatar.dart';

/// Contact name card — avatar/name/signature + message / voice / video.
/// Spec: Contacts/ContactDetail (`FlareContactDetail`).
class FlareContactDetail extends StatelessWidget {
  const FlareContactDetail({
    super.key,
    required this.contact,
    this.onMessage,
    this.onCall,
    this.onVideo,
  });

  final FlareContact contact;
  final VoidCallback? onMessage;
  final VoidCallback? onCall;
  final VoidCallback? onVideo;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(FlareSizes.spacingLg),
        child: Column(
          children: [
            FlareAvatar(
                userId: contact.id,
                displayName: contact.name,
                avatarUrl: contact.avatarUrl,
                size: 88,
                presence: contact.presence),
            const SizedBox(height: FlareSizes.spacingSm),
            Text(contact.name,
                style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: FlareSizes.fontSize4xl,
                    fontWeight: FontWeight.w600)),
            if (contact.signature != null && contact.signature!.isNotEmpty)
              Text(contact.signature!,
                  style: TextStyle(
                      color: colors.textTertiary, fontSize: FlareSizes.fontSizeLg)),
            const SizedBox(height: FlareSizes.spacing2xl),
            Row(
              children: [
                _action('发消息', Icons.chat_bubble_outline, onMessage, colors, primary: true),
                const SizedBox(width: FlareSizes.spacingMd),
                _action('语音', Icons.call_outlined, onCall, colors),
                const SizedBox(width: FlareSizes.spacingMd),
                _action('视频', Icons.videocam_outlined, onVideo, colors),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _action(String label, IconData icon, VoidCallback? onTap,
      FlareColors colors,
      {bool primary = false}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: FlareSizes.spacingMd),
          decoration: BoxDecoration(
            color: primary ? colors.primary : colors.bgSecondary,
            borderRadius: BorderRadius.circular(FlareSizes.radiusMd),
          ),
          child: Column(
            children: [
              Icon(icon, color: primary ? Colors.white : colors.textPrimary, size: 22),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      color: primary ? Colors.white : colors.textPrimary,
                      fontSize: FlareSizes.fontSizeSm)),
            ],
          ),
        ),
      ),
    );
  }
}
