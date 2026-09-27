import 'package:flutter/material.dart';

import '../models/directory_data.dart';
import '../platform/flare_platform.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_bottom_sheet.dart';
import 'flare_button.dart';
import 'flare_overlay.dart';
import 'flare_status_banner.dart';
import 'flare_transfer_queue.dart';
import 'flare_transfer_progress.dart';

enum FlareCapabilityState { loading, available, unavailable, denied, failed }

class FlareSceneAction {
  const FlareSceneAction({
    required this.id,
    required this.label,
    this.destructive = false,
    this.disabled = false,
  });
  final String id, label;
  final bool destructive, disabled;
}

class FlareSceneEntry {
  const FlareSceneEntry({
    required this.id,
    required this.title,
    required this.detail,
    this.badge,
    this.error,
    this.busy = false,
    this.actions = const [],
  });
  final String id, title, detail;
  final String? badge, error;
  final bool busy;
  final List<FlareSceneAction> actions;
}

class FlareDeviceSessionEntry extends FlareSceneEntry {
  const FlareDeviceSessionEntry({
    required super.id,
    required super.title,
    required super.detail,
    super.badge,
    super.error,
    super.busy,
    super.actions,
    this.current = false,
  });
  final bool current;
}

enum FlareMediaAvailability { available, expired, unavailable }

enum FlareMediaKind { image, video, audio, file }

class FlareMediaEntry extends FlareSceneEntry {
  const FlareMediaEntry({
    required super.id,
    required super.title,
    required super.detail,
    super.badge,
    super.error,
    super.busy,
    super.actions,
    required this.kind,
    required this.availability,
  });
  final FlareMediaKind kind;
  final FlareMediaAvailability availability;
}

class FlareNotificationPreference {
  const FlareNotificationPreference({
    required this.id,
    required this.title,
    required this.detail,
    required this.value,
    required this.enabled,
    this.busy = false,
  });
  final String id, title, detail;
  final bool value, enabled, busy;
}

typedef FlareSceneActionCallback = void Function(String id, String action);

class _SceneList extends StatelessWidget {
  const _SceneList({
    required this.title,
    required this.items,
    this.loading = false,
    this.error,
    this.onAction,
    this.onReload,
  });
  final String title;
  final List<FlareSceneEntry> items;
  final bool loading;
  final String? error;
  final FlareSceneActionCallback? onAction;
  final VoidCallback? onReload;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleMedium),
      if (loading) LinearProgressIndicator(semanticsLabel: title),
      if (error != null)
        FlareStatusBanner(
          text: error!,
          tone: FlareStatusTone.danger,
          actionText: FlareStrings.of(context).retry,
          onAction: loading ? null : onReload,
        ),
      if (items.isEmpty && !loading && error == null)
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(FlareStrings.of(context).noContent),
        ),
      for (final item in items)
        Padding(
          key: ValueKey(item.id),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(item.title, style: Theme.of(context).textTheme.titleSmall),
              if (item.badge != null) Text(item.badge!),
              Text(item.detail),
              if (item.error != null)
                Semantics(
                  liveRegion: true,
                  child: Text(
                    item.error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              if (item.busy)
                LinearProgressIndicator(semanticsLabel: item.title),
              Wrap(
                spacing: 8,
                children: [
                  for (final a in item.actions.where(
                    (a) => a.label.trim().isNotEmpty,
                  ))
                    TextButton(
                      onPressed: item.busy || a.disabled || onAction == null
                          ? null
                          : () => onAction!(item.id, a.id),
                      style: TextButton.styleFrom(
                        minimumSize: const Size(48, 48),
                        foregroundColor: a.destructive
                            ? Theme.of(context).colorScheme.error
                            : null,
                      ),
                      child: Text(a.label),
                    ),
                ],
              ),
            ],
          ),
        ),
    ],
  );
}

class FlareMemberPanel extends StatelessWidget {
  const FlareMemberPanel({
    super.key,
    required this.items,
    this.title = '群成员',
    this.loading = false,
    this.error,
    this.onAction,
    this.onReload,
  });
  final List<FlareSceneEntry> items;
  final String title;
  final bool loading;
  final String? error;
  final FlareSceneActionCallback? onAction;
  final VoidCallback? onReload;
  @override
  Widget build(BuildContext context) => _SceneList(
    title: title,
    items: items,
    loading: loading,
    error: error,
    onAction: onAction,
    onReload: onReload,
  );
}

class FlareDeviceSessions extends StatelessWidget {
  const FlareDeviceSessions({
    super.key,
    required this.items,
    this.title = '登录设备',
    this.currentText = '当前设备',
    this.loading = false,
    this.error,
    this.onAction,
    this.onReload,
  });
  final List<FlareDeviceSessionEntry> items;
  final String title, currentText;
  final bool loading;
  final String? error;
  final FlareSceneActionCallback? onAction;
  final VoidCallback? onReload;
  @override
  Widget build(BuildContext context) => _SceneList(
    title: title,
    items: [
      for (final i in items)
        FlareSceneEntry(
          id: i.id,
          title: i.title,
          detail: i.detail,
          badge: i.current ? currentText : i.badge,
          error: i.error,
          busy: i.busy,
          actions: i.current ? [] : i.actions,
        ),
    ],
    loading: loading,
    error: error,
    onAction: onAction,
    onReload: onReload,
  );
}

class FlareMediaCenter extends StatelessWidget {
  const FlareMediaCenter({
    super.key,
    required this.items,
    this.transfers,
    this.title = '文件与媒体',
    this.loading = false,
    this.error,
    this.onAction,
    this.onReload,
    this.onTransferAction,
    this.onRetryFailed,
  });
  final List<FlareMediaEntry> items;
  final List<FlareTransferQueueItem>? transfers;
  final String title;
  final bool loading;
  final String? error;
  final FlareSceneActionCallback? onAction;
  final VoidCallback? onReload;
  final void Function(String, FlareTransferAction)? onTransferAction;
  final ValueChanged<List<String>>? onRetryFailed;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      _SceneList(
        title: title,
        items: [
          for (final i in items)
            FlareSceneEntry(
              id: i.id,
              title: i.title,
              detail: i.detail,
              badge: i.badge,
              error: i.error,
              busy: i.busy,
              actions: i.actions
                  .where(
                    (a) =>
                        i.availability == FlareMediaAvailability.available ||
                        a.id != 'open',
                  )
                  .toList(),
            ),
        ],
        loading: loading,
        error: error,
        onAction: onAction,
        onReload: onReload,
      ),
      if (transfers != null)
        SizedBox(
          height: 400,
          child: FlareTransferQueue(
            items: transfers!,
            onAction: onTransferAction,
            onRetryFailed: onRetryFailed,
          ),
        ),
    ],
  );
}

class FlareCapabilityBoundary extends StatelessWidget {
  const FlareCapabilityBoundary({
    super.key,
    required this.state,
    required this.text,
    required this.child,
    this.actionText,
    this.onAction,
  });
  final FlareCapabilityState state;
  final String text;
  final String? actionText;
  final VoidCallback? onAction;
  final Widget child;
  @override
  Widget build(BuildContext context) => state == FlareCapabilityState.available
      ? child
      : Column(
          children: [
            if (state == FlareCapabilityState.loading)
              LinearProgressIndicator(semanticsLabel: text),
            FlareStatusBanner(
              text: text,
              tone: state == FlareCapabilityState.failed
                  ? FlareStatusTone.danger
                  : FlareStatusTone.neutral,
              actionText: actionText,
              onAction: state == FlareCapabilityState.loading ? null : onAction,
            ),
          ],
        );
}

class FlareNotificationPreferences extends StatelessWidget {
  const FlareNotificationPreferences({
    super.key,
    required this.items,
    required this.permission,
    required this.permissionText,
    this.permissionActionText,
    this.title = '通知设置',
    this.onChange,
    this.onPermissionAction,
  });
  final List<FlareNotificationPreference> items;
  final FlareCapabilityState permission;
  final String permissionText, title;
  final String? permissionActionText;
  final void Function(String, bool)? onChange;
  final VoidCallback? onPermissionAction;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(title, style: Theme.of(context).textTheme.titleMedium),
      FlareCapabilityBoundary(
        state: permission,
        text: permissionText,
        actionText: permissionActionText,
        onAction: onPermissionAction,
        child: Text(permissionText),
      ),
      for (final i in items)
        SwitchListTile(
          key: ValueKey(i.id),
          title: Text(i.title),
          subtitle: Text(i.detail),
          value: i.value,
          onChanged:
              permission != FlareCapabilityState.available ||
                  !i.enabled ||
                  i.busy ||
                  onChange == null
              ? null
              : (v) => onChange!(i.id, v),
        ),
    ],
  );
}

/// Destructive confirmation (spec DangerConfirm): what is about to happen,
/// to what, and a danger-styled confirm next to cancel. Present it with
/// [FlareDangerConfirm.show] — the kit's short-task surface, a bottom sheet on
/// the phone form factor and a centered FlareModal elsewhere — which locks
/// every way of closing it while the action runs.
///
/// On a kit overlay the surface carries the [title]; standing alone the widget
/// draws it as its own heading. [confirmText] and [cancelText] default to the
/// strings table.
class FlareDangerConfirm extends StatelessWidget {
  const FlareDangerConfirm({
    super.key,
    required this.title,
    required this.description,
    required this.target,
    this.busy = false,
    this.error,
    this.confirmText,
    this.cancelText,
    this.onConfirm,
    this.onCancel,
  });
  final String title, description, target;
  final String? confirmText, cancelText;
  final String? error;
  final bool busy;
  final VoidCallback? onConfirm, onCancel;

  /// Ask before a destructive step. Resolves true once confirmed and [action],
  /// when given, has succeeded; false when cancelled or dismissed. While
  /// [action] runs the confirmation shows busy and nothing closes it — not the
  /// scrim, a drag, Escape nor back; a failure keeps it open with the error so
  /// the user can retry or cancel.
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String description,
    String target = '',
    String? confirmText,
    String? cancelText,
    Future<void> Function()? action,
  }) async {
    final busy = ValueNotifier<bool>(false);
    try {
      final confirmed = await FlareBottomSheet.show<bool>(
        context,
        title: title,
        busy: busy,
        builder: (_) => _FlareDangerConfirmPresenter(
          busy: busy,
          title: title,
          description: description,
          target: target,
          confirmText: confirmText,
          cancelText: cancelText,
          action: action,
        ),
      );
      return confirmed ?? false;
    } finally {
      busy.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final onSurface = FlareOverlaySurface.maybeOf(context) != null;
    final error = this.error;
    final cancel = FlareButton(
      label: cancelText ?? strings.cancel,
      variant: FlareButtonVariant.secondary,
      size: FlareControlSize.lg,
      block: true,
      disabled: busy,
      onPressed: onCancel,
    );
    final confirm = FlareButton(
      label: confirmText ?? strings.confirm,
      variant: FlareButtonVariant.danger,
      size: FlareControlSize.lg,
      block: true,
      loading: busy,
      disabled: busy,
      onPressed: onConfirm,
    );
    // Thumb-reachable full-width keys on the phone form factor, danger last;
    // a trailing pair everywhere else.
    final stacked = flareCapabilitiesOf(context).bottomSheet;
    return PopScope(
      canPop: !busy,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          FlareSizes.spacingLg,
          onSurface ? FlareSizes.spacingXs : FlareSizes.spacingLg,
          FlareSizes.spacingLg,
          FlareSizes.spacingLg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!onSurface) ...[
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: FlareSizes.fontSizeXl,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: FlareSizes.spacingMd),
            ],
            Text(
              description,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: FlareSizes.fontSizeLg,
              ),
            ),
            if (target.isNotEmpty) ...[
              const SizedBox(height: FlareSizes.spacingSm),
              Text(
                target,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: FlareSizes.fontSizeLg,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (error != null) ...[
              const SizedBox(height: FlareSizes.spacingSm),
              Semantics(
                liveRegion: true,
                child: Text(
                  error,
                  style: TextStyle(
                    color: colors.errorText,
                    fontSize: FlareSizes.fontSizeMd,
                  ),
                ),
              ),
            ],
            const SizedBox(height: FlareSizes.spacingLg),
            if (stacked) ...[
              cancel,
              const SizedBox(height: FlareSizes.spacingSm),
              confirm,
            ] else
              Row(
                children: [
                  Expanded(child: cancel),
                  const SizedBox(width: FlareSizes.spacingMd),
                  Expanded(child: confirm),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _FlareDangerConfirmPresenter extends StatefulWidget {
  const _FlareDangerConfirmPresenter({
    required this.busy,
    required this.title,
    required this.description,
    required this.target,
    required this.confirmText,
    required this.cancelText,
    this.action,
  });
  final ValueNotifier<bool> busy;
  final String title, description, target;
  final String? confirmText, cancelText;
  final Future<void> Function()? action;

  @override
  State<_FlareDangerConfirmPresenter> createState() =>
      _FlareDangerConfirmPresenterState();
}

class _FlareDangerConfirmPresenterState
    extends State<_FlareDangerConfirmPresenter> {
  bool _busy = false;
  String? _error;

  void _setBusy(bool value) {
    _busy = value;
    widget.busy.value = value;
  }

  Future<void> _confirm() async {
    final action = widget.action;
    if (action == null) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _setBusy(true);
      _error = null;
    });
    try {
      await action();
      if (!mounted) return;
      _setBusy(false);
      Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _setBusy(false);
          _error = '$error';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => FlareDangerConfirm(
    title: widget.title,
    description: widget.description,
    target: widget.target,
    confirmText: widget.confirmText,
    cancelText: widget.cancelText,
    busy: _busy,
    error: _error,
    onConfirm: _confirm,
    onCancel: () => Navigator.of(context).pop(false),
  );
}
