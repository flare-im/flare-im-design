import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/directory_data.dart';
import '../tokens/flare_tokens.dart';
import 'flare_button.dart';
import 'flare_icon.dart';
import 'flare_primary_button.dart';
import 'flare_status_banner.dart';

/// Why the current session can no longer be used. Supplied by the host session layer.
enum FlareReauthReason { sessionExpired, kicked, credentialInvalid, accountDisabled }

/// Semantic tone of the reason glyph (never the only signal: the text always names the reason).
enum FlareReauthTone { info, warning, danger }

FlareReauthTone reauthTone(FlareReauthReason reason) => switch (reason) {
      FlareReauthReason.sessionExpired => FlareReauthTone.info,
      FlareReauthReason.kicked => FlareReauthTone.warning,
      FlareReauthReason.credentialInvalid => FlareReauthTone.warning,
      FlareReauthReason.accountDisabled => FlareReauthTone.danger,
    };

/// Semantic icon name (shared icon library) for each reason.
String reauthIcon(FlareReauthReason reason) => switch (reason) {
      FlareReauthReason.sessionExpired => 'clock',
      FlareReauthReason.kicked => 'devices',
      FlareReauthReason.credentialInvalid => 'lock',
      FlareReauthReason.accountDisabled => 'block',
    };

@immutable
class FlareReauthActionState {
  const FlareReauthActionState({required this.visible, required this.enabled});
  final bool visible, enabled;
  @override
  bool operator ==(Object other) =>
      other is FlareReauthActionState && other.visible == visible && other.enabled == enabled;
  @override
  int get hashCode => Object.hash(visible, enabled);
  @override
  String toString() => 'FlareReauthActionState(visible: $visible, enabled: $enabled)';
}

@immutable
class FlareReauthActions {
  const FlareReauthActions({required this.reauthenticate, required this.logout, required this.primary});
  final FlareReauthActionState reauthenticate, logout;
  /// True when Enter should trigger re-authentication; false when it is unavailable.
  final bool primary;
}

/// Which actions to show and whether they are enabled.
/// - reauthenticate needs a host handler and is never offered for a disabled account.
/// - logout needs a host handler.
/// - busy locks every action; the host sets it synchronously before dispatching.
FlareReauthActions reauthActions(
  FlareReauthReason reason, {
  required bool hasReauth,
  required bool hasLogout,
  bool busy = false,
}) {
  final reauthVisible = hasReauth && reason != FlareReauthReason.accountDisabled;
  return FlareReauthActions(
    reauthenticate: FlareReauthActionState(visible: reauthVisible, enabled: reauthVisible && !busy),
    logout: FlareReauthActionState(visible: hasLogout, enabled: hasLogout && !busy),
    primary: reauthVisible,
  );
}

/// Re-authentication prompt shown when the session can no longer be used.
/// The host owns the login flow and the container (full-screen overlay or
/// dialog); this panel names the reason, locks repeat submits, keeps the last
/// failure visible and dispatches [onReauthenticate] / [onLogout]. Buttons
/// whose callback is null are not rendered. Enter triggers the primary action;
/// Escape and system back are swallowed because a broken session cannot be
/// dismissed. Spec: General/ReauthPrompt (`FlareReauthPrompt`).
class FlareReauthPrompt extends StatelessWidget {
  const FlareReauthPrompt({
    super.key,
    required this.reason,
    this.detail,
    this.busy = false,
    this.error,
    this.accountLabel,
    this.title = '需要重新登录',
    this.sessionExpiredText = '登录状态已过期，请重新登录后继续。',
    this.kickedText = '你的账号已在其它设备登录，当前设备已下线。',
    this.credentialInvalidText = '登录凭证已失效，请重新登录。',
    this.accountDisabledText = '账号已被停用，暂时无法登录，请联系管理员。',
    this.reauthenticateText = '重新登录',
    this.busyText = '正在重新登录…',
    this.logoutText = '退出登录',
    this.accountCaption = '当前账号',
    this.onReauthenticate,
    this.onLogout,
  });

  final FlareReauthReason reason;
  final String? detail;
  final bool busy;
  final String? error;
  final String? accountLabel;
  final String title;
  final String sessionExpiredText, kickedText, credentialInvalidText, accountDisabledText;
  final String reauthenticateText, busyText, logoutText, accountCaption;
  final VoidCallback? onReauthenticate;
  final VoidCallback? onLogout;

  String get _reasonText => switch (reason) {
        FlareReauthReason.sessionExpired => sessionExpiredText,
        FlareReauthReason.kicked => kickedText,
        FlareReauthReason.credentialInvalid => credentialInvalidText,
        FlareReauthReason.accountDisabled => accountDisabledText,
      };

  Color _toneColor(FlareColors colors) => switch (reauthTone(reason)) {
        FlareReauthTone.info => colors.info,
        FlareReauthTone.warning => colors.warning,
        FlareReauthTone.danger => colors.error,
      };

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(Theme.of(context).brightness);
    final tone = _toneColor(colors);
    final actions = reauthActions(reason, hasReauth: onReauthenticate != null, hasLogout: onLogout != null, busy: busy);
    void reauthenticate() {
      if (actions.reauthenticate.enabled) onReauthenticate?.call();
    }

    return PopScope(
      canPop: false,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.enter): () {
            if (actions.primary) reauthenticate();
          },
          const SingleActivator(LogicalKeyboardKey.numpadEnter): () {
            if (actions.primary) reauthenticate();
          },
          // Swallowed: a broken session cannot be dismissed.
          const SingleActivator(LogicalKeyboardKey.escape): () {},
        },
        child: Focus(
          autofocus: true,
          child: Semantics(
            container: true,
            label: title,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: FlareSizes.spacingXl, vertical: FlareSizes.spacing2xl),
                decoration: BoxDecoration(
                  color: colors.bgPrimary,
                  borderRadius: BorderRadius.circular(FlareSizes.radiusXl),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(color: tone.withValues(alpha: 0.12), shape: BoxShape.circle),
                        child: Center(child: FlareIcon(reauthIcon(reason), size: 28, color: tone)),
                      ),
                    ),
                    const SizedBox(height: FlareSizes.spacingLg),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.textPrimary, fontSize: FlareSizes.fontSize3xl, fontWeight: FontWeight.w600, height: 1.3),
                    ),
                    const SizedBox(height: FlareSizes.spacingSm),
                    Text(
                      _reasonText,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colors.textPrimary, fontSize: FlareSizes.fontSizeLg, height: 1.5),
                    ),
                    if (detail != null && detail!.isNotEmpty) ...[
                      const SizedBox(height: FlareSizes.spacingSm),
                      Text(
                        detail!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colors.textSecondary, fontSize: FlareSizes.fontSizeMd, height: 1.5),
                      ),
                    ],
                    if (accountLabel != null && accountLabel!.isNotEmpty) ...[
                      const SizedBox(height: FlareSizes.spacingMd),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: colors.bgSecondary,
                            borderRadius: BorderRadius.circular(FlareSizes.radiusFull),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(accountCaption, style: TextStyle(color: colors.textSecondary, fontSize: FlareSizes.fontSizeSm)),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  accountLabel!,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: colors.textPrimary, fontSize: FlareSizes.fontSizeSm, fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (error != null && error!.isNotEmpty) ...[
                      const SizedBox(height: FlareSizes.spacingMd),
                      Semantics(liveRegion: true, child: FlareStatusBanner(text: error!, tone: FlareStatusTone.danger)),
                    ],
                    if (actions.reauthenticate.visible || actions.logout.visible) const SizedBox(height: FlareSizes.spacingXl),
                    if (actions.reauthenticate.visible)
                      FlarePrimaryButton(
                        label: reauthenticateText,
                        loading: busy,
                        loadingLabel: busyText,
                        disabled: !actions.reauthenticate.enabled,
                        onPressed: reauthenticate,
                      ),
                    if (actions.reauthenticate.visible && actions.logout.visible) const SizedBox(height: FlareSizes.spacingSm),
                    if (actions.logout.visible)
                      FlareButton(
                        label: logoutText,
                        variant: FlareButtonVariant.secondary,
                        size: FlareControlSize.lg,
                        block: true,
                        disabled: !actions.logout.enabled,
                        onPressed: () {
                          if (actions.logout.enabled) onLogout?.call();
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
