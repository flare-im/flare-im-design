import 'dart:async';

import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_bottom_sheet.dart';
import 'flare_settings_list.dart';

/// The system notification permission, as a settings row says it.
enum FlareNotificationStatus { on, off, notTurnedOn }

/// What the system lets the app do in the background, in the words of the
/// platform's battery settings.
enum FlareBackgroundDelivery { unrestricted, optimized, restricted }

/// One extra way to keep background delivery working, offered by the host (a
/// phone maker's auto-start page).
@immutable
class FlareNotificationGuideAction {
  const FlareNotificationGuideAction({this.label, required this.onSelect});

  /// Row label; defaults to [FlareStrings.backgroundDeliveryAutoStart].
  final String? label;
  final VoidCallback onSelect;
}

/// The words of [status] in a settings row.
String notificationStatusLabel(
  FlareNotificationStatus status, {
  FlareStrings strings = const FlareStrings(),
}) {
  switch (status) {
    case FlareNotificationStatus.on:
      return strings.notificationStatusOn;
    case FlareNotificationStatus.off:
      return strings.notificationStatusOff;
    case FlareNotificationStatus.notTurnedOn:
      return strings.notificationStatusNotTurnedOn;
  }
}

/// The words of [background] in a settings row.
String backgroundDeliveryLabel(
  FlareBackgroundDelivery background, {
  FlareStrings strings = const FlareStrings(),
}) {
  switch (background) {
    case FlareBackgroundDelivery.unrestricted:
      return strings.backgroundDeliveryUnrestricted;
    case FlareBackgroundDelivery.optimized:
      return strings.backgroundDeliveryOptimized;
    case FlareBackgroundDelivery.restricted:
      return strings.backgroundDeliveryRestricted;
  }
}

const _statusRow = 'notifications';
const _backgroundRow = 'backgroundDelivery';
const _batteryRow = 'batteryUsage';
const _vendorPrefix = 'vendor:';

/// Whether new messages reach the person when the app is not in front, as one
/// settings section. Spec: Profile/NotificationDeliverySettings
/// (`FlareNotificationDeliverySettings`).
///
/// "New message notifications" shows the system permission ([status]; null
/// until it has been read) and hands the press to the host in
/// [onStatusAction]: the host asks for the permission or opens the system
/// settings, whichever the platform allows (without the callback the row is
/// information only). With [background] a second row shows what the battery
/// settings let the app do and opens a guide in the kit bottom sheet: why
/// background running matters, the battery settings ([onOpenBatterySettings])
/// and any auto-start pages the host knows of ([vendorActions]). The section
/// draws through [FlareSettingsList], so it looks like the settings around it,
/// and takes a [footer]. It reads nothing from the platform and opens nothing
/// itself.
///
/// On its own it draws the group as a list of one section. A settings page
/// that is already one [FlareSettingsList] passes [sectionBuilder] instead and
/// places the group among its own sections:
///
/// ```dart
/// FlareNotificationDeliverySettings(
///   status: status,
///   onStatusAction: push.enableOrOpenSettings,
///   sectionBuilder: (context, notifications, select) => FlareSettingsList(
///     sections: [general, notifications, about],
///     onSelect: (item) {
///       if (!select(item)) openPage(item);
///     },
///   ),
/// )
/// ```
class FlareNotificationDeliverySettings extends StatefulWidget {
  const FlareNotificationDeliverySettings({
    super.key,
    required this.status,
    this.background,
    this.vendorActions = const [],
    this.title,
    this.footer,
    this.onStatusAction,
    this.onOpenBatterySettings,
    this.sectionBuilder,
  });

  /// The system notification permission; null until it has been read.
  final FlareNotificationStatus? status;

  /// What the battery settings let the app do; null where the platform has no
  /// such setting (iOS, the web, desktop).
  final FlareBackgroundDelivery? background;

  /// Auto-start pages of the phone maker, offered in the background guide.
  final List<FlareNotificationGuideAction> vendorActions;

  /// Section header; defaults to [FlareStrings.notificationDeliveryTitle], an
  /// empty string draws none.
  final String? title;

  /// A note under the section.
  final String? footer;
  final VoidCallback? onStatusAction;
  final VoidCallback? onOpenBatterySettings;

  /// The section form: the host draws the list and gets the group as one
  /// [FlareSettingsSection] with `select`, which runs a row of the group (the
  /// status action, or the background guide in the kit bottom sheet) and
  /// returns whether the row was one; the host handles the rows it returns
  /// false for. The group's rows are keyed `notifications` and
  /// `backgroundDelivery`, so the host's own rows keep other keys.
  final Widget Function(
    BuildContext context,
    FlareSettingsSection section,
    bool Function(FlareSettingsItem item) select,
  )?
  sectionBuilder;

  @override
  State<FlareNotificationDeliverySettings> createState() =>
      _FlareNotificationDeliverySettingsState();
}

class _FlareNotificationDeliverySettingsState
    extends State<FlareNotificationDeliverySettings> {
  // The open guide reads the newest values through this, so a battery setting
  // changed in the system shows when the person comes back.
  late final ValueNotifier<FlareNotificationDeliverySettings> _current =
      ValueNotifier(widget);
  bool _guideOpen = false;

  @override
  void didUpdateWidget(FlareNotificationDeliverySettings oldWidget) {
    super.didUpdateWidget(oldWidget);
    _current.value = widget;
  }

  @override
  void dispose() {
    _current.dispose();
    super.dispose();
  }

  Future<void> _openGuide() async {
    if (_guideOpen) return;
    _guideOpen = true;
    final strings = FlareStrings.of(context);
    try {
      await FlareBottomSheet.show<void>(
        context,
        title: strings.backgroundDeliveryLabel,
        listenable: _current,
        builder: (_) => _BackgroundDeliveryGuide(settings: _current.value),
      );
    } finally {
      _guideOpen = false;
    }
  }

  /// Runs a row of the group and says whether [item] was one.
  bool _select(FlareSettingsItem item) {
    switch (item.key) {
      case _statusRow:
        widget.onStatusAction?.call();
        return true;
      case _backgroundRow when widget.background != null:
        unawaited(_openGuide());
        return true;
    }
    return false;
  }

  /// The group as one settings section: the permission, then the background
  /// row where the platform has one.
  FlareSettingsSection _section(FlareStrings strings) {
    final background = widget.background;
    final status = widget.status;
    final title = widget.title ?? strings.notificationDeliveryTitle;
    return FlareSettingsSection(
      title: title.isEmpty ? null : title,
      footer: widget.footer,
      items: [
        FlareSettingsItem(
          key: _statusRow,
          label: strings.notificationDeliveryNewMessages,
          icon: 'notification',
          kind: widget.onStatusAction == null
              ? FlareSettingKind.value
              : FlareSettingKind.navigation,
          detail: status == null
              ? null
              : notificationStatusLabel(status, strings: strings),
        ),
        if (background != null)
          FlareSettingsItem(
            key: _backgroundRow,
            label: strings.backgroundDeliveryLabel,
            icon: 'refresh',
            detail: backgroundDeliveryLabel(background, strings: strings),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final section = _section(FlareStrings.of(context));
    final sectionBuilder = widget.sectionBuilder;
    if (sectionBuilder != null) {
      return sectionBuilder(context, section, _select);
    }
    return FlareSettingsList(
      shrinkWrap: true,
      onSelect: _select,
      sections: [section],
    );
  }
}

/// The guide behind the background row: why it matters, the battery settings,
/// then the maker's auto-start pages.
class _BackgroundDeliveryGuide extends StatelessWidget {
  const _BackgroundDeliveryGuide({required this.settings});

  final FlareNotificationDeliverySettings settings;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final background = settings.background;
    final vendorActions = settings.vendorActions;
    final onOpenBatterySettings = settings.onOpenBatterySettings;
    final textStyle = TextStyle(
      color: colors.textSecondary,
      fontSize: FlareSizes.fontSizeMd,
      height: FlareSizes.lineHeightNormal,
    );
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: FlareSizes.spacingLg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: FlareSizes.spacingLg,
            ),
            child: Text(strings.backgroundDeliveryExplanation, style: textStyle),
          ),
          if (vendorActions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                FlareSizes.spacingLg,
                FlareSizes.spacingSm,
                FlareSizes.spacingLg,
                0,
              ),
              child: Text(
                strings.backgroundDeliveryAutoStartHint,
                style: textStyle,
              ),
            ),
          FlareSettingsList(
            shrinkWrap: true,
            onSelect: (item) {
              if (item.key == _batteryRow) {
                onOpenBatterySettings?.call();
                return;
              }
              if (!item.key.startsWith(_vendorPrefix)) return;
              final index = int.tryParse(
                item.key.substring(_vendorPrefix.length),
              );
              if (index != null && index >= 0 && index < vendorActions.length) {
                vendorActions[index].onSelect();
              }
            },
            sections: [
              FlareSettingsSection(
                items: [
                  FlareSettingsItem(
                    key: _batteryRow,
                    label: strings.backgroundDeliveryBattery,
                    kind: onOpenBatterySettings == null
                        ? FlareSettingKind.value
                        : FlareSettingKind.navigation,
                    detail: background == null
                        ? null
                        : backgroundDeliveryLabel(background, strings: strings),
                  ),
                  for (var i = 0; i < vendorActions.length; i++)
                    FlareSettingsItem(
                      key: '$_vendorPrefix$i',
                      label:
                          vendorActions[i].label ??
                          strings.backgroundDeliveryAutoStart,
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
