import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../tokens/flare_tokens.dart';
import 'flare_avatar.dart';

/// Directory row — avatar, name, signature, presence.
/// Spec: Contacts/ContactItem (`FlareContactItem`).
class FlareContactItem extends StatelessWidget {
  const FlareContactItem({
    super.key,
    required this.item,
    this.showPresence = true,
    this.onSelect,
  });

  final FlareContact item;
  final bool showPresence;
  final VoidCallback? onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    return InkWell(
      onTap: onSelect,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: FlareSizes.spacingMd, vertical: FlareSizes.spacingSm),
        child: Row(
          children: [
            FlareAvatar(
              userId: item.id,
              displayName: item.name,
              avatarUrl: item.avatarUrl,
              size: 40,
              presence: showPresence ? item.presence : null,
            ),
            const SizedBox(width: FlareSizes.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(item.name,
                      style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: FlareSizes.fontSizeXl,
                          fontWeight: FontWeight.w500)),
                  if (item.signature != null && item.signature!.isNotEmpty)
                    Text(item.signature!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            color: colors.textTertiary,
                            fontSize: FlareSizes.fontSizeSm)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Derives the A-Z index letter for a contact.
String flareContactLetter(FlareContact c) {
  final raw = (c.indexKey ?? (c.name.trim().isNotEmpty ? c.name.trim()[0] : '#'))
      .toUpperCase();
  final ch = raw.isNotEmpty ? raw[0] : '#';
  return (ch.compareTo('A') >= 0 && ch.compareTo('Z') <= 0) ? ch : '#';
}
