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
/// How a [FlareProfilePanel] sits in its host (Vue `layout`).
enum FlareProfilePanelLayout {
  /// Sized to its content, inside a scrolling page.
  page,

  /// A desktop sidebar: the identity card stays at the top and the groups
  /// scroll in the height left under it. Needs a bounded height.
  sidebar,
}

class FlareProfilePanel extends StatelessWidget {
  const FlareProfilePanel({
    super.key,
    required this.user,
    this.entries,
    this.sections,
    this.signaturePlaceholder,
    this.identityActionLabel,
    this.onEdit,
    this.onQr,
    this.onEntry,
    this.onToggle,
    this.layout = FlareProfilePanelLayout.page,
  });

  final FlareUserProfile user;

  final FlareProfilePanelLayout layout;

  /// Flat entry list — used only when [sections] is null. Null shows the
  /// default entries ([entriesFor]) labelled from the ambient [FlareStrings].
  final List<FlareSettingsItem>? entries;

  /// Grouped rows (iOS-style cards). Overrides [entries] when provided.
  final List<FlareSettingsSection>? sections;

  /// Placeholder shown in the header when the user has no signature yet.
  final String? signaturePlaceholder;
  final String? identityActionLabel;

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
  static const double _avatarSize = 48;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final sidebar = layout == FlareProfilePanelLayout.sidebar;
    // Normalize to grouped sections so the body has one render path.
    final groups =
        sections ??
        [FlareSettingsSection(items: entries ?? entriesFor(strings))];
    final card = _cardDecoration(colors);

    final identity =
        // ── Identity card ────────────────────────────────────────────────────
        Container(
          margin: EdgeInsets.fromLTRB(
            sidebar ? FlareSizes.spacingSm : FlareSizes.spacingMd,
            sidebar ? FlareSizes.spacingSm : FlareSizes.spacingMd,
            sidebar ? FlareSizes.spacingSm : FlareSizes.spacingMd,
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
                _identity(colors, strings, sidebar),
                if (onQr != null)
                  PositionedDirectional(
                    top: 0,
                    bottom: 0,
                    end:
                        FlareSizes.spacingMd +
                        (onEdit != null
                            ? FlareSizes.iconSizeSm + FlareSizes.spacingXs
                            : 0),
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
        );
    final cards = [
      // ── Grouped entry cards ──────────────────────────────────────────────
      for (var gi = 0; gi < groups.length; gi++) ...[
        // Vue `.flare-profile__section`: 16 between blocks (12 in the
        // sidebar); a title sits 8 inside the cards' inset.
        SizedBox(height: sidebar ? FlareSizes.spacingMd : FlareSizes.spacingLg),
        if (groups[gi].title != null)
          Padding(
            padding: EdgeInsets.fromLTRB(
              (sidebar ? FlareSizes.spacingSm : FlareSizes.spacingMd) +
                  FlareSizes.spacingSm,
              0,
              FlareSizes.spacingMd + FlareSizes.spacingSm,
              sidebar ? FlareSizes.spacingXs : FlareSizes.spacingSm,
            ),
            child: Text(
              groups[gi].title!,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: FlareSizes.fontSizeSm,
                fontWeight: FontWeight.w500,
                height: FlareSizes.lineHeightNormal,
              ),
            ),
          ),
        Container(
          margin: EdgeInsets.symmetric(
            horizontal: sidebar ? FlareSizes.spacingSm : FlareSizes.spacingMd,
          ),
          // The sidebar's lists are rows on the rail, with no card.
          decoration: sidebar ? null : card,
          clipBehavior: sidebar ? Clip.none : Clip.antiAlias,
          child: Column(
            children: [
              for (var i = 0; i < groups[gi].items.length; i++) ...[
                if (i > 0 && sidebar)
                  const SizedBox(height: 2)
                else if (i > 0)
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
                  compact: sidebar,
                ),
              ],
            ],
          ),
        ),
      ],
    ];
    if (layout == FlareProfilePanelLayout.sidebar) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          identity,
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: FlareSizes.spacingMd),
              children: cards,
            ),
          ),
        ],
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [identity, ...cards],
    );
  }

  /// The identity row: avatar, name, signature and Flare ID in the text
  /// colours of the content around it. With [onEdit] it is one control named
  /// for what it does, with a trailing chevron; it leaves room at its end for
  /// the QR control.
  Widget _identity(FlareColors colors, FlareStrings strings, bool sidebar) {
    final hasSignature = user.signature != null && user.signature!.isNotEmpty;
    final placeholder = signaturePlaceholder ?? '';
    final flareId = user.flareId ?? '';
    final row = Padding(
      padding: const EdgeInsets.all(FlareSizes.spacingMd),
      child: Row(
        children: [
          FlareAvatar(
            userId: user.id,
            displayName: user.name,
            avatarUrl: user.avatarUrl,
            size: _avatarSize,
          ),
          const SizedBox(width: FlareSizes.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: sidebar
                        ? FlareSizes.fontSizeLg
                        : FlareSizes.fontSize3xl,
                    fontWeight: FontWeight.w600,
                    height: FlareSizes.lineHeightSnug,
                  ),
                ),
                if (flareId.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: FlareSizes.spacing3xs),
                    child: Text(
                      'Flare ID: $flareId',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: FlareSizes.fontSizeSm,
                      ),
                    ),
                  ),
                if (hasSignature || placeholder.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: FlareSizes.spacing2xs),
                    child: Text(
                      hasSignature ? user.signature! : placeholder,
                      maxLines: sidebar ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: hasSignature
                            ? colors.textSecondary
                            : colors.textTertiary,
                        fontSize: sidebar
                            ? FlareSizes.fontSizeSm
                            : FlareSizes.fontSizeMd,
                        height: FlareSizes.lineHeightNormal,
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
          if (onEdit != null) ...[
            const SizedBox(width: FlareSizes.spacingXs),
            Icon(
              Icons.chevron_right,
              color: colors.textTertiary,
              size: FlareSizes.iconSizeSm,
            ),
          ],
        ],
      ),
    );
    if (onEdit == null) return row;
    return Semantics(
      container: true,
      button: true,
      label: identityActionLabel ?? strings.profilePanelEditProfile(user.name),
      onTap: onEdit,
      excludeSemantics: true,
      child: InkWell(onTap: onEdit, excludeFromSemantics: true, child: row),
    );
  }

  /// The quiet surface shared by the identity card and the entry groups (Vue
  /// `.flare-profile__hdr` / `__list`): one hairline edge, no shadow.
  static BoxDecoration _cardDecoration(FlareColors colors) {
    return BoxDecoration(
      color: colors.bgElevated,
      borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
      border: Border.all(color: colors.borderSecondary),
    );
  }
}
