import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../tokens/flare_tokens.dart';
import 'flare_avatar.dart';
import 'flare_settings_list.dart';

/// Personal center — an aurora header (avatar / name / signature / id) over a
/// violet light source, followed by grouped cards of entry rows. The QR badge is
/// its own tap target ([onQr]), distinct from tapping the header ([onEdit]); a
/// trailing chevron marks the header as navigable. Spec: Profile/ProfilePanel
/// (`FlareProfilePanel`).
class FlareProfilePanel extends StatelessWidget {
  const FlareProfilePanel({
    super.key,
    required this.user,
    this.entries = defaultEntries,
    this.sections,
    this.signaturePlaceholder,
    this.onEdit,
    this.onQr,
    this.onEntry,
    this.onToggle,
  });

  final FlareUserProfile user;

  /// Flat entry list — used only when [sections] is null.
  final List<FlareSettingsItem> entries;

  /// Grouped rows (iOS-style cards). Overrides [entries] when provided.
  final List<FlareSettingsSection>? sections;

  /// Placeholder shown in the header when the user has no signature yet.
  final String? signaturePlaceholder;

  final VoidCallback? onEdit;

  /// QR badge tap — a distinct target from the header's [onEdit] tap.
  final VoidCallback? onQr;
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Normalize to grouped sections so the body has one render path.
    final groups = sections ?? [FlareSettingsSection(items: entries)];
    final hasSignature = user.signature != null && user.signature!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Aurora glow header ───────────────────────────────────────────────
        InkWell(
          onTap: onEdit,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF3B1F7A), Color(0xFF7C3AED), Color(0xFF8B5CF6)],
                stops: [0.0, 0.62, 1.0],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(
                FlareSizes.spacingLg, FlareSizes.spacingXl,
                FlareSizes.spacingLg, FlareSizes.spacingXl),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.22),
                        blurRadius: 0,
                        spreadRadius: 3,
                      ),
                      const BoxShadow(
                        color: Color(0x47000000),
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: FlareAvatar(
                      userId: user.id,
                      displayName: user.name,
                      avatarUrl: user.avatarUrl,
                      size: 56),
                ),
                const SizedBox(width: FlareSizes.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(user.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: FlareSizes.fontSize3xl,
                              fontWeight: FontWeight.w700)),
                      if (hasSignature)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(user.signature!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Color(0xD1FFFFFF),
                                  fontSize: FlareSizes.fontSizeMd)),
                        )
                      else if (signaturePlaceholder != null &&
                          signaturePlaceholder!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text(signaturePlaceholder!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Color(0x9EFFFFFF),
                                  fontSize: FlareSizes.fontSizeMd,
                                  fontStyle: FontStyle.italic)),
                        ),
                      if (user.flareId != null && user.flareId!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 3),
                          child: Text('Flare ID: ${user.flareId}',
                              style: const TextStyle(
                                  color: Color(0x9EFFFFFF),
                                  fontSize: FlareSizes.fontSizeSm)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: FlareSizes.spacingSm),
                // Own tap target — does not bubble to the header's onEdit.
                GestureDetector(
                  onTap: onQr,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.qr_code, color: Colors.white, size: 19),
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.chevron_right, color: Color(0xB3FFFFFF)),
              ],
            ),
          ),
        ),
        // ── Grouped entry cards ──────────────────────────────────────────────
        for (var gi = 0; gi < groups.length; gi++) ...[
          if (groups[gi].title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(FlareSizes.spacingLg,
                  FlareSizes.spacingLg, FlareSizes.spacingLg, FlareSizes.spacingXs),
              child: Text(groups[gi].title!,
                  style: TextStyle(
                      color: colors.textTertiary, fontSize: FlareSizes.fontSizeSm)),
            )
          else
            const SizedBox(height: FlareSizes.spacingMd),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: FlareSizes.spacingMd),
            decoration: BoxDecoration(
              color: colors.bgElevated,
              borderRadius: BorderRadius.circular(FlareSizes.radiusXl),
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
                for (var i = 0; i < groups[gi].items.length; i++) ...[
                  if (i > 0)
                    Divider(
                        height: 1,
                        indent: FlareSizes.spacingMd,
                        color: colors.borderSecondary),
                  // Shared with FlareSettingsList: renders kind + detail.
                  FlareSettingsRow(
                      item: groups[gi].items[i],
                      onSelect: onEntry,
                      onToggle: onToggle),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}
