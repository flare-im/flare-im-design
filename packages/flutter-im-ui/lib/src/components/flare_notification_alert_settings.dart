import 'dart:async';

import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../models/notification_alert.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_bottom_sheet.dart';
import 'flare_radio_group.dart';
import 'flare_settings_list.dart';
import 'flare_time_picker.dart';

const _quietHoursRow = 'quietHours';
const _startRow = 'quietHoursStart';
const _endRow = 'quietHoursEnd';
const _repeatRow = 'quietHoursRepeat';
const _allowMentionsRow = 'quietHoursAllowMentions';
const _previewRow = 'notificationPreview';
const _multiDeviceRow = 'multiDevice';
const _weekdayPrefix = 'weekday:';

/// A person's notification preferences as settings sections. Spec:
/// Profile/NotificationAlertSettings (`FlareNotificationAlertSettings`).
///
/// Do not disturb: the Quiet hours switch and, while it is on, Starts, Ends
/// (read as the next day when it is not after the start), Repeat and Alert me
/// when mentioned. Notification content: Preview. Multiple devices: While
/// active elsewhere. Each section has its footer. Starts and Ends open
/// [FlareTimePicker.show], Repeat a kit sheet of seven day switches that never
/// empties, Preview and While active elsewhere a kit sheet with a vertical
/// [FlareRadioGroup] that applies the pick and closes. Every row reports the
/// whole next value through [onChange]; the host saves it. The value is the
/// protocol's shape (spec/notification-alert-vectors.json).
///
/// On its own it draws a list of the three sections. A settings page that is
/// already one [FlareSettingsList] passes [sectionsBuilder] and places them
/// among its own:
///
/// ```dart
/// FlareNotificationAlertSettings(
///   value: prefs,
///   onChange: notifications.updateSettings,
///   sectionsBuilder: (context, alerts, select, toggle) => FlareSettingsList(
///     sections: [general, ...alerts, about],
///     onSelect: (item) {
///       if (!select(item)) openPage(item);
///     },
///     onToggle: (item, on) {
///       if (!toggle(item, on)) setOwn(item, on);
///     },
///   ),
/// )
/// ```
class FlareNotificationAlertSettings extends StatefulWidget {
  const FlareNotificationAlertSettings({
    super.key,
    required this.value,
    this.disabled = false,
    this.onChange,
    this.sectionsBuilder,
  });

  /// The preferences shown.
  final FlareNotificationAlertPreferences value;

  /// The rows show the value but take no input (while the host saves or
  /// cannot write). A picker already open stays open and its pick still goes
  /// through [onChange].
  final bool disabled;

  /// The whole next value, after any row changed it.
  final ValueChanged<FlareNotificationAlertPreferences>? onChange;

  /// The section form: the host draws the list and gets the three sections
  /// with `select` and `toggle`, which run a row of the group and return
  /// whether it was one. Rows are keyed quietHours, quietHoursStart,
  /// quietHoursEnd, quietHoursRepeat, quietHoursAllowMentions,
  /// notificationPreview and multiDevice.
  final Widget Function(
    BuildContext context,
    List<FlareSettingsSection> sections,
    bool Function(FlareSettingsItem item) select,
    bool Function(FlareSettingsItem item, bool on) toggle,
  )?
  sectionsBuilder;

  @override
  State<FlareNotificationAlertSettings> createState() =>
      _FlareNotificationAlertSettingsState();
}

class _FlareNotificationAlertSettingsState
    extends State<FlareNotificationAlertSettings> {
  // An open sheet reads the newest value through this, so a pick the host
  // saved shows in the sheet at once.
  late final ValueNotifier<FlareNotificationAlertSettings> _current =
      ValueNotifier(widget);
  bool _pickerOpen = false;

  @override
  void didUpdateWidget(FlareNotificationAlertSettings oldWidget) {
    super.didUpdateWidget(oldWidget);
    // An open sheet is in another route: notifying it while this frame is
    // still building would mark it dirty mid-build. Tell it once the frame is
    // done; this state reads `widget` directly, so it is current already.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _current.value = widget;
    });
  }

  @override
  void dispose() {
    _current.dispose();
    super.dispose();
  }

  FlareNotificationAlertPreferences get _value => widget.value;

  void _emit(FlareNotificationAlertPreferences next) =>
      widget.onChange?.call(next);

  void _emitQuietHours(FlareQuietHours next) =>
      _emit(_value.copyWith(quietHours: next));

  List<FlareSettingsSection> _sections(FlareStrings strings) {
    final value = widget.value;
    final quiet = value.quietHours;
    final disabled = widget.disabled;
    return [
      FlareSettingsSection(
        title: strings.quietHoursTitle,
        footer: strings.quietHoursFooter,
        items: [
          FlareSettingsItem(
            key: _quietHoursRow,
            label: strings.quietHoursLabel,
            kind: FlareSettingKind.toggle,
            value: quiet.enabled,
            disabled: disabled,
          ),
          if (quiet.enabled) ...[
            FlareSettingsItem(
              key: _startRow,
              label: strings.quietHoursStart,
              detail: formatMinuteOfDay(quiet.startMinute),
              disabled: disabled,
            ),
            FlareSettingsItem(
              key: _endRow,
              label: strings.quietHoursEnd,
              detail: quietHoursEndText(quiet, strings: strings),
              disabled: disabled,
            ),
            FlareSettingsItem(
              key: _repeatRow,
              label: strings.quietHoursRepeat,
              detail: weekdaySummaryText(quiet.weekdays, strings: strings),
              disabled: disabled,
            ),
            FlareSettingsItem(
              key: _allowMentionsRow,
              label: strings.quietHoursAllowMentions,
              kind: FlareSettingKind.toggle,
              value: quiet.allowMentions,
              disabled: disabled,
            ),
          ],
        ],
      ),
      FlareSettingsSection(
        title: strings.notificationPreviewTitle,
        footer: strings.notificationPreviewFooter,
        items: [
          FlareSettingsItem(
            key: _previewRow,
            label: strings.notificationPreviewLabel,
            detail: notificationPreviewText(value.preview, strings: strings),
            disabled: disabled,
          ),
        ],
      ),
      FlareSettingsSection(
        title: strings.multiDeviceTitle,
        footer: strings.multiDeviceFooter,
        items: [
          FlareSettingsItem(
            key: _multiDeviceRow,
            label: strings.multiDeviceLabel,
            detail: multiDeviceAlertText(value.multiDevice, strings: strings),
            disabled: disabled,
          ),
        ],
      ),
    ];
  }

  /// Runs a picker row of the group and says whether [item] was one.
  bool _select(FlareSettingsItem item) {
    switch (item.key) {
      case _startRow:
        unawaited(_open(() => _pickTime(end: false)));
        return true;
      case _endRow:
        unawaited(_open(() => _pickTime(end: true)));
        return true;
      case _repeatRow:
        unawaited(_open(_pickWeekdays));
        return true;
      case _previewRow:
        unawaited(_open(_pickPreview));
        return true;
      case _multiDeviceRow:
        unawaited(_open(_pickMultiDevice));
        return true;
    }
    return false;
  }

  /// Runs a switch row of the group and says whether [item] was one.
  bool _toggle(FlareSettingsItem item, bool on) {
    switch (item.key) {
      case _quietHoursRow:
        if (!widget.disabled) {
          _emitQuietHours(_value.quietHours.copyWith(enabled: on));
        }
        return true;
      case _allowMentionsRow:
        if (!widget.disabled) {
          _emitQuietHours(_value.quietHours.copyWith(allowMentions: on));
        }
        return true;
    }
    return false;
  }

  Future<void> _open(Future<void> Function() picker) async {
    if (_pickerOpen || widget.disabled) return;
    _pickerOpen = true;
    try {
      await picker();
    } finally {
      _pickerOpen = false;
    }
  }

  Future<void> _pickTime({required bool end}) async {
    final strings = FlareStrings.of(context);
    final quiet = _value.quietHours;
    final picked = await FlareTimePicker.show(
      context,
      value: formatMinuteOfDay(end ? quiet.endMinute : quiet.startMinute),
      title: end ? strings.quietHoursEnd : strings.quietHoursStart,
      minuteStep: quietHoursMinuteStep,
    );
    if (picked == null || !mounted) return;
    final minute = parseMinuteOfDay(picked);
    _emitQuietHours(
      end
          ? _value.quietHours.copyWith(endMinute: minute)
          : _value.quietHours.copyWith(startMinute: minute),
    );
  }

  Future<void> _pickWeekdays() async {
    final strings = FlareStrings.of(context);
    await FlareBottomSheet.show<void>(
      context,
      title: strings.quietHoursRepeat,
      listenable: _current,
      builder: (context) {
        final strings = FlareStrings.of(context);
        final mask = _value.quietHours.weekdays;
        final onCount = [
          for (var day = 0; day < 7; day++)
            if (weekdayIsOn(mask, day)) day,
        ].length;
        return FlareSettingsList(
          shrinkWrap: true,
          onToggle: (item, on) {
            if (!item.key.startsWith(_weekdayPrefix)) return;
            final day = int.parse(item.key.substring(_weekdayPrefix.length));
            final current = _value.quietHours.weekdays;
            final next = weekdayToggle(current, day, on);
            if (next != current) {
              _emitQuietHours(_value.quietHours.copyWith(weekdays: next));
            }
          },
          sections: [
            FlareSettingsSection(
              items: [
                for (var day = 0; day < 7; day++)
                  FlareSettingsItem(
                    key: '$_weekdayPrefix$day',
                    label: weekdayName(day, strings: strings),
                    kind: FlareSettingKind.toggle,
                    value: weekdayIsOn(mask, day),
                    // The last day left cannot be turned off.
                    disabled: weekdayIsOn(mask, day) && onCount == 1,
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickPreview() async {
    final strings = FlareStrings.of(context);
    final picked = await _pickOne(
      title: strings.notificationPreviewLabel,
      value: _value.preview.name,
      options: [
        for (final preview in FlareNotificationPreview.values)
          FlareSelectOption(
            value: preview.name,
            label: notificationPreviewText(preview, strings: strings),
          ),
      ],
    );
    if (picked == null || !mounted) return;
    _emit(
      _value.copyWith(preview: FlareNotificationPreview.values.byName(picked)),
    );
  }

  Future<void> _pickMultiDevice() async {
    final strings = FlareStrings.of(context);
    final picked = await _pickOne(
      title: strings.multiDeviceLabel,
      value: _value.multiDevice.name,
      options: [
        for (final policy in FlareMultiDeviceAlert.values)
          FlareSelectOption(
            value: policy.name,
            label: multiDeviceAlertText(policy, strings: strings),
          ),
      ],
    );
    if (picked == null || !mounted) return;
    _emit(
      _value.copyWith(multiDevice: FlareMultiDeviceAlert.values.byName(picked)),
    );
  }

  /// A kit sheet with a vertical radio group; a pick closes it.
  Future<String?> _pickOne({
    required String title,
    required String value,
    required List<FlareSelectOption> options,
  }) => FlareBottomSheet.show<String>(
    context,
    title: title,
    builder: (sheet) => Padding(
      padding: const EdgeInsets.fromLTRB(
        FlareSizes.spacingLg,
        FlareSizes.spacingSm,
        FlareSizes.spacingLg,
        FlareSizes.spacingLg,
      ),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: FlareRadioGroup(
          vertical: true,
          value: value,
          options: options,
          onSelect: (picked) => Navigator.of(sheet).pop(picked),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final sections = _sections(FlareStrings.of(context));
    final sectionsBuilder = widget.sectionsBuilder;
    if (sectionsBuilder != null) {
      return sectionsBuilder(context, sections, _select, _toggle);
    }
    return FlareSettingsList(
      shrinkWrap: true,
      sections: sections,
      onSelect: _select,
      onToggle: (item, on) => _toggle(item, on),
    );
  }
}
