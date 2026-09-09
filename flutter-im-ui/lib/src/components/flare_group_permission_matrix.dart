import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';
import 'flare_switch.dart';

/// Join policy values as the backend defines them on the group model.
const int flareGroupJoinInvite = 1;
const int flareGroupJoinApproval = 2;
const int flareGroupJoinOpen = 3;

/// The five settings the matrix edits — one key per real backend field
/// (`FlareGroupDetailModel`: joinPolicy, muteAll, onlyAdminCanAtAll,
/// onlyAdminCanPin, shareCardPermission). Nothing here is invented.
enum FlareGroupPermissionKey {
  joinPolicy,
  muteAll,
  onlyAdminCanAtAll,
  onlyAdminCanPin,
  shareCardPermission,
}

/// `toggle` renders a switch (bool value); `choice` renders a radio group (int value).
enum FlareGroupPermissionRowKind { toggle, choice }

/// The subset of the group model this panel edits.
@immutable
class FlareGroupPermissionSettings {
  const FlareGroupPermissionSettings({
    this.muteAll = false,
    this.onlyAdminCanAtAll = false,
    this.onlyAdminCanPin = false,
    this.shareCardPermission = true,
    this.joinPolicy = flareGroupJoinApproval,
  });
  final bool muteAll;
  final bool onlyAdminCanAtAll;
  final bool onlyAdminCanPin;
  final bool shareCardPermission;

  /// 1 = invite only, 2 = approval required, 3 = open.
  final int joinPolicy;
}

/// One rendered row; [value] is a `bool` for toggle rows and an `int` for choice rows.
@immutable
class FlareGroupPermissionRow {
  const FlareGroupPermissionRow({
    required this.key,
    required this.kind,
    required this.value,
    required this.editable,
    required this.busy,
    this.error,
  });
  final FlareGroupPermissionKey key;
  final FlareGroupPermissionRowKind kind;
  final Object value;

  /// Viewer may change this row; `false` renders a read-only value, never a dead switch.
  final bool editable;

  /// This row's command is in flight — the row alone locks, its siblings stay usable.
  final bool busy;

  /// Why this row's last command failed; kept until the host dismisses it.
  final String? error;

  bool get boolValue => value == true;
  int get intValue => value is int ? value as int : -1;
}

/// True when [value] is one of the three defined join policies.
bool isGroupJoinPolicy(int value) =>
    value == flareGroupJoinInvite ||
    value == flareGroupJoinApproval ||
    value == flareGroupJoinOpen;

/// The rows to render, in canonical order — same rule set as the other platforms.
///
/// [FlareGroupPermissionRow.editable] carries permission only (`canManage`), so a
/// read-only panel keeps showing values instead of disabled controls; `busy` and
/// `error` are per key, so one failed setting neither hides nor reverts the ones
/// that succeeded. An unknown `joinPolicy` is passed through untouched rather
/// than misreporting the group's real state.
List<FlareGroupPermissionRow> groupPermissionRows(
  FlareGroupPermissionSettings settings,
  bool canManage, [
  List<String> busyKeys = const <String>[],
  Map<String, String> errors = const <String, String>{},
]) {
  Object valueOf(FlareGroupPermissionKey key) => switch (key) {
        FlareGroupPermissionKey.joinPolicy => settings.joinPolicy,
        FlareGroupPermissionKey.muteAll => settings.muteAll,
        FlareGroupPermissionKey.onlyAdminCanAtAll => settings.onlyAdminCanAtAll,
        FlareGroupPermissionKey.onlyAdminCanPin => settings.onlyAdminCanPin,
        FlareGroupPermissionKey.shareCardPermission => settings.shareCardPermission,
      };
  return [
    for (final key in FlareGroupPermissionKey.values)
      FlareGroupPermissionRow(
        key: key,
        kind: key == FlareGroupPermissionKey.joinPolicy
            ? FlareGroupPermissionRowKind.choice
            : FlareGroupPermissionRowKind.toggle,
        value: valueOf(key),
        editable: canManage,
        busy: busyKeys.contains(key.name),
        error: errors[key.name],
      ),
  ];
}

/// Group permission panel — the "group settings" section of group management.
///
/// The host owns the values: switching a row only calls [onChange], and the
/// displayed value flips when the host writes the confirmed settings back. Each
/// row has its own busy and its own failure, so a partial failure keeps the rows
/// that succeeded. Spec: Contacts/GroupPermissionMatrix.
class FlareGroupPermissionMatrix extends StatefulWidget {
  const FlareGroupPermissionMatrix({
    super.key,
    required this.settings,
    this.canManage = false,
    this.busyKeys = const <String>[],
    this.errors = const <String, String>{},
    this.title = '群设置',
    this.readOnlyHintText = '仅群主和管理员可修改',
    this.joinPolicyLabel = '加群方式',
    this.joinPolicyDescription = '决定他人如何加入本群',
    this.joinInviteText = '仅邀请',
    this.joinApprovalText = '需管理员审批',
    this.joinOpenText = '允许直接加入',
    this.unknownJoinPolicyText = '当前加群方式未知，请重新选择',
    this.muteAllLabel = '全员禁言',
    this.muteAllDescription = '开启后仅群主和管理员可发言',
    this.onlyAdminCanAtAllLabel = '仅管理员可 @所有人',
    this.onlyAdminCanAtAllDescription = '限制 @所有人 的使用范围',
    this.onlyAdminCanPinLabel = '仅管理员可置顶消息',
    this.onlyAdminCanPinDescription = '限制群内置顶消息的权限',
    this.shareCardPermissionLabel = '允许分享群名片',
    this.shareCardPermissionDescription = '关闭后成员不能把本群分享给他人',
    this.onText = '已开启',
    this.offText = '已关闭',
    this.busyText = '提交中',
    this.retryText = '重试',
    this.dismissErrorText = '忽略此错误',
    this.onChange,
    this.onDismissError,
  });

  final FlareGroupPermissionSettings settings;

  /// Viewer may edit; false renders read-only value rows, never dead switches.
  final bool canManage;

  /// Keys whose command is in flight — the host sets this before dispatching.
  final List<String> busyKeys;

  /// Per-key failure reason, kept on screen until the host dismisses it.
  final Map<String, String> errors;

  final String title,
      readOnlyHintText,
      joinPolicyLabel,
      joinPolicyDescription,
      joinInviteText,
      joinApprovalText,
      joinOpenText,
      unknownJoinPolicyText,
      muteAllLabel,
      muteAllDescription,
      onlyAdminCanAtAllLabel,
      onlyAdminCanAtAllDescription,
      onlyAdminCanPinLabel,
      onlyAdminCanPinDescription,
      shareCardPermissionLabel,
      shareCardPermissionDescription,
      onText,
      offText,
      busyText,
      retryText,
      dismissErrorText;

  final void Function(FlareGroupPermissionKey key, Object value)? onChange;
  final void Function(FlareGroupPermissionKey key)? onDismissError;

  @override
  State<FlareGroupPermissionMatrix> createState() => _FlareGroupPermissionMatrixState();
}

class _FlareGroupPermissionMatrixState extends State<FlareGroupPermissionMatrix> {
  /// What this panel last asked for, per key, so "retry" resends the same intent.
  /// Not optimistic state: the rendered value stays the host's.
  final Map<FlareGroupPermissionKey, Object> _lastAttempt = {};

  bool get _canEdit => widget.canManage && widget.onChange != null;

  String _labelFor(FlareGroupPermissionKey key) => switch (key) {
        FlareGroupPermissionKey.joinPolicy => widget.joinPolicyLabel,
        FlareGroupPermissionKey.muteAll => widget.muteAllLabel,
        FlareGroupPermissionKey.onlyAdminCanAtAll => widget.onlyAdminCanAtAllLabel,
        FlareGroupPermissionKey.onlyAdminCanPin => widget.onlyAdminCanPinLabel,
        FlareGroupPermissionKey.shareCardPermission => widget.shareCardPermissionLabel,
      };

  String _descriptionFor(FlareGroupPermissionKey key) => switch (key) {
        FlareGroupPermissionKey.joinPolicy => widget.joinPolicyDescription,
        FlareGroupPermissionKey.muteAll => widget.muteAllDescription,
        FlareGroupPermissionKey.onlyAdminCanAtAll => widget.onlyAdminCanAtAllDescription,
        FlareGroupPermissionKey.onlyAdminCanPin => widget.onlyAdminCanPinDescription,
        FlareGroupPermissionKey.shareCardPermission => widget.shareCardPermissionDescription,
      };

  static IconData _iconFor(FlareGroupPermissionKey key) => switch (key) {
        FlareGroupPermissionKey.joinPolicy => Icons.lock_outline,
        FlareGroupPermissionKey.muteAll => Icons.volume_off_outlined,
        FlareGroupPermissionKey.onlyAdminCanAtAll => Icons.alternate_email,
        FlareGroupPermissionKey.onlyAdminCanPin => Icons.push_pin_outlined,
        FlareGroupPermissionKey.shareCardPermission => Icons.share_outlined,
      };

  List<({int value, String label})> get _joinOptions => [
        (value: flareGroupJoinInvite, label: widget.joinInviteText),
        (value: flareGroupJoinApproval, label: widget.joinApprovalText),
        (value: flareGroupJoinOpen, label: widget.joinOpenText),
      ];

  String _joinPolicyText(int value) {
    for (final option in _joinOptions) {
      if (option.value == value) return option.label;
    }
    return widget.unknownJoinPolicyText;
  }

  void _dispatch(FlareGroupPermissionRow row, Object value) {
    if (!_canEdit || row.busy) return;
    setState(() => _lastAttempt[row.key] = value);
    widget.onChange!(row.key, value);
  }

  /// A choice row can be retried only when we know what was attempted; its
  /// options stay live either way.
  Object? _retryValue(FlareGroupPermissionRow row) {
    final attempted = _lastAttempt[row.key];
    if (attempted != null) return attempted;
    return row.kind == FlareGroupPermissionRowKind.toggle ? !row.boolValue : null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    final rows = groupPermissionRows(widget.settings, _canEdit, widget.busyKeys, widget.errors);
    return Semantics(
      container: true,
      label: widget.title,
      child: Container(
        decoration: BoxDecoration(
          color: colors.bgPrimary,
          border: Border.all(color: colors.borderPrimary),
          borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
        ),
        padding: const EdgeInsets.all(FlareSizes.spacingMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _head(colors),
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) Divider(height: 1, color: colors.borderSecondary),
              _row(rows[i], colors),
            ],
          ],
        ),
      ),
    );
  }

  Widget _head(FlareColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: FlareSizes.spacingSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              widget.title,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: FlareSizes.fontSizeLg,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (!_canEdit)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 14, color: colors.textTertiary),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    widget.readOnlyHintText,
                    style: TextStyle(color: colors.textTertiary, fontSize: FlareSizes.fontSizeSm),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _row(FlareGroupPermissionRow row, FlareColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: FlareSizes.spacingSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: FlareSizes.touchTarget),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_iconFor(row.key), size: 18, color: colors.primary),
                ),
                const SizedBox(width: FlareSizes.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _labelFor(row.key),
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: FlareSizes.fontSizeLg,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _descriptionFor(row.key),
                        style: TextStyle(color: colors.textSecondary, fontSize: FlareSizes.fontSizeSm),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: FlareSizes.spacingSm),
                if (row.busy) _busy(colors),
                if (row.kind == FlareGroupPermissionRowKind.toggle)
                  row.editable
                      ? FlareSwitch(
                          value: row.boolValue,
                          disabled: row.busy,
                          onChanged: (v) => _dispatch(row, v),
                        )
                      : Text(
                          row.boolValue ? widget.onText : widget.offText,
                          style: TextStyle(color: colors.textSecondary, fontSize: FlareSizes.fontSizeMd),
                        )
                else if (!row.editable)
                  Flexible(
                    child: Text(
                      _joinPolicyText(row.intValue),
                      textAlign: TextAlign.end,
                      style: TextStyle(color: colors.textSecondary, fontSize: FlareSizes.fontSizeMd),
                    ),
                  ),
              ],
            ),
          ),
          if (row.kind == FlareGroupPermissionRowKind.choice && row.editable)
            Padding(
              padding: const EdgeInsets.only(left: 44, top: FlareSizes.spacingXs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final option in _joinOptions)
                        _choice(row, option.value, option.label, colors),
                    ],
                  ),
                  if (!isGroupJoinPolicy(row.intValue))
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        widget.unknownJoinPolicyText,
                        style: TextStyle(color: colors.warning, fontSize: FlareSizes.fontSizeSm),
                      ),
                    ),
                ],
              ),
            ),
          if (row.error != null) _error(row, colors),
        ],
      ),
    );
  }

  Widget _busy(FlareColors colors) {
    return Padding(
      padding: const EdgeInsets.only(right: FlareSizes.spacingSm),
      child: Semantics(
        liveRegion: true,
        label: widget.busyText,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: colors.textTertiary),
            ),
            const SizedBox(width: 5),
            Text(
              widget.busyText,
              style: TextStyle(color: colors.textTertiary, fontSize: FlareSizes.fontSizeSm),
            ),
          ],
        ),
      ),
    );
  }

  Widget _choice(FlareGroupPermissionRow row, int value, String label, FlareColors colors) {
    final selected = row.intValue == value;
    final enabled = row.editable && !row.busy;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      enabled: enabled,
      label: label,
      child: InkWell(
        onTap: enabled ? () => _dispatch(row, value) : null,
        borderRadius: BorderRadius.circular(FlareSizes.radiusMd),
        child: Opacity(
          opacity: enabled ? 1 : 0.5,
          child: Container(
            constraints: const BoxConstraints(minHeight: FlareSizes.touchTarget),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: selected ? colors.bgSelected : colors.bgSecondary,
              border: Border.all(color: selected ? colors.borderSelected : colors.borderPrimary),
              borderRadius: BorderRadius.circular(FlareSizes.radiusMd),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  child: selected ? Icon(Icons.check, size: 14, color: colors.primary) : null,
                ),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? colors.primary : colors.textPrimary,
                    fontSize: FlareSizes.fontSizeMd,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _error(FlareGroupPermissionRow row, FlareColors colors) {
    final retry = _retryValue(row);
    return Container(
      margin: const EdgeInsets.only(left: 44, top: FlareSizes.spacingXs),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: colors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(FlareSizes.radiusSm),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 14, color: colors.error),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              row.error!,
              style: TextStyle(color: colors.error, fontSize: FlareSizes.fontSizeSm),
            ),
          ),
          if (row.editable && retry != null && !row.busy)
            TextButton(
              onPressed: () => _dispatch(row, retry),
              child: Text(
                widget.retryText,
                style: TextStyle(color: colors.textPrimary, fontSize: FlareSizes.fontSizeSm),
              ),
            ),
          if (widget.onDismissError != null)
            IconButton(
              onPressed: () => widget.onDismissError!(row.key),
              tooltip: widget.dismissErrorText,
              icon: Icon(Icons.close, size: 14, color: colors.textSecondary),
            ),
        ],
      ),
    );
  }
}
