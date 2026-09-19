import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'action_icon.dart';
import 'flare_switch.dart';

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

/// `toggle` renders a switch (bool value); `choice` renders a radio group
/// ([FlareGroupJoinPolicy] value).
enum FlareGroupPermissionRowKind { toggle, choice }

/// The subset of the group model this panel edits.
@immutable
class FlareGroupPermissionSettings {
  const FlareGroupPermissionSettings({
    this.muteAll = false,
    this.onlyAdminCanAtAll = false,
    this.onlyAdminCanPin = false,
    this.shareCardPermission = true,
    this.joinPolicy,
  });
  final bool muteAll;
  final bool onlyAdminCanAtAll;
  final bool onlyAdminCanPin;
  final bool shareCardPermission;

  /// Who may join; null when the host does not know it.
  final FlareGroupJoinPolicy? joinPolicy;
}

/// One rendered row; [value] is a `bool` for toggle rows and a
/// [FlareGroupJoinPolicy] for the choice row — null when the policy is unknown.
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
  final Object? value;

  /// Viewer may change this row; `false` renders a read-only value, never a dead switch.
  final bool editable;

  /// This row's command is in flight — the row alone locks, its siblings stay usable.
  final bool busy;

  /// Why this row's last command failed; kept until the host dismisses it.
  final String? error;

  bool get boolValue => value == true;

  /// The choice row's policy; null when unknown (and on toggle rows).
  FlareGroupJoinPolicy? get joinPolicyValue => switch (value) {
    final FlareGroupJoinPolicy policy => policy,
    _ => null,
  };
}

/// The rows to render, in canonical order — same rule set as the other platforms.
///
/// [FlareGroupPermissionRow.editable] carries permission only (`canManage`), so a
/// read-only panel keeps showing values instead of disabled controls; `busy` and
/// `error` are per key, so one failed setting neither hides nor reverts the ones
/// that succeeded. An unknown `joinPolicy` stays null rather than a guessed
/// policy misreporting the group's real state.
List<FlareGroupPermissionRow> groupPermissionRows(
  FlareGroupPermissionSettings settings,
  bool canManage, [
  List<String> busyKeys = const <String>[],
  Map<String, String> errors = const <String, String>{},
]) {
  Object? valueOf(FlareGroupPermissionKey key) => switch (key) {
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
    this.title,
    this.readOnlyHintText,
    this.joinPolicyLabel,
    this.joinPolicyDescription,
    this.joinInviteText,
    this.joinApprovalText,
    this.joinOpenText,
    this.unknownJoinPolicyText,
    this.muteAllLabel,
    this.muteAllDescription,
    this.onlyAdminCanAtAllLabel,
    this.onlyAdminCanAtAllDescription,
    this.onlyAdminCanPinLabel,
    this.onlyAdminCanPinDescription,
    this.shareCardPermissionLabel,
    this.shareCardPermissionDescription,
    this.onText,
    this.offText,
    this.busyText,
    this.retryText,
    this.dismissErrorText,
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

  final String? title,
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

  /// The change a row asks for: a `bool` for a toggle, the picked
  /// [FlareGroupJoinPolicy] for the join policy.
  final void Function(FlareGroupPermissionKey key, Object value)? onChange;
  final void Function(FlareGroupPermissionKey key)? onDismissError;

  @override
  State<FlareGroupPermissionMatrix> createState() =>
      _FlareGroupPermissionMatrixState();
}

class _FlareGroupPermissionMatrixState
    extends State<FlareGroupPermissionMatrix> {
  String get _title =>
      widget.title ?? FlareStrings.of(context).groupPermissionMatrixTitle;
  String get _readOnlyHintText =>
      widget.readOnlyHintText ??
      FlareStrings.of(context).groupPermissionMatrixReadOnlyHint;
  String get _joinPolicyLabel =>
      widget.joinPolicyLabel ??
      FlareStrings.of(context).groupPermissionMatrixJoinPolicy;
  String get _joinPolicyDescription =>
      widget.joinPolicyDescription ??
      FlareStrings.of(context).groupPermissionMatrixJoinPolicyDescription;
  String get _joinInviteText =>
      widget.joinInviteText ??
      FlareStrings.of(context).groupPermissionMatrixJoinInvite;
  String get _joinApprovalText =>
      widget.joinApprovalText ??
      FlareStrings.of(context).groupPermissionMatrixJoinApproval;
  String get _joinOpenText =>
      widget.joinOpenText ??
      FlareStrings.of(context).groupPermissionMatrixJoinOpen;
  String get _unknownJoinPolicyText =>
      widget.unknownJoinPolicyText ??
      FlareStrings.of(context).groupPermissionMatrixUnknownJoinPolicy;
  String get _muteAllLabel =>
      widget.muteAllLabel ??
      FlareStrings.of(context).groupPermissionMatrixMuteAll;
  String get _muteAllDescription =>
      widget.muteAllDescription ??
      FlareStrings.of(context).groupPermissionMatrixMuteAllDescription;
  String get _onlyAdminCanAtAllLabel =>
      widget.onlyAdminCanAtAllLabel ??
      FlareStrings.of(context).groupPermissionMatrixOnlyAdminCanAtAll;
  String get _onlyAdminCanAtAllDescription =>
      widget.onlyAdminCanAtAllDescription ??
      FlareStrings.of(
        context,
      ).groupPermissionMatrixOnlyAdminCanAtAllDescription;
  String get _onlyAdminCanPinLabel =>
      widget.onlyAdminCanPinLabel ??
      FlareStrings.of(context).groupPermissionMatrixOnlyAdminCanPin;
  String get _onlyAdminCanPinDescription =>
      widget.onlyAdminCanPinDescription ??
      FlareStrings.of(context).groupPermissionMatrixOnlyAdminCanPinDescription;
  String get _shareCardPermissionLabel =>
      widget.shareCardPermissionLabel ??
      FlareStrings.of(context).groupPermissionMatrixShareCardPermission;
  String get _shareCardPermissionDescription =>
      widget.shareCardPermissionDescription ??
      FlareStrings.of(
        context,
      ).groupPermissionMatrixShareCardPermissionDescription;
  String get _onText =>
      widget.onText ?? FlareStrings.of(context).groupPermissionMatrixOn;
  String get _offText =>
      widget.offText ?? FlareStrings.of(context).groupPermissionMatrixOff;
  String get _busyText =>
      widget.busyText ?? FlareStrings.of(context).groupPermissionMatrixBusy;
  String get _retryText => widget.retryText ?? FlareStrings.of(context).retry;
  String get _dismissErrorText =>
      widget.dismissErrorText ??
      FlareStrings.of(context).groupPermissionMatrixDismissError;

  /// What this panel last asked for, per key, so "retry" resends the same intent.
  /// Not optimistic state: the rendered value stays the host's.
  final Map<FlareGroupPermissionKey, Object> _lastAttempt = {};

  bool get _canEdit => widget.canManage && widget.onChange != null;

  String _labelFor(FlareGroupPermissionKey key) => switch (key) {
    FlareGroupPermissionKey.joinPolicy => _joinPolicyLabel,
    FlareGroupPermissionKey.muteAll => _muteAllLabel,
    FlareGroupPermissionKey.onlyAdminCanAtAll => _onlyAdminCanAtAllLabel,
    FlareGroupPermissionKey.onlyAdminCanPin => _onlyAdminCanPinLabel,
    FlareGroupPermissionKey.shareCardPermission => _shareCardPermissionLabel,
  };

  String _descriptionFor(FlareGroupPermissionKey key) => switch (key) {
    FlareGroupPermissionKey.joinPolicy => _joinPolicyDescription,
    FlareGroupPermissionKey.muteAll => _muteAllDescription,
    FlareGroupPermissionKey.onlyAdminCanAtAll => _onlyAdminCanAtAllDescription,
    FlareGroupPermissionKey.onlyAdminCanPin => _onlyAdminCanPinDescription,
    FlareGroupPermissionKey.shareCardPermission =>
      _shareCardPermissionDescription,
  };

  static IconData _iconFor(FlareGroupPermissionKey key) =>
      flareIconGlyph(switch (key) {
        FlareGroupPermissionKey.joinPolicy => 'lock',
        FlareGroupPermissionKey.muteAll => 'silence',
        FlareGroupPermissionKey.onlyAdminCanAtAll => 'mention',
        FlareGroupPermissionKey.onlyAdminCanPin => 'pin',
        FlareGroupPermissionKey.shareCardPermission => 'share',
      });

  /// A choice's label; the choices show in [FlareGroupJoinPolicy.values] order
  /// (open, approval, invite).
  String _joinChoiceLabel(FlareGroupJoinPolicy policy) => switch (policy) {
    FlareGroupJoinPolicy.open => _joinOpenText,
    FlareGroupJoinPolicy.approval => _joinApprovalText,
    FlareGroupJoinPolicy.invite => _joinInviteText,
  };

  String _joinPolicyText(FlareGroupJoinPolicy? policy) =>
      policy == null ? _unknownJoinPolicyText : _joinChoiceLabel(policy);

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
    return row.kind == FlareGroupPermissionRowKind.toggle
        ? !row.boolValue
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final rows = groupPermissionRows(
      widget.settings,
      _canEdit,
      widget.busyKeys,
      widget.errors,
    );
    return Semantics(
      container: true,
      label: _title,
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
              _title,
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
                    _readOnlyHintText,
                    style: TextStyle(
                      color: colors.textTertiary,
                      fontSize: FlareSizes.fontSizeSm,
                    ),
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
            constraints: const BoxConstraints(
              minHeight: FlareSizes.touchTarget,
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _iconFor(row.key),
                    size: 18,
                    color: colors.primaryText,
                  ),
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
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: FlareSizes.fontSizeSm,
                        ),
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
                          row.boolValue ? _onText : _offText,
                          style: TextStyle(
                            color: colors.textSecondary,
                            fontSize: FlareSizes.fontSizeMd,
                          ),
                        )
                else if (!row.editable)
                  Flexible(
                    child: Text(
                      _joinPolicyText(row.joinPolicyValue),
                      textAlign: TextAlign.end,
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: FlareSizes.fontSizeMd,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (row.kind == FlareGroupPermissionRowKind.choice && row.editable)
            Padding(
              padding: const EdgeInsets.only(
                left: 44,
                top: FlareSizes.spacingXs,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final policy in FlareGroupJoinPolicy.values)
                        _choice(row, policy, _joinChoiceLabel(policy), colors),
                    ],
                  ),
                  if (row.joinPolicyValue == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _unknownJoinPolicyText,
                        style: TextStyle(
                          color: colors.warningText,
                          fontSize: FlareSizes.fontSizeSm,
                        ),
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
        label: _busyText,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: colors.textTertiary,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              _busyText,
              style: TextStyle(
                color: colors.textTertiary,
                fontSize: FlareSizes.fontSizeSm,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _choice(
    FlareGroupPermissionRow row,
    FlareGroupJoinPolicy value,
    String label,
    FlareColors colors,
  ) {
    final selected = row.joinPolicyValue == value;
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
            constraints: const BoxConstraints(
              minHeight: FlareSizes.touchTarget,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: selected ? colors.bgSelected : colors.bgSecondary,
              border: Border.all(
                color: selected ? colors.borderSelected : colors.borderPrimary,
              ),
              borderRadius: BorderRadius.circular(FlareSizes.radiusMd),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 14,
                  child: selected
                      ? Icon(Icons.check, size: 14, color: colors.primaryText)
                      : null,
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
          Icon(Icons.error_outline, size: 14, color: colors.errorText),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              row.error!,
              style: TextStyle(
                color: colors.errorText,
                fontSize: FlareSizes.fontSizeSm,
              ),
            ),
          ),
          if (row.editable && retry != null && !row.busy)
            TextButton(
              onPressed: () => _dispatch(row, retry),
              child: Text(
                _retryText,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: FlareSizes.fontSizeSm,
                ),
              ),
            ),
          if (widget.onDismissError != null)
            IconButton(
              onPressed: () => widget.onDismissError!(row.key),
              tooltip: _dismissErrorText,
              icon: Icon(Icons.close, size: 14, color: colors.textSecondary),
            ),
        ],
      ),
    );
  }
}
