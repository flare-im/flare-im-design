import 'package:flutter/material.dart';

import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_bottom_sheet.dart';
import 'flare_icon.dart';
import '../models/directory_data.dart';
import 'flare_button.dart';

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
/// [granted] lets a host bind the platform's permission status directly: the
/// prompt renders nothing for it.
enum FlarePermissionState {
  undetermined,
  denied,
  restricted,
  unavailable,
  granted,
}

/// What the person chose on a prompt presented with
/// [FlarePermissionPrompt.show].
enum FlarePermissionChoice { request, openSettings, dismiss }

/// Whether the prompt draws anything. Nothing for
/// [FlarePermissionState.granted]. A soft-ask is an invitation the person can
/// act on, so it shows only while the permission can be asked for or turned
/// on in settings.
bool permissionPromptShows(
  FlarePermissionState state, {
  bool softAsk = false,
}) {
  switch (state) {
    case FlarePermissionState.granted:
      return false;
    case FlarePermissionState.undetermined:
    case FlarePermissionState.denied:
      return true;
    case FlarePermissionState.restricted:
    case FlarePermissionState.unavailable:
      return !softAsk;
  }
}

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

  /// Visible whenever the host supplied a handler and the prompt shows.
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
}) => FlarePermissionActions(
  request: state == FlarePermissionState.undetermined && hasRequest,
  openSettings: state == FlarePermissionState.denied && hasOpenSettings,
  dismiss: state != FlarePermissionState.granted && hasDismiss,
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
      return 'storage';
    case FlarePermissionKind.photos:
      return 'image';
    case FlarePermissionKind.contacts:
      return 'people';
    case FlarePermissionKind.location:
      return 'location';
    case FlarePermissionKind.screen:
      return 'screen-share';
  }
}

/// State glyph so status never relies on colour alone.
String permissionStateIconName(FlarePermissionState state) {
  switch (state) {
    case FlarePermissionState.undetermined:
      return 'info';
    case FlarePermissionState.denied:
      return 'error';
    case FlarePermissionState.restricted:
      return 'lock';
    case FlarePermissionState.unavailable:
      return 'warning';
    case FlarePermissionState.granted:
      return 'success';
  }
}

/// `featureLabel` (e.g. "发送语音消息") is embedded in the description.
///
/// `strings` defaults to the kit's own copy; the widget passes the ambient
/// [FlareStrings] so a host that overrides them at the root gets translated
/// defaults here too. [FlarePermissionState.granted] has nothing to explain:
/// an empty description and no primary action.
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
    case FlarePermissionState.granted:
      return FlarePermissionCopy(
        title: title,
        description: '',
        primaryLabel: '',
      );
  }
}

/// The copy of a soft-ask (`FlarePermissionPrompt(softAsk: true)`). The
/// notifications kind has its own: an invitation titled for new messages,
/// "Turn on notifications" while the system can still ask and, once
/// notifications were turned off, "Open Settings" with where to turn them back
/// on. Any other kind keeps [defaultPermissionCopy].
FlarePermissionCopy defaultPermissionSoftAskCopy(
  FlarePermissionKind kind,
  FlarePermissionState state, {
  String? featureLabel,
  FlareStrings strings = const FlareStrings(),
}) {
  if (kind == FlarePermissionKind.notifications) {
    final title = strings.permissionSoftAskNotificationsTitle;
    if (state == FlarePermissionState.undetermined) {
      return FlarePermissionCopy(
        title: title,
        description: strings.permissionSoftAskNotificationsBody,
        primaryLabel: strings.permissionSoftAskNotificationsAction,
      );
    }
    if (state == FlarePermissionState.denied) {
      return FlarePermissionCopy(
        title: title,
        description: strings.permissionSoftAskNotificationsDeniedBody,
        primaryLabel: strings.permissionOpenSettings,
      );
    }
  }
  return defaultPermissionCopy(
    kind,
    state,
    featureLabel: featureLabel,
    strings: strings,
  );
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
    case FlarePermissionState.granted:
      return strings.permissionStateGranted;
  }
}

/// Unified "permission missing / denied" panel. The host owns the real
/// permission state and the request / openSettings side effects; this widget
/// only explains and dispatches. Spec: General/PermissionPrompt
/// (`FlarePermissionPrompt`).
///
/// [softAsk] is the non-blocking invitation a host shows at a moment it picks
/// (the first visit to the conversation list, say): no state chip, a "Not now"
/// dismiss and, for the notifications kind, copy of its own
/// ([defaultPermissionSoftAskCopy]). It shows only while the person can act on
/// it ([permissionPromptShows]); [FlarePermissionState.granted] renders
/// nothing, so a host binds the platform's status as it is. To ask in a kit
/// bottom sheet, use [FlarePermissionPrompt.show].
class FlarePermissionPrompt extends StatelessWidget {
  const FlarePermissionPrompt({
    super.key,
    required this.kind,
    required this.state,
    this.featureLabel,
    this.detail,
    this.busy = false,
    this.compact = false,
    this.softAsk = false,
    this.title,
    this.description,
    this.stateText,
    this.requestText,
    this.openSettingsText,
    this.dismissText,
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

  /// The non-blocking invitation: no state chip, "Not now", shown only while
  /// the person can act on it.
  final bool softAsk;
  final String? title, description, stateText, requestText, openSettingsText;

  /// Defaults to [FlareStrings.permissionNotNow] on a soft-ask and
  /// [FlareStrings.permissionDismiss] otherwise.
  final String? dismissText;
  final VoidCallback? onRequest, onOpenSettings, onDismiss;

  /// Asks in a kit bottom sheet — the sheet form of the prompt, usually a
  /// soft-ask at a moment the host picks. It follows [FlareBottomSheet.show]
  /// `auto`: a bottom sheet on the phone form factor, a centered FlareModal
  /// elsewhere.
  ///
  /// Resolves with the key the person pressed once the sheet is gone, so the
  /// system's own permission dialog then has the screen to itself; closing it
  /// by the scrim, a drag, Escape or back is [FlarePermissionChoice.dismiss].
  /// Resolves null at once, showing nothing, while the prompt would not show
  /// ([permissionPromptShows]). [request] and [openSettings] say which keys
  /// the host offers.
  static Future<FlarePermissionChoice?> show(
    BuildContext context, {
    required FlarePermissionKind kind,
    required FlarePermissionState state,
    bool softAsk = false,
    String? featureLabel,
    String? detail,
    String? title,
    String? description,
    String? requestText,
    String? openSettingsText,
    String? dismissText,
    bool request = true,
    bool openSettings = true,
  }) async {
    if (!permissionPromptShows(state, softAsk: softAsk)) return null;
    final strings = FlareStrings.of(context);
    final copy = softAsk
        ? defaultPermissionSoftAskCopy(
            kind,
            state,
            featureLabel: featureLabel,
            strings: strings,
          )
        : defaultPermissionCopy(
            kind,
            state,
            featureLabel: featureLabel,
            strings: strings,
          );
    final choice = await FlareBottomSheet.show<FlarePermissionChoice>(
      context,
      title: title ?? copy.title,
      // The prompt draws its own heading; the sheet keeps the title as its
      // accessible name only.
      titleHidden: true,
      builder: (sheet) => _FlarePermissionSheetBody(
        kind: kind,
        state: state,
        softAsk: softAsk,
        featureLabel: featureLabel,
        detail: detail,
        title: title,
        description: description,
        requestText: requestText,
        openSettingsText: openSettingsText,
        dismissText: dismissText,
        onRequest: request
            ? () => Navigator.of(sheet).pop(FlarePermissionChoice.request)
            : null,
        onOpenSettings: openSettings
            ? () =>
                  Navigator.of(sheet).pop(FlarePermissionChoice.openSettings)
            : null,
        onDismiss: () =>
            Navigator.of(sheet).pop(FlarePermissionChoice.dismiss),
      ),
    );
    return choice ?? FlarePermissionChoice.dismiss;
  }

  Color _tone(FlareColors colors) {
    switch (state) {
      case FlarePermissionState.undetermined:
      case FlarePermissionState.granted:
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
    if (!permissionPromptShows(state, softAsk: softAsk)) {
      return const SizedBox.shrink();
    }
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final copy = softAsk
        ? defaultPermissionSoftAskCopy(
            kind,
            state,
            featureLabel: featureLabel,
            strings: strings,
          )
        : defaultPermissionCopy(
            kind,
            state,
            featureLabel: featureLabel,
            strings: strings,
          );
    final actions = permissionActions(
      state,
      hasRequest: onRequest != null,
      hasOpenSettings: onOpenSettings != null,
      hasDismiss: onDismiss != null,
      busy: busy,
    );
    final tone = _tone(colors);
    final resolvedTitle = title ?? copy.title;

    final icon = _PermissionIcon(kind: kind, compact: compact);

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
        // A soft-ask is an invitation, not a status report: it carries no
        // state chip.
        if (!softAsk)
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
                  FlareIcon(
                    permissionStateIconName(state),
                    size: 14,
                    color: tone,
                  ),
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
        _primary(
          requestText ?? copy.primaryLabel,
          actions.enabled ? onRequest : null,
        ),
      if (actions.openSettings)
        _primary(
          openSettingsText ?? copy.primaryLabel,
          actions.enabled ? onOpenSettings : null,
        ),
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
          child: Text(
            dismissText ??
                (softAsk
                    ? strings.permissionNotNow
                    : strings.permissionDismiss),
          ),
        ),
    ];
    final actionRow = buttons.isEmpty
        ? null
        : Wrap(
            spacing: FlareSizes.spacingSm,
            runSpacing: FlareSizes.spacingSm,
            children: buttons,
          );

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
    child: FlareButton(
      label: label,
      size: FlareControlSize.lg,
      block: true,
      loading: busy,
      onPressed: onPressed,
    ),
  );
}

/// The kind's glyph on a tinted disc.
class _PermissionIcon extends StatelessWidget {
  const _PermissionIcon({required this.kind, required this.compact});
  final FlarePermissionKind kind;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final side = compact ? 32.0 : 44.0;
    return Container(
      width: side,
      height: side,
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: FlareIcon(
        permissionIconName(kind),
        size: compact ? 20 : 26,
        color: colors.primaryText,
      ),
    );
  }
}

/// The prompt as the body of a kit sheet ([FlarePermissionPrompt.show]): icon,
/// heading and explanation in one centered column, then full-width keys with
/// the action first and "Not now" under it.
class _FlarePermissionSheetBody extends StatelessWidget {
  const _FlarePermissionSheetBody({
    required this.kind,
    required this.state,
    required this.softAsk,
    required this.featureLabel,
    required this.detail,
    required this.title,
    required this.description,
    required this.requestText,
    required this.openSettingsText,
    required this.dismissText,
    required this.onRequest,
    required this.onOpenSettings,
    required this.onDismiss,
  });

  final FlarePermissionKind kind;
  final FlarePermissionState state;
  final bool softAsk;
  final String? featureLabel, detail, title, description;
  final String? requestText, openSettingsText, dismissText;
  final VoidCallback? onRequest, onOpenSettings, onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final copy = softAsk
        ? defaultPermissionSoftAskCopy(
            kind,
            state,
            featureLabel: featureLabel,
            strings: strings,
          )
        : defaultPermissionCopy(
            kind,
            state,
            featureLabel: featureLabel,
            strings: strings,
          );
    final actions = permissionActions(
      state,
      hasRequest: onRequest != null,
      hasOpenSettings: onOpenSettings != null,
      hasDismiss: onDismiss != null,
    );
    final detail = this.detail;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        FlareSizes.spacingLg,
        FlareSizes.spacingSm,
        FlareSizes.spacingLg,
        FlareSizes.spacingXl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(child: _PermissionIcon(kind: kind, compact: false)),
          const SizedBox(height: FlareSizes.spacingMd),
          Semantics(
            header: true,
            child: Text(
              title ?? copy.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: FlareSizes.fontSizeXl,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: FlareSizes.spacingXs),
          Text(
            description ?? copy.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: FlareSizes.fontSizeMd,
              height: FlareSizes.lineHeightNormal,
            ),
          ),
          if (detail != null && detail.isNotEmpty) ...[
            const SizedBox(height: FlareSizes.spacingXs),
            Text(
              detail,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textTertiary,
                fontSize: FlareSizes.fontSizeSm,
                height: FlareSizes.lineHeightNormal,
              ),
            ),
          ],
          const SizedBox(height: FlareSizes.spacingLg),
          if (actions.request) ...[
            FlareButton(
              label: requestText ?? copy.primaryLabel,
              size: FlareControlSize.lg,
              block: true,
              onPressed: onRequest,
            ),
            const SizedBox(height: FlareSizes.spacingSm),
          ],
          if (actions.openSettings) ...[
            FlareButton(
              label: openSettingsText ?? copy.primaryLabel,
              size: FlareControlSize.lg,
              block: true,
              onPressed: onOpenSettings,
            ),
            const SizedBox(height: FlareSizes.spacingSm),
          ],
          if (actions.dismiss)
            FlareButton(
              label:
                  dismissText ??
                  (softAsk
                      ? strings.permissionNotNow
                      : strings.permissionDismiss),
              variant: FlareButtonVariant.secondary,
              size: FlareControlSize.lg,
              block: true,
              onPressed: onDismiss,
            ),
        ],
      ),
    );
  }
}
