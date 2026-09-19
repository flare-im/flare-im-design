import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_avatar.dart';
import 'flare_icon.dart';
import 'flare_settings_list.dart';
import 'icon_control.dart';

/// Personal center: a quiet identity card followed by grouped entry rows. Spec:
/// Profile/ProfilePanel (`FlareProfilePanel`).
///
/// The identity card sits on the same elevated surface, radius and shadow as
/// the groups below it: the profile is content, not a banner. Its identity row
/// (avatar, name, signature, Flare ID, chevron) is one control named
/// [FlareStrings.profilePanelEditProfile] that opens the editor ([onEdit]); the
/// QR button beside it is a separate control named [FlareStrings.myQrCode]
/// ([onQr]), not a gesture inside the row's. Each is present only with its
/// callback.
class FlareProfilePanel extends StatelessWidget {
  const FlareProfilePanel({
    super.key,
    required this.user,
    this.entries,
    this.sections,
    this.signaturePlaceholder,
    this.onEdit,
    this.onQr,
    this.onEntry,
    this.onToggle,
  });

  final FlareUserProfile user;

  /// Flat entry list — used only when [sections] is null. Null shows the
  /// default entries ([entriesFor]) labelled from the ambient [FlareStrings].
  final List<FlareSettingsItem>? entries;

  /// Grouped rows (iOS-style cards). Overrides [entries] when provided.
  final List<FlareSettingsSection>? sections;

  /// Placeholder shown in the header when the user has no signature yet.
  final String? signaturePlaceholder;

  /// Opens the profile editor from the identity row.
  final VoidCallback? onEdit;

  /// Opens the user's QR code — a control beside the identity row, not in it.
  final VoidCallback? onQr;
  final ValueChanged<FlareSettingsItem>? onEntry;

  /// Toggle-row callback — without this a `FlareSettingKind.toggle` entry can't
  /// report back, so hosts that pass toggles must supply it.
  final void Function(FlareSettingsItem item, bool value)? onToggle;

  /// The default entries — favorites, moments and settings — labelled from
  /// [strings] (`favorites`, `moments`, `settings`), so a host changes their
  /// copy through [FlareStringsScope]. Mirrors iOS
  /// `ProfilePanelView.entries(for:)`.
  static List<FlareSettingsItem> entriesFor(FlareStrings strings) => [
    FlareSettingsItem(key: 'favorites', label: strings.favorites, icon: 'star'),
    FlareSettingsItem(key: 'moments', label: strings.moments, icon: 'moments'),
    FlareSettingsItem(
      key: 'settings',
      label: strings.settings,
      icon: 'settings',
    ),
  ];

  /// The QR control's visible circle; its touch target is the kit's.
  static const double _qrSize = 40;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Normalize to grouped sections so the body has one render path.
    final groups =
        sections ??
        [FlareSettingsSection(items: entries ?? entriesFor(strings))];
    final card = _cardDecoration(colors, isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Identity card ────────────────────────────────────────────────────
        Container(
          margin: const EdgeInsets.fromLTRB(
            FlareSizes.spacingMd,
            FlareSizes.spacingMd,
            FlareSizes.spacingMd,
            0,
          ),
          decoration: card,
          clipBehavior: Clip.antiAlias,
          child: Material(
            type: MaterialType.transparency,
            // The QR control is the row's sibling, drawn over the space the
            // row leaves for it, so each is reached and named on its own.
            child: Stack(
              children: [
                _identity(colors, strings),
                if (onQr != null)
                  PositionedDirectional(
                    top: 0,
                    bottom: 0,
                    end:
                        FlareSizes.spacingMd +
                        (onEdit != null ? FlareSizes.iconSizeLg : 0),
                    child: Center(
                      child: FlareIconControl(
                        label: strings.myQrCode,
                        onTap: onQr,
                        child: SizedBox(
                          width: _qrSize,
                          height: _qrSize,
                          child: Center(
                            child: FlareIcon(
                              'qr',
                              color: colors.textSecondary,
                              size: FlareSizes.iconSizeMd,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        // ── Grouped entry cards ──────────────────────────────────────────────
        for (var gi = 0; gi < groups.length; gi++) ...[
          if (groups[gi].title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                FlareSizes.spacingLg,
                FlareSizes.spacingLg,
                FlareSizes.spacingLg,
                FlareSizes.spacingXs,
              ),
              child: Text(
                groups[gi].title!,
                style: TextStyle(
                  color: colors.textTertiary,
                  fontSize: FlareSizes.fontSizeSm,
                ),
              ),
            )
          else
            const SizedBox(height: FlareSizes.spacingMd),
          Container(
            margin: const EdgeInsets.symmetric(
              horizontal: FlareSizes.spacingMd,
            ),
            decoration: card,
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var i = 0; i < groups[gi].items.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      indent: FlareSizes.spacingMd,
                      color: colors.borderSecondary,
                    ),
                  // Shared with FlareSettingsList: renders kind + detail.
                  FlareSettingsRow(
                    item: groups[gi].items[i],
                    onSelect: onEntry,
                    onToggle: onToggle,
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// The identity row: avatar, name, signature and Flare ID in the text
  /// colours of the content around it. With [onEdit] it is one control named
  /// for what it does, with a trailing chevron; it leaves room at its end for
  /// the QR control.
  Widget _identity(FlareColors colors, FlareStrings strings) {
    final hasSignature = user.signature != null && user.signature!.isNotEmpty;
    final placeholder = signaturePlaceholder ?? '';
    final flareId = user.flareId ?? '';
    final row = Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        FlareSizes.spacingLg,
        FlareSizes.spacingLg,
        FlareSizes.spacingMd,
        FlareSizes.spacingLg,
      ),
      child: Row(
        children: [
          FlareAvatar(
            userId: user.id,
            displayName: user.name,
            avatarUrl: user.avatarUrl,
            size: 56,
          ),
          const SizedBox(width: FlareSizes.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: FlareSizes.fontSize3xl,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (hasSignature || placeholder.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      hasSignature ? user.signature! : placeholder,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: hasSignature
                            ? colors.textSecondary
                            : colors.textTertiary,
                        fontSize: FlareSizes.fontSizeMd,
                      ),
                    ),
                  ),
                if (flareId.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      'Flare ID: $flareId',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textTertiary,
                        fontSize: FlareSizes.fontSizeSm,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (onQr != null)
            const SizedBox(
              width: FlareSizes.spacingXs + FlareSizes.touchTarget,
            ),
          if (onEdit != null)
            Icon(Icons.chevron_right, color: colors.textTertiary),
        ],
      ),
    );
    if (onEdit == null) return row;
    return Semantics(
      container: true,
      button: true,
      label: strings.profilePanelEditProfile(user.name),
      onTap: onEdit,
      excludeSemantics: true,
      child: InkWell(onTap: onEdit, excludeFromSemantics: true, child: row),
    );
  }

  /// The elevated surface shared by the identity card and the entry groups.
  static BoxDecoration _cardDecoration(FlareColors colors, bool isDark) {
    return BoxDecoration(
      color: colors.bgElevated,
      borderRadius: BorderRadius.circular(FlareSizes.radiusXl),
      boxShadow: [
        BoxShadow(
          color: isDark ? const Color(0x80000000) : const Color(0x14151320),
          blurRadius: isDark ? 24 : 22,
          offset: const Offset(0, 8),
        ),
        if (isDark)
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.14),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
      ],
    );
  }
}
