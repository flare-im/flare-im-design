import 'package:flutter/material.dart';

import '../tokens/flare_strings.dart';
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
  screen,
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

String _kindNoun(FlarePermissionKind kind, FlareStrings s) {
  switch (kind) {
    case FlarePermissionKind.microphone:
      return s.microphone;
    case FlarePermissionKind.camera:
      return s.camera;
    case FlarePermissionKind.notifications:
      return s.permissionNotifications;
    case FlarePermissionKind.storage:
      return s.permissionStorage;
    case FlarePermissionKind.photos:
      return s.permissionPhotos;
    case FlarePermissionKind.contacts:
      return s.permissionContacts;
    case FlarePermissionKind.location:
      return s.permissionLocation;
    case FlarePermissionKind.screen:
      return s.permissionScreen;
  }
}

String _kindVerb(FlarePermissionKind kind, FlareStrings s) {
  switch (kind) {
    case FlarePermissionKind.microphone:
      return s.permissionVerbMicrophone;
    case FlarePermissionKind.camera:
      return s.permissionVerbCamera;
    case FlarePermissionKind.notifications:
      return s.permissionVerbNotifications;
    case FlarePermissionKind.storage:
      return s.permissionVerbStorage;
    case FlarePermissionKind.photos:
      return s.permissionVerbPhotos;
    case FlarePermissionKind.contacts:
      return s.permissionVerbContacts;
    case FlarePermissionKind.location:
      return s.permissionVerbLocation;
    case FlarePermissionKind.screen:
      return s.permissionVerbScreen;
  }
}

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
    case FlarePermissionKind.screen:
      return 'devices';
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
///
/// `strings` defaults to the kit's own copy; the widget passes the ambient
/// [FlareStrings] so a host that overrides them at the root gets translated
/// defaults here too.
FlarePermissionCopy defaultPermissionCopy(
  FlarePermissionKind kind,
  FlarePermissionState state, {
  String? featureLabel,
  FlareStrings strings = const FlareStrings(),
}) {
  final feature = (featureLabel?.trim().isNotEmpty ?? false)
      ? featureLabel!.trim()
      : strings.permissionThisFeature;
  final verb = _kindVerb(kind, strings);
  final title = strings.permissionTitle(_kindNoun(kind, strings));
  switch (state) {
    case FlarePermissionState.undetermined:
      return FlarePermissionCopy(
        title: title,
        description: strings.permissionUndeterminedDescription(feature, verb),
        primaryLabel: strings.permissionAllow,
      );
    case FlarePermissionState.denied:
      return FlarePermissionCopy(
        title: title,
        description: strings.permissionDeniedDescription(feature, verb),
        primaryLabel: strings.permissionOpenSettings,
      );
    case FlarePermissionState.restricted:
      return FlarePermissionCopy(
        title: title,
        description: strings.permissionRestrictedDescription(feature, verb),
        primaryLabel: '',
      );
    case FlarePermissionState.unavailable:
      return FlarePermissionCopy(
        title: title,
        description: strings.permissionUnavailableDescription(feature, verb),
        primaryLabel: '',
      );
  }
}

String defaultPermissionStateLabel(
  FlarePermissionState state, {
  FlareStrings strings = const FlareStrings(),
}) {
  switch (state) {
    case FlarePermissionState.undetermined:
      return strings.permissionStateUndetermined;
    case FlarePermissionState.denied:
      return strings.permissionStateDenied;
    case FlarePermissionState.restricted:
      return strings.permissionStateRestricted;
    case FlarePermissionState.unavailable:
      return strings.permissionStateUnavailable;
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
    final strings = FlareStrings.of(context);
    final copy = defaultPermissionCopy(kind, state,
        featureLabel: featureLabel, strings: strings);
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
                  stateText ??
                      defaultPermissionStateLabel(state, strings: strings),
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
