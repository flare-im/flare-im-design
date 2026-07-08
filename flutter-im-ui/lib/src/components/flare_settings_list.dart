import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../tokens/flare_tokens.dart';

/// Settings list — grouped toggle / navigation / value rows. A generic settings
/// container. Spec: Profile/SettingsList (`FlareSettingsList`).
class FlareSettingsList extends StatelessWidget {
  const FlareSettingsList({
    super.key,
    required this.sections,
    this.onToggle,
    this.onSelect,
  });

  final List<FlareSettingsSection> sections;
  final void Function(FlareSettingsItem item, bool value)? onToggle;
  final ValueChanged<FlareSettingsItem>? onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    return ListView(
      children: [
        for (final section in sections) ...[
          if (section.title != null)
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: FlareSizes.spacingMd, vertical: FlareSizes.spacingSm),
              child: Text(section.title!,
                  style: TextStyle(
                      color: colors.textTertiary, fontSize: FlareSizes.fontSizeSm)),
            ),
          for (var i = 0; i < section.items.length; i++) ...[
            if (i > 0) Divider(height: 1, indent: FlareSizes.spacingMd, color: colors.borderSecondary),
            _row(section.items[i], colors),
          ],
        ],
      ],
    );
  }

  Widget _row(FlareSettingsItem item, FlareColors colors) {
    return InkWell(
      onTap: item.kind == FlareSettingKind.toggle ? null : () => onSelect?.call(item),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: FlareSizes.spacingMd, vertical: FlareSizes.spacingMd),
        child: Row(
          children: [
            if (item.icon != null) ...[
              Icon(item.icon, color: colors.textSecondary),
              const SizedBox(width: FlareSizes.spacingMd),
            ],
            Expanded(
                child: Text(item.label,
                    style: TextStyle(
                        color: colors.textPrimary, fontSize: FlareSizes.fontSizeLg))),
            switch (item.kind) {
              FlareSettingKind.toggle => Switch(
                  value: item.value,
                  activeTrackColor: colors.primary,
                  onChanged: (v) => onToggle?.call(item, v),
                ),
              FlareSettingKind.value => Text(item.detail ?? '',
                  style: TextStyle(
                      color: colors.textTertiary, fontSize: FlareSizes.fontSizeMd)),
              FlareSettingKind.navigation => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (item.detail != null)
                      Text(item.detail!,
                          style: TextStyle(
                              color: colors.textTertiary,
                              fontSize: FlareSizes.fontSizeMd)),
                    Icon(Icons.chevron_right, color: colors.textTertiary),
                  ],
                ),
            },
          ],
        ),
      ),
    );
  }
}
