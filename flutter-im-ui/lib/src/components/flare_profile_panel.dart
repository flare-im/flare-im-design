import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../tokens/flare_tokens.dart';
import 'flare_avatar.dart';
import 'flare_settings_list.dart';

/// Personal center — avatar / name / id + entry list. Spec: Profile/ProfilePanel
/// (`FlareProfilePanel`).
class FlareProfilePanel extends StatelessWidget {
  const FlareProfilePanel({
    super.key,
    required this.user,
    this.entries = defaultEntries,
    this.onEdit,
    this.onEntry,
    this.onToggle,
  });

  final FlareUserProfile user;
  final List<FlareSettingsItem> entries;
  final VoidCallback? onEdit;
  final ValueChanged<FlareSettingsItem>? onEntry;

  /// Toggle-row callback — without this a `FlareSettingKind.toggle` entry can't
  /// report back, so hosts that pass toggles must supply it.
  final void Function(FlareSettingsItem item, bool value)? onToggle;

  static const List<FlareSettingsItem> defaultEntries = [
    FlareSettingsItem(key: 'favorites', label: 'Favorites', icon: Icons.star_outline),
    FlareSettingsItem(key: 'moments', label: 'Moments', icon: Icons.photo_library_outlined),
    FlareSettingsItem(key: 'settings', label: 'Settings', icon: Icons.settings_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: onEdit,
          child: Container(
            color: colors.bgSelected,
            padding: const EdgeInsets.all(FlareSizes.spacingLg),
            child: Row(
              children: [
                FlareAvatar(userId: user.id, displayName: user.name, avatarUrl: user.avatarUrl, size: 56),
                const SizedBox(width: FlareSizes.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(user.name,
                          style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: FlareSizes.fontSize3xl,
                              fontWeight: FontWeight.w600)),
                      if (user.flareId != null && user.flareId!.isNotEmpty)
                        Text('Flare ID: ${user.flareId}',
                            style: TextStyle(
                                color: colors.textTertiary,
                                fontSize: FlareSizes.fontSizeSm)),
                      if (user.signature != null && user.signature!.isNotEmpty)
                        Text(user.signature!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: FlareSizes.fontSizeSm)),
                    ],
                  ),
                ),
                Icon(Icons.qr_code, color: colors.textTertiary),
              ],
            ),
          ),
        ),
        const SizedBox(height: FlareSizes.spacingSm),
        for (var i = 0; i < entries.length; i++) ...[
          if (i > 0) Divider(height: 1, color: colors.borderSecondary),
          // Shared with FlareSettingsList: renders kind (toggle/value/navigation) + detail.
          FlareSettingsRow(item: entries[i], onSelect: onEntry, onToggle: onToggle),
        ],
      ],
    );
  }
}
