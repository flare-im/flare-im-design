import 'package:flutter/material.dart';

import '../models/capability_ui.dart';
import '../models/directory_data.dart';
import '../tokens/flare_strings.dart';
import '../tokens/flare_tokens.dart';
import 'flare_bottom_sheet.dart';
import 'flare_button.dart';
import 'flare_icon.dart';

/// The consent a host shows the first time a plugin uses a host capability
/// (design 7.4; spec Message/CapabilityConsent): "〈plugin〉 wants to use
/// 〈capability〉", the purpose, and allow once, always allow, don't allow.
///
/// The kit keeps no consent record: [onDecide] hands the choice back and the
/// host answers the engine with [flareCapabilityConsentAnswer] (`{decision}`;
/// the engine keeps only "always"). A one-time location is confirmed
/// every time, so it offers no "always". [show] presents it on the kit sheet
/// and resolves with the choice (deny when dismissed).
class FlareCapabilityConsent extends StatelessWidget {
  const FlareCapabilityConsent({
    super.key,
    required this.pluginName,
    required this.capability,
    this.params,
    this.purpose,
    this.busy = false,
    this.onDecide,
  });

  final String pluginName;

  /// The capability the engine asks about (`consent.capability`).
  final String capability;

  /// Its params (`consent.params`): a location's precision picks the line.
  final Map<String, Object?>? params;

  /// Why the plugin wants it, in the plugin's words, when the host has one.
  final String? purpose;
  final bool busy;
  final ValueChanged<FlareCapabilityConsentDecision>? onDecide;

  static Future<FlareCapabilityConsentDecision> show(
    BuildContext context, {
    required String pluginName,
    required String capability,
    Map<String, Object?>? params,
    String? purpose,
  }) async {
    final decision =
        await FlareBottomSheet.show<FlareCapabilityConsentDecision>(
          context,
          // §6.5: off the phone a 400 dialog, the payment sheet's width.
          dialogWidth: FlareSizes.componentPaymentDialogWidth,
          titleBuilder: (inner) => FlareStrings.of(
            inner,
          ).capabilityConsentTitle.replaceAll('{plugin}', pluginName),
          builder: (sheet) => FlareCapabilityConsent(
            pluginName: pluginName,
            capability: capability,
            params: params,
            purpose: purpose,
            onDecide: (d) => Navigator.of(sheet).pop(d),
          ),
        );
    return decision ?? FlareCapabilityConsentDecision.deny;
  }

  static const _icons = {
    'capabilityDocumentCapture': 'camera',
    'capabilityCamera': 'camera',
    'capabilityPaymentConfirmation': 'wallet',
    'capabilityLocationCoarse': 'location',
    'capabilityLocationFine': 'location',
    'capabilityMicrophone': 'mic',
    'capabilityRtcSession': 'video',
  };

  @override
  Widget build(BuildContext context) {
    final colors = FlareColors.of(context);
    final strings = FlareStrings.of(context);
    final always = flareCapabilityConsentAllowsAlways(capability);
    final key = flareCapabilityLabelKey(capability, params);
    void decide(FlareCapabilityConsentDecision d) {
      if (!busy) onDecide?.call(d);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        FlareSizes.spacingLg,
        FlareSizes.spacingSm,
        FlareSizes.spacingLg,
        FlareSizes.spacingLg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MergeSemantics(
            child: Row(
              children: [
                Container(
                  width: FlareSizes.touchTarget,
                  height: FlareSizes.touchTarget,
                  decoration: BoxDecoration(
                    color: colors.bgSecondary,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: FlareIcon(
                    _icons[key] ?? 'info',
                    color: colors.primaryText,
                  ),
                ),
                const SizedBox(width: FlareSizes.spacingMd),
                Expanded(
                  child: Text(
                    flareCapabilityLabel(strings, capability, params),
                    key: const ValueKey('flare-consent-label'),
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: FlareSizes.fontSize2xl,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (purpose != null && purpose!.trim().isNotEmpty) ...[
            const SizedBox(height: FlareSizes.spacingMd),
            Text(
              strings.capabilityConsentPurpose,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: FlareSizes.fontSizeSm,
              ),
            ),
            const SizedBox(height: FlareSizes.spacingXs),
            Text(
              purpose!,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: FlareSizes.fontSizeLg,
              ),
            ),
          ],
          if (always) ...[
            const SizedBox(height: FlareSizes.spacingMd),
            Text(
              strings.capabilityConsentNote,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: FlareSizes.fontSizeSm,
              ),
            ),
          ],
          const SizedBox(height: FlareSizes.spacingLg),
          if (always) ...[
            FlareButton(
              key: const ValueKey('flare-consent-always'),
              block: true,
              size: FlareControlSize.lg,
              label: strings.capabilityConsentAllowAlways,
              disabled: busy,
              onPressed: () => decide(FlareCapabilityConsentDecision.always),
            ),
            const SizedBox(height: FlareSizes.spacingSm),
          ],
          FlareButton(
            key: const ValueKey('flare-consent-once'),
            block: true,
            size: FlareControlSize.lg,
            variant: always
                ? FlareButtonVariant.secondary
                : FlareButtonVariant.primary,
            label: strings.capabilityConsentAllowOnce,
            disabled: busy,
            onPressed: () => decide(FlareCapabilityConsentDecision.once),
          ),
          const SizedBox(height: FlareSizes.spacingSm),
          FlareButton(
            key: const ValueKey('flare-consent-deny'),
            block: true,
            size: FlareControlSize.lg,
            variant: FlareButtonVariant.quiet,
            label: strings.capabilityConsentDeny,
            disabled: busy,
            onPressed: () => decide(FlareCapabilityConsentDecision.deny),
          ),
        ],
      ),
    );
  }
}
