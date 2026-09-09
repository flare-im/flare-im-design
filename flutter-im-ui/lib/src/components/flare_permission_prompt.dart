import 'package:flutter/material.dart';

import '../tokens/flare_tokens.dart';
import 'flare_icon.dart';
import 'flare_primary_button.dart';

/// Which system permission the prompt explains. Spec: General/PermissionPrompt.
enum FlarePermissionKind {
  microphone,
  camera,
  notifications,
  storage,
  photos,
  contacts,
  location,
}

/// Host-reported permission state; the widget never queries the platform.
enum FlarePermissionState { undetermined, denied, restricted, unavailable }

/// Action visibility computed from state + which callbacks the host supplied.
@immutable
class FlarePermissionActions {
  const FlarePermissionActions({
    required this.request,
    required this.openSettings,
    required this.dismiss,
    required this.enabled,
  });

  /// Visible only while undetermined and the host supplied a handler.
  final bool request;

  /// Visible only while denied and the host supplied a handler.
  final bool openSettings;

  /// Visible whenever the host supplied a handler (any state).
  final bool dismiss;

  /// false while busy: visible actions stay rendered but disabled.
  final bool enabled;
}

FlarePermissionActions permissionActions(
  FlarePermissionState state, {
  required bool hasRequest,
  required bool hasOpenSettings,
  required bool hasDismiss,
  bool busy = false,
}) =>
    FlarePermissionActions(
      request: state == FlarePermissionState.undetermined && hasRequest,
      openSettings: state == FlarePermissionState.denied && hasOpenSettings,
      dismiss: hasDismiss,
      enabled: !busy,
    );

/// Default copy for a kind + state pair.
@immutable
class FlarePermissionCopy {
  const FlarePermissionCopy({
    required this.title,
    required this.description,
    required this.primaryLabel,
  });
  final String title, description, primaryLabel;
}

const Map<FlarePermissionKind, String> _kindNoun = {
  FlarePermissionKind.microphone: '麦克风',
  FlarePermissionKind.camera: '摄像头',
  FlarePermissionKind.notifications: '通知',
  FlarePermissionKind.storage: '存储空间',
  FlarePermissionKind.photos: '相册',
  FlarePermissionKind.contacts: '通讯录',
  FlarePermissionKind.location: '位置信息',
};
const Map<FlarePermissionKind, String> _kindVerb = {
  FlarePermissionKind.microphone: '使用麦克风',
  FlarePermissionKind.camera: '使用摄像头',
  FlarePermissionKind.notifications: '发送通知',
  FlarePermissionKind.storage: '访问存储空间',
  FlarePermissionKind.photos: '访问相册',
  FlarePermissionKind.contacts: '访问通讯录',
  FlarePermissionKind.location: '获取位置信息',
};

/// Kit icon name per kind (same semantic names on every platform).
String permissionIconName(FlarePermissionKind kind) {
  switch (kind) {
    case FlarePermissionKind.microphone:
      return 'mic';
    case FlarePermissionKind.camera:
      return 'camera';
    case FlarePermissionKind.notifications:
      return 'notification';
    case FlarePermissionKind.storage:
      return 'folder';
    case FlarePermissionKind.photos:
      return 'image';
    case FlarePermissionKind.contacts:
      return 'people';
    case FlarePermissionKind.location:
      return 'location';
  }
}

/// State glyph so status never relies on colour alone.
String permissionStateIconName(FlarePermissionState state) {
  switch (state) {
    case FlarePermissionState.undetermined:
      return 'info';
    case FlarePermissionState.denied:
      return 'block';
    case FlarePermissionState.restricted:
      return 'lock';
    case FlarePermissionState.unavailable:
      return 'warning';
  }
}

/// `featureLabel` (e.g. "发送语音消息") is embedded in the description.
FlarePermissionCopy defaultPermissionCopy(
  FlarePermissionKind kind,
  FlarePermissionState state, {
  String? featureLabel,
}) {
  final feature = (featureLabel?.trim().isNotEmpty ?? false)
      ? featureLabel!.trim()
      : '此功能';
  final verb = _kindVerb[kind]!;
  final title = '需要${_kindNoun[kind]}权限';
  switch (state) {
    case FlarePermissionState.undetermined:
      return FlarePermissionCopy(
        title: title,
        description: '$feature需要$verb，请允许后继续。',
        primaryLabel: '允许',
      );
    case FlarePermissionState.denied:
      return FlarePermissionCopy(
        title: title,
        description: '$verb的权限已被拒绝，$feature无法使用。请前往系统设置开启。',
        primaryLabel: '前往设置',
      );
    case FlarePermissionState.restricted:
      return FlarePermissionCopy(
        title: title,
        description: '$verb的权限受设备或组织策略限制，$feature暂不可用。',
        primaryLabel: '',
      );
    case FlarePermissionState.unavailable:
      return FlarePermissionCopy(
        title: title,
        description: '当前设备或运行环境不支持$verb，$feature暂不可用。',
        primaryLabel: '',
      );
  }
}

String defaultPermissionStateLabel(FlarePermissionState state) {
  switch (state) {
    case FlarePermissionState.undetermined:
      return '未授权';
    case FlarePermissionState.denied:
      return '已拒绝';
    case FlarePermissionState.restricted:
      return '受限制';
    case FlarePermissionState.unavailable:
      return '不可用';
  }
}

/// Unified "permission missing / denied" panel. The host owns the real
/// permission state and the request / openSettings side effects; this widget
/// only explains and dispatches. Spec: General/PermissionPrompt
/// (`FlarePermissionPrompt`).
class FlarePermissionPrompt extends StatelessWidget {
  const FlarePermissionPrompt({
    super.key,
    required this.kind,
    required this.state,
    this.featureLabel,
    this.detail,
    this.busy = false,
    this.compact = false,
    this.title,
    this.description,
    this.stateText,
    this.requestText,
    this.openSettingsText,
    this.dismissText = '知道了',
    this.onRequest,
    this.onOpenSettings,
    this.onDismiss,
  });

  final FlarePermissionKind kind;
  final FlarePermissionState state;

  /// What the permission unlocks, e.g. "发送语音消息".
  final String? featureLabel;

  /// Extra host explanation shown under the description.
  final String? detail;
  final bool busy;

  /// Inline single-row mode for placing above a composer; default is a card.
  final bool compact;
  final String? title, description, stateText, requestText, openSettingsText;
  final String dismissText;
  final VoidCallback? onRequest, onOpenSettings, onDismiss;

  Color _tone(FlareColors colors) {
    switch (state) {
      case FlarePermissionState.undetermined:
        return colors.info;
      case FlarePermissionState.denied:
        return colors.error;
      case FlarePermissionState.restricted:
        return colors.warning;
      case FlarePermissionState.unavailable:
        return colors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    final copy = defaultPermissionCopy(kind, state, featureLabel: featureLabel);
    final actions = permissionActions(
      state,
      hasRequest: onRequest != null,
      hasOpenSettings: onOpenSettings != null,
      hasDismiss: onDismiss != null,
      busy: busy,
    );
    final tone = _tone(colors);
    final resolvedTitle = title ?? copy.title;
    final iconSize = compact ? 32.0 : 44.0;

    final icon = Container(
      width: iconSize,
      height: iconSize,
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: FlareIcon(
        permissionIconName(kind),
        size: compact ? 20 : 26,
        color: colors.primary,
      ),
    );

    final heading = Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: FlareSizes.spacingSm,
      runSpacing: FlareSizes.spacingXs,
      children: [
        Text(
          resolvedTitle,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: compact ? FlareSizes.fontSizeLg : FlareSizes.fontSizeXl,
            fontWeight: FontWeight.w600,
          ),
        ),
        Semantics(
          liveRegion: true,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(FlareSizes.radiusFull),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                FlareIcon(permissionStateIconName(state), size: 14, color: tone),
                const SizedBox(width: FlareSizes.spacingXs),
                Text(
                  stateText ?? defaultPermissionStateLabel(state),
                  style: TextStyle(
                    color: tone,
                    fontSize: FlareSizes.fontSizeXs,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        heading,
        const SizedBox(height: FlareSizes.spacingXs),
        Text(
          description ?? copy.description,
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: compact ? FlareSizes.fontSizeSm : FlareSizes.fontSizeMd,
            height: FlareSizes.lineHeightNormal,
          ),
        ),
        if (detail != null && detail!.isNotEmpty) ...[
          const SizedBox(height: FlareSizes.spacingXs),
          Text(
            detail!,
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: FlareSizes.fontSizeSm,
              height: FlareSizes.lineHeightNormal,
            ),
          ),
        ],
      ],
    );

    final buttons = <Widget>[
      if (actions.request)
        _primary(requestText ?? copy.primaryLabel, actions.enabled ? onRequest : null),
      if (actions.openSettings)
        _primary(openSettingsText ?? copy.primaryLabel, actions.enabled ? onOpenSettings : null),
      if (actions.dismiss)
        OutlinedButton(
          onPressed: actions.enabled ? onDismiss : null,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(48, 48),
            foregroundColor: colors.textPrimary,
            side: BorderSide(color: colors.borderPrimary),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(FlareSizes.radiusLg),
            ),
          ),
          child: Text(dismissText),
        ),
    ];
    final actionRow = buttons.isEmpty
        ? null
        : Wrap(spacing: FlareSizes.spacingSm, runSpacing: FlareSizes.spacingSm, children: buttons);

    final content = compact
        ? LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 480;
              if (wide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    icon,
                    const SizedBox(width: FlareSizes.spacingMd),
                    Expanded(child: body),
                    if (actionRow != null) ...[
                      const SizedBox(width: FlareSizes.spacingMd),
                      actionRow,
                    ],
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      icon,
                      const SizedBox(width: FlareSizes.spacingMd),
                      Expanded(child: body),
                    ],
                  ),
                  if (actionRow != null) ...[
                    const SizedBox(height: FlareSizes.spacingSm),
                    actionRow,
                  ],
                ],
              );
            },
          )
        : Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              icon,
              const SizedBox(width: FlareSizes.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    body,
                    if (actionRow != null) ...[
                      const SizedBox(height: FlareSizes.spacingMd),
                      actionRow,
                    ],
                  ],
                ),
              ),
            ],
          );

    return Semantics(
      container: true,
      label: resolvedTitle,
      child: Container(
        padding: compact
            ? const EdgeInsets.symmetric(
                horizontal: FlareSizes.spacingMd,
                vertical: FlareSizes.spacingSm,
              )
            : const EdgeInsets.all(FlareSizes.spacingLg),
        decoration: BoxDecoration(
          color: colors.bgSecondary,
          borderRadius: BorderRadius.circular(
            compact ? FlareSizes.radiusMd : FlareSizes.radiusLg,
          ),
          border: compact ? Border.all(color: colors.borderSecondary) : null,
        ),
        child: content,
      ),
    );
  }

  Widget _primary(String label, VoidCallback? onPressed) => ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 48, maxWidth: 240),
        child: FlarePrimaryButton(
          label: label,
          loading: busy,
          onPressed: onPressed,
        ),
      );
}
