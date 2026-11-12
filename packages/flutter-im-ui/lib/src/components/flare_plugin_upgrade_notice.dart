import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../models/plugin_view.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_button.dart';
import 'flare_empty_state.dart';
import 'flare_status_banner.dart';
import 'flare_tag.dart';

/// What a plugin contribution this build cannot draw shows instead
/// (unavailableReason upgrade_required; docs/plugin-components.md "升级提示";
/// spec/plugin-view-vectors.json upgradeNotice).
///
/// [FlarePluginUpgradeVariant.card] is a line and the update key inside a
/// message card (FlarePluginView draws it), [FlarePluginUpgradeVariant.entry]
/// the "需更新" mark beside a "+" or Me entry, [FlarePluginUpgradeVariant.page]
/// the whole page (FlarePluginPage draws it). The kit asks nothing: the host
/// reads update.plugin_upgrade_status for the placeholder's minBuild and
/// passes it as [status]; the update key shows only when that build is
/// offered to this device and [onUpdate] is given (it opens update.open_flow
/// or the platform update UI). Without a build only the copy shows.
class FlarePluginUpgradeNotice extends StatelessWidget {
  const FlarePluginUpgradeNotice({
    super.key,
    this.variant = FlarePluginUpgradeVariant.card,
    this.title,
    this.status,
    this.onUpdate,
    this.busy = false,
  });

  final FlarePluginUpgradeVariant variant;

  /// The page variant's heading (the placeholder's title); the kit's
  /// "需要更新应用" when null.
  final String? title;

  /// update.plugin_upgrade_status for the placeholder's minBuild; null while
  /// the host has not asked.
  final FlarePluginUpgradeStatus? status;

  /// Opens the update flow. Without it no key is drawn.
  final VoidCallback? onUpdate;

  /// The update flow is opening: the key spins.
  final bool busy;

  /// The update key (a test hook).
  static const Key actionKey = ValueKey('flare-plugin-upgrade-action');

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final mode = flarePluginUpgradeMode(status, canUpdate: onUpdate != null);
    final update = mode == FlarePluginUpgradeMode.update
        ? FlareButton(
            key: actionKey,
            label: strings.pluginUpgradeAction,
            variant: variant == FlarePluginUpgradeVariant.page
                ? FlareButtonVariant.primary
                : FlareButtonVariant.text,
            size: variant == FlarePluginUpgradeVariant.page
                ? FlareControlSize.md
                : FlareControlSize.sm,
            maintainTouchTarget: true,
            loading: busy,
            disabled: busy,
            onPressed: busy ? null : onUpdate,
          )
        : null;
    switch (variant) {
      case FlarePluginUpgradeVariant.entry:
        return FlareTag(
          key: const ValueKey('flare-plugin-upgrade-entry'),
          label: strings.pluginUpgradeBadge,
          tone: FlareStatusTone.warning,
        );
      case FlarePluginUpgradeVariant.page:
        return FlareEmptyState(
          key: ValueKey('flare-plugin-upgrade-page-${mode.name}'),
          title: title?.isNotEmpty == true
              ? title!
              : strings.pluginUpgradeTitle,
          description: mode == FlarePluginUpgradeMode.notAvailable
              ? strings.pluginUpgradeNotAvailable
              : strings.pluginUpgradeDescription,
          icon: 'info',
          actions: [if (update != null) update],
        );
      case FlarePluginUpgradeVariant.card:
        return Semantics(
          key: ValueKey('flare-plugin-upgrade-card-${mode.name}'),
          liveRegion: true,
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: FlareSizes.spacingSm,
            runSpacing: FlareSizes.spacing2xs,
            children: [
              Text(
                mode == FlarePluginUpgradeMode.notAvailable
                    ? strings.pluginUpgradeNotAvailable
                    : strings.pluginViewUnavailableUpgradeRequired,
                style: TextStyle(
                  fontSize: FlareSizes.fontSizeSm,
                  color: colors.textSecondary,
                ),
              ),
              if (update != null) update,
            ],
          ),
        );
    }
  }
}
