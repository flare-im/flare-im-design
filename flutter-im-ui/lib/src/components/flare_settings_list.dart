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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: FlareSizes.spacingSm),
      children: [
        for (final section in sections) ...[
          if (section.title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(FlareSizes.spacingLg,
                  FlareSizes.spacingXs, FlareSizes.spacingLg, FlareSizes.spacingXs),
              child: Text(section.title!,
                  style: TextStyle(
                      color: colors.textTertiary, fontSize: FlareSizes.fontSizeSm)),
            ),
          // Aurora — rows float together on one elevated grouped card (iOS-style).
          Container(
            margin: const EdgeInsets.fromLTRB(FlareSizes.spacingMd, 0,
                FlareSizes.spacingMd, FlareSizes.spacingLg),
            decoration: BoxDecoration(
              color: colors.bgElevated,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: isDark ? const Color(0x80000000) : const Color(0x14151320),
                  blurRadius: isDark ? 24 : 22,
                  offset: const Offset(0, 8),
                ),
                if (isDark)
                  const BoxShadow(
                      color: Color(0x247C3AED), blurRadius: 12, offset: Offset(0, 2)),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < section.items.length; i++) ...[
                  if (i > 0)
                    Divider(height: 1, indent: FlareSizes.spacingMd, color: colors.borderSecondary),
                  FlareSettingsRow(item: section.items[i], onToggle: onToggle, onSelect: onSelect),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

}

/// One settings row — the single source of truth for how a [FlareSettingsItem]
/// renders (toggle / value / navigation). Shared by [FlareSettingsList] and
/// [FlareProfilePanel] so the two can't drift apart.
class FlareSettingsRow extends StatelessWidget {
  const FlareSettingsRow({super.key, required this.item, this.onToggle, this.onSelect});

  final FlareSettingsItem item;
  final void Function(FlareSettingsItem item, bool value)? onToggle;
  final ValueChanged<FlareSettingsItem>? onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
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
